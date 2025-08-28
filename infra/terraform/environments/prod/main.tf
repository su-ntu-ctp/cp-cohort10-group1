module "shopbot" {
  source = "../.."
  
  environment   = "prod"
  aws_region    = "ap-southeast-1"
  domain_name   = "shopbot.sctp-sandbox.com"
  task_cpu      = "1024"
  task_memory   = "2048"
  max_capacity  = 10
  min_capacity = 3
}
