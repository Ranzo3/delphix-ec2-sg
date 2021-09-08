# delphix-ec2-sg

# Build Security Groups for Delphix Oracle Sources and Targets with AWS CLI

## Instructions

1)  Make sure you can run `aws` CLI.  This requires downloading some software to your PC and configuring it (usually with `aws configure`)
2)  You will need the following IAM permissions to run this script:

    ec2:AuthorizeSecurityGroupIngress
    ec2:CreateSecurityGroup
    ec2:DescribeSecurityGroups
    ec2:DescribeSecurityGroupRules

    If you are modifying or recreating rules, you'll also need:
    ec2:RevokeSecurityGroupIngress
    ec2:DeleteSecurityGroup

3)  Modify the make_sg.sh script.  
    Change the VPC_ID.  You can comment it out and we'll look it up if you have one and only one VPC.
    Change MY_IP to a range of admin IPs, or comment it out to use just your current IP via checkip.amazon.com
    (Optional and not recommended) customize the names of the security groups.
    (Optional)  Modify AWS_CMD to include options like ` --profile <string>` and ` --region <string>`
4)  Run make_sg.sh

## Usage

Usage: ./make_sg.sh [ -r ] [ -d ] 

With no flags, this script will create the SGs and the Ingress Rules.

-r : Just Replace the Inbound Rules.  Useful if you change the rules and have already attached SGs to Instances

-d : Just Delete the Security Groups. Useful if you want to start over
    
   
