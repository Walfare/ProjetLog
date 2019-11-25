#!/bin/bash

#Formatage du format Apache pour que le fichier de sortie contienne dans cet ordre: IP Date Instant Url Taille Code Chemin Systeme Navigateur
FormaterApache(){
	#Fichier de retour
	FichierTemp="tmp1"
	#Unicité, retrait des crochets, des guillements et des premiers ':' puis formatage
	uniq $FichierLog| sed -e 's/\[/ /g' | sed -e 's/\]/ /g' | sed -e "s/\"//g" | sed -e 's/:/ /1' | \
	awk '
		function FormaterDate(var){
			split(var,tab, "/" );
			jour=tab[1]
			mois=tab[2]
			annee=tab[3]
			if (mois == "Jan")
				{mois="01"}
			else if ( mois == "Feb" )
				{mois="02"}
			else if ( mois == "Mar" )
				{mois="03"}
			else if ( mois == "Apr" )
				{mois="04"}
			else if ( mois == "May" )
				{mois="05"}
			else if ( mois == "Jun" )
				{mois="06"}
			else if ( mois == "Jul" )
				{mois="07"}
			else if ( mois == "Aug" )
				{mois="08"}
			else if ( mois == "Sep" )
				{mois="09"}
			else if ( mois == "Oct" )	
				{mois="10"}
			else if ( mois == "Nov" )
				{mois="11"}
			else if ( mois == "Dec" )
				{mois="12"}
			else 
				{mois="erreur"}
			result = sprintf("%s%s%s%s%s", annee, "/", mois, "/", jour)

			return result
		}
		function Navigateur(var){
			if (index(var,"Mozilla")) {
				var="Mozilla"
			}
			else if(index(var,"Chrome")){
				var="Chrome"
			}
			else if(index(var,"Netscape")){
				var="Netscape"
			}
			else{
				var="erreur"
			}

			return var
		}
		{print $1, FormaterDate($4), $5, $12, $10, $11, $8, $17, Navigateur($13)}' \
		>$FichierTemp	
}

#Suppression des lignes ayant une IP, date ou un code erroné
CorrectionApache(){
	FichierFinal="FinalApache"
	#IP au format xxx.xxx.xxx.xxx ou x est un chiffre de 0 à 9
	#Date au format yyyy/MM/dd ou l'année commence par 1 ou 2
	#Code HTTP au format xxx ou x est un chiffre entre 0 et 9
	awk '$1 ~ /[0-9][0-9]?[0-9]?\.[0-9][0-9]?[0-9]?\.[0-9][0-9]?[0-9]?\.[0-9][0-9]?[0-9]?/' $FichierTemp \
	| awk '$2 ~ /[1-2][0-9][0-9][0-9]\/[0-9][0-9]?\/[0-9][0-9]?/' \
	| awk '$6 ~ /[0-9][0-9][0-9]/'>$FichierFinal
}

#Verification qu'un fichier est donné en paramètre
if (($# ==  0));then
	echo "Aucun fichier passé en paramètre."
	read
	exit 1
else
	FichierLog=$(echo $1)
fi

#Verification que le fichier existe et que le chemin est correcte
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

FormaterApache
CorrectionApache
