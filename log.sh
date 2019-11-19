#!/bin/bash

#Verification qu'un fichier log est donné en paramètre
if (($# ==  0));then
	echo "Aucun fuchier log trouvé."
	read
	exit 1
else
	FichierLog=$(echo $1) 
fi