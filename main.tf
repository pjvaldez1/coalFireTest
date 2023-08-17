terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  backend "s3" {
    bucket = "pjtfstate"
    key    = "terraform"
    region = "us-west-2"
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-west-2"
}

#resource "tls_private_key" "web_key" {
#  algorithm = "RSA"
#  rsa_bits  = 4096
#}

#resource "local_file" "private_key" {
#  content         = tls_private_key.web_key.private_key_pem
#  filename        = "sysAccess.pem"
#  file_permission = 0400
#}

#resource "aws_key_pair" "sys_key" {
#  key_name   = "mykey22"
#  public_key = tls_private_key.web_key.public_key_openssh
#}

resource "aws_vpc" "prodVPC" {
  cidr_block = "10.1.0.0/16"

  tags = {
    Name = "Prod-VPC"
  }
}

resource "aws_subnet" "PublicSubnet1" {
  vpc_id                  = aws_vpc.prodVPC.id
  cidr_block              = "10.1.0.0/24"
  map_public_ip_on_launch = "true"
  tags = {
    Name = "PublicSub1"
  }
}

resource "aws_subnet" "PublicSubnet2" {
  vpc_id                  = aws_vpc.prodVPC.id
  cidr_block              = "10.1.1.0/24"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "PublicSub2"
  }
}

resource "aws_internet_gateway" "terragw" {
  vpc_id = aws_vpc.prodVPC.id
  tags = {
    Name = "terragw"
  }
}

resource "aws_route_table" "terra_route_table_for_IGW" {
  vpc_id = aws_vpc.prodVPC.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terragw.id
  }

  tags = {
    Name = "terra_route_table_for_IGW"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.PublicSubnet1.id
  route_table_id = aws_route_table.terra_route_table_for_IGW.id
}
resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.PublicSubnet2.id
  route_table_id = aws_route_table.terra_route_table_for_IGW.id
}

resource "aws_subnet" "PrivateSubnet1" {
  vpc_id     = aws_vpc.prodVPC.id
  cidr_block = "10.1.2.0/24"

  tags = {
    Name = "PrivateSub1"
  }
}

resource "aws_subnet" "PrivateSubnet2" {
  vpc_id     = aws_vpc.prodVPC.id
  cidr_block = "10.1.3.0/24"

  tags = {
    Name = "PrivateSub2"
  }
}

resource "aws_subnet" "DBSubnet1" {
  vpc_id            = aws_vpc.prodVPC.id
  availability_zone = "us-west-2a"
  cidr_block        = "10.1.4.0/24"

  tags = {
    Name = "DBSubnet1"
  }
}

resource "aws_subnet" "DBSubnet2" {

  vpc_id            = aws_vpc.prodVPC.id
  availability_zone = "us-west-2b"
  cidr_block        = "10.1.5.0/24"

  tags = {
    Name = "DBSubnet2"
  }
}

resource "aws_security_group" "web_fw" {
  name        = "web_fw"
  description = "Allow TCP inbound traffic for WebSite"
  vpc_id      = aws_vpc.prodVPC.id
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
    Name = "web_fw"
  }
}

resource "aws_instance" "pubOS1" {
  depends_on = [
    aws_security_group.web_fw
  ]
  ami                    = "ami-0f4aa97e74fc14682"
  instance_type          = "t3a.micro"
  subnet_id              = aws_subnet.PublicSubnet1.id
  vpc_security_group_ids = [aws_security_group.web_fw.id]

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "pubOS1"
  }

}

resource "aws_instance" "webOS1" {
  depends_on = [
    aws_security_group.web_fw
  ]
  ami                    = "ami-00aa0673b34e3c150"
  instance_type          = "t3a.micro"
  subnet_id              = aws_subnet.PrivateSubnet1.id
  vpc_security_group_ids = [aws_security_group.web_fw.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "webOS1"
  }

}

resource "aws_instance" "webOS2" {
  depends_on = [
    aws_security_group.web_fw
  ]
  ami                    = "ami-00aa0673b34e3c150"
  instance_type          = "t3a.micro"
  subnet_id              = aws_subnet.PrivateSubnet2.id
  vpc_security_group_ids = [aws_security_group.web_fw.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "webOS2"
  }
}

resource "aws_db_subnet_group" "dbSubnets" {
  name       = "main"
  subnet_ids = [aws_subnet.DBSubnet1.id,aws_subnet.DBSubnet2.id]

  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_db_instance" "web_db" {
  db_name              = "RDS1"
  engine               = "postgres"
  engine_version       = "11"
  instance_class       = "db.t3.micro"
  username             = "foo"
  password             = "foobarbaz"
  db_subnet_group_name = aws_db_subnet_group.dbSubnets.name
  allocated_storage    = 50
}

#resource "aws_route#53_record" "www" {
#  zone_id = aws_route53_zone.primary.zone_id
#  name    = "www.example.com"
#  type    = "A"
#  ttl     = 300
#  records = [aws_eip.lb.public_ip]
#}
