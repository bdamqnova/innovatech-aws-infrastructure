data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.project_name}-public-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "${var.project_name}-public-b"
  }
}

resource "aws_subnet" "web_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.project_name}-web-a"
  }
}

resource "aws_subnet" "web_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "${var.project_name}-web-b"
  }
}

resource "aws_subnet" "db_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.project_name}-db-a"
  }
}

resource "aws_subnet" "db_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "${var.project_name}-db-b"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name = "${var.project_name}-nat"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "web_private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-web-private-rt"
  }
}

resource "aws_route" "web_internet" {
  route_table_id         = aws_route_table.web_private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}

resource "aws_route_table_association" "web_a" {
  subnet_id      = aws_subnet.web_a.id
  route_table_id = aws_route_table.web_private.id
}

resource "aws_route_table_association" "web_b" {
  subnet_id      = aws_subnet.web_b.id
  route_table_id = aws_route_table.web_private.id
}

resource "aws_route_table" "db_private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-db-private-rt"
  }
}

resource "aws_route" "db_internet" {
  route_table_id         = aws_route_table.db_private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}

resource "aws_route_table_association" "db_a" {
  subnet_id      = aws_subnet.db_a.id
  route_table_id = aws_route_table.db_private.id
}

resource "aws_route_table_association" "db_b" {
  subnet_id      = aws_subnet.db_b.id
  route_table_id = aws_route_table.db_private.id
}
resource "aws_vpc_security_group_egress_rule" "db_outbound" {
  security_group_id = aws_security_group.db.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# MONITORING PRIVATE SUBNET/ I need to learn this

resource "aws_subnet" "monitoring_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.30.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.project_name}-monitoring-a"
  }
}

# Route table for the monitoring subnet

resource "aws_route_table" "monitoring_private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-monitoring-private-rt"
  }
}

# Allow monitoring EC2 to access the internet through NAT

resource "aws_route" "monitoring_internet" {
  route_table_id         = aws_route_table.monitoring_private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}

# Connect monitoring subnet to its route table

resource "aws_route_table_association" "monitoring_a" {
  subnet_id      = aws_subnet.monitoring_a.id
  route_table_id = aws_route_table.monitoring_private.id
}