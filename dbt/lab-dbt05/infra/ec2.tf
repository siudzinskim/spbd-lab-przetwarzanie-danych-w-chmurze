data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"] # Amazon
}

resource "aws_instance" "lab_instance" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.small"
  subnet_id                   = aws_subnet.public.id
  availability_zone           = aws_subnet.public.availability_zone
  associate_public_ip_address = true
  key_name                    = "kp" # Zastąp nazwą swojego klucza SSH
  security_groups             = [aws_security_group.allow_ssh.id]

  tags = {
    Name = "lab-ec2"
  }

  user_data_base64 = filebase64("./startup.sh")

  lifecycle {
    ignore_changes = ["security_groups"]
  }
}

resource "aws_ebs_volume" "example" {
  availability_zone = aws_subnet.public.availability_zone
  size              = 10
  type              = "gp2"

  tags = {
    Name = "lab-volume"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.example.id
  instance_id = aws_instance.lab_instance.id
  stop_instance_before_detaching = true
}


resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Ogranicz dostęp do konkretnego IP w produkcji!
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}