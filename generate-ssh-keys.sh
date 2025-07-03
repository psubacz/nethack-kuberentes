#!/bin/bash

# Generate SSH host keys for the container
mkdir -p ssh-keys
pushd ssh-keys

# Generate ECDSA host key
ssh-keygen -t ecdsa -f ssh_host_ecdsa_key -N ""

# Generate ED25519 host key  
ssh-keygen -t ed25519 -f ssh_host_ed25519_key -N ""

echo "SSH host keys generated in ssh-keys/ directory"
 
popd