#!/bin/bash

apt install reprepro lighttpd curl jq

mkdir -p www

# a faire une fois
gpg --list-secret-key
gpg --generate-key
