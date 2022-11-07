variable "aws_access_key" {
  type    = string
  default = ""
}

variable "aws_secret_key" {
  type    = string
  default = ""
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "host_os" {
  type    = string
  default = "linux"
}

variable "enivorment" {
  type    = string
  default = "dev"
}

variable "project" {
  type    = string
  default = ""
}

variable "bucket_name" {
  type    = string
  default = ""
}

variable "acl_value" {
  type    = string
  default = "private"
}

variable "rediscloud_creds" {
  type    = list(any)
  default = ["", ""]
}

variable "rediscloud_api_key" {
  type    = string
  default = "rediscloud_api_key"
}

variable "cc_last_4" {
  type    = string
  default = ""
}

variable "rediscloud_account_id" {
  type    = string
  default = ""
}

variable "aws_account_id" {
  type    = string
  default = ""
}
