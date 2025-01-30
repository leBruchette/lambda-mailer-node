variable "from_email" {
    description = "The email address that will be used as the sender of the email"
    type        = string
}

variable "from_password" {
    description = "The password for the email address that will be used as the sender of the email"
    type        = string
}

variable "bucket_name" {
    description = "The name of the S3 bucket where the resources will be stored"
    type        = string
}

variable "object_key" {
    description = "The key of the object that will be sent as an attachment in the email"
    type        = string
}

variable "aws_region" {
    description = "The AWS region where the resources will be created"
    type        = string
    default = "us-east-1"
}