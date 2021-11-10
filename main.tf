provider "aws" {
  region  = "eu-west-1"
  profile = "development"
}

resource "aws_vpc" "prod-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "production"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vpc.id
}

resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route = [{
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
    },
    {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw.id
  }]
  tags = {
    "Name" = "Prod"
  }
}

resource "aws_subnet" "subnet-1" {
  vpc_id            = aws_vpc.prod-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-1a"

  tags = {
    "Name" = "prod-subnet"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}

resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow Web Inbound Traffic"
  vpc_id      = aws_vpc.prod-vpc.id


  ingress = [{
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
    from_port   = 443
    protocol    = "tcp"
    to_port     = 443
    },
    {
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP"
      from_port   = 80
      protocol    = "tcp"
      to_port     = 80
    },
    {
      cidr_blocks = ["0.0.0.0/0"]
      description = "SSH"
      from_port   = 22
      protocol    = "tcp"
      to_port     = 22
  }]
  egress = [{
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }]
  tags = {
    "Name" = "allow-web"
  }
}

resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

  tags = {
    "Name" = "prod-nic-for-web-server"
  }
}

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [
    aws_internet_gateway.gw
  ]
  tags = {
    "Name" = "prod-web-server-eip"
  }
}

resource "aws_instance" "web-server-instance" {
  ami               = "ami-08edbb0e85d6a0a07"
  instance_type     = "t2.micro"
  availability_zone = "eu-west-1a"
  key_name          = "main-key"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.web-server-nic.id
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo bash -c 'echo First Web Server with Terraform  > /var/www/html/index.html'
              EOF

  tags = {
    "Name" = "web-server"
  }
}
