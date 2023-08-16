variable "public_subnet_cidrs" {
 type        = list(string)
 description = "Public Subnet CIDR values"
 default     = ["10.1.0.0/24", "10.1.1.0/24"]
}
 
variable "private_subnet_webApp" {
 type        = list(string)
 description = "WP Web Application"
 default     = ["10.1.2.0/24", "10.1.3.0/24"]
}

variable "private_subnet_dbs" {
 type        = list(string)
 description = "WP Web Application"
 default     = ["10.1.4.0/24", "10.1.5.0/24"]
}

variable "azs" {
 type        = list(string)
 description = "Availability Zones"
 #default     = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
 default     = ["us-gov-west-1a","us-gov-west-1b"]
}

