#!/bin/bash

# Setup the variables
version=${1:-2022}
sa_password=${2:-Password@12345!}
db_user=${3:-test}
db_password=${4:-test}
db_name=${5:-test}
port=${6:-1433}
container_name=${7:-setup_mssql_server}
ssl_mode=${8:-disable} # (Not fully implemented yet)
tag="latest"
image="mcr.microsoft.com/mssql/server:${version}-${tag}"
client="/opt/mssql-tools18/bin/sqlcmd"
addr="localhost"
ssl_opt="-N disabled"

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

setup_ssl () {
    # Setup SSL mode
    mkdir -p /opt/mssql

    # Generate the mssql.pem and mssql.key files
    openssl req -x509 -nodes -newkey rsa:2048 \
        -subj '/CN=localhost' \
        -keyout /opt/mssql/mssql.key \
        -out /opt/mssql/mssql.pem -days 30

    # Create the mssql.conf file
    touch /opt/mssql/mssql.conf
    echo "[network]" >> /opt/mssql/mssql.conf
    echo "tlscert = /var/opt/mssql/mssql.pem" >> /opt/mssql/mssql.conf
    echo "tlskey = /var/opt/mssql/mssql.key" >> /opt/mssql/mssql.conf
    echo "tlsprotocols = 1.2" >> /opt/mssql/mssql.conf

    sudo chmod -R 775 /opt/mssql

    cp /opt/mssql/mssql.pem /usr/share/ca-certificates/mssql.crt

    sudo dpkg-reconfigure ca-certificates
}

# Run MSSQL server container
setup_ssl

docker run \
    --name=$container_name \
    -e "ACCEPT_EULA=Y" \
    -e "SA_PASSWORD=$sa_password" \
    --health-cmd="$client -C -S $addr -U sa -P '$sa_password' -Q 'SELECT 1' -b -o /dev/null" \
    --health-start-period="10s" \
    --health-retries=3 \
    --health-interval="10s" \
    -p ${port}:1433 \
    -v /opt/mssql/mssql.conf:/var/opt/mssql/mssql.conf \
    -v /opt/mssql/mssql.pem:/var/opt/mssql/mssql.pem \
    -v /opt/mssql/mssql.key:/var/opt/mssql/mssql.key \
    -d "$image"

container_health_check

# Create the database and user
docker exec $container_name $client -C -S $addr -U sa -P $sa_password -Q "CREATE DATABASE $db_name;"
docker exec $container_name $client -C -S $addr -U sa -P $sa_password -Q "USE master; CREATE LOGIN $db_user WITH PASSWORD = '$db_password', CHECK_POLICY = OFF;"
docker exec $container_name $client -C -S $addr -U sa -P $sa_password -Q "USE master; EXEC master..sp_addsrvrolemember @loginame = '$db_user', @rolename = 'sysadmin';"
