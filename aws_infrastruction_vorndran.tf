provider "aws" {
  region     = "us-east-1"
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


resource "aws_security_group" "test1" {
  name        = "test1"
  description = "Allow inbound SSH"

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
ingress {
     description = "HTTP"
     from_port   = 8080
     to_port     = 8080
     protocol    = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
   }
     egress {
     from_port   = 0
     to_port     = 0
     protocol    = "-1"
     cidr_blocks = ["0.0.0.0/0"]
   }
}


resource "aws_instance" "ec2_web_pipeline" {
  ami           = data.aws_ami.ami_dynamic.id
  instance_type = "t2.micro"

  tags = {
    Name = "project-terrafrom-instance"
  }
   key_name = "web-key"
   user_data = <<-EOF
      #!/bin/bash
        sudo yum install git -y
        sudo amazon-linux-extras install java-openjdk11 -y
  	   sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
        sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
        sudo yum install jenkins -y
        sudo systemctl start jenkins
   EOF
}

resource "aws_network_interface_sg_attachment" "sg_attachment1" {

security_group_id = aws_security_group.test1.id

network_interface_id = aws_instance.web1.primary_network_interface_id

}
