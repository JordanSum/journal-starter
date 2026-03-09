variable "subscription_id" {
  description = "The subscription ID for the Azure provider"
  type        = string
}

variable "pip" {
    description = "The public IP address to allow access to the PostgreSQL server"
    type = string
  
}