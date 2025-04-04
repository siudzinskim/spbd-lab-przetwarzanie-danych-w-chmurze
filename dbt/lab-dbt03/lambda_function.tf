# --- Lambda Function ---

# Assume deployment package `lambda_package.zip` is in the same directory as terraform files
# You need to create this zip file manually (see instructions below)
resource "null_resource" "install_layer_dependencies" {
  provisioner "local-exec" {
    command = "pip install -r package/requirements.txt -t package/"
  }
  triggers = {
    trigger = timestamp()
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/package" # Directory containing lambda_function.py and dependencies
  output_path = "${path.module}/lambda_package.zip"
  depends_on  = [null_resource.install_layer_dependencies]
}

data "aws_iam_role" "lab-role" {
  name = "LabRole"
}

resource "aws_lambda_function" "data-generator" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = var.lambda_function_name
  role             = data.aws_iam_role.lab-role.arn
  handler          = "lambda_function.lambda_handler" # Python File name . Handler function name
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.12" # Or python3.10, python3.11, python3.12 as supported

  timeout     = var.lambda_timeout
  memory_size = var.lambda_memory_size

  tags = {
    Project = "DataGenerator"
  }

  lifecycle {
    replace_triggered_by = [data.archive_file.lambda_zip.output_md5]
  }
}

# --- API Gateway ---

resource "aws_api_gateway_rest_api" "api" {
  name        = var.api_gateway_name
  description = "API Gateway for Data Generator Lambda"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "proxy_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "generate" # The path for the endpoint, e.g., /generate
}

resource "aws_api_gateway_method" "proxy_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.proxy_resource.id
  http_method   = "POST" # Use POST to send request body
  authorization = "NONE" # Publicly accessible
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.proxy_resource.id
  http_method = aws_api_gateway_method.proxy_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY" # Use Lambda Proxy integration
  uri                     = aws_lambda_function.data-generator.invoke_arn
}

resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  # Trigger redeployment when API resources change
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.proxy_resource.id,
      aws_api_gateway_method.proxy_method.id,
      aws_api_gateway_integration.lambda_integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  # Depends on the method and integration being created
  depends_on = [aws_api_gateway_method.proxy_method, aws_api_gateway_integration.lambda_integration]
}

resource "aws_api_gateway_stage" "api_stage" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = var.api_stage_name
}

# Grant API Gateway permission to invoke the Lambda function
resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.data-generator.function_name
  principal     = "apigateway.amazonaws.com"

  # Restrict permission to the specific API Gateway ARN
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/${aws_api_gateway_method.proxy_method.http_method}${aws_api_gateway_resource.proxy_resource.path}"
}


# --- Outputs ---

output "api_endpoint_url" {
  description = "The invocation URL for the API Gateway stage"
  value       = "${aws_api_gateway_deployment.api_deployment.invoke_url}/${aws_api_gateway_stage.api_stage.stage_name}${aws_api_gateway_resource.proxy_resource.path}"
  # Example URL: https://<api-id>.execute-api.<region>.amazonaws.com/v1/generate
}