# ---- Terraform State ----
terraform {
  backend "s3" {
    # Specify the bucket name at runtime with -backend-config="bucket=..."
    key    = "calcutta-madness/terraform/state"
    region = "us-east-1"
    dynamodb_table = "terraform-locks"
  }
}
provider "aws" {
  region = "us-east-1"
}

# ---- Auctions Infrastructure ----


resource "aws_iam_role" "lambda_role" {
  name = "lambda_apis_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "lambda.amazonaws.com",
            "apigateway.amazonaws.com"
          ]
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  role = aws_iam_role.lambda_role.name
  name = "lambda_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Effect   = "Allow"
        Resource = [
          aws_dynamodb_table.auction_connections.arn,
          "${aws_dynamodb_table.auction_connections.arn}/index/*",
          aws_dynamodb_table.calcutta_auctions.arn,
          "${aws_dynamodb_table.calcutta_auctions.arn}/index/*"
        ]
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action = [
          "execute-api:ManageConnections",
          "execute-api:Invoke"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:execute-api:*:*:${aws_apigatewayv2_api.websocket_api.id}/@connections/*",
          "arn:aws:execute-api:*:*:${aws_apigatewayv2_api.websocket_api.id}/*"
        ]
      }
    ]
  })
}

# ---- Websocket API ----

data "aws_s3_object" "websocket_lambda" {
  bucket = var.s3_artifact_bucket
  key    = "calcutta-madness/lambdas/websocket.zip"
}

resource "aws_lambda_function" "calcutta_websockets" {
  s3_bucket        = var.s3_artifact_bucket
  s3_key           = "calcutta-madness/lambdas/websocket.zip"
  source_code_hash = data.aws_s3_object.websocket_lambda.etag
  function_name    = "calcutta_websockets"
  role             = aws_iam_role.lambda_role.arn
  handler          = "websocket_server.lambda_handler"
  runtime          = "python3.11"

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.auction_connections.name
    }
  }
  reserved_concurrent_executions = 10
}

resource "aws_apigatewayv2_api" "websocket_api" {
  name          = "websocket_api"
  protocol_type = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
}


resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.calcutta_websockets.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket_api.execution_arn}/*"
}


# TODO: need * cert
# resource "aws_apigatewayv2_domain_name" "rest_domain" {
#   domain_name = "api.${var.domain_name}.com"
#   domain_name_configuration {
#     certificate_arn = data.aws_acm_certificate.cert.arn
#     endpoint_type = "REGIONAL"
#     security_policy = "TLS_1_2"
#   }
# }
# resource "aws_apigatewayv2_api_mapping" "rest_mapping" {
#   api_id = aws_apigatewayv2_api.rest_api.id
#   domain_name = aws_apigatewayv2_domain_name.rest_domain.domain_name
#   stage = aws_apigatewayv2_stage.rest_stage.name
# }

data "aws_route53_zone" "calcutta_zone" {
  name = "${var.domain_name}.com"
}

resource "aws_route53_record" "websocket_api" {
  zone_id = data.aws_route53_zone.calcutta_zone.zone_id
  name    = "websocket.${var.domain_name}.com"  # Replace with your desired subdomain
  type    = "CNAME"
  ttl     = 300
  records = [aws_apigatewayv2_api.websocket_api.api_endpoint]
}