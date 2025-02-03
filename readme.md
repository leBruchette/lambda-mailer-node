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

1. Navigate to the `infra/` directory and run `packageLambda.sh`.  This will build a zip of the lambda function for use with terraform provisioning:

   ```sh
   cd infra && ./packageLambda.sh
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

Once the infrastructure is provisioned and the Lambda function is deployed, you can trigger the Lambda function by publishing a message to the SNS topic created by the Terraform configuration. The message should include an `email` attribute with the recipient's email address.

## Outputs

The Terraform configuration outputs the `cognito_user_pool_id`, which is the ID of the Cognito User Pool. This ID can be used in your React app to allow users to authenticate and publish SNS messages.

### Using Outputs in a React App

1. **Retrieve the Output**: After running `terraform apply`, you can retrieve the output value using the Terraform CLI or from the `terraform.tfstate` file.

2. **Configure AWS SDK**: Use the AWS SDK in your React app to configure Cognito and SNS.

3. **Authenticate Users**: Use the Cognito User Pool ID to authenticate users in your React app.

4. **Publish SNS Messages**: Once authenticated, users can publish messages to the SNS topic to trigger the Lambda function.

Example code snippet for a React app:

```javascript
import AWS from 'aws-sdk';

// Configure AWS SDK
AWS.config.update({
  region: 'your-aws-region',
  credentials: new AWS.CognitoIdentityCredentials({
    IdentityPoolId: 'your-cognito-identity-pool-id',
  }),
});

const sns = new AWS.SNS();

const publishMessage = (email) => {
  const params = {
    Message: JSON.stringify({ email }),
    TopicArn: 'your-sns-topic-arn',
  };

  sns.publish(params, (err, data) => {
    if (err) {
      console.error('Error publishing message:', err);
    } else {
      console.log('Message published:', data);
    }
  });
};

// Use the publishMessage function in your React components