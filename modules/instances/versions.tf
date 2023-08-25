terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    signalfx = {
      source = "splunk-terraform/signalfx"
    }
    splunk = {
      source = "splunk/splunk"
      version = "1.4.19"
    }
  }
  # required_version = ">= 0.13"
}
