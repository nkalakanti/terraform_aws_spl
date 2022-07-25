#provider vars
aws_region = "ap-south-1"

#vpc vars
vpc_cidr_block            = "10.0.0.0/16"
private_subnet_cidr_block = "10.0.1.0/24"
public_subnet_cidr_block  = "10.0.100.0/24"
private_ip                = "10.0.1.50"
public_ip                 = "10.0.100.50"
vpc_name                  = "dev_vpc"
availability_zone         = "ap-south-1a"

#ec2 vars
ami           = "ami-006d3995d3a6b963b" #It usually depends on region so, go to create instance and search your AMI
instance_type = "t2.micro"
key_name      = "kaushal_dev"


#s3 vars
bucket_name = "test-rand-bucket-14332"
environment = "Dev"
filepath    = "scripts/index.html"
