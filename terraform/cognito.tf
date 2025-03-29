# Cognito User Pool for authentication
resource "aws_cognito_user_pool" "calcutta_user_pool" {
  name = var.user_pool_name
  
  # Password policy
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }
  
  # Configure verification
  auto_verified_attributes = ["email"]
  
  # Username attributes and requirements
  username_attributes = ["email"]
  username_configuration {
    case_sensitive = false
  }
  
  # Configure MFA
  mfa_configuration = "OFF"
  
  # Schema attributes
  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "email"
    required                 = true
    
    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }
  
  # Configure account recovery
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }
  
  tags = {
    Environment = "production"
    Project     = "Calcutta Auction"
  }
}

# App Client for web application
resource "aws_cognito_user_pool_client" "web_client" {
  name                = "calcutta-web-client"
  user_pool_id        = aws_cognito_user_pool.calcutta_user_pool.id
  
  # OAuth configuration
  generate_secret     = false
  refresh_token_validity = 30
  access_token_validity = 1
  id_token_validity = 1
  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }
  
  # Allowed OAuth flows and scopes
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows  = ["implicit", "code"]
  allowed_oauth_scopes = ["email", "openid", "profile"]
  
  # Callback and logout URLs
  callback_urls        = ["http://localhost:8000", "https://${var.domain_name}.com"]
  logout_urls          = ["http://localhost:8000", "https://${var.domain_name}.com"]
  
  # Auth flows
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH"
  ]
  
  supported_identity_providers = ["COGNITO"]
}

# Create domain for Cognito hosted UI (optional)
resource "aws_cognito_user_pool_domain" "main" {
  domain       = "calcutta-auth"
  user_pool_id = aws_cognito_user_pool.calcutta_user_pool.id
}

# Outputs for reference in other files
output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.calcutta_user_pool.id
}

output "cognito_client_id" {
  value = aws_cognito_user_pool_client.web_client.id
}