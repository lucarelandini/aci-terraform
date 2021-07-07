# Create a VPC to launch our instances into
resource "aws_vpc" "vpc_backend_demo" {
  cidr_block = "10.0.0.0/16"
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "gw_backend_demo" {
  vpc_id = aws_vpc.vpc_backend_demo.id
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.vpc_backend_demo.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw_backend_demo.id
}

# Create a subnet to launch our instances into
resource "aws_subnet" "sub_backend_demo" {
  vpc_id                  = aws_vpc.vpc_backend_demo.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

# Our default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "sg_backend_demo" {
  name        = random_pet.name.id
  description = "Used in the terraform"
  vpc_id      = aws_vpc.vpc_backend_demo.id

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = random_pet.name.id
  public_key = tls_private_key.example.public_key_openssh
}

resource "aws_instance" "backend_server" {
  key_name                = aws_key_pair.generated_key.key_name
  ami                     = var.ami
  instance_type           = var.instance_type
  vpc_security_group_ids  = [aws_security_group.sg_backend_demo.id]
  subnet_id               = aws_subnet.sub_backend_demo.id

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.example.private_key_pem
    host        = self.public_ip
  }

  tags = {
    Name      = random_pet.name.id
    owner     = "lrelandi@cisco.com"
    ttl       = 48
    se-region = "emea-se"
    purpose   = "test and demo policy tags enforcement"
    terraform = "true"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "sudo apt-get -y install nginx",
      "sudo service nginx start",
    ]
  }
}
