variable "profile" {
  type = string
}

variable "aws_access_key_id" {
  type = string
}

variable "aws_secret_access_key" {
  type = string
}

variable "use_aws_profile" {
  description = "Set to true to use AWS profile, or false to use access keys"
  type        = bool
}

variable "region_master" {
  type = string
}


variable "api_endpoint" {
  type = string
}

variable "endpoint" {
  type = string
}

variable "basic_dynamodb_table" {
  type = string
}

variable "function_name" {
  type = string
}

variable "runtime" {
  type = string
}


variable "dns" {
  type = string
}

variable "dns_cors" {
  description = "The DNS names allowed for CORS."
  type        = list(string)
}


variable "index_document" {
  type = string
}

variable "error_document" {
  type = string
}


variable "default_code_repository" {
  type = string
}


# Boolean variable to check for custom domain existence based on the dns variable.
variable "custom_domain_exists" {
  description = "Determines if a custom domain exists based on whether 'dns' is set."
  type        = bool
}



# =============================== dynamic end-point ============================


resource "null_resource" "update_index_js" {
  depends_on = [
    aws_apigatewayv2_stage.lambda,
    aws_lambda_function.lambda
  ]

  triggers = {
    api_gateway_invoke_url = "${aws_apigatewayv2_stage.lambda.invoke_url}",
    lambda_function_name   = "${aws_lambda_function.lambda.function_name}"
  }

  provisioner "local-exec" {
    command = "sed -i 's#%%API_ENDPOINT%%#${aws_apigatewayv2_api.lambda.api_endpoint}/${var.endpoint}/${aws_lambda_function.lambda.function_name}#g' ./html/index.js"
    environment = {
      API_GATEWAY_INVOKE_URL = aws_apigatewayv2_stage.lambda.invoke_url,
      LAMBDA_FUNCTION_NAME   = aws_lambda_function.lambda.function_name
    }
  }
}


# =============================== Outputs ======================================

output "api_endpoint" {
  description = "The end_point of the API"
  value       = "${aws_apigatewayv2_api.lambda.api_endpoint}/${var.endpoint}/${aws_lambda_function.lambda.function_name}"
}


output "cloudfront_distribution_domain_name" {
  description = "The domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.product_s3_distribution.domain_name
}

output "custom_domain_exists" {
  description = "Boolean flag indicating if a custom domain DNS zone exists."
  value       = length(data.aws_route53_zone.public_zone) > 0 ? true : false
}

output "dns" {
  value = var.custom_domain_exists ? "https://${var.dns}" : null
}



