output "datadog_api_key" {
  value       = local.dd_secrets.datadog_api_key
  sensitive   = true
  description = "Datadog api key"
}

output "datadog_app_key" {
  value       = local.dd_secrets.datadog_app_key
  sensitive   = true
  description = "Datadog app key"
}
