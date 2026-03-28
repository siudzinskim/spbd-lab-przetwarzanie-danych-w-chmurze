data "aws_s3_bucket" "my_bucket" {
  bucket = var.tfstate_bucket_name # Zastąp nazwą bucketu z lab 1
}

resource "aws_s3_bucket_versioning" "tfstate-bucket-versioning" {
  bucket = data.aws_s3_bucket.my_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}