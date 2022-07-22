variable "domain_hosted_zone" {
  type        = string
  description = "Zone in which domain should be added"
}

variable "domain_name" {
  type        = string
  description = "The domain name for the website."
}

variable "support_spa" {
  type        = bool
  description = "This bucket should support single page applications"
  default     = false
}

variable "create_certificate" {
  type        = bool
  description = "Whether or not a new certificate should be created"
  default     = true
}

variable "certificate_domain" {
  type        = string
  description = "The domain to use for the certificate. If you have a pre-existing wildcard cert, you can specify the wildcard domain here."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Tags you want set on all resources"
  default     = {}
}

variable "cloudfront_price_class" {
  type        = string
  description = "Cloudfront distribution price class. More here: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PriceClass.html"
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_All", "PriceClass_200", "PriceClass_100"], var.cloudfront_price_class)
    error_message = "You must enter a valid price class. Can be: PriceClass_All, PriceClass_200, PriceClass_100."
  }
}
