
output "s3_website_url" {
  value = aws_s3_bucket_website_configuration.website.website_domain
}

output "cloudfront_distribution_domain" {
  value = aws_cloudfront_distribution.website_distribution.domain_name
}

output "websocket_api_endpoint" {
  value = aws_apigatewayv2_api.websocket_api.api_endpoint
}