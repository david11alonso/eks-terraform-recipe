module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = "wavelength-eks-vpc"

  cidr = "172.20.0.0/16"
  azs  = ["eu-west-3a", "eu-west-3b", "eu-west-3c"] # Regional AZs only

  private_subnets = ["172.20.1.0/24", "172.20.2.0/24"]
  public_subnets  = ["172.20.4.0/24", "172.20.5.0/24", "172.20.6.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
  }
}

# Wavelength Zone Subnet
resource "aws_subnet" "wavelength_subnet" {
  vpc_id            = module.vpc.vpc_id
  cidr_block        = "172.20.10.0/24"
  availability_zone = "eu-west-3-cmn-wlz-1a" # Wavelength Zone

  tags = {
    Name = "Wavelength Zone Subnet"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "NAT Gateway EIP"
  }
}

# NAT Gateway in a Regional Subnet (not Wavelength)
resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = module.vpc.public_subnets[0] # Ensure it's a regional subnet

  tags = {
    Name = "NAT Gateway"
  }
}

# Route Wavelength Zone traffic through NAT Gateway
resource "aws_route_table" "wavelength" {
  vpc_id = module.vpc.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }
}

resource "aws_route_table_association" "wavelength" {
  subnet_id      = aws_subnet.wavelength_subnet.id
  route_table_id = aws_route_table.wavelength.id
}
