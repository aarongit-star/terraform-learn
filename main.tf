provider "aws" {
  region = "us-east-1"
}

variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable avail_zone {}
variable env_prefix {}
variable public_key {}


resource "aws_vpc" "myapp-vpc" {
  cidr_block       = var.vpc_cidr_block

  tags = {
    Name = "${var.env_prefix}-vpc"
  }
}


resource "aws_subnet" "myapp-subnet-1" {
  vpc_id     = aws_vpc.myapp-vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.avail_zone

  tags = {
    Name = "${var.env_prefix}-subnet-1"
  }
}


resource "aws_route_table" "myapp-route-table" {
    vpc_id     = aws_vpc.myapp-vpc.id

    route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }

   tags = {
    Name = "${var.env_prefix}-rtb"
  }

}

resource "aws_internet_gateway" "myapp-igw" {
  vpc_id     = aws_vpc.myapp-vpc.id

   tags = {
    Name = "${var.env_prefix}-igw"
  }

}

resource "aws_route_table_association" "a-rtb-subnet" {
  subnet_id      = aws_subnet.myapp-subnet-1.id
  route_table_id = aws_route_table.myapp-route-table.id
}

resource "aws_security_group" "myapp-sg" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.myapp-vpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["1.145.233.68/32"]
    
  }

    ingress {
    description      = "TLS from VPC"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  tags = {
    Name = "allow_tls"
  }
}

data "aws_ami" "latest-amazon-ami" {
  most_recent      = true
  owners = ["amazon"]
 

}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = var.public_key
}

resource "aws_instance" "mywebserver" {
  ami           = data.aws_ami.latest-amazon-ami.id
  instance_type = "t2.micro"
  subnet_id =aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids  = [aws_security_group.myapp-sg.id]
  availability_zone=var.avail_zone
  associate_public_ip_address =true
  key_name = aws_key_pair.deployer.key_name

  user_data = file("entry-script.sh")

  tags = {
    Name = "myserver"
  }
}

output "server_ip" {
  value = aws_instance.mywebserver.public_ip
}