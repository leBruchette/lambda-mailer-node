# lambda-mailer-node

Simple lambda function I use to send out my resume.  Motivation was to not have a pdf with PII sitting on my website.  
Instead, I have a lambda function triggered by an SNS event that emails the resume requester a signed S3 URL to my resume.

## Directory Structure

- `mailer`: Source code for the Lambda function.
- `infra`: Terraform configuration for provisioning to AWS

## Prerequisites

- Node.js and npm installed
- AWS CLI configured
- Terraform installed

## Setup

### Provisioning

1. Navigate to the `infra/` directory and run `deploy.sh`.  This will build a zip of the lambda function for use with terraform provisioning:

   ```sh
   cd infra && ./deploy.sh
   ```

2. Run terraform apply to provision the infrastructure, note the following variables:
   ```sh
    terraform apply \ 
      -var='from_email=<email-sending-the-resume>' \ 
      -var='from_password=<password-used-for-email>' \
      -var='bucket_name=<bucket-with-resume>' \
      -var='object_key=<resume-file-name>' 
   ```
   
Under the covers, the lambda uses [nodemailer](https://www.nodemailer.com/) to send the email.  The `from_email` and `from_password` variables are used by nodemailer to authenticate with your mail provider i.e. Gmail.  
## Usage

Once the infrastructure is provisioned and the Lambda function is deployed, you can trigger the Lambda function by publishing a message to the SNS topic created by the Terraform configuration. 
The message should include an `email` attribute with the recipient's email address.
