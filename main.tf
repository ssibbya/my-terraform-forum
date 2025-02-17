provider "aws" {
  region = var.aws_region
  assume_role {
    role_arn = var.aws_role_arn
  }
}

variable "aws_region" {}
variable "aws_role_arn" {}

resource "aws_s3_bucket" "example" {
  bucket = "my-tf-cloud-test-bucket"
}
