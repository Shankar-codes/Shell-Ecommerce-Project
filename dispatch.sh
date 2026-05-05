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

dnf install golang -y &>>LOGS_FILE
VALIDATE $? "Installing golang"

id roboshop &>>LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Creating system user"
else
    echo -e "User already exists... $Y SKIPPING $N"
fi

mkdir /app &>>LOGS_FILE
VALIDATE $? "Creating app directory"

curl -L -o /tmp/dispatch.zip https://roboshop-artifacts.s3.amazonaws.com/dispatch-v3.zip  &>>LOGS_FILE
VALIDATE $? "Copying the artifacts"

cd /app &>>LOGS_FILE
VALIDATE $? "Changing the directory"

unzip /tmp/dispatch.zip &>>LOGS_FILE
VALIDATE $? "Extracting the artifacts"

cd /app &>>LOGS_FILE
VALIDATE $? "Changing the directory"

go mod init dispatch &>>LOGS_FILE
VALIDATE $? "Initializing the go module"

go get  &>>LOGS_FILE
VALIDATE $? "Downloading the dependencies"

go build &>>LOGS_FILE
VALIDATE $? "Building the application"

cp $SCRIPT_DIR/dispatch.service /etc/systemd/system/dispatch.service &>>LOGS_FILE
VALIDATE $? "Copying the service file"

systemctl daemon-reload &>>LOGS_FILE
VALIDATE $? "Reloading the systemctl daemon"

systemctl enable dispatch &>>LOGS_FILE
VALIDATE $? "Enabling the dispatch service"

systemctl start dispatch &>>LOGS_FILE
VALIDATE $? "Starting the dispatch service"