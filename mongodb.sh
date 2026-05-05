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

mkdir -p $LOGS_FOLDER
echo "Script started at $(date)" | tee -a $LOGS_FILE

if [ $USERID -ne 0 ]; then
    echo "please use root login to execute this script" | tee -a $LOGS_FILE
    exit 1
fi

VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOGS_FILE
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOGS_FILE
    fi
}

cp mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOGS_FILE
VALIDATE $? "Copying mongo.repo file"

dnf install mongodb-org -y &>>$LOGS_FILE
VALIDATE $? "Installing MongoDB"

systemctl enable mongod &>>$LOGS_FILE
VALIDATE $? "Enabling MongoDB"

systemctl start mongod &>>$LOGS_FILE
VALIDATE $? "Starting MongoDB"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Allowing remote connections to MongoDB"

systemctl restart mongod &>>$LOGS_FILE
VALIDATE $? "Restarting MongoDB"