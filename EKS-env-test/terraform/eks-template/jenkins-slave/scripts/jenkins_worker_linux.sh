#!/bin/bash
set -x
sudo apt update
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    unzip \
    lsb-release \
    netcat \
    default-jre \
    git-all \
    wget \
    default-jre \
    docker.io -y
sudo apt install python3-pip -y
sudo pip3 install boto3
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 10
sudo curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/${argo_cli_version}/argocd-linux-amd64
sudo chmod +x /usr/local/bin/argocd
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo unzip awscliv2.zip
sudo ./aws/install
aws eks --region ${region} update-kubeconfig --name "eks-${env_profile}" --kubeconfig /home/ubuntu/.kube/config
# Allow access to github.com; or else we'll get host verification errors in the jobs
cat > /home/ubuntu/.ssh/config <<EOF
Host github.com
StrictHostKeyChecking no
EOF

# Vpc assoc with route ninja, login logic
function wait_for_jenkins ()
{
    echo "Waiting jenkins to launch on HTTPS..."

    while (( 1 )); do
        echo "Waiting for Jenkins"

        nc -zv ${server_ip} 443
        if (( $? == 0 )); then
            break
        fi

        sleep 10
    done

    echo "Jenkins launched"
}

function wait_for_argo ()
{
    echo "Waiting argocd to launch on HTTPS..."

    while (( 1 )); do
        echo "Waiting for argocd"

        nc -zv argocd-${env_profile}.int.explorium.ninja 443
        if (( $? == 0 )); then
            break
        fi

        sleep 10
    done

    echo "ArgoCD launched"
}


function slave_setup()
{
    # Wait till jar file gets available
    ret=1
    while (( $ret != 0 )); do
        sudo wget -O /opt/jenkins-cli.jar https://${server_ip}/jnlpJars/jenkins-cli.jar --no-check-certificate
        ret=$?

        echo "jenkins cli ret [$ret]"
    done

    ret=1
    while (( $ret != 0 )); do
        sudo wget -O /opt/slave.jar https://${server_ip}/jnlpJars/slave.jar --no-check-certificate
        ret=$?

        echo "jenkins slave ret [$ret]"
    done
    
    sudo mkdir -p /opt/jenkins-slave
    sudo chown -R ubuntu:ubuntu /opt/jenkins-slave

    # Register_slave
    JENKINS_URL="https://${server_ip}"

    JENKINS_USERNAME="${jenkins_username}"
    
    # PASSWORD=$(cat /tmp/secret)
    JENKINS_PASSWORD="${jenkins_password}"

    SLAVE_IP=${elastic_ip}
    NODE_NAME="${name}"
    NODE_SLAVE_HOME="/opt/jenkins-slave"
    EXECUTORS=10
    SSH_PORT=22

    CRED_ID="$NODE_NAME"
    LABELS="$NODE_NAME"
    USERID="ubuntu"

    cd /opt
    
    # Creating CMD utility for jenkins-cli commands
    jenkins_cmd="java -jar /opt/jenkins-cli.jar -s $JENKINS_URL -auth $JENKINS_USERNAME:$JENKINS_PASSWORD"

    # Waiting for Jenkins to load all plugins
    while (( 1 )); do

      count=$($jenkins_cmd list-plugins 2>/dev/null | wc -l)
      ret=$?

      echo "count [$count] ret [$ret]"

      if (( $count > 0 )); then
          break
      fi

      sleep 30
    done

    # Delete Credentials if present for respective slave machines
    $jenkins_cmd delete-credentials system::system::jenkins _ $CRED_ID

    # Generating cred.xml for creating credentials on Jenkins server
    cat > /tmp/cred.xml <<EOF
<com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey plugin="ssh-credentials@1.16">
  <scope>GLOBAL</scope>
  <id>$CRED_ID</id>
  <description>Generated via Terraform for $SLAVE_IP</description>
  <username>$USERID</username>
  <privateKeySource class="com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey\$DirectEntryPrivateKeySource">
    <privateKey>${explorium_pem}</privateKey>
  </privateKeySource>
</com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey>
EOF

    # Creating credential using cred.xml
    cat /tmp/cred.xml | $jenkins_cmd create-credentials-by-xml system::system::jenkins _

    # For Deleting Node, used when testing
    $jenkins_cmd delete-node $NODE_NAME
    
    # Generating node.xml for creating node on Jenkins server
    cat > /tmp/node.xml <<EOF
<slave>
  <name>$NODE_NAME</name>
  <description>Linux Slave</description>
  <remoteFS>$NODE_SLAVE_HOME</remoteFS>
  <numExecutors>$EXECUTORS</numExecutors>
  <mode>NORMAL</mode>
  <retentionStrategy class="hudson.slaves.RetentionStrategy\$Always"/>
  <launcher class="hudson.plugins.sshslaves.SSHLauncher" plugin="ssh-slaves@1.5">
    <host>$SLAVE_IP</host>
    <port>$SSH_PORT</port>
    <credentialsId>$CRED_ID</credentialsId>
  </launcher>
  <label>$LABELS</label>
  <nodeProperties/>
  <userId>$USERID</userId>
</slave>
EOF

  sleep 10
  
  # Creating node using node.xml
  cat /tmp/node.xml | $jenkins_cmd create-node $NODE_NAME
}

### script begins here ###

wait_for_jenkins

slave_setup

wait_for_argo
runuser -l ubuntu -c "sudo chown -R ubuntu /home/ubuntu/.kube"
runuser -l ubuntu -c "argocd login argocd-${env_profile}.int.explorium.ninja --username admin --password $(kubectl get secret -n argocd argocd-initial-admin-secret -o yaml --kubeconfig /home/ubuntu/.kube/config | grep password| head -1| cut -d " " -f4 | base64 -d) --grpc-web"
runuser -l ubuntu -c "curl -L https://git.io/get_helm.sh | bash && helm init"
runuser -l ubuntu -c "export BINARY_NAME=helm3 && curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash"
runuser -l ubuntu -c "kubectl -n kube-system create serviceaccount tiller"
runuser -l ubuntu -c "kubectl -n kube-system create clusterrolebinding tiller-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:tiller"
runuser -l ubuntu -c "kubectl -n kube-system patch deploy tiller-deploy -p '{\"spec\":{\"template\":{\"spec\":{\"serviceAccount\":\"tiller\"}}}}'"

echo "Done"
exit 0