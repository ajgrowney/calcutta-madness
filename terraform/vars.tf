variable "s3_artifact_bucket" {
    description = "The name of the S3 bucket to store the website artifacts"
    type        = string
    default = "ajg-infra"
}

variable "user_pool_name" {
    description = "value of the user pool name"
    type        = string
    default = "calcutta-user-pool"
}

variable "domain_name" {
    description = "value of the domain name"
    type        = string
    default     = "calcutta-madness" 
}