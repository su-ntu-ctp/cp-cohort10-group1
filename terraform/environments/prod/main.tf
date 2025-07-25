module "shopmate" {
  source = "../../"
  
  environment        = "prod"
  aws_region         = "ap-southeast-1"
  app_count          = 3
  session_secret     = "prod-session-secret-change-me"
  domain_name        = "shopmate.prod.sctp-sandbox.com"
  route53_zone_name  = "sctp-sandbox.com"
  create_route53_zone = false  # Using existing zone
}