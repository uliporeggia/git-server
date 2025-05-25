#!/bin/bash

home="/home/git"

for file in "$home"/public-keys/*; do
    if [ -f "$file" ]; then
        echo "no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty $(cat $file)" >> tmp.pub
        
        # Verifica se o conteúdo do arquivo já está em authorized_keys
        if ! grep -q -F -x -f tmp.pub "$home"/.ssh/authorized_keys; then
            echo "Adicionado nova chave pública: $file"
            cat tmp.pub >> "$home"/.ssh/authorized_keys
        else
            echo "Nenhuma nova chave precisa ser adicionada."
        fi

        rm tmp.pub
    fi
done