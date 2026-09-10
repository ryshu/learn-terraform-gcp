variable "port" {
  description = "HTTP Port of the web server"
  type        = number
  default     = 8080
  validation {
    condition     = var.port > 1024 && var.port < 65536
    error_message = "Port must be between 1025 and 65535."
  }
}
