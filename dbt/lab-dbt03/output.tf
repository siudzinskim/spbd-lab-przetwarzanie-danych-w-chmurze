output "bucket_name" {
  value = data.aws_s3_bucket.my_bucket.bucket
}

output "bucket_arn" {
  value = data.aws_s3_bucket.my_bucket.arn
}

output "versioning_enabled" {
  value = aws_s3_bucket_versioning.tfstate-bucket-versioning.versioning_configuration.0.status
}

output "vscode-tunnel-cmd" {
  value = "ssh -N -f -L 8888:localhost:8888 -L 8080:localhost:8080 -i ~/Downloads/kp.pem ec2-user@${aws_instance.lab_instance.public_ip}"
}

