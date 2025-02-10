# 🔹 Création du rôle IAM pour EC2
resource "aws_iam_role" "ec2_wordpress_role" {
  name = "EC2-WordPress-Access-${var.environment}"

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

#   lifecycle {
#     ignore_changes = [name]
#   }
 }

# 🔹 Création de la policy IAM pour accéder à Secrets Manager
resource "aws_iam_policy" "secrets_manager_read" {
  name        = "EC2SecretsManagerReadOnly"
  description = "Permission de lecture seule sur AWS Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Effect   = "Allow"
      Resource = "*"
    }]
  })

  lifecycle {
    ignore_changes = [tags_all]  # ✅ Terraform ne tentera plus d'ajouter des tags
  }
}

# 🔹 Attachement de la policy IAM au rôle EC2
resource "aws_iam_role_policy_attachment" "attach_secrets_policy" {
  role       = aws_iam_role.ec2_wordpress_role.name  
  policy_arn = aws_iam_policy.secrets_manager_read.arn
}
