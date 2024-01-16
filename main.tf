#generate new key-pair using
#ssh-keygen -t rsa -f C:\terraform_pythonapp_provisioners\id_rsa

resource "aws_key_pair" "mykey" {
  key_name   = "bala-terraform"
  public_key = file("id_rsa.pub")
}
resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "mypubsubnet" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "myigw" {
  vpc_id = aws_vpc.myvpc.id
}

resource "aws_route_table" "myrt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myigw.id
  }
}

resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.mypubsubnet.id
  route_table_id = aws_route_table.myrt.id
}

resource "aws_security_group" "mysecgrp" {
  name   = "mywebapp-traffic"
  vpc_id = aws_vpc.myvpc.id
  ingress {
    description = "enabling ssh port for connecting to the machine"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "enabling http port for python application running"
    from_port   = 80
    to_port     = 80
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
    Name = "mywebapp-secgrp"
  }
}

resource "aws_instance" "myec2instance" {
  key_name               = aws_key_pair.mykey.key_name
  ami                    = "ami-0261755bbcb8c4a84"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.mysecgrp.id]
  subnet_id              = aws_subnet.mypubsubnet.id
  tags = {
    Name = "my-python-app-instance"
  }
  connection {
    type        = "ssh"
    host        = aws_instance.myec2instance.public_ip
    user        = "ubuntu"
    private_key = file("id_rsa")
  }
  
  provisioner "file" {
  source      = "app.py"  # Replace with the path to your local app.py file
  destination = "/home/ubuntu/app.py"  # Replace with the path on the remote instance
}

provisioner "file" {
  source      = "myapp.service"  # Replace with the path to your local myapp.service file
  destination = "/home/ubuntu/myapp.service"  # Replace with the path on the remote instance
}


  provisioner "remote-exec" {
    inline = [
      "echo 'Hello here I am connecting my remote machine using SSH'",
      "sudo apt update -y",
      "sudo apt install python3 -y",
      "sudo apt install python3-pip -y",
      "cd /home/ubuntu",
      "sudo pip3 install flask",
      "sudo mv /home/ubuntu/myapp.service /etc/systemd/system/",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable myapp",
      "sudo systemctl restart myapp",
    ]
  }

}