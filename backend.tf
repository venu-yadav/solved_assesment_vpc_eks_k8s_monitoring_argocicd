resource "aws_lb" "example" {
  name               = "example-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.example.id]
  subnets            = module.vpc.public_subnets

#  access_logs {
#    bucket  = aws_s3_bucket.terraform_backend.bucket
#    enabled = true
 # }
}
