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

mkdir -p /app
VALIDATE $? "Creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>LOGS_FILE
VALIDATE $? "Copying the artifacts"

cd /app
VALIDATE $? "Changing the directory"

rm -rf /app/*
VALIDATE $? "Removing old files"

unzip /tmp/catalogue.zip &>>LOGS_FILE
VALIDATE $? "Unzipping the Catalogue artifact"

npm install &>>LOGS_FILE
VALIDATE $? "Installing the Dependencies"

cp catalogue.service /etc/systemd/system/
VALIDATE $? "Copy systemctl service"

systemctl daemon-reload
systemctl enable catalogue &>>LOGS_FILE
VALIDATE $? "Enabling the catalogue service"

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copying the mongo repo"

dnf install mongodb-mongosh -y &>>LOGS_FILE
VALIDATE $? "Install mongodb client"

INDEX=$(mongosh mongodb.ellamma.fun --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")
if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
    VALIDATE $? "Load catalogue products"
else
    echo -e "Catalogue products already loaded ... $Y SKIPPING $N"
fi

systemctl restart catalogue
VALIDATE $? "Restarted catalogue"