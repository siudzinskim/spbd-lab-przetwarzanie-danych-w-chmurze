data "aws_vpc" "main" {
  id = var.vpc_id
}

resource "aws_subnet" "public" {
  vpc_id     = data.aws_vpc.main.id
  cidr_block = var.subnetwork_cidr

  tags = {
    Name = "lab-subnet-${var.environment}"
  }
}
