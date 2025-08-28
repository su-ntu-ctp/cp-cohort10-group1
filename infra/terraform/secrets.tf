# ============================================================================
# SECRETS MANAGEMENT
# ============================================================================
# AWS Secrets Manager for sensitive configuration values

# Grafana admin password
resource "aws_secretsmanager_secret" "grafana_password" {
  name                           = "${var.prefix}/${var.environment}/grafana-admin-password"
  description                    = "Grafana admin password for ${var.environment} environment"
  force_overwrite_replica_secret = true
  recovery_window_in_days        = 0
}

resource "aws_secretsmanager_secret_version" "grafana_password" {
  secret_id     = aws_secretsmanager_secret.grafana_password.id
  secret_string = random_password.grafana_admin.result
}

# Generate random password for Grafana
resource "random_password" "grafana_admin" {
  length  = 16
  special = true
}

# Session secret for application
resource "random_password" "session_secret" {
  length  = 64
  special = true
}

resource "aws_secretsmanager_secret" "session_secret" {
  name                           = "${var.prefix}-session-key-${var.environment}"
  description                    = "Session secret for ShopBot ${var.environment}"
  force_overwrite_replica_secret = true
  recovery_window_in_days        = 0
}

resource "aws_secretsmanager_secret_version" "session_secret" {
  secret_id     = aws_secretsmanager_secret.session_secret.id
  secret_string = random_password.session_secret.result
}