variable "environment" {
  type = string
}

variable "vpc_id" {
  type        = string
  description = "Nazwa sieci VPC"
}

variable "subnetwork_cidr" {
  type        = string
  description = "Adres podsieci IPv4 z maską podsieci w notacji CIDR (n.p. 10.0.0.0/16)"

  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}\\/([0-9]|[1-2][0-9]|3[0-2])$", var.subnetwork_cidr))
    error_message = "The network_cidr value must be a valid IPv4 CIDR block (e.g., 10.0.0.0/16). It must include the subnet mask."
  }
}

