
locals {
  event_pattern = {
    source = []
    detail-type = []
    detail = {

    }
    resources = [

    ]
  }
}

resource "aws_cloudwatch_event_rule" "event_success" {
   name        = "${var.project_name}-event-success"
   description = "Event handler completed"
   event_pattern = jsonencode(local.event_pattern)
 }


  resource "aws_cloudwatch_event_target" "sns_success" {
   rule      = aws_cloudwatch_event_rule.event_success.name
   target_id = "${var.project_name}-event-success.target"
   arn       = aws_sns_topic.this.arn
 }
