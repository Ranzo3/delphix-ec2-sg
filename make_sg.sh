#!/bin/bash

#RFE:  If VPC_ID is blank, assume I only have one and look it up for me
#RFE:  Allow user choice to add 22, 80, 443 access from Delphix Admin PC.  Users might have a separate SG for this type of Admin access.

#AWS_CMD="docker run --rm -it -v ${HOME}/.aws:/root/.aws -v $(pwd):/aws amazon/aws-cli"   #Doens't work, due to extra characters in the output
AWS_CMD=aws
DELPHIX_ENGINE_SG_NAME=delphix-engine-sg
DELPHIX_ENGINE_SG_DESC="Delphix Engine SG"
DELPHIX_TARGET_SG_NAME=delphix-target-sg
DELPHIX_TARGET_SG_DESC="Delphix Target SG"
DELPHIX_SOURCE_SG_NAME=delphix-source-sg
DELPHIX_SOURCE_SG_DESC="Delphix Source SG"
VPC_ID=vpc-0df13675
#MY_IP=123.123.123.123/24      #Your company probably uses a range here, but if you comment it out we'll use "checkip.amazon.com and append /32"



delete_inbound_rules() {
DELPHIX_ENGINE_SG_ID=`${AWS_CMD} ec2 describe-security-groups --filters Name=group-name,Values=${DELPHIX_ENGINE_SG_NAME} --query "SecurityGroups[*].[GroupId]" --output text`
TMPFILE=`mktemp`
chmod u+x $TMPFILE
echo "${AWS_CMD} ec2 revoke-security-group-ingress --group-id ${DELPHIX_ENGINE_SG_ID} --ip-permissions '" > $TMPFILE
${AWS_CMD} ec2 describe-security-groups --group-ids ${DELPHIX_ENGINE_SG_ID} --query "SecurityGroups[*].IpPermissions[]" --output json >> $TMPFILE
echo "'" >> $TMPFILE
cat $TMPFILE
$TMPFILE
rm $TMPFILE

DELPHIX_TARGET_SG_ID=`${AWS_CMD} ec2 describe-security-groups --filters Name=group-name,Values=${DELPHIX_TARGET_SG_NAME} --query "SecurityGroups[*].[GroupId]" --output text`
TMPFILE=`mktemp`
chmod u+x $TMPFILE
echo "${AWS_CMD} ec2 revoke-security-group-ingress --group-id ${DELPHIX_TARGET_SG_ID} --ip-permissions '" > $TMPFILE
${AWS_CMD} ec2 describe-security-groups --group-ids ${DELPHIX_TARGET_SG_ID} --query "SecurityGroups[*].IpPermissions[]" --output json >> $TMPFILE
echo "'" >> $TMPFILE
cat $TMPFILE
$TMPFILE
rm $TMPFILE

DELPHIX_SOURCE_SG_ID=`${AWS_CMD} ec2 describe-security-groups --filters Name=group-name,Values=${DELPHIX_SOURCE_SG_NAME} --query "SecurityGroups[*].[GroupId]" --output text`
TMPFILE=`mktemp`
chmod u+x $TMPFILE
echo "${AWS_CMD} ec2 revoke-security-group-ingress --group-id ${DELPHIX_SOURCE_SG_ID} --ip-permissions '" > $TMPFILE
${AWS_CMD} ec2 describe-security-groups --group-ids ${DELPHIX_SOURCE_SG_ID} --query "SecurityGroups[*].IpPermissions[]" --output json >> $TMPFILE
echo "'" >> $TMPFILE
cat $TMPFILE
$TMPFILE
rm $TMPFILE
}

delete_sgs() {
${AWS_CMD} ec2 delete-security-group --group-id ${DELPHIX_ENGINE_SG_ID}
${AWS_CMD} ec2 delete-security-group --group-id ${DELPHIX_TARGET_SG_ID}
${AWS_CMD} ec2 delete-security-group --group-id ${DELPHIX_SOURCE_SG_ID}
}



create_sgs() {
RESULT=`${AWS_CMD} ec2 create-security-group --group-name ${DELPHIX_ENGINE_SG_NAME} --description "{DELPHIX_ENGINE_SG_DESC}" --vpc-id ${VPC_ID} --output json`
DELPHIX_ENGINE_SG_ID=`echo $RESULT | jq --raw-output '.GroupId'`
echo "DELPHIX_ENGINE_SG_ID: ${DELPHIX_ENGINE_SG_ID}"

RESULT=`${AWS_CMD} ec2 create-security-group --group-name ${DELPHIX_TARGET_SG_NAME} --description "{DELPHIX_TARGET_SG_DESC}" --vpc-id ${VPC_ID} --output json`
DELPHIX_TARGET_SG_ID=`echo $RESULT | jq --raw-output '.GroupId'`
echo "DELPHIX_TARGET_SG_ID: ${DELPHIX_TARGET_SG_ID}"

RESULT=`${AWS_CMD} ec2 create-security-group --group-name ${DELPHIX_SOURCE_SG_NAME} --description "{DELPHIX_SOURCE_SG_DESC}" --vpc-id ${VPC_ID} --output json`
DELPHIX_SOURCE_SG_ID=`echo $RESULT | jq --raw-output '.GroupId'`
echo "DELPHIX_SOURCE_SG_ID: ${DELPHIX_SOURCE_SG_ID}"
}

create_inbound_rules() {
RESULT=`${AWS_CMD} ec2 describe-security-groups --group-id ${DELPHIX_ENGINE_SG_ID} --output json`
echo $RESULT
DELPHIX_ENGINE_SG_OWNER_ID=`echo $RESULT | jq --raw-output '.SecurityGroups[].OwnerId'`
echo "DELPHIX_ENGINE_SG_OWNER_ID: ${DELPHIX_ENGINE_SG_OWNER_ID}"

#Assume the owner is the same for all three
DELPHIX_TARGET_SG_OWNER_ID=${DELPHIX_ENGINE_SG_OWNER_ID}
DELPHIX_SOURCE_SG_OWNER_ID=${DELPHIX_ENGINE_SG_OWNER_ID}

if [ ${MY_IP}x = 'x' ]; then
  MY_IP=`curl -s https://checkip.amazonaws.com`/32
fi
echo $MY_IP

#It's strangely difficult to pass in JSON to these commands.  Sorry for the weird workaround with temp files.
TMPFILE=`mktemp`
chmod u+x ${TMPFILE}
echo "${AWS_CMD} ec2 authorize-security-group-ingress --group-id ${DELPHIX_ENGINE_SG_ID} --ip-permissions '" > $TMPFILE
cat delphix-engine-sg.json >> $TMPFILE
echo "'" >> $TMPFILE
sed -i.bak "s[DELPHIX_TARGET_SG_ID[${DELPHIX_TARGET_SG_ID}[" ${TMPFILE}
sed -i.bak "s[DELPHIX_SOURCE_SG_ID[${DELPHIX_SOURCE_SG_ID}[" ${TMPFILE}
sed -i.bak "s[USER_ID[${DELPHIX_TARGET_SG_OWNER_ID}[" ${TMPFILE}
sed -i.bak "s[MY_IP[${MY_IP}[" ${TMPFILE}
cat $TMPFILE
$TMPFILE
rm $TMPFILE

#It's strangely difficult to pass in JSON to these commands.  Sorry for the weird workaround with temp files.
TMPFILE=`mktemp`
chmod u+x ${TMPFILE}
echo "${AWS_CMD} ec2 authorize-security-group-ingress --group-id ${DELPHIX_TARGET_SG_ID} --ip-permissions '" > $TMPFILE
cat delphix-target-sg.json >> $TMPFILE
echo "'" >> $TMPFILE
sed -i.bak "s[DELPHIX_ENGINE_SG_ID[${DELPHIX_ENGINE_SG_ID}[" ${TMPFILE}
sed -i.bak "s[USER_ID[${DELPHIX_TARGET_SG_OWNER_ID}[" ${TMPFILE}
sed -i.bak "s[MY_IP[${MY_IP}[" ${TMPFILE}
cat $TMPFILE
$TMPFILE
rm $TMPFILE

#It's strangely difficult to pass in JSON to these commands.  Sorry for the weird workaround with temp files.
TMPFILE=`mktemp`
chmod u+x ${TMPFILE}
echo "${AWS_CMD} ec2 authorize-security-group-ingress --group-id ${DELPHIX_SOURCE_SG_ID} --ip-permissions '" > $TMPFILE
cat delphix-source-sg.json >> $TMPFILE
echo "'" >> $TMPFILE
sed -i.bak "s[DELPHIX_ENGINE_SG_ID[${DELPHIX_ENGINE_SG_ID}[" ${TMPFILE}
sed -i.bak "s[USER_ID[${DELPHIX_TARGET_SG_OWNER_ID}[" ${TMPFILE}
sed -i.bak "s[MY_IP[${MY_IP}[" ${TMPFILE}
cat $TMPFILE
$TMPFILE
rm $TMPFILE
}


#Function to print a help message
usage() {
  echo
  echo 'Copyright (c) 2009,2010,2020 Delphix, All Rights Reserved.'
  echo
  echo "Usage: $0 [ -r ] [ -d ] "
  echo
  echo "With no flags, this script will create the SGs and the Ingress Rules."
  echo
  echo "-r : Just Replace the Inbound Rules.  Useful if you change the rules and have already attached SGs to Instances"
  echo
  echo "-d : Just Delete the Security Groups. Useful if you want to start over"
}

exit_abnormal() {
  echo
  echo
  usage
  exit 1
}



REPLACE_INBOUND_RULES=false
DELETE_SGS=false

while getopts "rd" OPTION; do
    case $OPTION in
    r)
        REPLACE_INBOUND_RULES=true
        ;;
    d)
        DELETE_SGS=true
        ;;
    esac
done

#Define Invalid Parameter Combinations
if [ ${REPLACE_INBOUND_RULES} = "true" ] && [ ${DELETE_SGS} = "true" ]; then
   echo "It's an invalid combination to use -r and -d together."
   exit_abnormal
fi

if [ ${REPLACE_INBOUND_RULES} = "true" ]; then
  delete_inbound_rules
  create_inbound_rules
  exit 0
fi
if [ ${DELETE_SGS} = "true" ] ; then
  delete_inbound_rules
  delete_sgs
  exit 0
fi

create_sgs
create_inbound_rules
exit 0



