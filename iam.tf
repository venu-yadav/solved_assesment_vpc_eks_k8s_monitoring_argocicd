module "allow_eks_access_iam_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.3.1"

  name          = "allow-eks-access"
  create_policy = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "eks:DescribeCluster",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# 2. Creating IAM Role for EKS Access
module "eks_admins_iam_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.3.1"

  role_name         = "eks-admin"
  create_role       = true
  role_requires_mfa = false

  custom_role_policy_arns = [module.allow_eks_access_iam_policy.arn]

  trusted_role_arns = [
    "arn:aws:iam::${module.vpc.vpc_owner_id}:root"
  ]
}

# 3. Creating IAM User
module "user1_iam_user" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "5.3.1"

  name                          = "user1"
  create_iam_access_key         = false
  create_iam_user_login_profile = false

  force_destroy = true
}

# 4. IAM Policy to Allow Assuming EKS Admin Role
module "allow_assume_eks_admins_iam_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.3.1"

  name          = "allow-assume-eks-admin-iam-role"
  create_policy = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
        ]
        Effect   = "Allow"
        Resource = module.eks_admins_iam_role.iam_role_arn
      },
    ]
  })
}

# 5. Creating IAM Group and Adding User
module "eks_admins_iam_group" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-group-with-policies"
  version = "5.3.1"

  name                              = "eks-admin"
  attach_iam_self_management_policy = false
  create_group                      = true
  group_users                       = [module.user1_iam_user.iam_user_name]
  custom_group_policy_arns          = [module.allow_assume_eks_admins_iam_policy.arn]
}

# 6. Adding IAM Role for AWS Load Balancer Controller
resource "aws_iam_role" "lb_controller_role" {
  name = "aws-load-balancer-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# 7. Adding IAM Policy for AWS Load Balancer Controller
resource "aws_iam_policy" "aws_lb_controller_policy" {
  name        = "aws-load-balancer-controller-policy"
  description = "Policy for AWS Load Balancer Controller"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateRule",
          "elasticloadbalancing:CreateTargetGroup",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:DeleteRule",
          "elasticloadbalancing:DeleteTargetGroup",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeSSLPolicies",
          "elasticloadbalancing:DescribeTags",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:SetSecurityGroups",
          "elasticloadbalancing:SetSubnets",
          "elasticloadbalancing:ModifyLoadBalancerAttributes",  # Ensure this is included for modifying attributes.
          "elasticloadbalancing:ModifyListener",               # This can help with listener changes.
          "elasticloadbalancing:ModifyTargetGroup"
        ]
        Resource = "*"
      }
    ]
  })
}

# 8. Attach Policy to AWS Load Balancer Controller IAM Role
resource "aws_iam_role_policy_attachment" "attach_lb_controller_policy" {
  role       = aws_iam_role.lb_controller_role.name
  policy_arn = aws_iam_policy.aws_lb_controller_policy.arn
}

