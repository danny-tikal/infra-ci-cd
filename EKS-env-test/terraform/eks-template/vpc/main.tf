# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE VPC and Perimeter81 Connection
# ---------------------------------------------------------------------------------------------------------------------

data "aws_availability_zones" "available" {}

locals {
  cluster_name = "eks-${var.env_profile}"
}

module "vpc" {
  source  = "../../modules/resources/vpc"

  name                 = "${var.env_profile}-vpc"
  cidr                 = var.vpc_cidr
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = var.private_subnets
  public_subnets       = var.public_subnets
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  #enable_vpn_gateway   = true

  tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

resource "aws_vpn_gateway" "vpn" {
  vpc_id = module.vpc.vpc_id
  tags = {
    Name = "perimter81${var.env_profile}vpc"
  }
}

resource "aws_vpn_connection" "main" {
  vpn_gateway_id      = aws_vpn_gateway.vpn.id
  customer_gateway_id = var.customer_gw
  type                = "ipsec.1"
  static_routes_only  = true
  tags = {
    Name = "perimter81${var.env_profile}"
  }
}

resource "aws_vpn_connection_route" "perimeter81" {
  destination_cidr_block = var.destination_p81_cidr
  vpn_connection_id      = aws_vpn_connection.main.id
}

resource "aws_route" "r" {
  route_table_id            = module.vpc.vpc_main_route_table_id
  destination_cidr_block    = var.destination_p81_cidr
  gateway_id                = aws_vpn_gateway.vpn.id
  depends_on                = [aws_vpn_gateway.vpn]
}

resource "aws_route" "r-private" {
  route_table_id            = module.vpc.private_route_table_ids[0]
  destination_cidr_block    = var.destination_p81_cidr
  gateway_id                = aws_vpn_gateway.vpn.id
  depends_on                = [aws_vpn_gateway.vpn]
}

resource "aws_route" "r-public" {
  route_table_id            = module.vpc.public_route_table_ids[0]
  destination_cidr_block    = var.destination_p81_cidr
  gateway_id                = aws_vpn_gateway.vpn.id
  depends_on                = [aws_vpn_gateway.vpn]
}

## add to route assoc
data "aws_route53_zone" "ninja" {
  name         = "int.explorium.ninja"
  private_zone = true
}

resource "aws_route53_zone_association" "secondary" {
  zone_id = data.aws_route53_zone.ninja.zone_id
  vpc_id  = module.vpc.vpc_id
}

resource "aws_ec2_transit_gateway_vpc_attachment" "management_tgw"{
  subnet_ids         = module.vpc.private_subnets
  transit_gateway_id = var.management_tgw_id
  vpc_id             = module.vpc.vpc_id

  tags = {
    Name        = "${var.env_profile}"
  }
}