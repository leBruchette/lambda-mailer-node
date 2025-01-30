provider "aws" {
  region = var.aws_region
}

locals {
  function_name = "mailer-nodejs"
  log_group_name = "/aws/lambda/${local.function_name}"
}

data "aws_s3_bucket" "resource_bucket" {
  bucket = var.bucket_name
}

resource "aws_iam_role" "lambda_role" {
  name = "${local.function_name}-lambda-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "${local.function_name}-lambda-policy"
  description = "IAM policy for ${local.function_name} Lambda to access S3 and SQS"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          data.aws_s3_bucket.resource_bucket.arn,
          "${data.aws_s3_bucket.resource_bucket.arn}/*"
        ]
      },
      {
        Action = [
          "sns:Subscribe",
          "sns:Receive"
        ]
        Effect = "Allow"
        Resource = aws_sns_topic.request_by_email_topic.arn
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"

        Resource = "arn:aws:logs:*:*:log-group:${local.log_group_name}:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}


resource "aws_lambda_function" "mailer" {
  filename      = "zips/lambda.zip"
  function_name = local.function_name
  timeout       = 10
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"

  source_code_hash = filebase64sha256("zips/lambda.zip")

  environment {
    variables = {
      FROM_EMAIL     = var.from_email
      FROM_PASSWORD  = var.from_password
      S3_OBJECT_KEY  = var.object_key
      S3_BUCKET_NAME = data.aws_s3_bucket.resource_bucket.bucket
    }
  }
}

resource "aws_cloudwatch_log_group" "mailer_lambda_logs" {
  name              = local.log_group_name
  retention_in_days = 7
}

resource "aws_sns_topic" "request_by_email_topic" {
  name = "${local.function_name}-email-recipients-topic"
}

resource "aws_lambda_permission" "with_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.mailer.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.request_by_email_topic.arn
}

resource "aws_sns_topic_subscription" "sns_to_lambda_emailer" {
  topic_arn = aws_sns_topic.request_by_email_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.mailer.arn
}
