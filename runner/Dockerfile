FROM ubuntu:latest


RUN apt update;\
    DEBIAN_FRONTEND="noninteractive" apt install -y \
        git \
        software-properties-common \
        lsb-release \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg; \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg; \
    echo \
      "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null;

RUN apt update;\
    apt install -y \
        docker-ce docker-ce-cli containerd.io docker-compose;

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-key C99B11DEB97541F0;\
    apt-add-repository https://cli.github.com/packages;\
    apt update;\
    apt install gh -y;

RUN apt-cache policy docker-ce;

COPY bundlerunner.sh /usr/local/bin/docker-entrypoint
COPY askpass.sh /askpass.sh

ADD ./wrapdocker /usr/local/bin/wrapdocker
RUN chmod +x /usr/local/bin/wrapdocker

# Define additional metadata for our image.
VOLUME /var/lib/docker
CMD ["docker-entrypoint"]
ENTRYPOINT ["wrapdocker"]