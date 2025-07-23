module "shopmate" {
  source = "../../"
  
  environment    = "uat"
  aws_region     = "ap-southeast-1"
  app_count      = 2
  session_secret = "uat-session-secret-change-me"
}