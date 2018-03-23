;-------------------------------------------------------------
;+
; NAME:
;       REP_MARKED_LINES
; PURPOSE:
;       Edit a text array by replacing lines that have markers.
; CATEGORY:
; CALLING SEQUENCE:
;       rep_marked_lines, txt, s
; INPUTS:
;       s = Structure with replacement strings.  in
; KEYWORD PARAMETERS:
;       Keywords:
;         DELIMITER=del Delimiter string (def='$$').
; OUTPUTS:
;       txt = Text array to edit.                in, out
; COMMON BLOCKS:
; NOTES:
;       Notes: Lines in the text array may contain marker strings
;         to be replaced by specified values found in structure s.
;         The line in txt to be replaced must contain nothing other
;         than the marker string.  For example:
;         $$text$$
;         could be a line in the text array.
;         If the given structure, s, contains the tag TEXT then the
;         value from the structure will replace that line in txt.
;         The tag in the marker string must match a tag in the
;         structure (case is ignored) or it will not be changed.
;         The replacement value from the structure may be an array.
;         See rep_txtmarks to deal with markers in a line.
; MODIFICATION HISTORY:
;       R. Sterner, 2010 Jul 20
;       R. Sterner, 2012 Feb 22 --- Corrected error with case match.
;
; Copyright (C) 2010, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
        pro rep_marked_lines, txt, s, delimiter=del0, help=hlp
 
	if (n_params(0) lt 2) or keyword_set(hlp) then begin
	  print,' Edit a text array by replacing lines that have markers.'
	  print,' rep_marked_lines, txt, s'
	  print,'   txt = Text array to edit.                in, out'
	  print,'   s = Structure with replacement strings.  in'
	  print,' Keywords:'
	  print,"   DELIMITER=del Delimiter string (def='$$')."
	  print,' Notes: Lines in the text array may contain marker strings'
	  print,'   to be replaced by specified values found in structure s.'
          print,'   The line in txt to be replaced must contain nothing other'
          print,'   than the marker string.  For example:'
	  print,'   $$text$$'
	  print,'   could be a line in the text array.'
	  print,'   If the given structure, s, contains the tag TEXT then the'
	  print,'   value from the structure will replace that line in txt.'
	  print,'   The tag in the marker string must match a tag in the'
	  print,'   structure (case is ignored) or it will not be changed.'
          print,'   The replacement value from the structure may be an array.'
          print,'   See rep_txtmarks to deal with markers in a line.'
	  return
	endif
 
	;---------------------------------------------------------
	;  Deal with delimiter
	;
	;  Default delimiter is $$.
	;---------------------------------------------------------
	if n_elements(del0) eq 0 then del0='$$'	  ; Default delimiter string.
        del = del0
 
	;---------------------------------------------------------
	;  Convert tags in structure to possible markers
	;---------------------------------------------------------
        tag = del+strlowcase(tag_names(s))+del    ; Tags with added elimiters.
        n = n_elements(tag)                       ; # tags.
 
	;---------------------------------------------------------
        ;  Loop over tags, doing replacement if found
	;---------------------------------------------------------
        for ins=0,n-1 do begin                    ; Loop over structure tags.
          tg = tag[ins]                           ; i'th tag.
          txtlo = strlowcase(txt)                 ; Lowercase version of txt.
          w = where(txtlo eq tg, cnt)             ; Is this tag a line in txt?
          if cnt gt 0 then begin                  ; Found a match.
            intxt = w[0]                          ; Do first one.
            val = s.(ins)                         ; Structure value.
            txt = list_insert(txt,'R',intxt,val)  ; Replace line with str val.
            ins = ins - 1                         ; Allow multiple times.
          endif ; cnt.
        endfor
 
        end
