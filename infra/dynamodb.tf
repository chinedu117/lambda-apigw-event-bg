
resource "aws_dynamodb_table" "user_job_counts" {
  name           = local.user_table_name
  billing_mode   = "PAY_PER_REQUEST"  
  hash_key       = "userId"

  attribute {
    name = "userId"
    type = "S" 
  }

  tags = var.tags
}
