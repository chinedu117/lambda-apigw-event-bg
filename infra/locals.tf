locals {
  tags = merge({Project = var.project_name},var.tags)
  sns_lambda_name = "${var.project_name}-event-responder"
  sns_lambda_source = "${path.module}/artifacts/lambda.zip"
  job_scheduler_lambda_name = "${var.project_name}-job-scheduler"
  job_lambda_name = "${var.project_name}-job"
  job_scheduler_lambda_source = "${path.module}/artifacts/lambda.zip"
  job_lambda_source = "${path.module}/artifacts/lambda.zip"
  sns_topic = "${var.project_name}-event-responder-sns-topic"

  concurrent_job_parameter_name = "/dev/concurrent-job-count"
  user_table_name = "UsersConcurrentJobsCount"
  event_bus_name = "dataspan-chinedu"
  env = {

    SSM_PARAMETER_NAME = local.concurrent_job_parameter_name
    EVENT_BUS_NAME = local.event_bus_name
    MAX_CONCURRENT_JOB_COUNT = 5
    EVENT_HANDLER_FUNCTION_NAME = local.job_lambda_name
    USERS_TABLE_NAME = local.user_table_name

  }
  
  event_pattern = {
    source = ["my.custom.source"]
    detail-type = ["LambdaFunctionCompleted"]
    
  }
}
