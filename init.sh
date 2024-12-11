#!/bin/sh

if [ -z "$INPUT_SA_PASSWORD" ]; then
    echo "INPUT_SA_PASSWORD is not set. Exiting."
    exit 1
fi
if [ -z "$INPUT_DB" ]; then
    echo "INPUT_DB is not set. Exiting."
    exit 1
fi
if [ -z "$INPUT_USER" ]; then
    echo "INPUT_USER is not set. Exiting."
    exit 1
fi
if [ -z "$INPUT_PASSWORD" ]; then
    echo "INPUT_PASSWORD is not set. Exiting."
    exit 1
fi

sqlbin=/opt/mssql-tools/bin/sqlcmd
addr=localhost
query="$sqlbin -S $addr -U sa -P $INPUT_SA_PASSWORD -Q"

is_mssql_running() {
    $query "SELECT 1" > /dev/null 2>&1
}

# Delay until SQL Server is up
while ! is_mssql_running; do
    sleep 1
done

# Create user and password with full grant
$query "CREATE LOGIN $INPUT_USER WITH PASSWORD = '$INPUT_PASSWORD';"
$query "CREATE USER $INPUT_USER FOR LOGIN $INPUT_USER;"
$query "ALTER ROLE db_owner ADD MEMBER $INPUT_USER;"
$query "ALTER LOGIN $INPUT_USER ENABLE;"
$query "ALTER LOGIN $INPUT_USER WITH DEFAULT_DATABASE = $INPUT_DB_NAME;"
