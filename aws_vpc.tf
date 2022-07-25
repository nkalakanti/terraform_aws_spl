variable "vpc_cidr_block" {
  description = "cidr bock for vpc"
}

variable "private_subnet_cidr_block" {
  description = "cidr bock for private subnet"
}

variable "public_subnet_cidr_block" {
  description = "cidr bock for public subnet"
}

variable "private_ip" {
  description = "host ip of private subnet"
}

variable "public_ip" {
  description = "host ip of public subnet"
}

variable "vpc_name" {
  description = "Name for the VPC"
}

variable "availability_zone" {
  description = "Avaibility zone for subnet."
}

#VPC
resource "aws_vpc" "prod-vpc" {
  cidr_block       = var.vpc_cidr_block
  instance_tenancy = "default"

  tags = {
    Name = var.vpc_name
  }
}

#Internet Gatewat to make VPC connected to intenert
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vpc.id
}

#Common Routing table for public gateway
resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "${var.vpc_name}-aws_route_table"
  }
}

#private subnet
resource "aws_subnet" "private-subnet" {
  vpc_id            = aws_vpc.prod-vpc.id
  cidr_block        = var.private_subnet_cidr_block
  availability_zone = var.availability_zone

  tags = {
    Name = "${var.vpc_name}-private_subnet"
  }
}

#public subnet
resource "aws_subnet" "public-subnet" {
  vpc_id            = aws_vpc.prod-vpc.id
  cidr_block        = var.public_subnet_cidr_block
  availability_zone = var.availability_zone

  tags = {
    Name = "${var.vpc_name}-public_subnet"
  }
}

#Linking common routing table to public subner
resource "aws_route_table_association" "public-subnet-association" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.prod-route-table.id
}

#private subnet nic(Network Interface Card), this will link to ec2 instance as network card
resource "aws_network_interface" "private-web-server-nic" {
  subnet_id       = aws_subnet.private-subnet.id
  private_ips     = [var.private_ip]
  security_groups = [aws_security_group.allow_web_private.id]
}


#public subnet nic(Network Interface Card), this will link to ec2 instance as network card
resource "aws_network_interface" "public-web-server-nic" {
  subnet_id       = aws_subnet.public-subnet.id
  private_ips     = [var.public_ip]
  security_groups = [aws_security_group.allow_web_public.id]
}

#Elastic IP(Public IP) for public ec2
resource "aws_eip" "public-ip" {
  vpc                       = true
  network_interface         = aws_network_interface.public-web-server-nic.id
  associate_with_private_ip = var.public_ip
  depends_on                = [aws_internet_gateway.gw]
}

#Elastic IP for NAT Gateway. It will select a IP from public subnet, so it can forward private subnet requests to internet
resource "aws_eip" "nat-gateway-ip" {
  depends_on = [aws_route_table_association.public-subnet-association]
  vpc        = true
}

#Creation of NAT Gateway with public subnet's elastic ip
resource "aws_nat_gateway" "nat-gateway" {
  depends_on    = [aws_eip.nat-gateway-ip]
  allocation_id = aws_eip.nat-gateway-ip.id
  subnet_id     = aws_subnet.public-subnet.id
  tags = {
    Name = "Nat-Gateway-Private"
  }
}

#Routing Table for private subnet, refer to Network diagram for better understanding.
#It will re-route internet requests to NAT.
resource "aws_route_table" "nat-gateway-route-table" {
  depends_on = [aws_nat_gateway.nat-gateway]
  vpc_id     = aws_vpc.prod-vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gateway.id
  }
  tags = {
    Name = "Route Table for NAT Gateway"
  }

}

#Linking private subnet to NAT gateway using routing table
resource "aws_route_table_association" "nat-gateway-route-table-association" {
  depends_on     = [aws_route_table.nat-gateway-route-table]
  subnet_id      = aws_subnet.private-subnet.id
  route_table_id = aws_route_table.nat-gateway-route-table.id
}

#Security group for public ec2
resource "aws_security_group" "allow_web_public" {
  name        = "allow_web_public_traffic"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web_public"
  }
}

#Security group for private ec2
resource "aws_security_group" "allow_web_private" {
  name        = "allow_web_private_traffic"
  description = "Allow 8080 inbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description     = "8080"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.allow_web_public.id]
  }

  ingress {
    description     = "SSH"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.allow_web_public.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web_private"
  }
}