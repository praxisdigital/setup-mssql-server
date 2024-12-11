#!/bin/sh

printf "Setting up SQL Server\n"

if [ -z "$INPUT_VERSION" ]; then
    echo "INPUT_VERSION is not set."
    exit 1
else
    echo "Using mcr.microsoft.com/mssql/server:${INPUT_VERSION}"
fi

if [ -z "$INPUT_SA_PASSWORD" ]; then
    echo "INPUT_SA_PASSWORD is not set. Exiting."
    exit 1
else
    echo "SA password is set"
fi

if [ -z "$INPUT_DB" ]; then
    echo "INPUT_DB is not set. Exiting."
    exit 1
else
    printf "Database name: $INPUT_DB\n"
fi

if [ -z "$INPUT_USER" ]; then
    echo "INPUT_USER is not set. Exiting."
    exit 1
else
    printf "DB user name: $INPUT_USER\n"
fi

if [ -z "$INPUT_PASSWORD" ]; then
    echo "INPUT_PASSWORD is not set. Exiting."
    exit 1
else
    printf "DB user password is set\n"
fi

container_name=$(tr -dc a-z0-9 </dev/urandom | head -c 14)

image=mcr.microsoft.com/mssql/server:${INPUT_VERSION}

# Run SQL Server
printf "Starting SQL Server container $container_name with image $image\n"
docker_run="docker run --detach --rm --name $container_name -p ${INPUT_PORT:-1433}:1433 -e ACCEPT_EULA=Y -e MSSQL_SA_PASSWORD=$INPUT_SA_PASSWORD $image"

printf "Running: $docker_run\n"

container_id=$($docker_run)

printf "Container $container_name started with id $container_id\n"

# Prepare for DB initiazation
sqlbin=/opt/mssql-tools/bin/sqlcmd

is_mssql_running() {
    docker exec $container_id $sqlbin -S localhost -U sa -P $INPUT_SA_PASSWORD -Q "SELECT 1" > /dev/null 2>&1
}

# Delay until SQL Server is up
printf "Waiting for SQL Server to start."
while ! is_mssql_running; do
    printf "."
    sleep 1
done

# Create database
printf "Creating database $INPUT_DB\n"
docker exec $container_id $sqlbin -S localhost -U sa -P $INPUT_SA_PASSWORD -Q "CREATE DATABASE $INPUT_DB;"

# Create user and password with full grant
printf "Creating user $INPUT_USER with password $INPUT_PASSWORD\n"
create_user_query="CREATE LOGIN $INPUT_USER WITH PASSWORD = '$INPUT_PASSWORD';"
create_user_query="$create_user_query CREATE USER $INPUT_USER FOR LOGIN $INPUT_USER;"
create_user_query="$create_user_query ALTER ROLE db_owner ADD MEMBER $INPUT_USER;"
create_user_query="$create_user_query ALTER LOGIN $INPUT_USER ENABLE;"
docker exec $container_id $sqlbin -S localhost -U sa -P $INPUT_SA_PASSWORD -Q "$create_user_query";

printf "SQL Server container $container_name is ready\n"
