
resource "aws_sns_topic" "this" {
  name = local.sns_topic
  tags = local.tags
}

resource "aws_sns_topic_policy" "default" {
  arn    = aws_sns_topic.this.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    effect  = "Allow"
    actions = ["SNS:Publish"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com", "cloudwatch.amazonaws.com"]
    }

    resources = [aws_sns_topic.this.arn]
  }
}

resource "aws_lambda_function" "this" {
  filename      = local.sns_lambda_source
  function_name = local.sns_lambda_name
  handler       = "sns.handler"
  memory_size   = 128
  role = aws_iam_role.function_role.arn
  timeout       = 10
  source_code_hash = filebase64sha256(local.sns_lambda_source)
  runtime = "python3.9"
  environment {
    variables = local.env
  }
}

resource "aws_lambda_permission" "with_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.this.arn
}


resource "aws_sns_topic_subscription" "lambda" {
  depends_on = [aws_lambda_function.this]
  topic_arn = aws_sns_topic.this.arn
  protocol = "lambda"
  endpoint = aws_lambda_function.this.arn
}

resource "aws_cloudwatch_log_group" "function_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.this.function_name}"
  retention_in_days = 7
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_iam_role" "function_role" {
  name               = "${local.sns_lambda_name}-lambda-role"
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

resource "aws_iam_policy" "sns_lambda_policy" {
  name   = "${local.sns_lambda_name}-lambda-policy"
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
                "ssm:GetParameter",
                "ssm:PutParameter"
            ],
            "Resource": "*"
        }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sns_lambda_policy_attachment" {
  role = aws_iam_role.function_role.id
  policy_arn = aws_iam_policy.sns_lambda_policy.arn
}