variable "subscription_id" {
  description = "The subscription ID for the Azure provider"
  type        = string
}

variable "psqlusername" {
  description = "The PostgreSQL admin username"
  type        = string
}

variable "psqlpassword" {
  description = "The PostgreSQL admin password"
  type        = string
  sensitive   = true
}