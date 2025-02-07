resource "aws_iam_role" "ec2_wordpress_role" {
  name = "EC2-WordPress-Access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "secrets_manager_read" {
  name        = "EC2SecretsManagerReadOnly"
  description = "Permission de lecture seule sur AWS Secrets Manager"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Effect   = "Allow"
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_secrets_policy" {
  role       = aws_iam_role.ec2_wordpress_role.name
  policy_arn = aws_iam_policy.secrets_manager_read.arn
}
