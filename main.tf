terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
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
 
 tags = {
   Name = "PublicSub1"
 }
}

resource "aws_subnet" "PublicSubnet2" {
  vpc_id = "${aws_vpc.prodVPC.id}"
  cidr_block = "10.1.1.0/24"
 
 tags = {
   Name = "PublicSub2"
 }
}


#resource "aws_route#53_record" "www" {
#  zone_id = aws_route53_zone.primary.zone_id
#  name    = "www.example.com"
#  type    = "A"
#  ttl     = 300
#  records = [aws_eip.lb.public_ip]
#}
