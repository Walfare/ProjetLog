#!/bin/bash

#Verification que le champs passé existe
VerifCurrentField(){
	exist=$(grep $currentField $FichierLog)
	if [ -z "$exist" ]
	then
		echo "Erreur champs: "$currentField
		exit 4
	fi
}

#Calcul de la position du champs
Position(){
	subSection=$(echo $mainLine | grep -o "$1.*" )
	nbFieldSubSection=$(echo $subSection | grep -o "%" | wc -l)
	returnPosition="$"$(($NbFields-$nbFieldSubSection+1))
}

#Détermination du type de fichier passé (app/iis) en vérifiant la 1ère ligne du fichier puis si fichier de type IIS, vérification des champs nécessaire et détermination de leur position
VerifTypeLog(){
        echo "Vérification du type de fichier..."
	mainLine=$(grep '^#Fields' $FichierLog)
	NbFields=$(echo $mainLine | grep -o "%" | wc -l)
	if [ -z "$mainLine" ]
	then
		iis="false"
		echo "Fichier Apache"
	else
		for currentField in '%date' '%time' '%c-ip' '%sc-bytes' '%cs-uri-stem' '%sc-status' '%cs(User-Agent)'  '%cs(Referer)'
		do 
			VerifCurrentField $FichierLog
		done
		Position '%date'
		date=$returnPosition
		Position '%time'
		instant=$returnPosition
		Position '%c-ip'
		ip=$returnPosition
		Position '%cs(User-Agent)'
		naviOS=$returnPosition
		Position '%sc-status'
		codeHTTP=$returnPosition
		Position '%sc-bytes'
		size=$returnPosition
		Position '%cs(Referer)'
		csReferer=$returnPosition
        	Position '%cs-uri-stem'
        	URI=$returnPosition
		
		iis="true"
		echo "Fichier IIS"
	fi
}

#Formatage et correction d'un fichier IIS
TraiterIIS(){
	FichierTemp1="tmpIIS1"
	FichierTemp2="tmpIIS2"
	
	#Unicité et retrait des retours à la ligne
	uniq $FichierLog | tr -d '\r' >$FichierTemp1
  
	#Tri des champs selon la norme c
	awk "{ print $ip,$date,$instant,$URI,$size,$codeHTTP,$csReferer,$naviOS}" $FichierTemp1>$FichierTemp2

	#IP au format xxx.xxx.xxx.xxx ou x est un chiffre de 0 à 9
	#Date au format yyyy/MM/dd ou l'année commence par 1 ou 2
	#Code HTTP au format xxx ou x est un chiffre entre 0 et 9
	awk '$1 ~ /[0-9][0-9]?[0-9]?\.[0-9][0-9]?[0-9]?\.[0-9][0-9]?[0-9]?\.[0-9][0-9]?[0-9]?/' $FichierTemp2 \
	| awk '$2 ~ /[1-2][0-9][0-9][0-9]-[0-9][0-9]?-[0-9][0-9]?/' \
	| awk '$6 ~ /[0-9][0-9][0-9]/' >$FichierTemp1

	#Recherche du navigateur dans le champs naviOS
	awk '{
		if ($8 ~ /.*[m,M]ozilla.*/) 
			{print $1,$2,$3,$4,$5,$6,$7,$8,"Mozilla"}
		else if ($8 ~ /.*[c,C]hrome.*/) 
			{print $1,$2,$3,$4,$5,$6,$7,$8,"Chrome" }
		else if ($8 ~ /.*[s,S]afari.*/) 
			{print $1,$2,$3,$4,$5,$6,$7,$8,"Safari" } 
		else 
			{print $1,$2,$3,$4,$5,$6,$7,$8,"erreur"}}' $FichierTemp1>$FichierTemp2

	#Recherche de l'os dans le champs naviOS
   	awk '{
		if ($8 ~ /.*[w,W]indows.*/) 
			{print $1,$2,$3,$4,$5,$6,$7,"Windows", $9 }
		else if ($8 ~ /.*[l,L]inux.*/) 
			{print $1,$2,$3,$4,$5,$6,$7,"Linux", $9 } 
		else if ($8 ~ /.*[m,M]ac.*/) 
			{print $1,$2,$3,$4,$5,$6,$7,"Mac",$9 }
		else 
			{print $1,$2,$3,$4,$5,$6,$7,"erreur",$9}}' $FichierTemp2>$FichierTemp1
		

}


#Formatage du format Apache pour que le fichier de sortie contienne dans cet ordre: IP Date Instant Url Taille Code Chemin Systeme Navigateur, puis correction suppression des lignes ayant une IP, date ou un code erroné
TraiterApache(){
	#Fichier de retour
	FichierTemp="tmp1"
	#Unicité, retrait des crochets, des guillements et des premiers ':' puis formatage
	uniq $FichierLog| sed -e 's/\[/ /g' | sed -e 's/\]/ /g' | sed -e "s/\"//g" | sed -e 's/:/ /1' | \
	awk '{
		split($4,tab, "/" );
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
		date = sprintf("%s%s%s%s%s", annee, "/", mois, "/", jour)
		if (index($13,"Mozilla")) {
			navigateur="Mozilla"
		}
		else if(index($13,"Chrome")){
			navigateur="Chrome"
		}
		else if(index($13,"Safari")){
			navigateur="Safari"
		}
		else{
			navigateur="erreur"
		}
		{print $1, date, $5, $12, $11, $10, $8, $17, navigateur}}' \
		>$FichierTemp	

		#Suppression des lignes ayant une IP, date ou un code erroné

		FinalApache="FinalApache"
		#IP au format xxx.xxx.xxx.xxx ou x est un chiffre de 0 à 9
		#Date au format yyyy/MM/dd ou l'année commence par 1 ou 2
		#Code HTTP au format xxx ou x est un chiffre entre 0 et 9
		awk '$1 ~ /[0-9][0-9]?[0-9]?\.[0-9][0-9]?[0-9]?\.[0-9][0-9]?[0-9]?\.[0-9][0-9]?[0-9]?/' $FichierTemp \
		| awk '$2 ~ /[1-2][0-9][0-9][0-9]\/[0-9][0-9]?\/[0-9][0-9]?/' \
		| awk '$6 ~ /[0-9][0-9][0-9]/'>$FinalApache
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

#Création du répertoire et du fichier final puis appel des fonctions 
Execution(){
	
	Annee=$(date +%Y)
	Mois=$(date +%m)
	Jour=$(date +%d)
	FichierFinal=$Annee"-"$Mois"-"$Jour".txt"
	mkdir -p "FichierLog/"$Annee"/"$Mois

	VerifTypeLog

	if [ $iis = "true" ]
	then
		TraiterIIS
		mv $FichierTemp1 $FichierFinal
		rm $FichierTemp2
	else	
		TraiterApache
		mv $FinalApache $FichierFinal
		rm $FichierTemp
	fi
	mv $FichierFinal "FichierLog/"$Annee"/"$Mois
	echo "Fichier $FichierFinal cree !"
	
}

Execution

exit 0
