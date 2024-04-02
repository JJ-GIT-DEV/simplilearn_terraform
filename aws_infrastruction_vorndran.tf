provider "aws" {
  region     = var.region
  shared_credentials_files = ["~/.aws/credentials"]
}

data "aws_ami" "ami_dynamic" {
  most_recent      = true
  owners           = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

resource "aws_vpc" "sl-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
  Name = "sl-vpc"
  }
}

resource "aws_subnet" "subnet-1" {
  vpc_id     = aws_vpc.sl-vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  depends_on = [aws_vpc.sl-vpc ]
  tags = {
    Name = "subnet-1"
  }
}
resource "aws_route_table" "sl-route-table" {
  vpc_id = aws_vpc.sl-vpc.id
  tags = {
    Name = "sl-route-table"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.sl-route-table.id
}

resource "aws_internet_gateway" "sl-gw" {
  vpc_id = aws_vpc.sl-vpc.id
  depends_on = [aws_vpc.sl-vpc ] 
  tags = {
    Name = "sl-gw"
  }
}

resource "aws_route" "sl-route" {
  route_table_id            = aws_route_table.sl-route-table.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.sl-gw.id
}

resource "aws_security_group" "allow_web" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.sl-vpc.id
  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  
  }
  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
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
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "allow_tls"
  }
}

resource "tls_private_key" "web-key" {
  algorithm = "RSA"
}

resource "aws_key_pair" "app-web-key" {
  key_name   = "web-key"
  public_key = tls_private_key.web-key.public_key_openssh
}

resource "local_file" "web-key" {
  content  = tls_private_key.web-key.private_key_pem
  filename = "web-key.pem"
}

resource "aws_instance" "ec2_web_pipeline" {
  ami           = data.aws_ami.ami_dynamic.id
  instance_type = var.instance_type
  count = var.instance_count
  subnet_id = aws_subnet.subnet-1.id
  key_name = "web-key"
  security_groups = [aws_security_group.allow_web.id]
  tags = {
    Name = "${var.environment}-${count.index}"
  }
  provisioner "remote-exec" {
    connection {
        type     = "ssh"
        user     = "ec2-user"
        private_key = tls_private_key.web-key.private_key_pem
        host     = self.public_ip
    }
  inline = [
        "sudo yum update -y",
        "sudo yum install git -y",
        "sudo amazon-linux-extras install java-openjdk11 -y",
        "sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo",
        "sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key",
        "sudo yum install jenkins -y",
        "sudo yum install python3.9 -y"
    ]
  }
}