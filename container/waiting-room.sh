#!/bin/bash
# set as user's shell to act as a waiting room

set -eu # TODO remove x

# use git-style first 7 chars of sha as a session id and name for stuff
# add current time to connection info for collision avoidance
export USER_SHA=$(echo "$SSH_CONNECTION" "$(date +%s)" | sha1sum | head -c 7 )

log_run () {
  systemd-cat -t "chal-setup-$USER_SHA" $*
}

# destroy if terraform dies or whatever
function cleanup {
  log_run nohup terraform apply -auto-approve \
    -state "/tmp/$USER_SHA.tfstate" \
    -var session_id="$USER_SHA" \
    -var-file setup.tfvars \
    -destroy &
  echo goodbye!
}
trap cleanup EXIT

spinner() {
  # from https://stackoverflow.com/a/20369590
  local pid=$!
  local delay=0.75
  local spinstr='|/-\'
  while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
    local temp=${spinstr#?}
    printf " [%c]  " "$spinstr"
    local spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\b\b\b\b\b\b"
  done
  printf "    \b\b\b\b"
}

echo
echo
tput setaf 12
echo "    welcome to the waiting room"
tput sgr0
echo
echo
echo your session id: "$(tput setaf 9)$USER_SHA$(tput sgr0)"
echo if things break, include that when talking to admin
echo
echo setting up things...
tput setaf 8
echo "(this may take a few minutes)"
tput sgr0

cd /provisioning/

export TF_INPUT=0 # disable input
export TF_PLUGIN_CACHE_DIR=/terraform/ # prepopulated
export TF_DATA_DIR="/tmp/tf-$USER_SHA" # store in private-tmp
mkdir "$TF_DATA_DIR"

# i need to hardcode these ughhhhh
export KUBERNETES_SERVICE_HOST=10.245.0.1
export KUBERNETES_SERVICE_PORT=443

# spin up new runner and project
log_run terraform init
log_run terraform plan \
  -state "/tmp/$USER_SHA.tfstate" \
  -var session_id="$USER_SHA" \
  -var-file setup.tfvars \
  -out /tmp/$USER_SHA.tfplan &
spinner
log_run terraform apply -state "/tmp/$USER_SHA.tfstate" /tmp/$USER_SHA.tfplan &
spinner


# boot user into it
POD="$(terraform output -state "/tmp/$USER_SHA.tfstate" -raw pod_name)"
kubectl wait -n runners --for=condition=Ready "pod/$POD" &>/dev/null

echo all set!
echo this session will be closed after "$(tput setaf 9)1h$(tput sgr0)"
echo

timeout --foreground 1h \
  kubectl exec -n runners -it "pod/$POD" -- sudo -H -u ubuntu sh -c "cd && env TERM=xterm-256color bash -i"

exit
