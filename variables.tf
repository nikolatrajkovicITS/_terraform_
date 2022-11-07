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

variable "rediscloud_creds" {
  type    = list(any)
  default = ["", ""]
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
