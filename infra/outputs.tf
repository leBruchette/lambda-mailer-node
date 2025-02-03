output "cognito_user_pool_id" {
  description = "The ID of the Cognito User Pool to be used in the frontend to publish SNS messages"
  value = aws_cognito_identity_pool.identity_pool.identity_pool_name
}