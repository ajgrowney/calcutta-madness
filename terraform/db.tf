# Table for websocket connections
resource "aws_dynamodb_table" "auction_connections" {
  name           = "calcutta_auction_connections"
  billing_mode   = "PAY_PER_REQUEST"  # Use on-demand mode for scalability
  hash_key       = "connectionId"  # Partition Key

  attribute {
    name = "connectionId"
    type = "S"  # String type for partition key
  }

  tags = {
    Environment = "production"
    Project     = "Calcutta Auction"
  }
}

# Single Table Design for Calcutta Auction
resource "aws_dynamodb_table" "calcutta_auctions" {
  name           = "calcutta_auction"
  billing_mode   = "PAY_PER_REQUEST"  # Use on-demand mode for scalability
  hash_key       = "PK"  # Partition Key
  range_key      = "SK"  # Sort Key

  # Only define attributes that are used as keys
  attribute {
    name = "PK"
    type = "S"  # String type for partition key
  }

  attribute {
    name = "SK"
    type = "S"  # String type for sort key
  }

  # Optional: You can define Global Secondary Indexes (GSIs) if you need additional access patterns
  # Using existing attributes as keys
  global_secondary_index {
    name            = "user_auction_index"
    hash_key        = "PK"
    range_key       = "SK"
    projection_type = "ALL"  # Include all attributes in the index

    # Optional: You can add Provisioned capacity for the GSI if needed
    read_capacity  = 5
    write_capacity = 5
  }

  tags = {
    Environment = "production"
    Project     = "Calcutta Auction"
  }
}
