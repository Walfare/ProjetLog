#!/bin/bash

#Verification qu'un fichier est donné en paramètre
if (($# ==  0));then
	echo "Aucun fichier passé en paramètre."
	read
	exit 1
else
	FichierLog=$(echo $1)
fi

#Verification que le fichier existe et quele chemin est correcte
ls $FichierLog > /dev/null 2>&1
if (($? != 0));then
	echo "Le fichier n'existe pas ou le chemin est incorrecte"
	read
	exit 2
fi

#Verification que le fichier est accessible
cat $FichierLog > /dev/null 2>&1
if (($? != 0));then
	echo "Le fichier n'est pas accessible."
	read
	exit 3
fi


