resource "aws_s3_bucket" "terraform_backend" {
  bucket = "terraform-eks-s3-backend-eu-west-2"
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.terraform_backend.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.terraform_backend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.terraform_backend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "elb_logs_policy" {
  bucket = aws_s3_bucket.terraform_backend.id

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "elasticloadbalancing.amazonaws.com"
        },
        "Action": "s3:PutObject",
        "Resource": "${aws_s3_bucket.terraform_backend.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket" "alb_logs" {
  bucket = "example-alb-logs"
  # Removed acl = "private" since it's deprecated and might cause issues
}

