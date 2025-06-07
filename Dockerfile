FROM alpine:latest AS openssh-server

# git user ID.
# 
# When using volumes, user 'git' should have the same ID then the user executing 
# the container in host machine
ARG GIT_USER_UID=1000

# Install required packages using --no-cache to reduce image size
RUN apk update && \
    apk add --no-cache \
        openssh \
        shadow

# Create directory for sshd
RUN mkdir /var/run/sshd

# Configure sshd.
#
# PermitRootLogin no:        Disable root login
# PubkeyAuthentication yes:  Enable public key authentication
# PasswordAuthentication no: Disable password authentication
# AuthorizedKeysFile:        Define location of authorized keys file
RUN echo 'PermitRootLogin no' >> /etc/ssh/sshd_config && \
    echo 'PubkeyAuthentication yes' >> /etc/ssh/sshd_config && \
    echo 'PasswordAuthentication no' >> /etc/ssh/sshd_config && \
    echo 'AuthorizedKeysFile .ssh/authorized_keys' >> /etc/ssh/sshd_config

# Generate a new host key
RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ""

# Expose SSH port
EXPOSE 22

# Second stage: Git server configuration
FROM openssh-server AS git-server

# Importing arg from previous stage
ARG GIT_USER_UID=1000

# Install git
RUN apk add --no-cache git

# Verify git-shell. If it doesn't exists, fail the build.
# This ensures the 'git' user always has a restricted shell.
RUN if [ ! -f /usr/bin/git-shell ]; then \
        echo "Error: /usr/bin/git-shell not found after installing git." >&2; \
        exit 1; \
    fi && \
    # Add git-shell to valid shells list
    echo /usr/bin/git-shell >> /etc/shells

# Add 'git' user without password (-D), with specific UID (-u) and set git-shell as 
# his shell (-s)
# The 'shadow' package installed in previous stage provides the adduser command
RUN adduser -D -u $GIT_USER_UID -s /usr/bin/git-shell git && \
    # Unlock the git account by setting an invalid password hash (!)
    sed -i 's/git:!/git:*/' /etc/shadow

# Create .ssh directory for git user, set permissions and create authorized_keys file
RUN mkdir /home/git/.ssh && \
    chmod 700 /home/git/.ssh && \
    touch /home/git/.ssh/authorized_keys && \
    chmod 600 /home/git/.ssh/authorized_keys && \
    chown -R git:git /home/git/.ssh

# Create a directory for Git repositories
RUN mkdir /r && \
    chown -R git:git /r

# Copy helper scripts to /usr/local/bin inside the container
COPY bin/ /usr/local/bin/
# Make scripts executable
RUN chmod +x /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/copy-public-keys.sh

# Set default working directory
WORKDIR /home/git

# Set container entrypoint to run the entrypoint.sh script
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# DStarts SSH server in debug mode
CMD ["/usr/sbin/sshd", "-D"]
