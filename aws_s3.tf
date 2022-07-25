variable "bucket_name" {
  description = "Name of the bucket"
}

variable "environment" {
  description = "Set bucket environment"
}

variable "filepath" {
  description = "Path to the file which you want to upload"
}

#Creates s3 bucket
resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
  tags = {
    Name        = var.bucket_name
    Environment = var.environment
  }
}

#Set bucket ACL to private
resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.bucket.id
  acl    = "private"
}


# Upload a file from scripts folder to newly created bucket
resource "aws_s3_object" "object" {
  bucket = aws_s3_bucket.bucket.id
  key    = "index.html"
  acl    = "private"
  source = var.filepath
  etag   = filemd5(var.filepath)
}
