output "instance_sg" {
  description = "The ID of the security group"
  value = aws_security_group.instance_sg.*.id
}