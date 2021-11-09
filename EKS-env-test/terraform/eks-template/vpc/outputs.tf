# VPC
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

# Subnets
output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}
output "public_subnets" {
  description = "List of IDs of public_subnets"
  value       = module.vpc.public_subnets
}
 

output "main_route_table" {
  description = "main route table value"
  value = module.vpc.vpc_main_route_table_id
}

output "private_route_table" {
  description = "private route table value"
  value = module.vpc.private_route_table_ids[0]
}

output "public_route_table" {
  description = "public route table value"
  value = module.vpc.public_route_table_ids[0]
}