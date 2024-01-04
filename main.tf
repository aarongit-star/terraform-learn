provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "dev-vpc" {
  cidr_block       = "10.0.0.0/16"

  tags = {
    Name = "dev-vpc"
  }
}

variable "subnet_cidr_block" {}

resource "aws_subnet" "dev-subnet-1" {
  vpc_id     = aws_vpc.dev-vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = "us-east-1a"

  tags = {
    Name = "dev-subnet-1"
  }
}

output "dev-vpc-id" {
    value = aws_vpc.dev-vpc.id
}

output "aws_subnet-id" {
    value = aws_subnet.dev-subnet-1.id
}

