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
MYSQL_HOST="mysql.ellamma.fun"
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

dnf install maven -y &>>LOGS_FILE
VALIDATE $? "Installing maven"

id roboshop &>>LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>LOGS_FILE
    VALIDATE $? "Creating system user"
else
    echo -e "User already exists... $Y SKIPPING $N"
fi

mkdir -p /app &>>LOGS_FILE
VALIDATE $? "Creating app directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>LOGS_FILE
VALIDATE $? "Copying the artifacts"

cd /app &>>LOGS_FILE
VALIDATE $? "Changing the directory"

unzip /tmp/shipping.zip &>>LOGS_FILE
VALIDATE $? "Extracting the artifacts"

cd /app &>>LOGS_FILE
VALIDATE $? "Changing the directory"

mvn clean package &>>LOGS_FILE
VALIDATE $? "Building the shipping service"

mv target/shipping-1.0.jar shipping.jar &>>LOGS_FILE
VALIDATE $? "Renaming the shipping service"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service &>>LOGS_FILE
VALIDATE $? "Copying the shipping service file"

systemctl daemon-reload &>>LOGS_FILE
VALIDATE $? "Reloading the systemctl daemon"

systemctl enable shipping &>>LOGS_FILE
VALIDATE $? "Enabling the shipping service"

systemctl start shipping &>>LOGS_FILE
VALIDATE $? "Starting the shipping service"

dnf install mysql -y &>>LOGS_FILE
VALIDATE $? "Installing mysql client"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use cities' &>>$LOGS_FILE
if [ $? -ne 0 ]; then
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql 
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql
else
    echo -e "Shipping cities already loaded ... $Y SKIPPING $N"
fi

systemctl restart shipping &>>LOGS_FILE
VALIDATE $? "Restarting the shipping service"