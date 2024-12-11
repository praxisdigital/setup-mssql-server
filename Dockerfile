FROM docker:stable

USER root

COPY entrypoint.sh /entrypoint.sh

RUN apk add --no-cache bash

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
