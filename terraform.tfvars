#provider vars
aws_region = "eu-west-1"

#vpc vars
vpc_cidr_block            = "10.0.0.0/16"
private_subnet_cidr_block = "10.0.1.0/24"
public_subnet_cidr_block  = "10.0.100.0/24"
private_ip                = "10.0.1.50"
public_ip                 = "10.0.100.50"
vpc_name                  = "dev_vpc"
availability_zone         = "eu-west-1a"

#ec2 vars
ami           = "ami-0d75513e7706cf2d9" #It usually depends on region so, go to create instance and search your AMI
instance_type = "t2.micro"
key_name      = "java-kubernetes"


#s3 vars
bucket_name = "s3-rand-bucket-14332"
environment = "Dev"
filepath    = "scripts/index.html"
