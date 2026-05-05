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

dnf module disable redis -y &>>LOGS_FILE
VALIDATE $? "Disabling redis"

dnf module enable redis:7 -y &>>LOGS_FILE
VALIDATE $? "Enabling redis"

dnf install redis -y &>>LOGS_FILE
VALIDATE $? "Installing redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
VALIDATE $? "Allowing remote connections to redis"

systemctl enable redis &>>LOGS_FILE
VALIDATE $? "Enabling redis"

systemctl start redis &>>LOGS_FILE
VALIDATE $? "Starting redis"