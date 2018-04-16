; $Id: read_params_vm.pro,v 1.2 2008/01/08 09:34:15 mugnier Exp $
; Copyright (c) L. Mugnier, ONERA, 2007.
;
; This software is copyright ONERA.
; The author is Laurent Mugnier.
; E-mail: mugnier at onera.fr
;
; This software is a computer program whose purpose is to read a parameter
; file to pass parameters to IDL when using a Virtual Machine.
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

 ;+
; NAME:
;   READ_PARAMS_VM - Read a parameter file to pass parameters to IDL when
;                    using a Virtual Machine
;   
; CATEGORY:
;   Input/Output Routines 
;
; CALLING SEQUENCE:
;   structure = READ_PARAMS_VM(filename [, COMMENTS = comments]
;                              [, /VERSION] [, /HELP])
;
; PURPOSE:
;   lit un fichier de paramètres pour lancer un batch en IDL Virtual Machine.
;   On indique sur chaque ligne du fichier le nom du paramètre (i.e. de la
;   variable), son type (Byte, Int, Long, Float, Double, String) et sa valeur.
;   la structure du fichier est la suivante : 
;   NOM_VARIABLE TYPE_VARIABLE VALEUR_VARIABLE
;   ou :
;   NOM_VARIABLE TYPE_VARIABLE VALEUR_VARIABLE ; commentaire

;   la fin du fichier est donnée par 'EOF' sur la dernière ligne, ou par la
;   fin du fichier (éviter une ligne vide, ou débugger ce cas (merci))
;                                
;   La STRUCTURE retournée en sortie contient les variables lues.
;
;   
; POSITIONAL PARAMETERS:
;   FILENAME : [entrée] chaine de caracteres, nom du fichier contenant les
;              paramètres à lire.
;   
; KEYWORD PARAMETERS:
;
;   COMMENTS : [sortie] chaîne de caracteres, commentaires lus dans FILENAME
;
;   /VERSION : [entrée] affichage de la version avant l'exécution.
;   
;   /HELP    : [entrée] affichage de la syntaxe et sortie du programme.
;
; 
; AUTHORS:
;   J.-F. Sauvage and L. Mugnier.
;
; RESTRICTIONS:
;   This code is copyright (c) J.-F. Sauvage and L. Mugnier, ONERA, 2007-2008. 
;   
;   WISARD is governed by the CeCILL-C license under French law and abiding by
;   the rules of distribution of free software. You can use, modify and/ or
;   redistribute the software under the terms of the CeCILL-C license as
;   circulated by CEA, CNRS and INRIA at the following URL:
;   "http://www.cecill.info".
;   See source code for the full notice.
;
; EXAMPLE:
; Say parameter file "params.txt" contains the following: 
; ; 1ere var = hyperparamètre :
; hyperparam    float  1.5        ; variable 1
; ; 2eme var = fichier image :
; filename      string image.fits ; variable 2. Note: No <<">> or <<'>> used!
; EOF
;
; Then the execution of the following line will create a structure with
; "hyperparam" and "filename" as its 2 fields:
; IDL> params = read_params_vm("params.txt")
; IDL> help, /struct, params
; ** Structure <23dbc8>, 2 tags, length=24, data length=20, refs=1:
;   HYPERPARAM      FLOAT           1.50000
;   FILENAME        STRING    'image.fits'
;
; TODO:
; Translate this doc fully into English...
; 
; SEE ALSO:
;
; ACKNOWLEDGMENTS:
;
; HISTORY:
;   $Log: read_params_vm.pro,v $
;   Revision 1.2  2008/01/08 09:34:15  mugnier
;   Added copyright, license, English doc template. Completed example.
;
;   Revision 1.1  2007/05/22 08:43:05  sauvage
;   Initial revision
;
;-


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION READ_PARAMS_VM, filename, VERSION = version, HELP = help, COMMENTS = comments

on_error,2
IF keyword_set(version) THEN $
    printf, -2, '% '+routine_courante()+': $Revision: 1.2 $, $Date: 2008/01/08 09:34:15 $'
IF (n_params() NE 1) OR keyword_set(help) THEN BEGIN ;(remplir d'apres syntaxe)
    message, 'Aide demandée ou syntaxe incorrecte. Documentation :', /INFO
    doc_library, routine_courante()
    retall
ENDIF


s = ''
comments = ''

; Ouverture fichier : 
openr, unit, filename, /get_lun
init = 0B

WHILE ((NOT EOF(unit))) DO BEGIN 
; 'EOF' en debut de ligne = fin de fichier
   readf, unit, s, format='(A)' ; chaine
   s = strcompress(strtrim(s,2)) ; enlever les blancs en trop
   
   IF (strpos(s,';') EQ 0) THEN  BEGIN   
      comments = comments + strmid(s,1,strlen(s)-1) + string(10B) + string(13B) 
      ;; eventuellement afficher les commentaires à la fin.
   ENDIF ELSE BEGIN
      chopped_s = str_sep(s, ' ') ; couper s en morceaux separes par esp.
      
      IF (strpos(s,'EOF') EQ 0) THEN return, structure ELSE BEGIN
         
         name = chopped_s[0]  ; 1er  champ = nom  variable
         type = chopped_s[1]  ; 2eme champ = type variable
         
         CASE type OF
            'byte':   currentvar = 0B
            'int':    currentvar = 0
            'long':   currentvar = 0L
            'float':  currentvar = 0.
            'double': currentvar = 0D
            'string': currentvar = ''
            ELSE: message, 'Erreur sur le type de paramètre'
         ENDCASE
         reads, chopped_s[2], currentvar
         
         IF NOT(init) THEN structure = create_struct(name, currentvar) $
         ELSE structure = create_struct(structure, name, currentvar)
         
         init = 1B
      ENDELSE
   ENDELSE
   
ENDWHILE

free_lun, unit
return, structure

END

