# Cloud Resume Challenge Part 2 - Visitor Traffic Tracking
Take your cloud resume to the next level in Part 2 of the Cloud Resume Challenge. If you're catching up, start with [Part 2](https://devopsmajid.hashnode.dev/cloud-resume-challenge-part-2) where we set up a back-end visitor counter on AWS. Now, let's connect our code to the back-end.


You'll find a complete guide on my [blog post](https://devopsmajid.hashnode.dev/cloud-resume-challenge-part-3).

![Blog image](./images/aws.png)


Welcome to Part 3 of the Cloud Resume Challenge. This repository connects the visitor count feature. We will use the previousely created infrastructure.

## Architecture
![Architecture Image](./images/architecture.png)


## Prerequisites
- An AWS account's identity (user or role) with adequate permissions to interact with S3, Route 53, AWS Certificate Manager, and CloudFront.
- If you plan to use a custom domain, it must be previously registered as this is not automated in the script.
- AWS account with permissions to work with DynamoDB, Lambda, and API Gateway.
- Terraform already set up and ready to go.

## How to Use

1. Execute `script_lunch.sh`.
2. During the first run, if prompted `"To use an AWS profile, enter the profile name (or type 'none' to specify Access Keys instead):"`, you can enter the AWS [profile](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html) name if available. If not, type 'none' and provide `aws_access_key_id` and `aws_secret_access_key`.

3. Enter your registered domain name (e.g., example.com). If you don't have a custom domain, enter 'no' to proceed with the CloudFormation-generated one.

4. Type in the HTML index and error files.

5. Follow the prompts to enter your preferred region and any other required AWS configurations as requested by the script.

6. If asked `"Choose yes if you have a Github with your resume code? (yes/no):"`, type 'yes' if your resume HTML code is in a Github repo, and provide an accessible Github URL pointing to your resume code folder. The repository should contain 'index' and 'error' files at the root, not in a nested folder. If you type 'no', the default code will be used.


7. Wait approximately 6 minutes for your website to be live.

When you see the end-point of the API Gateway, you're all set to test it and if the count increments.

To clean up all resources, run `script_destroy.sh` from the root of your folder. Ensure it reads `"Terraform destroying infrastructure"` to verify successful deletion of resources.


To reset all variables, run `script_reset.sh` from the root of your folder.

