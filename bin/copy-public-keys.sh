#!/bin/bash

home="/home/git"

for file in "$home"/public-keys/*; do
    if [ -f "$file" ]; then
        # Verifica se o conteúdo do arquivo já está em authorized_keys
        if ! grep -q -F -x -f "$file" "$home"/.ssh/authorized_keys; then
            echo "Adicionado nova chave pública: $file"
            cat "$file" >> "$home"/.ssh/authorized_keys
        fi
    fi
done