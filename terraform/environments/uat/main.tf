module "shopmate" {
  source = "../../"
  
  environment        = "uat"
  aws_region         = "ap-southeast-1"
  app_count          = 2
  session_secret     = "uat-session-secret-change-me"
  domain_name        = "shopmate.uat.sctp-sandbox.com"
  route53_zone_name  = "sctp-sandbox.com"
  create_route53_zone = false  # Using existing zone
}