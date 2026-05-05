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
MONGODB_HOST="mongodb.ellamma.fun"
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

dnf module disable nodejs -y &>>LOGS_FILE
VALIDATE $? "Disabling node js"

dnf module enable nodejs:20 -y &>>LOGS_FILE
VALIDATE $? "Enabling node js"

dnf install nodejs -y &>>LOGS_FILE
VALIDATE $? "Installing node js"

id roboshop &>>LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>LOGS_FILE
    VALIDATE $? "Creating system user"
else
    echo -e "User already exists... $Y SKIPPING $N"
fi

mkdir /app &>>LOGS_FILE
VALIDATE $? "Creating app directory"

curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>>LOGS_FILE
VALIDATE $? "Copying the artifacts"

cd /app
VALIDATE $? "Changing the directory"

rm -rf /app/*
unzip /tmp/user.zip &>>LOGS_FILE
VALIDATE $? "Extracting the artifacts"

cd /app 
VALIDATE $? "Changing the directory"

npm install &>>LOGS_FILE
VALIDATE $? "Installing node js dependencies"

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service &>>LOGS_FILE
VALIDATE $? "Copying systemctl service file"

systemctl daemon-reload
systemctl enable user &>>LOGS_FILE
VALIDATE $? "Enabling user service"

systemctl start user &>>LOGS_FILE
VALIDATE $? "Starting user service"