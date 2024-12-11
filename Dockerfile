ARG VERSION=2022-latest

# Build Microsoft SQL Server
FROM mcr.microsoft.com/mssql/server:${VERSION:-2022-latest}

USER root

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENV ACCEPT_EULA=Y

ENTRYPOINT [ "/entrypoint.sh" ]
