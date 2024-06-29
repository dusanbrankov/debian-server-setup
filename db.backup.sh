#!/usr/bin/env bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 2>&1
   exit 1
fi

# Define AWS CLI configuration file paths
export AWS_CONFIG_FILE="/home/dusan/.aws/config"
export AWS_SHARED_CREDENTIALS_FILE="/home/dusan/.aws/credentials"

bucket=wunderbaumbucket
mysql_cnf=/home/dusan/.my.cnf

databases=(
    ic_berlin
    wunderbaum_prod
)

for db in "${databases[@]}"; do
    backup_file="/tmp/$db.backup.$(date +%F-%H-%M).sql"

    mysqldump --defaults-extra-file="$mysql_cnf" "$db" >"$backup_file" 
    aws --profile eu2 --region default --endpoint-url "https://eu2.contabostorage.com/$bucket" s3 cp "$backup_file" "s3://$bucket"

    rm "$backup_file"
done

