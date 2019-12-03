#!/bin/bash
#Verification des champs
VerifChamp(){
	exist=$(grep $ChampEnCours $FichierLog)
	if [ -z "$exist" ]
	then
		echo "Erreur : Ligne #Fields semble indiquer format LOG_IIS mais absence du champ "$ChampEnCours
		exit 4
	fi
}
Position(){
	subSection=$(echo $LigneFields | grep -o "$1.*" )
	nbFieldSubSection=$(echo $subSection | grep -o "%" | wc -l)
	returnPosition="$"$(($NbFields-$nbFieldSubSection+1))
}
#%ip %date %instant %url=cs-uri-stem %size=sc-bytes %code=sc-status %referer %browser=cs(User-Agent) %os
#%date %time %c-ip %cs-uri-stem= %sc-bytes %cs %sc-status
ContientFields(){
        echo "Vérification du type de fichier..."
	LigneFields=$(grep '^#Fields' $FichierLog)
	NbFields=$(echo $LigneFields | grep -o "%" | wc -l)
	if [ -z "$LigneFields" ]
	then
		EstIIS="false"
		echo "Fichier de type APP detecte"
	else
		for ChampEnCours in '%date' '%time' '%c-ip' '%sc-bytes' '%cs-uri-stem' '%sc-status' '%cs(User-Agent)'  '%cs(Referer)'
		do 
			VerifChamp $FichierLog
		done
		Position '%date'
		PositionDate=$returnPosition
		Position '%time'
		PositionInstant=$returnPosition
		Position '%c-ip'
		PositionIp=$returnPosition
		Position '%cs(User-Agent)'
		PositionNaviOS=$returnPosition
		Position '%sc-status'
		PositionCodeHTTP=$returnPosition
		Position '%sc-bytes'
		PositionSize=$returnPosition
		Position '%cs(Referer)'
		PositionCsReferer=$returnPosition
        Position '%cs-uri-stem'
        PositionURI=$returnPosition
		
		EstIIS="true"
		echo "Fichier de type IIS detecte"
	fi
}
#OrdonnerColonnes - cree les fichiers temporaires puis ordonne les colonnes d'un fichier IIS de la meme facon que dans un fichier APP dans un fichier temporaire et retire les lignes en double
OrdonnerColonnes(){
	Fichier1Cree="false"
	Fichier2Cree="false"
	FichierTemporaire1="ToBeDeleted1"
	FichierTemporaire2="ToBeDeleted2"
	while [[ $Fichier1Cree = "false" || $Fichier2Cree = "false" ]]
	do
		if [ ! -e "./$FichierTemporaire1" ]
		then
			>$FichierTemporaire1
			Fichier1Cree="true"
		else
	        FichierTemporaire1=$FichierTemporaire1"1"
                        cat $FichierTemporaire1

		fi
        	if [ ! -e "./$FichierTemporaire2" ]
        	then
                >$FichierTemporaire2
        		Fichier2Cree="true"
		else
        		FichierTemporaire2=$FichierTemporaire2"2"
		fi
	done
	sort $FichierLog | tr -d '\r' | uniq >$FichierTemporaire2
  
	awk "{ print $PositionIp,$PositionDate,$PositionInstant,$PositionURI,$PositionSize,$PositionCodeHTTP,$PositionCsReferer,$PositionNaviOS}" $FichierTemporaire2>$FichierTemporaire1
		

}
#CorrectionsIIS - effectue les corrections pour un format IIS
CorrectionsIIS(){
#Suppression mauvaises dates | Suppression mauvais codes retour HTTP | Suppression mauvaises IP

	awk '$2 ~ /[1-2][0-9][0-9][0-9]-[0-9][0-9]?-[0-9][0-9]?/ && $2 !~ /[1-2][0-9][0-9][0-9]-[0-9][0-9]?-[0-9][0-9]./' $FichierTemporaire1 \
	| awk '$6 ~ /[0-9][0-9][0-9]/ && $6 !~ /[0-9][0-9][0-9]./' \
	| awk '$1 ~ /[0-9][0-9]?[0-9]?\.[0-9][0-9]?[0-9]?\.[0-9][0-9]?[0-9]?\.[0-9][0-9]?[0-9]?/ && $1 !~/[0-9][0-9]?[0-9]?\.[0-9][0-9]?[0-9]?\.[0-9][0-9]?[0-9]?\.[0-9][0-9][0-9]./'>$FichierTemporaire2
	  
}

#FormaterIIS - formate a partir d'un format IIS
FormaterIIS(){
  #cat $FichierTemporaire2
	awk '{if ($8 ~ /.*[m,M]ozilla.*/) print $1,$2,$3,$4,$5,$6,$7,$8,"Mozilla" ; else if ($8 ~ /.*[c,C]hrome.*/) print $1,$2,$3,$4,$5,$6,$7,$8,"Chrome" ; else if ($8 ~ /.*[s,S]afari.*/) print $1,$2,$3,$4,$5,$6,$7,$8,"Safari" ; else print $1,$2,$3,$4,$5,$6,$7,$8,"Navigateur_Inconnu"}' $FichierTemporaire2>$FichierTemporaire1
    awk 'BEGIN {print "IP Date Instant URI Size code referer Browser System"} ; {if ($8 ~ /.*[w,W]indows.*/) print $1,$2,$3,$4,$5,$6,$7,$9,"Windows" ; else if ($8 ~ /.*[l,L]inux.*/) print $1,$2,$3,$4,$5,$6,$7,$9,"Linux" ; else if ($8 ~ /.*[m,M]ac.*/) print $1,$2,$3,$4,$5,$6,$7,$9,"Mac"; else print $1,$2,$3,$4,$5,$6,$7,$9,"Systeme_Inconnu",$9}' $FichierTemporaire1>$FichierTemporaire2
	

}

#Formatage du format Apache pour que le fichier de sortie contienne dans cet ordre: IP Date Instant Url Taille Code Chemin Systeme Navigateur
FormaterApache(){
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
		else if(index($13,"Netscape")){
			navigateur="Netscape"
		}
		else{
			navigateur="erreur"
		}

		{print $1, date, $5, $12, $10, $11, $8, $17, navigateur}}' \
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
#CreerFichierFinal - copie-colle le fichier temporaire à sa destination prevue, et supprimer les fichiers temporaires
CreerFichierFinal(){
	
	FichierFinal="FinalISS"
	
	mv $FichierTemporaire2 $FichierFinal
	rm $FichierTemporaire1
	echo "Fichier $FichierFinal cree !"
}
#Fichier accessible - formatage du fichier.

ContientFields

if [ $EstIIS = "true" ]
then
	OrdonnerColonnes
	CorrectionsIIS
	FormaterIIS
else
	
FormaterApache
CorrectionApache
fi

CreerFichierFinal

exit 0