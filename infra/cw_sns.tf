

resource "aws_cloudwatch_event_bus" "custom_event_bus" {
  name = local.event_bus_name
}

resource "aws_cloudwatch_event_rule" "event_success" {
   name        = "${var.project_name}-event-success"
   description = "Event handler completed"
   event_bus_name = aws_cloudwatch_event_bus.custom_event_bus.name
   event_pattern = jsonencode(local.event_pattern)
 }


  resource "aws_cloudwatch_event_target" "sns_success" {
   event_bus_name = aws_cloudwatch_event_bus.custom_event_bus.name
   rule      = aws_cloudwatch_event_rule.event_success.name
   target_id = "${var.project_name}-event-success.target"
   arn       = aws_sns_topic.this.arn
 }
