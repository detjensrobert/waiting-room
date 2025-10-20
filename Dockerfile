# use image with systemd entrypoint
FROM dokken/ubuntu-24.04

# install toools
RUN wget -qO- https://apt.releases.hashicorp.com/gpg | gpg --dearmor \
    > /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    > /etc/apt/sources.list.d/hashicorp.list
RUN apt-get update && \
    apt-get install -qq -y terraform openssh-server && \
    apt-get clean
RUN wget -qO /usr/local/bin/kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x /usr/local/bin/


# set up user for ssh access with empty password
ARG USERNAME="user"
COPY container/waiting-room.sh /waiting-room.sh
RUN useradd ${USERNAME} --create-home --shell /waiting-room.sh && \
    # printf "${USERNAME}:*" | chpasswd -e && \
    passwd -d $USERNAME && \
    touch /home/$USERNAME/.hushlogin
COPY container/sshd_config /etc/ssh/sshd_config


# copy pod template and provisioning terraform
COPY --chown=${USERNAME}:${USERNAME} ./provisioning/* /provisioning/
WORKDIR /provisioning/
# prime terraform cache
ENV TF_INPUT=0
ENV TF_PLUGIN_CACHE_DIR=/terraform/
RUN mkdir /terraform && \
    terraform init


# send graceful shutdown https://systemd.io/CONTAINER_INTERFACE/
STOPSIGNAL SIGRTMIN+3

# default systemd entrypoint
