#!/bin/sh

home="/home/git"

# Process all public key files in the public-keys directory
for file in "$home"/public-keys/*; do
    if [ -f "$file" ]; then
        echo "no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty $(cat $file)" >> tmp.pub
        
        # Check if authorized_keys already contains the public key content
        if ! grep -q -F -x -f tmp.pub "$home"/.ssh/authorized_keys; then
            echo "New public key added: $file"
            cat tmp.pub >> "$home"/.ssh/authorized_keys
        else
            echo "$file already authorized."
        fi

        rm tmp.pub
    fi
done