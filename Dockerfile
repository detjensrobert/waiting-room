# use image with systemd entrypoint, new for opentofu in repos
FROM dokken/ubuntu-24.04

# install ssh server
RUN apt-get update && \
    apt-get install -qq -y openssh-server git curl && \
    apt-get clean

# set up user for ssh access with empty password
ARG USERNAME="user"
COPY container/waiting-room.sh /waiting-room.sh
RUN useradd ${USERNAME} --create-home --shell /waiting-room.sh && \
    # printf "${USERNAME}:*" | chpasswd -e && \
    passwd -d $USERNAME && \
    touch /home/$USERNAME/.hushlogin
COPY container/sshd_config /etc/ssh/sshd_config

# install tooling
COPY --from=ghcr.io/opentofu/opentofu:minimal /usr/local/bin/tofu /usr/local/bin/tofu
RUN wget -qO /usr/local/bin/kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x /usr/local/bin/kubectl


# copy pod template and provisioning opentofu
COPY --chown=${USERNAME}:${USERNAME} ./provisioning/* /provisioning/
WORKDIR /provisioning/
# prime opentofu cache
ENV TF_INPUT=0
ENV TF_PLUGIN_CACHE_DIR=/tofu/
RUN mkdir /tofu && \
    tofu init


# send graceful shutdown https://systemd.io/CONTAINER_INTERFACE/
STOPSIGNAL SIGRTMIN+3

# default systemd entrypoint
