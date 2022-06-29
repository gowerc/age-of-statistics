FROM node:16.15

# Get dev containers to use bash by default
ENV SHELL /bin/bash

# Get container to run as user 1000 to stop files being
# created as root on host machine
ARG UID=1000
ARG GID=1000
USER ${UID}:${GID}


