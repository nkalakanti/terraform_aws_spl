#creates assume role for ec2
resource "aws_iam_role" "ec2-cloudwatch-s3-access-role" {
  name               = "ec2_cloudwatch_s3_access_role"
  assume_role_policy = file("json/assumerolepolicy.json")
}

#creates cloudwatch policy
resource "aws_iam_policy" "cloudwatch-policy" {
  name        = "cloudwatch_policy"
  description = "CloudWatch policy for EC2"
  policy      = file("json/policycloudwatch.json")
}

#creates s3 policy
resource "aws_iam_policy" "s3-policy" {
  name        = "s3_policy"
  description = "S3 policy for EC2"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowAuroraToExampleBucket",
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject",
          "s3:GetObject",
          "s3:AbortMultipartUpload",
          "s3:ListBucket",
          "s3:DeleteObject",
          "s3:GetObjectVersion",
          "s3:ListMultipartUploadParts"
        ],
        "Resource" : [
          "arn:aws:s3:::${var.bucket_name}/*",
          "arn:aws:s3:::${var.bucket_name}"
        ]
      }
    ]
  })
  depends_on = [aws_s3_bucket.bucket]
}

#Linking assume role to cloudwatch policy
resource "aws_iam_policy_attachment" "cloudwatch-policy-attachment" {
  name       = "cloudwatch-policy-attachment"
  roles      = ["${aws_iam_role.ec2-cloudwatch-s3-access-role.name}"]
  policy_arn = aws_iam_policy.cloudwatch-policy.arn
}

#Linking assume role to s3 policy
resource "aws_iam_policy_attachment" "s3-policy-attachment" {
  name       = "s3-policy-attachment"
  roles      = ["${aws_iam_role.ec2-cloudwatch-s3-access-role.name}"]
  policy_arn = aws_iam_policy.s3-policy.arn
}

#Provides an IAM instance profile.
resource "aws_iam_instance_profile" "ec2-instance-profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2-cloudwatch-s3-access-role.name
}
