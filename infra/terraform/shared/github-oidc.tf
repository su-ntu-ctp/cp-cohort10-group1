
# GitHub OIDC Provider
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

}

# IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  name = "shopbot-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:*:*"
          }
        }
      }
    ]
  })
}

# IAM Policy for ECR access
resource "aws_iam_role_policy" "github_actions_ecr" {
  name = "shopbot-github-actions-ecr-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:*",
          "iam:*",
          "ec2:*",
          "ecs:*",
          "elasticloadbalancing:*",
          "logs:*",
          "secretsmanager:*",
          "dynamodb:*",
          "route53:*",
          "acm:*",
          "cloudwatch:*",
          "s3:*",
          "autoscaling:*",
          "application-autoscaling:*",
          "ssm:GetParameter",
          "ssm:PutParameter",
          "ssm:ListTagsForResource",
          "ssm:AddTagsToResource",
          "ssm:UpdateItem",

        ]
        Resource = "*"
      }
    ]
  })
}



