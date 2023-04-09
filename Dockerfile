# syntax=docker/dockerfile:experimental
ARG UBUNTU=18.04
FROM ubuntu:18.04

# uid on Github action host 
# uid=1001(runner) gid=123(docker) groups=123(docker),4(adm),101(systemd-journal)
# uid on Github action host 
ARG UBUNTU
ARG UID=1001
ARG GID=123

LABEL version="0.5.0" builder_user_uid=${UID} builder_user_uid=${GID}

RUN addgroup --gid ${GID} builder \
  && useradd --uid ${UID} --gid ${GID} -ms /bin/bash builder \
  && apt-get -qq update && apt-get -qq install sudo \
  && /bin/bash -c 'echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/99_sudo_include_file'
RUN id builder

USER builder
WORKDIR /home/builder
RUN --mount=type=bind,source=.,target=/tmp/host cd /tmp/host && ./initenv.sh

#FIXME# RUN --mount=type=bind,source=.,target=/tmp/host cd /tmp/host && ./ccache-hack-install.sh
COPY ccache-hack-install.sh .
RUN /bin/bash ccache-hack-install.sh
