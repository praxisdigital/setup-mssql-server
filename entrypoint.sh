#!/bin/sh

if [ -z "$INPUT_VERSION" ]; then
    echo "INPUT_VERSION is not set."
    exit 1
fi
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

container_name=$(tr -dc a-z0-9 </dev/urandom | head -c 14)

image=mcr.microsoft.com/mssql/server:${INPUT_VERSION}
docker_run="docker run -e ACCEPT_EULA=Y -e MSSQL_SA_PASSWORD=$INPUT_SA_PASSWORD -e MSSQL_PID=Developer -p ${INPUT_PORT:-1433}:1433 --name $container_name --rm -d $image"


sh -c "$docker_run"

# Prepare for DB initiazation
sqlbin=/opt/mssql-tools/bin/sqlcmd

is_mssql_running() {
    docker exec -it $container_name $sqlbin -S localhost -U sa -P $INPUT_SA_PASSWORD -Q "SELECT 1" > /dev/null 2>&1
}

# Delay until SQL Server is up
while ! is_mssql_running; do
    sleep 1
done

# Create database
docker exec -it $container_name $sqlbin -S localhost -U sa -P $INPUT_SA_PASSWORD -Q "CREATE DATABASE $INPUT_DB;"

# Create user and password with full grant
create_user_query="CREATE LOGIN $INPUT_USER WITH PASSWORD = '$INPUT_PASSWORD';"
create_user_query="$create_user_query CREATE USER $INPUT_USER FOR LOGIN $INPUT_USER;"
create_user_query="$create_user_query ALTER ROLE db_owner ADD MEMBER $INPUT_USER;"
create_user_query="$create_user_query ALTER LOGIN $INPUT_USER ENABLE;"
docker exec -it $container_name $sqlbin -S localhost -U sa -P $INPUT_SA_PASSWORD -Q "$create_user_query";
