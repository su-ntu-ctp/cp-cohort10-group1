module "shopbot" {
  source = "../.."
  
  environment     = "prod"
  aws_region      = "ap-southeast-1"
  domain_name     = "shopbot.sctp-sandbox.com"
  task_cpu        = "1024"
  task_memory     = "2048"
  app_count_max   = 10
  app_count_min   = 3
  image_tag       = "latest"
}
