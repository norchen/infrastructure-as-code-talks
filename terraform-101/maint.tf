# ----------------------------------------------------------
# main.tf
# ----------------------------------------------------------
# set provider
# the starting point to connect to AWS
provider "aws" {
  profile = "test"      # the profile you configured via AWS CLI 
  region  = "us-east-1" # the region you want to deploy to 
}

# set variables
variable "s3_bucket_name" {
  description = "the bucket name for our website bucket"
  type        = string
}

# set resources
# s3 bucket
resource "aws_s3_bucket" "website" {
  bucket = var.s3_bucket_name
  acl    = "public-read"
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
              "arn:aws:s3:::${var.s3_bucket_name}/*"
          ]
      }
  ]
}
POLICY

  website {
    index_document = "index.html"
  }
}

# s3 object
resource "aws_s3_bucket_object" "website" {
  bucket       = aws_s3_bucket.website.id
  key          = "index.html"          # how your file will be named in S3 Bucket (we need an index.html)
  source       = "index.html"          # set the path to your "index.html" (here it lies in the same directory) 
  content_type = "text/html"           # use the respective MIME type for your object 
  etag         = filemd5("index.html") # same path as in source 
}

# set output
output "s3_bucket_website_url" {
  value = aws_s3_bucket.website.website_endpoint
}
