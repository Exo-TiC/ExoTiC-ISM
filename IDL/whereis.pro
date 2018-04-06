; $Id: whereis.pro,v 2.0 2012/01/26 11:22:01 lmugnier Exp $
; Copyright (c) L. Mugnier, ONERA, 2007-2012.
;
; This software is copyright ONERA.
; The author is Laurent Mugnier.
; E-mail: mugnier at onera.fr
;
; This software is a computer program whose purpose is to find an IDL program.
;
; This software is governed by the CeCILL-C license under French law and
; abiding by the rules of distribution of free software. You can use, modify
; and/ or redistribute the software under the terms of the CeCILL-C license as
; circulated by CEA, CNRS and INRIA at the following URL
; "http://www.cecill.info".
;
; As a counterpart to the access to the source code and  rights to copy,
; modify and redistribute granted by the license, users are provided only
; with a limited warranty  and the software's author,  the holder of the
; economic rights,  and the successive licensors  have only  limited
; liability. 
;
; In this respect, the user's attention is drawn to the risks associated
; with loading,  using,  modifying and/or developing or reproducing the
; software by the user in light of its specific status of free software,
; that may mean  that it is complicated to manipulate,  and  that  also
; therefore means  that it is reserved for developers  and  experienced
; professionals having in-depth computer knowledge. Users are therefore
; encouraged to load and test the software's suitability as regards their
; requirements in conditions enabling the security of their systems and/or 
; data to be ensured and,  more generally, to use and operate it in the 
; same conditions as regards security. 
;
; The fact that you are presently reading this means that you have had
; knowledge of the CeCILL-C license and that you accept its terms.
;

PRO WHEREIS, routine, result, NOSUFFIX = nosuffix, QUIET = quiet, $
             VERSION = version, HELP = help
;+
;NOM :
;   WHEREIS - Trouve l'emplacement d'un programme IDL.
;   
;CATEGORIE :
;   Help Routines
;
;SYNTAXE :
;   WHEREIS, routine [, result] [, /NOSUFFIX] [, /QUIET] [, /VERSION] [, /HELP]
;
;DESCRIPTION :
;   La procédure WHEREIS recherche une routine (procédure ou fonction) dans le
;   chemin courant (!PATH), et affiche son nom complet (répertoire + nom de
;   fichier).
;
;   ARGUMENTS :
;   routine  : (entrée) chaîne de caractères contenant la routine à rechercher
;
;   result   : (sortie) nom de variable optionnel, qui contient en sortie le
;              nom complet de la routine (répertoire + nom de fichier), ou ''
;              si celle-ci est introuvable.
;
;   /NOSUFFIX: (entrée) si ce mot-clé est présent et non nul, on recherche
;              le nom de fichier exact 'routine' sans ajouter le suffixe
;              '.pro' (utile pour trouver par exemple des librairies .so).
;
;   /QUIET   : (entrée) n'affiche pas le nom complet de la routine. Utile
;              uniquement en conjonction avec l'argument result.
;
;   /VERSION : (entrée) affichage de la version avant l'exécution.
;   
;   /HELP    : (entrée) affichage de la syntaxe et sortie du programme.
;
;VOIR AUSSI :
;   FILE_SEARCH (appele' par ce programme).
;
;AUTEUR :
;   $Author: lmugnier $
;
;HISTORIQUE :
;   $Log: whereis.pro,v $
;   Revision 2.0  2012/01/26 11:22:01  lmugnier
;   Routine re-ecrite, marche sur toute plateforme.
;
;   Revision 1.5  2007/01/26 11:24:41  mugnier
;   Ajout copyright et licence CeCILL-C.
;
;   Revision 1.4  2003/04/16 17:31:11  mugnier
;   Mot-clé /QUIET ajouté.
;
;   Revision 1.3  2003/04/15 09:18:02  mugnier
;   Mot-clé /NOSUFFIX pour chercher des fichiers autres que .pro.
;
;   Revision 1.2  2001-05-18 12:25:34+02  mugnier
;   Remplacement de str_sep(), obsolete depuis IDL 5.3, par strsplit.
;
;   Revision 1.1  1999-04-26 10:55:20+02  mugnier
;   Initial revision
;
;-

on_error,2
IF keyword_set(version) THEN $
    message, '$Revision: 2.0 $, $Date: 2012/01/26 11:22:01 $', /INFO 

IF (n_params() LT 1) OR (n_params() GT 2) OR keyword_set(help) THEN $
    message, 'Usage : WHEREIS, routine [, result] [, /NOSUFFIX] [, /QUIET] [, /VERSION] [, /HELP]'


IF keyword_set(nosuffix) THEN suffix = '' ELSE suffix = '.pro'

result = FILE_SEARCH(STRSPLIT(!PATH, PATH_SEP(/SEARCH_PATH), /EXTRACT) + $
                     PATH_SEP() + routine + suffix) ; chemin+nom_fichier

IF NOT keyword_set(quiet) THEN print, result

END
