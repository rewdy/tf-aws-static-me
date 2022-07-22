# AWS Static Website Terraform Module

This is a terraform module to setup a simple static website in S3. Ideal for react apps, gatsby sites, or whatever other static content you got.

## Resource this creates

- **AWS Certificate Manager**: Creates a certificate for your domain. OR, if you already have a wildcard cert you use, you can opt to use that instead. #flexibility
- **S3**: Bucket for website files
- **Cloudfront**: Distribution pointing to the S3 bucket
- **Route53**: record to point to the cloudfront distribution

## Usage

This might be your main.tf file:

```HCL
provider "aws" {
  region = "us-east-1"
}

module "aws_static_website" {
  source = "github.com/rewdy/tf-aws-static-me"

  # Route53 hosted zone to use, should already exist
  domain_hosted_zone = "rewdy.lol"

  # Domain name you want to use; can be the domain root or a sub domain
  domain_name = "rewdy.lol"
  support_spa = true

  tags = {
    Project = "rewdy.lol website"
  }
}
```

## Options

| Option | Default | Description |
| ------ | ------- | ----------- |
| `domain_hosted_zone` | none | AWS hosted zone that the domain should be created in. Enter the URL for the HZ (not ARN). |
| `domain_name` | none | The domain you want for your website. Can be a subdomain or domain. |
| `support_spa` | `false` | Sets up bucket config to work with most common single page application setups. |
| `create_certificate` | `true` | Whether or not you want a new cert created. If you have one already, we'll look for it. |
| `tags` | `{}` | Tags you want added to your resources; helpful for tracking when you have many projects. |
| `cloudfront_price_class` | `"PriceClass_100"` | Select the appropriate price class. See [price class options](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PriceClass.html). |

## Outputs

| Output | Description |
| ------ | ----------- |
| `website_cdn_root_id` | Cloudfront distribution id |
| `website_files_s3_bucket` | S3 bucket for the files |

## Author

Module written by [@rewdy](https://github.com/rewdy).

Some parts are heavily borrowed from [terraform-aws-static-website](https://github.com/cloudmaniac/terraform-aws-static-website) (which is fuller-featured for those who are looking for that.)
