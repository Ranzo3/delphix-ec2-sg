# delphix-ec2-sg
Make Security Groups for Delphix Oracle Sources and Targets

Instructions

1)  Make sure you can run "aws" CLI.  This requires downloading some software to your PC and configuring it (usually with aws configure)
2)  Modify the make_sg.sh script.  
    Change the VPC_ID.  You can comment it out and we'll look it up if you have one and only one VPC.
    Change MY_IP to a range of admin IPs, or comment it out to use just your current IP via checkip.amazon.com
    (Optional and not recommended) customize the names of the security groups.
    (Optional)  Modify AWS_CMD to include options like --profile <string> and --region <string>
3)  Run make_sg.sh
    
   
