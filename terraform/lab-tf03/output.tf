output "bucket_name" {
  value = data.aws_s3_bucket.my_bucket.bucket
}

output "bucket_arn" {
  value = data.aws_s3_bucket.my_bucket.arn
}

output "versioning_enabled" {
  value = aws_s3_bucket_versioning.tfstate-bucket-versioning.versioning_configuration.0.status
}
