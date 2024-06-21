
resource "aws_ssm_parameter" "concurrent_job_count" {
  name  = local.concurrent_job_parameter_name
  type  = "String"
  value = "0"
}
