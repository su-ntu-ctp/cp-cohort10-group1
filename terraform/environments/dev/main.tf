module "shopmate" {
  source = "../../"
  
  environment        = "dev"
  aws_region         = "ap-southeast-1"
  app_count          = 1
  session_secret     = "dev-session-secret-change-me"
  domain_name        = "shopmate.sctp-sandbox.com"
  route53_zone_name  = "sctp-sandbox.com"
  create_route53_zone = false  # Using existing zone
}