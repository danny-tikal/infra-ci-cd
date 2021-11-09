resource "aws_security_group" "jenkins_worker_linux" {
  name        = "${var.env_profile}_jenkins_worker_linux"
  description = "Jenkins Server: created by Terraform for ${var.env_profile}"

# legacy name of VPC ID
  vpc_id = "${var.vpc_id}"

  tags = {
    Name = "${var.env_profile}_jenkins_worker_linux"
    env  = "${var.env_profile}"
  }
}

###############################################################################
# ALL INBOUND
###############################################################################

# ssh
resource "aws_security_group_rule" "jenkins_worker_linux_from_source_ingress_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = "${aws_security_group.jenkins_worker_linux.id}"
  cidr_blocks       = var.accepted_cidrs
  description       = "ssh to jenkins_worker_linux"
}

resource "aws_security_group_rule" "jenkins_worker_linux_allow_from_master_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = "${aws_security_group.jenkins_worker_linux.id}"
  cidr_blocks       = ["${local.public_jenkins_ip}/32"]
  description       = "ssh to jenkins_worker_linux"
}

###############################################################################
# ALL OUTBOUND
###############################################################################

resource "aws_security_group_rule" "jenkins_worker_linux_to_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.jenkins_worker_linux.id}"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "allow jenkins worker to all"
}

data "aws_ami" "jenkins_worker_linux" {
 most_recent = true
 owners = [ "amazon" ]
 filter {
   name   = "owner-alias"
   values = ["amazon"]
 }


 filter {
   name   = "name"
   values = ["ubuntu-*-*-amd64-server-*"]
 }
}
data "local_file" "jenkins_worker_pem" {
  filename = pathexpand("~/.ssh/explorium.pem")

}

data "aws_secretsmanager_secret" "token" {
  name = "jenkins_api_token" # need to create manually
}

data "aws_secretsmanager_secret_version" "current" {
  secret_id = data.aws_secretsmanager_secret.token.id
}
data "template_file" "userdata_jenkins_worker_linux" {
  template = "${file("scripts/jenkins_worker_linux.sh")}"

  vars = {
    env_profile         = "${var.env_profile}"
    region      = "${var.region}"
    datacenter  = "${var.env_profile}-${var.region}"
    argo_cli_version = "v2.0.5"
    name   = "${var.env_profile}-jenkins_worker_linux"
    server_ip   = "${var.jenkins_master_ip}"
    explorium_pem  = "${data.local_file.jenkins_worker_pem.content}"
    elastic_ip = "${aws_eip.lb.public_ip}"
    jenkins_username = "jenkins@explorium.ai"
    jenkins_password = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["token"]
  }
}

resource "aws_iam_role" "eks_access_role" {
  name = "eks-${var.env_profile}_access_role"
  assume_role_policy = "${file("assumerolepolicy.json")}"
}

resource "aws_iam_policy" "policy" {
  name        = "eks-${var.env_profile}-jenkins-policy"
  description = "Connection from jenkins slave to eks-${var.env_profile} cluster policy"
  policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          "Effect": "Allow",
          "Action": "eks:*",
          "Resource": "arn:aws:eks:${var.region}:182893536443:cluster/eks-${var.env_profile}"
        },
        {
            "Effect": "Allow",
            "Action": [
                "route53:*",
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:*",
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ses:*"
            ],
            "Resource": "*"
        }
      ]
    })
}

resource "aws_iam_policy_attachment" "attach-role" {
  name       = "eks-${var.env_profile}-jenkins-attachment"
  roles      = ["${aws_iam_role.eks_access_role.name}"]
  policy_arn = "${aws_iam_policy.policy.arn}"
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.env_profile}_jenkins_access"
  role = aws_iam_role.eks_access_role.name
}
module "ec2_cluster" {
  source                 = "../../modules/resources/ec2_cluster"

  name                   = "${var.env_profile}-jenkins-worker-linux"
  instance_count         = 1
  associate_public_ip_address = true
  ami                    = "${data.aws_ami.jenkins_worker_linux.image_id}"
  iam_instance_profile   = "${var.env_profile}_jenkins_access"
  instance_type          = "t3a.2xlarge"
  key_name               = "explorium"
  monitoring             = true
  subnet_ids              = var.subnet_ids
  vpc_security_group_ids = ["${aws_security_group.jenkins_worker_linux.id}"]
  user_data              = "${data.template_file.userdata_jenkins_worker_linux.rendered}"
  root_block_device = [
      {
        volume_size = 80
      }
  ]
  tags = {
    Name               = "${var.env_profile}-jenkins_worker_linux"
    class              = "${var.env_profile}-jenkins_worker_linux"
    Type               = "infrastructure"
  }

  depends_on = [
    aws_iam_instance_profile.ec2_instance_profile
  ]
}

resource "aws_eip" "lb" {
  vpc      = true
}
resource "aws_eip_association" "eip_assoc" {
  instance_id   = module.ec2_cluster.id[0]
  allocation_id = aws_eip.lb.id
}

data "aws_instance" "jenkins_master" {
  filter {
    name   = "tag:Name"
    values = ["** jenkins **"] # TODO add var
  }
}
locals {
  public_jenkins_ip = data.aws_instance.jenkins_master.public_ip
}

data "aws_security_group" "jenkins_master" {
  tags = {
    name = "${var.master_jenkins_sg_name_tag}"
  }
}
resource "aws_security_group_rule" "master_nat" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["${aws_eip.lb.public_ip}/32"]
  security_group_id = data.aws_security_group.jenkins_master.id
  description = "jenkins slave ${var.env_profile} connection"
}