#!/bin/bash

# Copyright (c) 2019 P3TERX
# From https://github.com/P3TERX/Actions-OpenWrt

set -vx
set -eo pipefail
export DEBIAN_FRONTEND=noninteractive

echo "Installing building components ..."
sudo -E apt-get -qq update
# shellcheck disable=SC2046
#sudo -E apt-get -qq install $(grep -vE "^\s*#" packages.txt  | tr "\n" " ")
sudo -E apt-get -qq install ccache xxhash zstd xz-utils
sudo -E apt-get -qq autoremove --purge
sudo -E apt-get -qq clean


curl -LORJ https://github.com/ccache/ccache/releases/download/v4.8/ccache-4.8-linux-x86_64.tar.xz
curl -LORJ https://github.com/ccache/ccache/releases/download/v4.8/ccache-4.8-linux-x86_64.tar.xz.asc
curl -LORJ https://db.debian.org/fetchkey.cgi?fingerprint=5A939A71A46792CF57866A51996DDA075594ADB8
### FIXME ###
echo "3b35ec9e8af0f849e66e7b5392e2d436d393adbb0574b7147b203943258c6205 *ccache-4.8-linux-x86_64.tar.xz" | sha256sum -c \
&& sudo tar -xJvf ccache-4.8-linux-x86_64.tar.xz --strip-components=1 -C /usr/bin/

export -p | grep -i XDG_RUNTIME_DIR ||:
export -p | grep -i XDG ||:

##sudo mkdir -p /run/user/$(id -u)/ccache-tmp
# sudo chown --verbose -R $(whoami):$(id -ng) /run/user/$(id -u)/ccache-tmp
## sudo chown --verbose -R "$(id -u):$(id -g)" /run/user/$(id -u)/ccache-tmp
echo 'set -x' | tee -a ~/.bashrc
echo 'sudo mkdir -p /run/user/$(id -u)/ccache-tmp' | tee -a ~/.bashrc
echo 'sudo chown --verbose -R "$(id -u):$(id -g)" /run/user/$(id -u)/ccache-tmp' | tee -a ~/.bashrc
echo 'sudo mkdir -p /dev/shm/$(id -u)/ccache/' | tee -a ~/.bashrc
echo 'sudo chown --verbose -R "$(id -u):$(id -g)" /dev/shm/$(id -u)/ccache/' | tee -a ~/.bashrc
echo 'sudo mkdir -p /dev/shm/ccache/' | tee -a ~/.bashrc
echo 'sudo chown --verbose -R "$(id -u):$(id -g)" /dev/shm/ccache/' | tee -a ~/.bashrc
echo 'df -ha' | tee -a ~/.bashrc
echo "###################"
cat ~/.bashrc
echo "###################"
# Source bashrc to test the new PATH
source ~/.bashrc ||: # FIXME
ls -latrR /dev/shm/ /run/user/ ||: # FIXME
sudo ls -latrR /dev/shm/ /run/user/ ||: # FIXME

### cat <<EOF | sudo tee /etc/ccache.conf.form-docker-build | sudo tee /usr/local/etc/ccache.conf.form-docker-build
cat <<EOF | sudo tee /usr/local/etc/ccache.conf
#cache_dir=/ccache/
###cache_dir=/dev/shm/ccache/
#cache_dir=/tmp/ccache/
temporary_dir=/run/user/$(id -u)/ccache-tmp
### In previous versions of ccache, CCACHE_TEMPDIR had to be on the same filesystem as the CCACHE_DIR path, but this requirement has been relaxed.
# temporary_dir /run/user/$(id -u)/ccache-tmp # $XDG_RUNTIME_DIR The default is $XDG_RUNTIME_DIR/ccache-tmp (typically /run/user/<UID>/ccache-tmp) if XDG_RUNTIME_DIR is set and the directory exists, otherwise <cache_dir>/tmp. 
#compression=false
#compression_level
#file_clone=true
hard_link=false
umask=002
#secondary_storage=http://172.17.0.1:8080|layout=bazel
#secondary_storage=file://home/builder/.ccache
remote_storage=file:/home/builder/.ccache|umask=002
remote_storage=file:/home/builder/openwrt/.ccache|umask=002
remote_storage=file:/home/builder/ccache|umask=002
remote_storage=file:/home/builder/openwrt/ccache|umask=002
max_size=1500M
# reshare (CCACHE_RESHARE or CCACHE_NORESHARE, see Boolean values above)
# If true, ccache will write results to secondary storage even for primary storage cache hits. The default is false.
# reshare=true
EOF

echo "###########################"
cat /usr/local/etc/ccache.conf
echo "###########################"

# Update symlinks
sudo /usr/sbin/update-ccache-symlinks

# Prepend ccache into the PATH
echo 'export PATH="/usr/lib/ccache:$PATH"' | tee -a ~/.bashrc.form-docker-build
echo 'export CONFIG_CCACHE=y' | tee -a ~/.bashrc.form-docker-build
# Source bashrc to test the new PATH
# source ~/.bashrc && echo $PATH


# https://github.com/ccache/ccache/blob/master/test/suites/remote_file.bash
touch test.h
echo '#include "test.h"' >test.c
# backdate test.h ||:
#$CCACHE_COMPILE -c test.c
echo "#################"
ccache -p
echo "#################"
ccache -svv
echo "#################"
PATH="/usr/lib/ccache:$PATH" gcc -c test.c   ||: # FIXME
echo "#################"
ccache -svv
echo "#################"
