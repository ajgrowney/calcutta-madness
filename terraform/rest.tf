# ---- REST API Infrastructure ----

data "aws_s3_object" "rest_lambda" {
  bucket = var.s3_artifact_bucket
  key    = "calcutta-madness/lambdas/rest.zip"
}

resource "aws_lambda_function" "calcutta_rest_create_auction" {
  s3_bucket        = data.aws_s3_object.rest_lambda.bucket
  s3_key           = data.aws_s3_object.rest_lambda.key
  source_code_hash = data.aws_s3_object.rest_lambda.etag
  function_name    = "calcutta_rest_create_auction"
  role             = aws_iam_role.lambda_role.arn
  handler          = "rest_server.create_auction"
  runtime          = "python3.11"

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.calcutta_auctions.name
      CONNECTION_TABLE = aws_dynamodb_table.auction_connections.name
    }
  }
  reserved_concurrent_executions = 10
}
resource "aws_lambda_function" "calcutta_rest_get_user_auctions" {
  s3_bucket        = data.aws_s3_object.rest_lambda.bucket
  s3_key           = data.aws_s3_object.rest_lambda.key
  source_code_hash = data.aws_s3_object.rest_lambda.etag
  function_name    = "calcutta_rest_get_user_auctions"
  role             = aws_iam_role.lambda_role.arn
  handler          = "rest_server.get_user_auctions"
  runtime          = "python3.11"

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.calcutta_auctions.name
    }
  }
  reserved_concurrent_executions = 10
}
resource "aws_lambda_function" "calcutta_rest_get_auction_details" {
  s3_bucket        = data.aws_s3_object.rest_lambda.bucket
  s3_key           = data.aws_s3_object.rest_lambda.key
  source_code_hash = data.aws_s3_object.rest_lambda.etag
  function_name    = "calcutta_rest_get_auction_details"
  role             = aws_iam_role.lambda_role.arn
  handler          = "rest_server.get_auction_details"
  runtime          = "python3.11"

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.calcutta_auctions.name
    }
  }
  reserved_concurrent_executions = 10
}
resource "aws_lambda_function" "calcutta_rest_get_auction_history" {
  s3_bucket = data.aws_s3_object.rest_lambda.bucket
  s3_key = data.aws_s3_object.rest_lambda.key
  source_code_hash = data.aws_s3_object.rest_lambda.etag
  function_name = "calcutta_rest_get_auction_history"
  role = aws_iam_role.lambda_role.arn
  handler = "rest_server.get_auction_item_history"
  runtime = "python3.11"
  timeout = 30
  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.calcutta_auctions.name
    }
  }
  reserved_concurrent_executions = 10
}
resource "aws_lambda_function" "calcutta_rest_get_auction_items" {
  s3_bucket = data.aws_s3_object.rest_lambda.bucket
  s3_key = data.aws_s3_object.rest_lambda.key
  source_code_hash = data.aws_s3_object.rest_lambda.etag
  function_name = "calcutta_rest_get_auction_items"
  role = aws_iam_role.lambda_role.arn
  handler = "rest_server.get_auction_items"
  runtime = "python3.11"
  timeout = 30
  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.calcutta_auctions.name
    }
  }
  reserved_concurrent_executions = 10
}
resource "aws_lambda_function" "calcutta_rest_add_auction_time" {
  s3_bucket = data.aws_s3_object.rest_lambda.bucket
  s3_key = data.aws_s3_object.rest_lambda.key
  source_code_hash = data.aws_s3_object.rest_lambda.etag
  function_name = "calcutta_rest_add_auction_time"
  role = aws_iam_role.lambda_role.arn
  handler = "rest_server.add_auction_time"
  runtime = "python3.11"
  timeout = 30
  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.calcutta_auctions.name
      CONNECTION_TABLE = aws_dynamodb_table.auction_connections.name
      WEBSOCKET_API_ENDPOINT = replace("${aws_apigatewayv2_api.websocket_api.api_endpoint}/prod", "wss://", "https://")
    }
  }
  reserved_concurrent_executions = 10
}

resource "aws_lambda_function" "calcutta_rest_add_auction_users" {
  s3_bucket        = data.aws_s3_object.rest_lambda.bucket
  s3_key           = data.aws_s3_object.rest_lambda.key
  source_code_hash = data.aws_s3_object.rest_lambda.etag
  function_name    = "calcutta_rest_add_auction_users"
  role             = aws_iam_role.lambda_role.arn
  handler          = "rest_server.add_auction_users"
  runtime          = "python3.11"

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.calcutta_auctions.name
      CONNECTION_TABLE = aws_dynamodb_table.auction_connections.name
      WEBSOCKET_API_ENDPOINT = replace("${aws_apigatewayv2_api.websocket_api.api_endpoint}/prod", "wss://", "https://")
    }
  }
  reserved_concurrent_executions = 10
}
resource "aws_lambda_function" "calcutta_rest_place_bid" {
  s3_bucket        = data.aws_s3_object.rest_lambda.bucket
  s3_key           = data.aws_s3_object.rest_lambda.key
  source_code_hash = data.aws_s3_object.rest_lambda.etag
  function_name    = "calcutta_rest_place_bid"
  role             = aws_iam_role.lambda_role.arn
  handler          = "rest_server.place_bid"
  runtime          = "python3.11"

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.calcutta_auctions.name
      CONNECTION_TABLE = aws_dynamodb_table.auction_connections.name
      WEBSOCKET_API_ENDPOINT = replace("${aws_apigatewayv2_api.websocket_api.api_endpoint}/prod", "wss://", "https://")
    }
  }
  reserved_concurrent_executions = 10
}
resource "aws_lambda_function" "calcutta_rest_start_auction" {
  s3_bucket        = data.aws_s3_object.rest_lambda.bucket
  s3_key           = data.aws_s3_object.rest_lambda.key
  source_code_hash = data.aws_s3_object.rest_lambda.etag
  function_name    = "calcutta_rest_start_auction"
  role             = aws_iam_role.lambda_role.arn
  handler          = "rest_server.start_auction"
  runtime          = "python3.11"

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.calcutta_auctions.name
      CONNECTION_TABLE = aws_dynamodb_table.auction_connections.name
      WEBSOCKET_API_ENDPOINT = replace("${aws_apigatewayv2_api.websocket_api.api_endpoint}/prod", "wss://", "https://")
    }
  }
  reserved_concurrent_executions = 10
}
resource "aws_lambda_function" "calcutta_rest_auction_next" {
  s3_bucket        = data.aws_s3_object.rest_lambda.bucket
  s3_key           = data.aws_s3_object.rest_lambda.key
  source_code_hash = data.aws_s3_object.rest_lambda.etag
  function_name    = "calcutta_rest_auction_next"
  role             = aws_iam_role.lambda_role.arn
  handler          = "rest_server.auction_next"
  runtime          = "python3.11"

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.calcutta_auctions.name
      CONNECTION_TABLE = aws_dynamodb_table.auction_connections.name
      WEBSOCKET_API_ENDPOINT = replace("${aws_apigatewayv2_api.websocket_api.api_endpoint}/prod", "wss://", "https://")
    }
  }
  reserved_concurrent_executions = 10
}

resource "aws_lambda_permission" "get_user_auctions_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.calcutta_rest_get_user_auctions.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.rest_api.execution_arn}/*"
}

resource "aws_lambda_permission" "get_auction_details_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.calcutta_rest_get_auction_details.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.rest_api.execution_arn}/*"
}

resource "aws_lambda_permission" "add_auction_users_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.calcutta_rest_add_auction_users.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.rest_api.execution_arn}/*"
}

resource "aws_lambda_permission" "add_auction_time_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.calcutta_rest_add_auction_time.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.rest_api.execution_arn}/*"
}

resource "aws_lambda_permission" "place_bid_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.calcutta_rest_place_bid.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.rest_api.execution_arn}/*"
}

resource "aws_lambda_permission" "start_auction_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.calcutta_rest_start_auction.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.rest_api.execution_arn}/*"
}

resource "aws_lambda_permission" "auction_history_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.calcutta_rest_get_auction_history.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.rest_api.execution_arn}/*"
}

resource "aws_lambda_permission" "auction_items_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.calcutta_rest_get_auction_items.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.rest_api.execution_arn}/*"
}

resource "aws_lambda_permission" "auction_next_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.calcutta_rest_auction_next.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.rest_api.execution_arn}/*"
}

resource "aws_lambda_permission" "create_auction_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.calcutta_rest_create_auction.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.rest_api.execution_arn}/*"
}

resource "aws_api_gateway_rest_api" "rest_api" {
  name          = "rest_api"
  body          = file("${path.module}/../docs/rest.openapi.yaml")
}

# Add the authorizer to the REST API
resource "aws_api_gateway_authorizer" "cognito_authorizer" {
  name                   = "cognito-authorizer"
  rest_api_id            = aws_api_gateway_rest_api.rest_api.id
  type                   = "COGNITO_USER_POOLS"
  provider_arns          = [aws_cognito_user_pool.calcutta_user_pool.arn]
  identity_source        = "method.request.header.Authorization"
}

resource "aws_api_gateway_deployment" "rest_deployment" {
  depends_on = [aws_api_gateway_rest_api.rest_api]
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
}

resource "aws_api_gateway_stage" "rest_stage" {
  deployment_id = aws_api_gateway_deployment.rest_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  stage_name    = "prod"
}
