module "shopbot" {
  source = "../.."
  
  environment     = "dev"
  aws_region      = "ap-southeast-1"
  domain_name     = "dev-shopbot.sctp-sandbox.com"
  task_cpu        = "256"
  task_memory     = "512"
  app_count_max   = 3
  app_count_min   = 1
  image_tag       = "latest"
}
