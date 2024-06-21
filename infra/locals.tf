locals {
  tags = merge({Project = var.project_name},var.tags)
  lambda_name = "${var.project_name}-event-responder"
  lambda_source = "${path.module}/artifacts/lambda.zip"
  sns_topic = "${var.project_name}-event-responder-sns-topic"
  env = {
    SSM_PARAMETER_NAME = ""
  }

  event_pattern = {
    source = []
    detail-type = []
    detail = {

    }
    resources = [

    ]
  }
}
