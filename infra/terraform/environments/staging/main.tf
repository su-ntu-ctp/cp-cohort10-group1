module "shopbot" {
  source = "../.."
  
  environment   = "staging"
  aws_region    = "ap-southeast-1"
  domain_name   = "staging-shopbot.sctp-sandbox.com"
  app_count     = 2
  task_cpu      = "512"
  task_memory   = "1024"
  max_capacity  = 5
  min_capacity = 1
}
