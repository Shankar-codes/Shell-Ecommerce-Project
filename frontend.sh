#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[34m"
N="\e[0m"

USERID=$(id -u)

LOGS_FOLDER="/var/log/Shell-Ecommerce-Project"
SCRIPT_FILE=$(echo $0 | cut -d "." -f1)
LOGS_FILE="$LOGS_FOLDER/$SCRIPT_FILE.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo "Script execution started $(date)"

if [ $USERID -ne 0 ]; then
	echo "Please login to root user to execute the script"
	exit 1
fi

VALIDATE() {
	if [ $1 -ne 0 ]; then
		echo -e "$2  ... $R FAILURE $N" | tee -a $LOGS_FILE
		exit 1
	else
		echo -e "$2 ... $F SUCCESS $N" | tee -a $LOGS_FILE
	fi
}

dnf module disable nginx -y &>>LOGS_FILE
VALIDATE $? "Disabling nginx"

dnf module enable nginx:1.24 -y &>>LOGS_FILE
VALIDATE $? "Enabling nginx"

dnf install nginx -y &>>LOGS_FILE
VALIDATE $? "Installing nginx"

systemctl enable nginx &>>LOGS_FILE
VALIDATE $? "Enabling nginx"

systemctl start nginx &>>LOGS_FILE
VALIDATE $? "Starting nginx"

rm -rf /usr/share/nginx/html/* &>>LOGS_FILE
VALIDATE $? "Cleaning nginx default content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>LOGS_FILE
VALIDATE $? "Copying the artifacts"

cd /usr/share/nginx/html &>>LOGS_FILE
VALIDATE $? "Changing the directory"

unzip /tmp/frontend.zip &>>LOGS_FILE
VALIDATE $? "Extracting the artifacts"

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf &>>LOGS_FILE
VALIDATE $? "Copying nginx configuration"

systemctl restart nginx &>>LOGS_FILE
VALIDATE $? "Restarting nginx"