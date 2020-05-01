#!/bin/bash

export CEPH_RELEASE="nautilus"

set -e

# add ceph repository
wget -q -O- 'https://download.ceph.com/keys/release.asc' | sudo apt-key add -
echo deb https://download.ceph.com/debian-${CEPH_RELEASE}/ $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph.list

# install self
DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -yq ntp ceph-deploy jq

# Keys
mkdir -p /root/.ssh
cp .ssh/id_rsa .ssh/id_rsa.pub /root/.ssh
cp .ssh/id_rsa.pub /root/.ssh/authorized_keys
ssh-keyscan -H -t rsa ceph-server-1 ceph-server-2 ceph-server-3 ceph-client > /root/.ssh/known_hosts

# setup config
mkdir -p test-cluster
cd test-cluster
ceph-deploy install --release=${CEPH_RELEASE} ceph-admin ceph-server-1 ceph-server-2 ceph-server-3 ceph-client
ceph-deploy new ceph-server-1 ceph-server-2 ceph-server-3
echo "mon_clock_drift_allowed = 1" >> ceph.conf
echo "[mon]" >> ceph.conf
echo "mon_allow_pool_delete = true" >> ceph.conf

# other dependencies
ssh ceph-server-1 DEBIAN_FRONTEND=noninteractive apt install -yq ceph-mgr-dashboard python-routes

# ceph-deploy
ceph-deploy mon create-initial
ceph-deploy admin ceph-admin ceph-server-1 ceph-server-2 ceph-server-3 ceph-client
ceph-deploy mgr create ceph-server-1
ceph-deploy rgw create ceph-server-1
ceph-deploy mds create ceph-server-1

# ceph modules
ceph mgr module enable dashboard
ceph dashboard create-self-signed-cert

# keyrings
chmod +r /etc/ceph/ceph.client.admin.keyring
ssh ceph-server-1 sudo chmod +r /etc/ceph/ceph.client.admin.keyring
ssh ceph-server-2 sudo chmod +r /etc/ceph/ceph.client.admin.keyring
ssh ceph-server-3 sudo chmod +r /etc/ceph/ceph.client.admin.keyring

# setup osd
ceph-deploy osd create --bluestore --data /dev/sdc ceph-server-1
ceph-deploy osd create --bluestore --data /dev/sdc ceph-server-2
ceph-deploy osd create --bluestore --data /dev/sdc ceph-server-3

# rgw binding to dashboard
ADMIN_USER=$(radosgw-admin user create --uid=admin --display-name=admin --system)
ACCESS_KEY=$(echo $ADMIN_USER | jq ".keys[0].access_key")
SECRET_KEY=$(echo $ADMIN_USER | jq ".keys[0].secret_key")
ceph dashboard set-rgw-api-access-key $ACCESS_KEY
ceph dashboard set-rgw-api-secret-key $SECRET_KEY

# ceph fs setup
ceph osd pool create cephfs_data 8
ceph osd pool create cephfs_metadata 8
ceph fs new cephfs cephfs_metadata cephfs_data

# ceph dashboard ac-user-create administrator password administrator
