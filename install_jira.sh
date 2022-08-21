#!/bin/bash

#USING A FUNCTION SO THAT COMMANDS WILL BE EXECUTED IN A SUB-SHELL
function install_jira() {

#JIRA INSTALLATION COMMANDS
wget https://www.atlassian.com/software/jira/downloads/binary/atlassian-jira-software-8.22.6-x64.bin;
sudo chmod a+x atlassian-jira-software-8.22.6-x64.bin;
sudo bash ./atlassian-jira-software-8.22.6-x64.bin -q -varfile response.varfile;
sudo tar -xzf mysql-connector-java-8.0.30.tar.gz;
cd mysql-connector-java-8.0.30;
sudo cp mysql-connector-java-8.0.30.jar  /opt/atlassian/jira/lib/;
export CLASSPATH=$CLASSPATH:/opt/atlassian/jira/lib/mysql-connector-java-8.0.30.jar;


#AWS CLI ENVIRONMENT VARIABLE
export AWS_DEFAULT_REGION=us-east-1;

password=$(aws secretsmanager get-secret-value --secret-id MysqldbCreds --query 'SecretString' --output text | jq .password | tr -d \"); 
database=$(aws rds describe-db-instances --db-instance-identifier mysqldb-server --query DBInstances[0] --output json | jq .DBName | tr -d \");
user=$(aws rds describe-db-instances --db-instance-identifier mysqldb-server --query DBInstances[0] --output json | jq .MasterUsername | tr -d \");
hostname=$(aws rds describe-db-instances --db-instance-identifier mysqldb-server --query DBInstances[0] --output json | jq .Endpoint.Address | tr -d \");
    
    
#PASSING VALUES TO JIRA DBCONFIG FILE
cd ..
sudo sed -i "s/dbname/${database}/g" dbconfig.xml;
sudo sed -i "s/dbusername/${user}/g" dbconfig.xml;
sudo sed -i "s/dbpassword/${password}/g" dbconfig.xml;
sudo sed -i "s/dbhostname/${hostname}/g" dbconfig.xml;

cp dbconfig.xml /var/atlassian/application-data/jira/;
sudo chown jira:jira /var/atlassian/application-data/jira/dbconfig.xml;
cp healthy.html /var/www/html/;


sudo /etc/init.d/jira stop;
sudo /etc/init.d/jira start;

}

# calling function
install_jira
