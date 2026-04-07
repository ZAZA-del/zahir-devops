# ---------------------------------------------------------------------------
# Lambda function: zahir-hello-proxy
# Calls the backend Spring Boot /hello endpoint and returns JSON.
# Source: ../../lambda/hello_proxy.py
#
# Import command:
#   terraform import aws_lambda_function.hello_proxy zahir-hello-proxy
# ---------------------------------------------------------------------------

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.root}/../../lambda/hello_proxy.py"
  output_path = "${path.root}/../../lambda/function.zip"
}

resource "aws_lambda_function" "hello_proxy" {
  function_name    = "zahir-hello-proxy"
  role             = aws_iam_role.lambda.arn
  handler          = "hello_proxy.handler"
  runtime          = "python3.13"
  timeout          = 10
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  environment {
    variables = {
      BACKEND_URL = var.backend_lb_url
    }
  }

  lifecycle {
    ignore_changes = [tags, tags_all]
  }

  depends_on = [aws_iam_role_policy_attachment.lambda_basic]
}

# ---------------------------------------------------------------------------
# Lambda permission for API Gateway invocation
# Import command:
#   terraform import aws_lambda_permission.apigw \
#     zahir-hello-proxy/apigw-invoke
# ---------------------------------------------------------------------------
resource "aws_lambda_permission" "apigw" {
  statement_id  = "apigw-invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello_proxy.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.aws_region}:${var.aws_account_id}:${aws_api_gateway_rest_api.main.id}/*/GET/"
}
