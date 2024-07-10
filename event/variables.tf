variable "region" {
  description = "Main region for all resources"
  type        = string
}

variable "default_tags" {
  type = map(any)
  default = {
    Application = "Demo App"
    Environment = "Dynamo"
  }
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
