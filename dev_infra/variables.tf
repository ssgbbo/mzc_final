variable "region" {
  description = "Main region for all resources"
  type        = string
}
variable "dev_vpc_cidr" {
  type        = string
  description = "CIDR block for the dev VPC"
}
variable "dev_public_subnet_1" {
  type        = string
  description = "CIDR block for dev public subnet 1"
}

variable "dev_public_subnet_2" {
  type        = string
  description = "CIDR block for dev public subnet 2"
}
variable "dev_private_subnet_1" {
  type        = string
  description = "CIDR block for dev private subnet 1"
}

variable "dev_private_subnet_2" {
  type        = string
  description = "CIDR block for dev private subnet 2"
}
variable "dev_availibilty_zone_1" {
  type        = string
  description = "First dev availibility zone"
}

variable "dev_availibilty_zone_2" {
  type        = string
  description = "Second dev availibility zone"
}
variable "dev_default_tags" {
  type = map(any)
  default = {
    Application = "Demo App"
    Environment = "Dev"
  }
}
variable "container_port" {
  description = "Port that needs to be exposed for the application"
}

variable "shared_config_files" {
  description = "Path of your shared config file in .aws folder"
}

variable "shared_credentials_files" {
  description = "Path of your shared credentials file in .aws folder"
}

variable "credential_profile" {
  description = "Profile name in your credentials file"
  type        = string
}

variable "domain_name" {
  description = "domain name"
  type        = string
}
variable "dev_subdomain_name" {
  description = "dev_domain name"
  type        = string
}

variable "dev_ecs_service_name" {
  description = "dev_ecs_service_name"
  type        = string
}
variable "dev_ecs_cluster_name" {
  description = "dev_ecs_cluster_name"
  type        = string
}