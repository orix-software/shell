#! /bin/bash

MYPATH=$1

if [ -e "$MYPATH/STARTED" ]; then
    echo "Le fichier $MYPATH/STARTED existe."
else
    echo "Le fichier $MYPATH/STARTED n'existe pas."
    echo "Le script submit n'a pas été lancé ou touch à un pb, vérifier le timeout"
    exit 1
fi

