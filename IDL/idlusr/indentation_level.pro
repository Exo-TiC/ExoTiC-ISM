;-------------------------------------------------------------
;+
; NAME:
;       INDENTATION_LEVEL
; PURPOSE:
;       Determine indentation levels of input text.
; CATEGORY:
; CALLING SEQUENCE:
;       indentation_level, txt0, txt2, lev
; INPUTS:
;       txt0 = Input text array with indented text.    in
; KEYWORD PARAMETERS:
;       Keywords:
;         TAB=tb  number of spaces per tab (def=8).
; OUTPUTS:
;       txt2 = Output trimmed text.                    out
;       lev = Returned indentation level of each line. out
; COMMON BLOCKS:
; NOTES:
;       Notes: The lines in the input text may have various
;       amounts of indentation (whitespace).  The indentation
;       level array, lev, will give the level for each line,
;       with 0 for the least amount, 1 for the next amount,
;       and so on.  Make sure the indentation is the same
;       for each level.  It may be a mixture of tabs and
;       spaces as long as the tab size is given (if not 8).
;       Here is an example of indented text (txt0):
;              line 1
;              line 2
;                line 2.1
;                line 2.2
;              line 3
;                line 3.1
;                line 3.2
;                  line 3.2.1
;                  line 3.2.2
;              line 4
;              line 5
;       The lev array would be [0, 0, 1, 1, 0, 1, 1, 2, 2, 0, 0].
; MODIFICATION HISTORY:
;       R. Sterner, 2008 Oct 17
;
; Copyright (C) 2008, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro indentation_level, txt0, txt2, lev, tab=nspc, help=hlp
 
	if (n_params(0) lt 3) or keyword_set(hlp) then begin
	  print,' Determine indentation levels of input text.'
	  print,' indentation_level, txt0, txt2, lev'
	  print,'   txt0 = Input text array with indented text.    in'
	  print,'   txt2 = Output trimmed text.                    out'
	  print,'   lev = Returned indentation level of each line. out'
	  print,' Keywords:'
	  print,'   TAB=tb  number of spaces per tab (def=8).'
	  print,' Notes: The lines in the input text may have various'
	  print,' amounts of indentation (whitespace).  The indentation'
	  print,' level array, lev, will give the level for each line,'
	  print,' with 0 for the least amount, 1 for the next amount,'
	  print,' and so on.  Make sure the indentation is the same'
	  print,' for each level.  It may be a mixture of tabs and'
	  print,' spaces as long as the tab size is given (if not 8).'
	  print,' Here is an example of indented text (txt0):'
	  print,'        line 1'
	  print,'        line 2'
	  print,'          line 2.1'
	  print,'          line 2.2'
	  print,'        line 3'
	  print,'          line 3.1'
	  print,'          line 3.2'
	  print,'            line 3.2.1'
	  print,'            line 3.2.2'
	  print,'        line 4'
	  print,'        line 5'
	  print,' The lev array would be [0, 0, 1, 1, 0, 1, 1, 2, 2, 0, 0].'
	  return
	endif
 
	;---  Detab text  ---
	n = n_elements(txt0)
	txt1 = detab(txt0,tab=nspc)
 
	;---  Look at whitespace sizes  ---
	ws = stregex(txt1,'[[:graph:]]')  ; First non-whitespace.
 
	;---  Make a translation table from # spaces to indent level  ---
	h = histogram(ws,min=0)	; Find all indentations.
	mx = max(ws)		; Max number of spaces.
	tb = intarr(mx+1)	; Start translation table.
	w = where(h gt 0, cnt)	; Locate indentations.
	in = indgen(cnt)	; Indentation levels.
	tb[w] = in		; Translate from # spaces to indent level.
 
	;---  Indentation level for each line  ---
	lev = tb[ws]
 
	;---  Trimmed output text  ---
	txt2 = strtrim(txt1,2)
 
	end
