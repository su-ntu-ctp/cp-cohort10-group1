terraform {
  backend "s3" {
    bucket = "sctp-ce10-tfstate"
    key    = "Prod-shopbot.tfstate"
    region = "ap-southeast-1"
  }
}
