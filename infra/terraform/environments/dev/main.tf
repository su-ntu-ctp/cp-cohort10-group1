module "shopbot" {
  source = "../.."
  
  environment   = "dev"
  aws_region    = "ap-southeast-1"
  domain_name   = "dev-shopbot.sctp-sandbox.com"
  app_count     = 1
  task_cpu      = "256"
  task_memory   = "512"
  max_capacity  = 3
  min_capacity  = 1
}
