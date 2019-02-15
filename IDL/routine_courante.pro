; $Id: routine_courante.pro,v 1.2 2004/10/18 12:44:53 cassaing Exp $
FUNCTION routine_courante, help = help, version = version

;+
;NOM :
;   ROUTINE_COURANTE - Retourne le nom de la routine en cours
;   
;CATEGORIE :
;   STRING PROCESSING ROUTINES
;
;SYNTAXE :
;   nom=routine_courante([, /VERSION] [, /HELP])
;
;DESCRIPTION :
;   Retourne le nom de la fonction en cours. Créé pour simplifier la saisie
;   du message d'erreur de syntaxe dans une bibliothèque (appel à doc_library).
;   
;   ARGUMENTS :
;
;   /VERSION : (entrée) affichage de la version avant l'exécution.
;   
;   /HELP    : (entrée) affichage de la syntaxe et sortie du programme.
;
;DIAGNOSTIC D'ERREUR :
;   
;
;VOIR AUSSI :
;   doc_library
;
;AUTEUR :
;   $Author: cassaing $
;
;HISTORIQUE :
;   $Log: routine_courante.pro,v $
;   Revision 1.2  2004/10/18 12:44:53  cassaing
;   Category/comment corrected
;
;   Revision 1.1  2001-01-17 12:27:47+01  cassaing
;   Initial revision
;
;-

on_error,2
IF keyword_set(version) THEN $
    message, '$Revision: 1.2 $, $Date: 2004/10/18 12:44:53 $', /INFO

IF (n_params() NE 0) OR keyword_set(help) THEN BEGIN  
     message, 'Aide demandée ou syntaxe incorrecte. Documentation :', /INFO
     doc_library, routine_courante()
     message, 'Rappeler la routine avec les bons paramètres.'
ENDIF

help,calls=noms                ; récupère la pile des appels
fin = strpos(noms[1], ' ')
nom = strmid(noms[1], 0, fin) ; nom fonction appelante
return, strupcase(nom)
END

print, routine_courante(/help)
END
          
