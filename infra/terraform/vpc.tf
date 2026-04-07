# ---------------------------------------------------------------------------
# VPC + Networking
# Previously created by eksctl; now managed by Terraform for full rebuild.
#
# Import commands (one-time, already-existing resources):
#   terraform import aws_vpc.main                          vpc-04031749c8b836ba7
#   terraform import aws_subnet.public_1b                  subnet-0af9da2aa1bda019d
#   terraform import aws_subnet.public_1f                  subnet-09316561ce8129bce
#   terraform import aws_subnet.private_1b                 subnet-04947bfff2536a195
#   terraform import aws_subnet.private_1f                 subnet-00e80835781aa3152
#   terraform import aws_internet_gateway.main             igw-0ce7bccf64c353e2a
#   terraform import aws_eip.nat                           eipalloc-069f3df9eff06a346
#   terraform import aws_nat_gateway.main                  nat-0e79d8e0ecd6ebdc9
#   terraform import aws_route_table.public                rtb-0da2b5691e7d8fe06
#   terraform import aws_route_table.private_1b            rtb-028238e18dc158ba4
#   terraform import aws_route_table.private_1f            rtb-0672ea0641c3ad2ee
#   terraform import aws_route_table_association.public_1b subnet-0af9da2aa1bda019d/rtb-0da2b5691e7d8fe06
#   terraform import aws_route_table_association.public_1f subnet-09316561ce8129bce/rtb-0da2b5691e7d8fe06
#   terraform import aws_route_table_association.private_1b subnet-04947bfff2536a195/rtb-028238e18dc158ba4
#   terraform import aws_route_table_association.private_1f subnet-00e80835781aa3152/rtb-0672ea0641c3ad2ee
# ---------------------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  lifecycle {
    ignore_changes = [tags, tags_all]
  }
}

# ---------------------------------------------------------------------------
# Subnets
# ---------------------------------------------------------------------------

resource "aws_subnet" "public_1b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "192.168.0.0/19"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  lifecycle {
    ignore_changes = [tags, tags_all]
  }
}

resource "aws_subnet" "public_1f" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "192.168.32.0/19"
  availability_zone       = "us-east-1f"
  map_public_ip_on_launch = true

  lifecycle {
    ignore_changes = [tags, tags_all]
  }
}

resource "aws_subnet" "private_1b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "192.168.64.0/19"
  availability_zone = "us-east-1b"

  lifecycle {
    ignore_changes = [tags, tags_all]
  }
}

resource "aws_subnet" "private_1f" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "192.168.96.0/19"
  availability_zone = "us-east-1f"

  lifecycle {
    ignore_changes = [tags, tags_all]
  }
}

# ---------------------------------------------------------------------------
# Internet Gateway
# ---------------------------------------------------------------------------

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  lifecycle {
    ignore_changes = [tags, tags_all]
  }
}

# ---------------------------------------------------------------------------
# NAT Gateway (single, in public_1b)
# ---------------------------------------------------------------------------

resource "aws_eip" "nat" {
  domain = "vpc"

  lifecycle {
    ignore_changes = [tags, tags_all]
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1b.id

  lifecycle {
    ignore_changes = [tags, tags_all]
  }

  depends_on = [aws_internet_gateway.main]
}

# ---------------------------------------------------------------------------
# Route Tables
# ---------------------------------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  lifecycle {
    ignore_changes = [tags, tags_all]
  }
}

resource "aws_route_table" "private_1b" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  lifecycle {
    ignore_changes = [tags, tags_all]
  }
}

resource "aws_route_table" "private_1f" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  lifecycle {
    ignore_changes = [tags, tags_all]
  }
}

# ---------------------------------------------------------------------------
# Route Table Associations
# ---------------------------------------------------------------------------

resource "aws_route_table_association" "public_1b" {
  subnet_id      = aws_subnet.public_1b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1f" {
  subnet_id      = aws_subnet.public_1f.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_1b" {
  subnet_id      = aws_subnet.private_1b.id
  route_table_id = aws_route_table.private_1b.id
}

resource "aws_route_table_association" "private_1f" {
  subnet_id      = aws_subnet.private_1f.id
  route_table_id = aws_route_table.private_1f.id
}
