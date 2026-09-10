output "load_balancer_url" {
  description = "Load balancer URL"
  value       = "http://${google_compute_global_forwarding_rule.default.ip_address}"
}
