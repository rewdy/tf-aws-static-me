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
  description = "(Optional) Should this bucket support SPA apps? Default: true"
  default     = false
}

variable "create_certificate" {
  type        = bool
  description = "(Optional) If you have an existing certificate, pass in the ARN"
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "(Optional) Common tags you want applied to all components."
  default     = {}
}

variable "cloudfront_price_class" {
  type        = "PriceClass_All" || "PriceClass_200" || "PriceClass_100"
  description = "(Optional) Set the price class. You can find what they mean here: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PriceClass.html"
  default     = "PriceClass_100"
}
