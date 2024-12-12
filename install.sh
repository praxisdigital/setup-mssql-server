#!/bin/bash

# Setup the variables
version=${1:-2022}
sa_password=${2:-Password@12345!}
db_user=${3:-test}
db_password=${4:-test}
db_name=${5:-test}
port=${6:-1433}
ssl_mode=${7:-disable} # (Not implemented yet) disable|require
tag="latest"
image="mcr.microsoft.com/mssql/server:${version}-${tag}"
container_name=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 12)
client="/opt/mssql-tools18/bin/sqlcmd"
addr="localhost"

# Check if the version is supported
if [[ $version -le 2017 ]]; then
    printf "Version 2017 or earlier is not supported\n"
    exit 1
fi

# Wait for the container to be healthy
container_health_check () {
    check_interval=1
    timeout=60

    while [ $timeout -gt 0 ]; do
        health_status=$(docker inspect --format='{{.State.Health.Status}}' $container_name 2> /dev/null)
        if [ "$health_status" == "healthy" ]; then
            printf "Container '%s' is healthy.\n" $container_name
            break
        elif [ $timeout -eq 0 ]; then
            printf "Timed out waiting for container '%s' to be healthy.\n" $container_name
            docker logs $container_name
            docker inspect --format "{{json .State.Health }}" $container_name
            exit 2
        fi
        sleep $check_interval
        timeout=$((timeout-$check_interval))
    done
}

# Run MSSQL server container
docker run \
    --name=$container_name \
    -e "ACCEPT_EULA=Y" \
    -e "SA_PASSWORD=$sa_password" \
    --health-cmd="$client -C -S $addr -U sa -P '$sa_password' -Q 'SELECT 1' -b -o /dev/null" \
    --health-start-period="10s" \
    --health-retries=3 \
    --health-interval="10s" \
    -p ${port}:1433 \
    -d "$image"

container_health_check

# Create the database and user
docker exec -it $container_name $client -S $addr -U sa -P $sa_password -Q "CREATE DATABASE $db_name;"
docker exec -it $container_name $client -S $addr -U sa -P $sa_password -Q "CREATE LOGIN $db_user WITH PASSWORD='$db_password';"
docker exec -it $container_name $client -S $addr -U sa -P $sa_password -Q "CREATE USER $db_user FOR LOGIN $db_user;"
