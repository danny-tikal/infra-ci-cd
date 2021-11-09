output "image_id" {
  description = "jenkins slave image id"
  value       = module.ec2_cluster.id
}
output "elastic_ip" {
  description = "jenkins slave image id"
  value       = aws_eip.lb.public_ip
}