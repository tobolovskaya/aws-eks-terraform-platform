# Backend settings for state (S3 + DynamoDB)
terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket-unique-name"
    key            = "terraform/state"
    region         = "eu-north-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}