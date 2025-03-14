# module "dev" {
#   source = "../lab-module"
#   environment = "dev"
#   vpc_id = var.main_vpc_id
#   subnetwork_cidr = "10.0.2.0/24"
# }
#
# module "prod" {
#   source = "../lab-module"
#   environment = "prod"
#   vpc_id = var.main_vpc_id
#   subnetwork_cidr = "10.0.1.0/24"
# }
#

locals {
  environments = {
    dev = {
      vpc_id = var.main_vpc_id
      subnetwork_cidr = "10.0.16.0/24"
      environment = "dev"
    }
    staging = {
      vpc_id = var.main_vpc_id
      subnetwork_cidr = "10.0.32.0/24"
      environment = "staging"
    }
    prod = {
      vpc_id = var.main_vpc_id
      subnetwork_cidr = "10.0.0.0/24"
      environment = "prod"
    }
  }
}

module "environment" {
  for_each = local.environments
  source = "../lab-module"
  environment = each.value["environment"]
  vpc_id = each.value["vpc_id"]
  subnetwork_cidr = each.value["subnetwork_cidr"]
}