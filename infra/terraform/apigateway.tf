# ---------------------------------------------------------------------------
# API Gateway REST API
# Exposes Lambda via HTTP GET /
#
# Import commands:
#   terraform import aws_api_gateway_rest_api.main         q9gzox7h34
#   terraform import aws_api_gateway_method.root_get       q9gzox7h34/0gz3qjpy1c/GET
#   terraform import aws_api_gateway_integration.root_get  q9gzox7h34/0gz3qjpy1c/GET
#   terraform import aws_api_gateway_deployment.main       q9gzox7h34/dkyaab
#   terraform import aws_api_gateway_stage.prod            q9gzox7h34/prod
# ---------------------------------------------------------------------------

resource "aws_api_gateway_rest_api" "main" {
  name = "zahir-lambda-api"

  lifecycle {
    ignore_changes = [tags, tags_all]
  }
}

# GET method on the root resource (/)
resource "aws_api_gateway_method" "root_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_rest_api.main.root_resource_id
  http_method   = "GET"
  authorization = "NONE"
}

# Lambda proxy integration
resource "aws_api_gateway_integration" "root_get" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_rest_api.main.root_resource_id
  http_method             = aws_api_gateway_method.root_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.hello_proxy.invoke_arn
}

# Deployment — recreated on any method/integration change
resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_method.root_get,
      aws_api_gateway_integration.root_get,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_method.root_get,
    aws_api_gateway_integration.root_get,
  ]
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = "prod"

  lifecycle {
    ignore_changes = [tags, tags_all]
  }
}
