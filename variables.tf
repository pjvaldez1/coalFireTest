
variable "region" {
  type = string 
  description = "Region for VPC"
  #testing with us-west-2
  #default = "us-west-2"
  default = "us-gov-west-1"
}

variable "azs" {
  type        = list(string)
  description = "Availability Zones"
  #default     = ["us-west-2a","us-west-2b"]
  default = ["us-gov-west-1a", "us-gov-west-1b"]
}

