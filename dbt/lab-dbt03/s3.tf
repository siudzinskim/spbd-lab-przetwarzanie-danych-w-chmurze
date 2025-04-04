resource "aws_s3_bucket" "public_bucket" {
  bucket = "spdb-siudzinskim-public" # Replace with your desired bucket name (must be globally unique)
  # acl = "public-read" # This makes the bucket publicly readable
}

# resource "aws_s3_bucket_acl" "public-bucket-acl" {
#   bucket = aws_s3_bucket.public_bucket.id
#   acl = "public-read"
# }
#
# resource "aws_s3_bucket_public_access_block" "public_bucket_access_block" {
#   bucket                  = aws_s3_bucket.public_bucket.id
#   block_public_acls = false # Allow public ACLs
#   block_public_policy = false # Allow public bucket policies
#   ignore_public_acls = false # Don't ignore public ACLs
#   restrict_public_buckets = false # Don't restrict public buckets
# }
#
# resource "aws_s3_bucket_policy" "public_bucket_policy" {
#   bucket = aws_s3_bucket.public_bucket.id
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid       = "PublicReadGetObject"
#         Effect    = "Allow"
#         Principal = "*"
#         Action = [
#           "s3:GetObject"
#         ]
#         Resource = [
#           "${aws_s3_bucket.public_bucket.arn}/*"
#         ]
#       }
#     ]
#   })
# }