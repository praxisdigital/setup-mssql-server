ARG VERSION=2022-latest

# Build Microsoft SQL Server
FROM mcr.microsoft.com/mssql/server:${VERSION:-2022-latest}

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
