#!/bin/bash
set -euo pipefail

###############################################################################
# AWS IRE SSH Setup
#
# 1. Reads Terraform outputs
# 2. Generates ~/.ssh/config on the laptop
# 3. Copies SSH keys to all EC2s
# 4. Appends /etc/hosts on every EC2 (without duplicates)
# 5. Generates ~/.ssh/config on every EC2
###############################################################################

TF_DIR="."

command -v terraform >/dev/null || { echo "terraform not installed"; exit 1; }
command -v jq >/dev/null || { echo "jq not installed"; exit 1; }

echo "Reading Terraform outputs..."

pushd "$TF_DIR" >/dev/null

MGMT_IP=$(terraform output -json private_ips | jq -r '.management')
CORE_IP=$(terraform output -json private_ips | jq -r '.core')
PROTECTED_IP=$(terraform output -json private_ips | jq -r '.protected')

popd >/dev/null

###############################################################################
# Laptop SSH Config
###############################################################################

echo "Generating local SSH config..."

mkdir -p ~/.ssh

cat > ~/.ssh/config <<EOF
Host management
    HostName ${MGMT_IP}
    User ec2-user
    IdentityFile ~/.ssh/management
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host core
    HostName ${CORE_IP}
    User ec2-user
    IdentityFile ~/.ssh/management
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host protected
    HostName ${PROTECTED_IP}
    User ec2-user
    IdentityFile ~/.ssh/management
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF

chmod 600 ~/.ssh/config

###############################################################################
# Copy key to Management
###############################################################################

echo "Copying key to Management..."

scp \
    ~/.ssh/management \
    ~/.ssh/management.pub \
    management:~/.ssh/

###############################################################################
# Configure Management
###############################################################################

ssh management <<EOF

chmod 600 ~/.ssh/management
sudo hostnamectl set-hostname management

grep -q "management" /etc/hosts || echo "${MGMT_IP} management" | sudo tee -a /etc/hosts
grep -q "core" /etc/hosts || echo "${CORE_IP} core" | sudo tee -a /etc/hosts
grep -q "protected" /etc/hosts || echo "${PROTECTED_IP} protected" | sudo tee -a /etc/hosts

cat > ~/.ssh/config <<CONFIG
Host management
    HostName management
    User ec2-user
    IdentityFile ~/.ssh/management
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host core
    HostName core
    User ec2-user
    IdentityFile ~/.ssh/management
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host protected
    HostName protected
    User ec2-user
    IdentityFile ~/.ssh/management
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
CONFIG

chmod 600 ~/.ssh/config

echo "Copying key to Core..."

scp ~/.ssh/management ~/.ssh/management.pub core:~/.ssh/

ssh core <<INNER

chmod 600 ~/.ssh/management
sudo hostnamectl set-hostname core

grep -q "management" /etc/hosts || echo "${MGMT_IP} management" | sudo tee -a /etc/hosts
grep -q "core" /etc/hosts || echo "${CORE_IP} core" | sudo tee -a /etc/hosts
grep -q "protected" /etc/hosts || echo "${PROTECTED_IP} protected" | sudo tee -a /etc/hosts

cat > ~/.ssh/config <<CONFIG2
Host management
    HostName management
    User ec2-user
    IdentityFile ~/.ssh/management
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host core
    HostName core
    User ec2-user
    IdentityFile ~/.ssh/management
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host protected
    HostName protected
    User ec2-user
    IdentityFile ~/.ssh/management
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
CONFIG2

chmod 600 ~/.ssh/config

echo "Copying key to Protected..."

scp ~/.ssh/management ~/.ssh/management.pub protected:~/.ssh/

ssh protected <<FINAL

chmod 600 ~/.ssh/management
sudo hostnamectl set-hostname protected

grep -q "management" /etc/hosts || echo "${MGMT_IP} management" | sudo tee -a /etc/hosts
grep -q "core" /etc/hosts || echo "${CORE_IP} core" | sudo tee -a /etc/hosts
grep -q "protected" /etc/hosts || echo "${PROTECTED_IP} protected" | sudo tee -a /etc/hosts

cat > ~/.ssh/config <<CONFIG3
Host management
    HostName management
    User ec2-user
    IdentityFile ~/.ssh/management
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host core
    HostName core
    User ec2-user
    IdentityFile ~/.ssh/management
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host protected
    HostName protected
    User ec2-user
    IdentityFile ~/.ssh/management
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
CONFIG3

chmod 600 ~/.ssh/config

FINAL

INNER

EOF

echo
echo "========================================="
echo "Setup completed successfully."
echo "========================================="
echo
echo "You can now use:"
echo
echo "ssh management"
echo "ssh core"
echo "ssh protected"