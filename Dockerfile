FROM debian:latest AS openssh-server

ARG GIT_USER_UID=1000

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y openssh-server

RUN mkdir /var/run/sshd

RUN echo 'PermitRootLogin no' >> /etc/ssh/sshd_config && \
    echo 'PasswordAuthentication no' >> /etc/ssh/sshd_config && \
    echo 'PubkeyAuthentication yes' >> /etc/ssh/sshd_config && \
    echo 'AuthorizedKeysFile /home/git/.ssh/authorized_keys' >> /etc/ssh/sshd_config

EXPOSE 22

FROM openssh-server AS git-server

RUN apt-get install -y git

RUN adduser --disabled-password --gecos "" git --uid $GIT_USER_UID && \
    echo "$(which git-shell)" >> /etc/shells && \
    chsh git -s $(which git-shell) 

RUN mkdir /home/git/.ssh && \
    chown -R git:git /home/git/.ssh && \
    chmod 700 /home/git/.ssh && \
    touch /home/git/.ssh/authorized_keys && \
    chown git:git /home/git/.ssh/authorized_keys && \
    chmod 600 /home/git/.ssh/authorized_keys

RUN mkdir /home/git/public-keys && \
    chown -R git:git /home/git/public-keys

COPY public-keys/*.pub /home/git/public-keys

COPY bin/* /usr/local/bin

RUN chmod +x /usr/local/bin/copy-public-keys.sh && \
    chmod +x /usr/local/bin/entrypoint.sh

RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
