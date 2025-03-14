provider "aws" {
  region  = "us-east-1" # Frankfurt
  profile = "default"
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = "spbd-siudzinskim-tfstate" # Zastąp unikalną nazwą
# (zalecana konwencja:
# spdb-<nr_indeksu>-tfstate

  tags = {
    Name        = "My Bucket"
    Environment = "Development"
  }
}
