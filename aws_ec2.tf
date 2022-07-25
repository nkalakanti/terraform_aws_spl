variable "ami" {
  description = "You can get ami name from create instance search ist"
}


variable "instance_type" {
  description = "Eg t2.micro"
}


variable "key_name" {
  description = "Name of key pair to connect using ssh. It don't have any then create a new pem for linux."
}

#Code for creating public EC2
resource "aws_instance" "public-ec2" {
  ami                  = var.ami
  instance_type        = var.instance_type
  availability_zone    = var.availability_zone
  key_name             = var.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2-instance-profile.name
  network_interface {
    device_index         = 0 #index starts from 0 like array, you can add multiple NICs
    network_interface_id = aws_network_interface.public-web-server-nic.id
  }
  #it will send parsed script to ec2 on creation and execute it.
  user_data = templatefile("scripts/public_init.sh", {
    private_ip  = var.private_ip
  })
  tags = {
    Name = "public-web-server"
  }
  depends_on = [aws_s3_bucket.bucket]
}

#Code for creating private EC2
resource "aws_instance" "private-ec2" {
  ami                  = var.ami
  instance_type        = var.instance_type
  availability_zone    = var.availability_zone
  key_name             = var.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2-instance-profile.name
  network_interface {
    device_index         = 0 #index starts from 0 like array, you can add multiple NICs
    network_interface_id = aws_network_interface.private-web-server-nic.id
  }
  #it will send parsed script to ec2 on creation and execute it.
  user_data = templatefile("scripts/private_init.sh", {
    aws_region  = var.aws_region
    bucket_name = var.bucket_name
  })
  tags = {
    Name = "private-web-server"
  }
}