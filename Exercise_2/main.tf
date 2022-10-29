provider "aws" {
  profile = "default"
  region  = "${var.aws_region}"
}

resource "aws_iam_role" "greeting_lambda_execute_role" {
  name = "greeting_lambda_execute_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_cloudwatch_log_group" "greeting_log_group" {
  name = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 14
}

resource "aws_iam_policy" "greeting_logs_policy" {
  name        = "greeting_logs_policy"
  path        = "/"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "greeting_logs_policy" {
  role       = aws_iam_role.greeting_lambda_execute_role.name
  policy_arn = aws_iam_policy.greeting_logs_policy.arn
}

resource "aws_lambda_function" "greeting_lambda" {
  function_name = var.lambda_function_name
  filename = "greet_lambda.zip"  
  handler = "greet_lambda.lambda_handler"
  runtime = "python3.8"
  role = aws_iam_role.greeting_lambda_execute_role.arn

  environment{
      variables = {
          greeting = "Welcome to IaS"
      }
  }

  depends_on = [aws_iam_role_policy_attachment.greeting_logs_policy, aws_cloudwatch_log_group.greeting_log_group]
}

