

resource "aws_vpc_endpoint" "service_endpoint" {
  count               = length(var.service_endpoints)
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.${var.service_endpoints[count.index]}"
  vpc_endpoint_type   = "Interface"

  //security_group_ids  = [module.sg_module[count.index].instance_sg[0]]

  security_group_ids  = [var.security_group_ids[count.index].instance_sg[0]]
  subnet_ids          = var.subnet_ids
  private_dns_enabled = true

  tags = {
    Name              = replace("vpce-${var.service_endpoints[count.index]}-${var.env_profile}",".", "-")
    Owner             = var.owner
    Managed_by        = "Terraform"
    Environment       = var.env_profile
  }
}


resource "aws_vpc_endpoint" "s3_gateway_endpoint" {
  count               = length(var.gateway_endpoints)
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.${var.gateway_endpoints[count.index]}"
  vpc_endpoint_type   = "Gateway"
  route_table_ids     = var.route_tables


  tags = {
    Name              = "vpce-${var.gateway_endpoints[count.index]}-${var.env_profile}"
    Owner             = var.owner
    Managed_by        = "Terraform"
    Environment       = var.env_profile
  }
}

