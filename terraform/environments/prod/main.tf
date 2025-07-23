module "shopmate" {
  source = "../../"
  
  environment    = "prod"
  aws_region     = "ap-southeast-1"
  app_count      = 3
  session_secret = "prod-session-secret-change-me"
}