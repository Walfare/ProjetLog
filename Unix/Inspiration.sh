
 
#! /bin/bash
######################################
##### Declaration des fonctions ######
######################################
#VerifChamp - verifie la presence des champs necessaires, stoppe le script et renvoie une erreur si absent
VerifChamp(){
	Verif=$(grep $ChampEnCours $FichierLog)
	if [ -z "$Verif" ]
	then
		echo "Erreur : Ligne #Fields semble indiquer format LOG_IIS mais absence du champ "$ChampEnCours
		exit 4
	fi
}

#Position - initialise les variables "PositionChamp"
Position(){
	SousChaine=$(echo $LigneFields | grep -o "$1.*" )
	NbChampsSousChaine=$(echo $SousChaine | grep -o "%" | wc -l)
	RetourPosition="$"$(($NbChamps-$NbChampsSousChaine+1))
}

#ContientFields - verifie si une ligne du fichier commence par #Fields. Cree la variable EstIIS et l'initialise a "true" si oui, "false" sinon.
#Dans le cas "true", verifie la presence des champs requis via VerifChamp et initialise les variables PositionChamp
ContientFields(){
        echo "Vérification du type de fichier..."
	LigneFields=$(grep '^#Fields' $FichierLog)
	NbChamps=$(echo $LigneFields | grep -o "%" | wc -l)
	if [ -z "$LigneFields" ]
	then
		EstIIS="false"
		echo "Fichier de type APP detecte"
	else
		for ChampEnCours in '%c-ip' '%sc-bytes' '%cs(Referer)' '%cs(User-Agent)' '%sc-status' '%date' '%time' '%cs-uri-stem'
		do
			VerifChamp $FichierLog
		done
		Position '%c-ip'
		PositionIP=$RetourPosition
		Position '%sc-bytes'
		PositionTaille=$RetourPosition
		Position '%cs(Referer)'
		PositionSource=$RetourPosition
		Position '%cs(User-Agent)'
		PositionNaviOS=$RetourPosition
		Position '%sc-status'
		PositionCodeHTTP=$RetourPosition
		Position '%date'
		PositionDate=$RetourPosition
		Position '%time'
		PositionInstant=$RetourPosition
                Position '%cs-uri-stem'
                PositionURI=$RetourPosition
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
	awk "{ print $PositionIP,$PositionDate,$PositionInstant,$PositionCodeHTTP,$PositionTaille,$PositionSource,$PositionNaviOS,$PositionURI}" $FichierTemporaire2>$FichierTemporaire1

}

#CorrectionsIIS - effectue les corrections pour un format IIS
CorrectionsIIS(){
#Suppression mauvaises dates | Suppression mauvais codes retour HTTP | Suppression mauvaises IP
				

	awk '$2 ~ /[1-2][0-9][0-9][0-9]-[0-9][0-9]?-[0-9][0-9]?/ && $2 !~ /[1-2][0-9][0-9][0-9]-[0-9][0-9]?-[0-9][0-9]./' $FichierTemporaire1 \
	| awk '$4 ~ /[0-9][0-9][0-9]/ && $4 !~ /[0-9][0-9][0-9]./' \
	| awk '$1 ~ /[0-9][0-9]?[0-9]?\.[0-9][0-9]?[0-9]?\.[0-9][0-9]?[0-9]?\.[0-9][0-9]?[0-9]?/ && $1 !~/[0-9][0-9]?[0-9]?\.[0-9][0-9]?[0-9]?\.[0-9][0-9]?[0-9]?\.[0-9][0-9][0-9]./'>$FichierTemporaire2
cat $FichierTemporaire2
}

#FormaterIIS - formate a partir d'un format IIS
FormaterIIS(){
	awk '{if ($7 ~ /.*[m,M]ozilla.*/) print $1,$2,$3,$4,$5,$6,$7,$8,"Mozilla" ; else if ($7 ~ /.*[c,C]hrome.*/) print $1,$2,$3,$4,$5,$6,$7,$8,"Chrome" ; else if ($7 ~ /.*[s,S]afari.*/) print $1,$2,$3,$4,$5,$6,$7,$8,"Safari" ; else print $1,$2,$3,$4,$5,$6,$7,$8,"Navigateur_Inconnu"}' $FichierTemporaire2>$FichierTemporaire1
	cat $FichierTemporaire1
	awk 'BEGIN {print "IP Date Instant Code Taille Source URI Systeme Navigateur"} ; {if ($7 ~ /.*[w,W]indows.*/) print $1,$2,$3,$4,$5,$6,$8,"Windows",$9 ; else if ($7 ~ /.*[l,L]inux.*/) print $1,$2,$3,$4,$5,$6,$8,"Linux",$9 ; else if ($7 ~ /.*[m,M]ac.*/) print $1,$2,$3,$4,$5,$6,$8,"Mac",$9 ; else print $1,$2,$3,$4,$5,$6,$8,"Systeme_Inconnu",$9}' $FichierTemporaire1>$FichierTemporaire2
}

#SupprimerColonnesInutiles - supprime les colonnes inutiles pour un format APP
SupprimerColonnesInutiles(){
	FichierTemporaire1="ToBeDeleted1"
		FichierTemporaire1="ToBeDeleted1"
		#suppression doublon - suppression [] et séparation time
		sort $FichierLog | uniq | sed -e 's/\[/ /g' | sed -e 's/:/ /1' | \
	    awk '
		function FormatDateAPP(var){
			awk split(var,tabDate, "/" );
			jour=tabDate[1]
			mois=tabDate[2]
			if (mois == "Jan"){mois="01"}
			else if ( mois == "Feb" ){mois="02"}
			else if ( mois == "Mar" ){mois="03"}
			else if ( mois == "Apr" ){mois="04"}
			else if ( mois == "May" ){mois="05"}
			else if ( mois == "Jun" ){mois="06"}
			else if ( mois == "Jul" ){mois="07"}
			else if ( mois == "Aug" ){mois="08"}
			else if ( mois == "Sep" ){mois="09"}
			else if ( mois == "Oct" ){mois="10"}
			else if ( mois == "Nov" ){mois="11"}
			else if ( mois == "Dec" ){mois="12"}
			else {mois="INCONNU"}
			annee=tabDate[3]
			anneeComplete = sprintf("%s%s%s%s%s", annee, "-", mois, "-", jour)
			return anneeComplete
		}
		function DeleteQuote(var){
			if(var== "-"){
				var = "INCONNU"
			}
			else{
				awk gsub(/"/,"",var)
			}
			return var
		}
		function GetBrowser(var){
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
				var="INCONNU"
			}
			return var
		}
		function GetSystem(var){
			if (index(var,"Windows")) {
				var="Windows"
			}
			else if(index(var,"Mac")){
				var="Mac"
			}
			else if(index(var,"Linux")){
				var="Linux"
			}
			else{
				var="INCONNU"
			}
			return var
		}
		BEGIN {print "IP Date Instant Code Taille URL CHEMIN_URL Systeme Navigateur"};
		{print $1, FormatDateAPP($4), $5, $10, $11, DeleteQuote($12), $8, GetBrowser($13), $17 }' \
		>$FichierTemporaire1
}

#CorrectionsAPP - effectue les corrections pour un format APP
CorrectionsAPP(){
	FichierTemporaire2="ToBeDeleted2"
	awk '$2 ~ /[1-2][0-9][0-9][0-9]-[0-9][0-9]?-[0-9][0-9]?/ && $2 !~ /[1-2][0-9][0-9][0-9]-[0-9][0-9]?-[0-9][0-9]./' $FichierTemporaire1 \
	| awk '$4 ~ /[0-9][0-9][0-9]/ && $4 !~ /[0-9][0-9][0-9]./' \
	| awk '$1 ~ /[0-9][0-9]?[0-9]?\.[0-9][0-9]?[0-9]?\.[0-9][0-9]?[0-9]?\.[0-9][0-9]?[0-9]?/ && $1 !~/[0-9][0-9]?[0-9]?\.[0-9][0-9]?[0-9]?\.[0-9][0-9]?[0-9]?\.[0-9][0-9][0-9]./'>$FichierTemporaire2
}

#CreerFichierFinal - copie-colle le fichier temporaire à sa destination prevue, et supprimer les fichiers temporaires
CreerFichierFinal(){
	AnneeEnCours=$(date +%Y)
	MoisEnCours=$(date +%m)
	JourEnCours=$(date +%d)
	FichierFinal=$AnneeEnCours"/"$MoisEnCours"/"$AnneeEnCours$MoisEnCours$JourEnCours
	mkdir -p $AnneeEnCours"/"$MoisEnCours
	mv $FichierTemporaire2 $FichierFinal
	rm $FichierTemporaire1
	echo "Fichier $FichierFinal cree !"
}

#################################
##### Fin des declarations ######
#################################

#Verification qu'un fichier est donne en parametre
if (($# ==  0));then
	echo "Emplacement du fichier log manquant."
	read
	exit 1
else
	FichierLog=$(echo $1 | tr '\r\n' '\n') 		#Transformation au format DOS si necessaire
fi

#Verification que le chemin en parametre est correct
ls $FichierLog > /dev/null 2>&1
if (($? != 0));then
	echo "Fichier introuvable."
	read
	exit 2
fi

#Verification que le fichier est accessible
cat $FichierLog > /dev/null 2>&1
if (($? !=0))
then
	echo "Vous ne disposez pas des droits pour consulter le fichier "$FichierLog
	read
	exit 3
fi

#Fichier accessible - formatage du fichier.

ContientFields

if [ $EstIIS = "true" ]
then
	OrdonnerColonnes
	CorrectionsIIS
	FormaterIIS
else
	SupprimerColonnesInutiles
	CorrectionsAPP
fi

CreerFichierFinal

exit 0
