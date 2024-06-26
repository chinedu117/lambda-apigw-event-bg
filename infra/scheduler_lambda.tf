

resource "aws_lambda_function" "js_this" {
  filename      = local.job_scheduler_lambda_source
  function_name = local.job_scheduler_lambda_name
  handler       = "scheduler.handler"
  memory_size   = 128
  role = aws_iam_role.js_function_role.arn
  timeout       = 10
  source_code_hash = filebase64sha256(local.job_scheduler_lambda_source)
  runtime = "python3.9"
  environment {
    variables = local.env
  }
}

resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.js_this.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.api_execution_arn}/*/*"
}



resource "aws_cloudwatch_log_group" "js_function_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.js_this.function_name}"
  retention_in_days = 7
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_iam_role" "js_function_role" {
  name               = "${local.job_scheduler_lambda_name}-lambda-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Action : "sts:AssumeRole",
        Effect : "Allow",
        Principal : {
          "Service" : "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "js_lambda_policy" {
  name   = "${local.job_scheduler_lambda_name}-lambda-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Effect" : "Allow",
        "Resource" : "arn:aws:logs:*:*:*"
      },
       {
            "Effect": "Allow",
            "Action": [
                "dynamodb:GetItem",
                "dynamodb:Query",
                "dynamodb:PutItem"
            ],
            "Resource": "${aws_dynamodb_table.user_job_counts.arn}"
        },
        {
            "Effect": "Allow",
            "Action": "lambda:InvokeFunction",
            "Resource": "${aws_lambda_function.jb_this.arn}"
        }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "js_lambda_policy_attachment" {
  role = aws_iam_role.js_function_role.id
  policy_arn = aws_iam_policy.js_lambda_policy.arn
}