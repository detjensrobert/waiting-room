# FROM dokken/rockylinux-9
FROM dokken/ubuntu-22.04

RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor \
      > /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
      https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
      > /etc/apt/sources.list.d/hashicorp.list && \
    apt-get update && \
    apt-get install -qq -y terraform openssh-server && \
    apt-get clean

RUN wget -q "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
  chmod +x kubectl && \
  mv kubectl /usr/local/bin/


# set up user for ssh access
COPY container/waiting-room.sh /waiting-room.sh
RUN useradd chal --create-home --shell /waiting-room.sh && \
    printf "chal:damctf" | chpasswd && \
    touch /home/chal/.hushlogin
COPY container/sshd_config /etc/ssh/sshd_config

# copy pod template and provisioning terraform
COPY --chown=chal:chal ./provisioning/* /chal-setup/
WORKDIR /chal-setup/
# prime terraform cache
ENV TF_INPUT=0
ENV TF_PLUGIN_CACHE_DIR=/terraform/
RUN mkdir /terraform && \
    terraform init

# setup creds/args for waiting room tf
ARG USER_TOKEN
ARG TEMPLATE_PROJECT
ARG GITLAB_URL
COPY <<EOF setup.tfvars
gitlab_url = "${GITLAB_URL}"
gitlab_user_token = "${USER_TOKEN}"
template_project = "${TEMPLATE_PROJECT}"
EOF


# send graceful shutdown https://systemd.io/CONTAINER_INTERFACE/
STOPSIGNAL SIGRTMIN+3

# default systemd entrypoint
