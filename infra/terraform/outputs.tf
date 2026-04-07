output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "ecr_backend_url" {
  description = "ECR URI for backend image"
  value       = aws_ecr_repository.backend.repository_url
}

output "ecr_frontend_url" {
  description = "ECR URI for frontend image"
  value       = aws_ecr_repository.frontend.repository_url
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.hello_proxy.function_name
}

output "api_gateway_url" {
  description = "Lambda serverless endpoint"
  value       = "https://${aws_api_gateway_rest_api.main.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.prod.stage_name}/"
}

# ── Application URLs (set by CI after kubectl deploy) ──────────────────────
# These are populated by the deploy job reading the k8s LoadBalancer hostnames
# and re-running: terraform apply -var="backend_lb_url=..." etc.
# After a fresh deploy, run: terraform output  to see all live URLs.

output "app_frontend_url" {
  description = "Frontend Angular app URL"
  value       = var.frontend_lb_url != "" ? "http://${var.frontend_lb_url}" : "(not yet deployed)"
}

output "app_backend_url" {
  description = "Backend Spring Boot API URL"
  value       = var.backend_lb_url != "" ? "http://${var.backend_lb_url}" : "(not yet deployed)"
}

output "app_kibana_url" {
  description = "Kibana dashboard URL"
  value       = var.kibana_lb_url != "" ? "http://${var.kibana_lb_url}:5601" : "(not yet deployed)"
}
