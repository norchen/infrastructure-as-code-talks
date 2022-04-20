/* ----------------------------------------------------------
  main.tf
  * maintained by @norchen
  * for educational purpose only, no production readyness 
    garantued
------------------------------------------------------------*/

/* ----------------------------------------------------------
  set provider
------------------------------------------------------------*/
# the starting point to connect to AWS
provider "aws" {
  profile = "test"      # the profile you configured via AWS CLI 
  region  = var.region  # the region you want to deploy to 
}

# configure terraform version and backend properties
terraform {
  required_providers {

    # sets version for AWS Terraform provider
    # https://github.com/hashicorp/terraform-provider-aws/blob/main/CHANGELOG.md
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.10.0"

      # default tags to be added to every AWS ressource
      default_tags = {
        Owner = "Wolkencode"
      }
    }
  }

  # sets Terraform version
  required_version = ">= 1.1"

  # if applicable put your remote backend configuration here (e.g. S3 backend)
  # backend "s3" {...}
} 

/* ----------------------------------------------------------
  set locals & variables
------------------------------------------------------------*/
locals {
  s3_bucket_name = join("-", [
    "my-bucket-", 
    var.region,
    timestamp()
  ])
}

variable "region" {
  description = "The AWS region to deploy to"
  type        = string
  default = "us-east-1"
}

/* ----------------------------------------------------------
  set resources
------------------------------------------------------------*/
# s3 bucket
resource "aws_s3_bucket" "website" {
  bucket = local.s3_bucket_name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Sid": "PublicReadGetObject",
          "Effect": "Allow",
          "Principal": "*",
          "Action": [
              "s3:GetObject"
          ],
          "Resource": [
              "arn:aws:s3:::${local.s3_bucket_name}/*"
          ]
      }
  ]
}
POLICY
}

# s3 access control lists (acl) configuration (since aws provider version 4.9)
resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.website.id
  acl    = "public-read"
}

# s3 website configuration (since aws provider version 4.9)
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.bucket

  index_document {
    suffix = "index.html"
  }
}

# s3 object
resource "aws_s3_bucket_object" "website" {
  bucket       = aws_s3_bucket.website.id
  key          = "index.html"          # how your file will be named in the S3 Bucket (we need an index.html)
  source       = "index.html"          # set the path to your "index.html" (here it lies in the same directory) 
  content_type = "text/html"           # use the respective MIME type for your object 
  etag         = filemd5("index.html") # same path as in source 
}

/* ----------------------------------------------------------
  set output
------------------------------------------------------------*/
output "s3_bucket_website_url" {
  value = aws_s3_bucket.website.website_endpoint
}
