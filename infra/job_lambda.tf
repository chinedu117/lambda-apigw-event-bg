

resource "aws_lambda_function" "jb_this" {
  filename      = local.job_lambda_source
  function_name = local.job_lambda_name
  handler       = "job.handler"
  memory_size   = 128
  role = aws_iam_role.jb_function_role.arn
  timeout       = 300
  source_code_hash = filebase64sha256(local.job_lambda_source)
  runtime = "python3.9"
  environment {
    variables = local.env
  }
}


resource "aws_cloudwatch_log_group" "jb_function_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.jb_this.function_name}"
  retention_in_days = 7
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_iam_role" "jb_function_role" {
  name               = "${local.job_lambda_name}-lambda-role"
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

resource "aws_lambda_permission" "lambda_invoke_permission" {
  statement_id  = "AllowLambdaInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.jb_this.function_name
  principal     = "lambda.amazonaws.com"
  source_arn    = aws_lambda_function.js_this.arn
}


resource "aws_iam_policy" "jb_lambda_policy" {
  name   = "${local.job_lambda_name}-lambda-policy"
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
            "Action": "events:PutEvents",
            "Resource": "${aws_cloudwatch_event_bus.custom_event_bus.arn}"
        }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "jb_lambda_policy_attachment" {
  role = aws_iam_role.jb_function_role.id
  policy_arn = aws_iam_policy.jb_lambda_policy.arn
}