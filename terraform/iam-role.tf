# iam-role.tf - Add this to your existing Terraform files

data "aws_caller_identity" "current" {}

# Create OIDC provider
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# Create IAM role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  name = "github-actions-s3-website-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:Nada1478/websiteautomation:*"
          }
        }
      }
    ]
  })
}

# Attach policy for S3, EC2, VPC, and IAM read permissions
resource "aws_iam_role_policy" "terraform" {
  name = "terraform-policy"
  role = aws_iam_role.github_actions.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*",
          "ec2:*", 
          "vpc:*",
          "iam:GetOpenIDConnectProvider",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListInstanceProfiles",
          "iam:ListRoles",
          "iam:ListOpenIDConnectProviders"
        ]
        Resource = ["*"]
      }
    ]
  })
}

output "role_arn" {
  value = aws_iam_role.github_actions.arn
}