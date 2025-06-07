#!/bin/sh

# Copy public keys to authorized_keys file
/usr/local/bin/copy-public-keys.sh

# Execute the command passed from CMD
exec "$@"
