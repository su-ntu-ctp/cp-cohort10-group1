terraform {
  backend "s3" {
    bucket = "sctp-ce10-tfstate"
    key    = "staging-shopbot.tfstate"
    region = "ap-southeast-1"
  }
}
