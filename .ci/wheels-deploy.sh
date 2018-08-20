#!/bin/bash
set -e
#set -xv

if [ "$(echo *.whl)" == '*.whl' ]; then
    echo "deploy: no wheels built"
    exit 0
fi

openssl aes-256-cbc -K $encrypted_632cb16dd578_key -iv $encrypted_632cb16dd578_iv -in .ci/starforge-depot.key.enc -out .ci/starforge-depot.key -d
echo 'wheels.galaxyproject.org ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCXELLgds0rObMT25AWrUFBCx6W6Z5j/wTlT54ke/grCo6RaQ9gLc5GHrJnApKpqVzyNbCIdhz/50QpzVr6EsKSITfadkoDfmmgISq6i2R+OpVgjrBvNWrUtNy6qcZqvgReOyc7yZGlhhZFU8KMTGb2Qajo3TNYiSo9Sbt96HHQIAni1xcocI1Wqw6v/wKlg+2qQgO5g56XzVeZ4yS7zTlKgLexm1GIG3CNI42lndQJJ2pVD/TJ4CDC3CV2HRv5wpJ8Y/T5/7iZr0H/5lvVd5S8wxAx5xrJr1UOIQ/76fjymq5L0kK9FpsX3vjHAOvVkwykGm2I/P4YXB6I+nuJCYtP' >> $HOME/.ssh/known_hosts
echo 'wheels.galaxyproject.org ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBPTnO0DR+VKfErJfN20IY6rjHbbismna9z6SQLEYzbQwpc20fQ06qmMsGJpLD4stBB2zQibTmKRd00QNWAfdILY=' >> $HOME/.ssh/known_hosts
echo 'wheels.galaxyproject.org ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAxM4arE1L41qQ88XDNIxiAVnHeF3S2qloeTUe3AmI85' >> $HOME/.ssh/known_hosts
eval "$(ssh-agent -s)"
chmod 600 .ci/starforge-depot.key
ssh-add .ci/starforge-depot.key
scp -p *.whl wheels@wheels.galaxyproject.org:/srv/nginx/wheels.galaxyproject.org/packages
