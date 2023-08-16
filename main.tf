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

resource "aws_vpc" "prodVPC" {
 cidr_block = "10.1.0.0/16"
 
 tags = {
   Name = "Prod-VPC"
 }
}

resource "aws_subnet" "PublicSubnet1" {
  vpc_id = "${aws_vpc.prodVPC.id}"
  cidr_block = "10.1.0.0/24"
  map_public_ip_on_launch = "true"
 tags = {
   Name = "PublicSub1"
 }
}

resource "aws_subnet" "PublicSubnet2" {
  vpc_id = "${aws_vpc.prodVPC.id}"
  cidr_block = "10.1.1.0/24"
  map_public_ip_on_launch = "true"
 
 tags = {
   Name = "PublicSub2"
 }
}

resource "aws_internet_gateway" "terragw" {
  vpc_id = "${aws_vpc.prodVPC.id}"
  tags = {
    Name = "terragw"
  }
}

resource "aws_route_table" "terra_route_table_for_IGW" {
  vpc_id = "${aws_vpc.prodVPC.id}"
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
  vpc_id = "${aws_vpc.prodVPC.id}"
  cidr_block = "10.1.2.0/24"
 
 tags = {
   Name = "PrivateSub1"
 }
}

resource "aws_subnet" "PrivateSubnet2" {
  vpc_id = "${aws_vpc.prodVPC.id}"
  cidr_block = "10.1.2.0/24"
 
 tags = {
   Name = "PrivateSub2"
 }
}

#resource "aws_route#53_record" "www" {
#  zone_id = aws_route53_zone.primary.zone_id
#  name    = "www.example.com"
#  type    = "A"
#  ttl     = 300
#  records = [aws_eip.lb.public_ip]
#}
