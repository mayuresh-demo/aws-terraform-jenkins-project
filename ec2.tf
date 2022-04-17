
data "aws_ami" "latest-ubuntu" {
most_recent = true
owners = ["099720109477"] # Canonical

  filter {
      name   = "name"
      values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
      name   = "virtualization-type"
      values = ["hvm"]
  }
}
resource "aws_instance" "jenkins-instance" {
  ami           = data.aws_ami.latest-ubuntu.id
  instance_type = "t2.micro"
  key_name      = var.keyname
  #vpc_id          = "${aws_vpc.development-vpc.id}"
  vpc_security_group_ids = [aws_security_group.sg_allow_ssh_jenkins.id]
  subnet_id              = aws_subnet.public-subnet-1.id
  #name            = "${var.name}"
  #user_data                   = file("install_jenkins.sh")
  associate_public_ip_address = true

  provisioner "remote-exec" {
    inline = [
      "wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -",
      "sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'",
      "sudo apt update -qq",
      "sudo apt install -y default-jre",
      "sudo apt install -y jenkins",
      "sudo systemctl start jenkins",
      "sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080",
      "sudo sh -c \"iptables-save > /etc/iptables.rules\"",
      "echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections",
      "echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections",
      "sudo apt-get -y install iptables-persistent",
      "sudo ufw allow 8080",
    ]
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file("tf-jenkins-aws.pem")
  }

  tags = {
    Name = "Jenkins-Instance"
  }
}

resource "aws_security_group" "sg_allow_ssh_jenkins" {
  name        = "allow_ssh_jenkins"
  description = "Allow SSH and Jenkins inbound traffic"
  vpc_id      = aws_vpc.development-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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

output "jenkins_ip_address" {
  value = aws_instance.jenkins-instance.public_dns
}
