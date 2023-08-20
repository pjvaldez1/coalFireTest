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
  region = var.region
}


# Generates a secure private key and encodes it as PEM
resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create the Key Pair
resource "aws_key_pair" "generated_key" {
  key_name   = "adminKey"
  public_key = tls_private_key.example.public_key_openssh
}

# Save file
resource "local_file" "ssh_key" {
  filename = "${aws_key_pair.generated_key.key_name}.pem"
  content  = tls_private_key.example.private_key_pem
}

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
  #availability_zone = "us-west-2a"
  availability_zone = tolist(var.azs)[0]
  cidr_block        = "10.1.4.0/24"

  tags = {
    Name = "DBSubnet1"
  }
}

resource "aws_subnet" "DBSubnet2" {

  vpc_id            = aws_vpc.prodVPC.id
  #availability_zone = "us-west-2b"
  availability_zone = tolist(var.azs)[1]
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
    description = "RDP access"
    from_port   = 3389
    to_port     = 3389 
    protocol    = "tcp"
    #TEST, access from Home....I mean not my home....
    cidr_blocks = ["71.227.192.209/32"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0",aws_subnet.PrivateSubnet1.cidr_block,aws_subnet.PrivateSubnet2.cidr_block]
  }
  tags = {
    Name = "web_fw"
  }
}


resource "aws_security_group" "wp_sg1" {
  name        = "wp_sg1"
  description = "Least permissive in Private Subnet1"
  vpc_id      = aws_vpc.prodVPC.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_subnet.PrivateSubnet1.cidr_block,aws_subnet.PublicSubnet1.cidr_block]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_subnet.PrivateSubnet1.cidr_block,aws_subnet.PrivateSubnet2.cidr_block,aws_subnet.DBSubnet1.cidr_block]
  }

  tags = {
    Name = "wp_sg1"

  }
}

resource "aws_security_group" "wp_sg2" {
  name        = "wp_sg2"
  description = "Least permissive in Private Subnet2"
  vpc_id      = aws_vpc.prodVPC.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_subnet.PrivateSubnet2.cidr_block,aws_subnet.PublicSubnet1.cidr_block]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_subnet.PrivateSubnet1.cidr_block,aws_subnet.PrivateSubnet2.cidr_block,aws_subnet.DBSubnet1.cidr_block]
  }

  tags = {
    Name = "wp_sg2"

  }
}

resource "aws_security_group" "db_sg" {
  name        = "db_sg"
  description = "Least permissive in DB Subnet"
  vpc_id      = aws_vpc.prodVPC.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_subnet.DBSubnet1.cidr_block,aws_subnet.PrivateSubnet1.cidr_block,aws_subnet.PrivateSubnet2.cidr_block]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_subnet.DBSubnet1.cidr_block]
  }

  tags = {
    Name = "db_sg"

  }
}

data "template_file" "user_datapowershell" {
  template = <<EOF
<powershell>
Rename-Computer -NewName "bastion1" -Force -Restart
</powershell>
EOF
}


resource "aws_instance" "pubOS1" {
  depends_on = [
    aws_security_group.web_fw
  ]
  ami                    = "ami-0f4aa97e74fc14682"
  instance_type          = "t3a.micro"
  subnet_id              = aws_subnet.PublicSubnet1.id
  vpc_security_group_ids = [aws_security_group.web_fw.id]
  user_data = data.template_file.user_datapowershell.rendered
  #key_name = aws_key_pair.key_pair.key_name
  key_name      = aws_key_pair.generated_key.key_name
  associate_public_ip_address = true 

root_block_device {
    volume_size = 50
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "pubOS1"
  }

}

resource "aws_eip" "eip_pubOS1" {
  instance = aws_instance.pubOS1.id
  vpc = true
}




# data "template_file" "user_data_webOS1" {
#  template = <<EOF
#    #!/bin/bash
#    sudo hostname wpserver1
#  EOF  
#}

# data "template_file" "user_data_webOS2" {
#  template = <<EOF
#    #!/bin/bash
#    sudo hostname wpserver2
#  EOF  
#}

resource "aws_instance" "webOS1" {
  depends_on = [
    aws_security_group.web_fw
  ]
  ami                    = "ami-00aa0673b34e3c150"
  instance_type          = "t3a.micro"
  subnet_id              = aws_subnet.PrivateSubnet1.id
  vpc_security_group_ids = [aws_security_group.wp_sg1.id]

 ####################
 ## Pause, Time Constraint  ##
 #
 # Issue, No access to instance from Terraform client
 # The SecurityGroup for this client is locked in a non-PublicSubnet.
 # Remote-exec will not work.
 # 
 # provisioner "remote-exec" {
 # inline = ["sudo hostnamectl set-hostname wpserver1"]
 # connection {
 #  host        = coalesce(self.public_ip, self.private_ip)
 #  agent       = false
 #  type        = "ssh"
 #  user        = "ec2-user"
 #  private_key = file("${aws_key_pair.generated_key.key_name}.pem")
 #  }
 # }
 # 
 # Going to Figure out on a later day.
 #
 ####################

  key_name      = aws_key_pair.generated_key.key_name 

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
  vpc_security_group_ids = [aws_security_group.wp_sg2.id]
  key_name      = aws_key_pair.generated_key.key_name
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
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  allocated_storage    = 50
  skip_final_snapshot  = true
  apply_immediately    = true
  backup_retention_period = 0
  ##BadPractice, shutting off the backups for dev-test purposes.
}


#Note: Only Compute...Soooo no services....
#resource "aws_route#53_record" "www" {
#  zone_id = aws_route53_zone.primary.zone_id
#  name    = "www.example.com"
#  type    = "A"
#  ttl     = 300
#  records = [aws_eip.lb.public_ip]
#}
