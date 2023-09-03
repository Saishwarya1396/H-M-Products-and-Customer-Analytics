provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "bucket1" {
  bucket = "handm-datalake-1-seppt"
  tags = {
    Name = "My bucket"
  }
}

resource "aws_s3_bucket_ownership_controls" "bucket1" {
  bucket = aws_s3_bucket.bucket1.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "bucket1" {
  bucket = aws_s3_bucket.bucket1.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "bucket1" {
  depends_on = [
    aws_s3_bucket_ownership_controls.bucket1,
    aws_s3_bucket_public_access_block.bucket1,
  ]

  bucket = aws_s3_bucket.bucket1.id
  acl    = "public-read"
}

resource "aws_s3_object" "object1_transaction" {
  bucket = aws_s3_bucket.bucket1.id
  key    = "Transactions/"
}

resource "aws_s3_object" "object2_customers" {
  bucket = aws_s3_bucket.bucket1.id
  key    = "Customers/"
}

resource "aws_s3_object" "object3_articles" {
  bucket = aws_s3_bucket.bucket1.id
  key    = "Articles/"
}



