# VPC Module using official terraform-aws-modules/vpc
# Provides comprehensive VPC configuration with public/private subnets, NAT Gateways, and security features

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  # Database subnets for RDS
  database_subnets                   = var.database_subnets
  create_database_subnet_group       = var.create_database_subnet_group
  create_database_subnet_route_table = var.create_database_subnet_route_table

  # ElastiCache subnets
  elasticache_subnets = var.elasticache_subnets

  # Intra subnets (private with no internet access)
  intra_subnets = var.intra_subnets

  # NAT Gateway configuration
  enable_nat_gateway     = var.enable_nat_gateway
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az

  # Internet Gateway
  create_igw = var.create_igw

  # DNS configuration
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  # VPC Flow Logs
  enable_flow_log                      = var.enable_flow_log
  create_flow_log_cloudwatch_log_group = var.create_flow_log_cloudwatch_log_group
  create_flow_log_cloudwatch_iam_role  = var.create_flow_log_cloudwatch_iam_role

  # VPC Endpoints
  enable_vpn_gateway = var.enable_vpn_gateway

  # IPv6 support
  enable_ipv6 = var.enable_ipv6

  # Default security group
  manage_default_security_group  = var.manage_default_security_group
  default_security_group_ingress = var.default_security_group_ingress
  default_security_group_egress  = var.default_security_group_egress

  # DHCP options
  enable_dhcp_options      = var.enable_dhcp_options
  dhcp_options_domain_name = var.dhcp_options_domain_name

  # Tags
  tags = merge(
    var.tags,
    {
      Terraform   = "true"
      Environment = var.environment
      Module      = "vpc"
    }
  )

  vpc_tags = merge(
    var.vpc_tags,
    {
      Name = var.vpc_name
    }
  )

  public_subnet_tags = merge(
    var.public_subnet_tags,
    {
      "kubernetes.io/role/elb" = "1"
    }
  )

  private_subnet_tags = merge(
    var.private_subnet_tags,
    {
      "kubernetes.io/role/internal-elb" = "1"
    }
  )

  # Resource naming
  igw_tags = {
    Name = "${var.vpc_name}-igw"
  }

  nat_gateway_tags = {
    Name = "${var.vpc_name}-nat"
  }

  nat_eip_tags = {
    Name = "${var.vpc_name}-nat-eip"
  }
}
