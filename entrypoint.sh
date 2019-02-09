#!/bin/bash -eu

set +H -xeuo pipefail

ONEDRIVE_UID=$(stat /onedrive/data -c '%u')
ONEDRIVE_GID=$(stat /onedrive/data -c '%g')

# Create new group using target GID
if ! odgroup="$(getent group $ONEDRIVE_GID)"; then
  odgroup='onedrive'
  groupadd "${odgroup}" -g $ONEDRIVE_GID
fi

# Create new user using target UID
if ! oduser="$(getent passwd $ONEDRIVE_UID)"; then
  oduser='onedrive'
  useradd "${oduser}" -u $ONEDRIVE_UID -g $ONEDRIVE_GID
else
  oduser="${oduser%%:*}"
  odgroup="${odgroup%%:*}"
  usermod -g "${odgroup}" "${oduser}"
  grep -qv root <( groups "${oduser}" ) || { echo 'ROOT level priviledges prohibited!'; exit 1; }
fi

chown "${oduser}:${odgroup}" /onedrive/ /onedrive/conf
exec gosu "${oduser}" /usr/local/bin/onedrive --monitor --verbose --confdir /onedrive/conf --syncdir /onedrive/data