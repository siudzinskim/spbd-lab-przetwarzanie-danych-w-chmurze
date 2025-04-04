variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1" # Choose your preferred region
}

variable "tfstate_bucket_name" {
  type = string
}

variable "api_gateway_name" {
  description = "Name for the API Gateway"
  type        = string
  default     = "DataGeneratorAPI"
}

variable "api_stage_name" {
  description = "Name for the API Gateway deployment stage"
  type        = string
  default     = "v1"
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 300 # Increased timeout, max 900
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 512 # Increased memory, adjust as needed
}

variable "lambda_function_name" {
  description = "Name for the Lambda function"
  type        = string
  default     = "data-generator-lambda"
}
