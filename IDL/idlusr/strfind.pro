;-------------------------------------------------------------
;+
; NAME:
;       STRFIND
; PURPOSE:
;       Find and list substrings in a string array.
; CATEGORY:
; CALLING SEQUENCE:
;       strfind, txt, str
; INPUTS:
;       txt = Text array to search.   in
;       str = string to find.         in
; KEYWORD PARAMETERS:
;       Keywords:
;         OUT=txt2 Returned matched text.
;         /INVERSE means find elements without str.
;         COUNT=cnt Number of matches found.
;         /QUIET do not list lines.
;         INDEX=ind  Returned array of indices (-1=not found).
;         ICOUNT=icnt Number of non-matches found.
;         IINDEX=iind Array of indices of non-matches.
;           The last two keywords apply if /INVERSE is not given.
;           If /INVERSE is given then COUNT and INDEX return the
;           inverse values.  This is for backward compatibility.
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
;       Notes: Ignores case.  Lists lines that contain the
;         text to find, also the index into the text array.
;         Uses stregex so allows regular expressions.
;           See help for IDL stregex for more details.
; MODIFICATION HISTORY:
;       R. Sterner, 2002 Apr 22
;       R. Sterner, 2002 Apr 24 --- Added INDEX=in and /QUIET.
;       R. Sterner, 2002 Dec 23 --- Added /INVERSE.
;       R. Sterner, 2006 Oct 18 --- Added IINDEX=iind, ICOUNT=icnt.
;       R. Sterner, 2008 Jan 30 --- Added OUT=txt2.
;       R. Sterner, 2010 Apr 29 --- Converted arrays from () to [].
;       R. Sterner, 2014 Sep 03 --- Returned scalars if only 1 element.
;
; Copyright (C) 2002, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro strfind, txt, sub, index=w, quiet=quiet, $
	  inverse=inverse, count=c, iindex=iw, icount=ic, $
	  out=txt2, help=hlp
 
	if (n_params(0) lt 2) or keyword_set(hlp) then begin
	  print,' Find and list substrings in a string array.'
	  print,' strfind, txt, str'
	  print,'   txt = Text array to search.   in'
	  print,'   str = string to find.         in'
	  print,' Keywords:'
	  print,'   OUT=txt2 Returned matched text.'
	  print,'   /INVERSE means find elements without str.'
	  print,'   COUNT=cnt Number of matches found.'
	  print,'   /QUIET do not list lines.'
	  print,'   INDEX=ind  Returned array of indices (-1=not found).'
	  print,'   ICOUNT=icnt Number of non-matches found.'
	  print,'   IINDEX=iind Array of indices of non-matches.'
	  print,'     The last two keywords apply if /INVERSE is not given.'
	  print,'     If /INVERSE is given then COUNT and INDEX return the'
	  print,'     inverse values.  This is for backward compatibility.'
	  print,' Notes: Ignores case.  Lists lines that contain the'
	  print,'   text to find, also the index into the text array.'
	  print,'   Uses stregex so allows regular expressions.'
	  print,'     See help for IDL stregex for more details.'
	  return
	endif
 
	r = stregex(txt,sub,/fold)
	if keyword_set(inverse) then begin	; Inverse match.
	  w = where(r lt 0, c)
	endif else begin			        ; Normal match.
	  w = where(r ge 0, c, comp=iw, ncomp=ic)
	endelse
	if c eq 0 then begin
	  if not keyword_set(quiet) then print,' No matches found.'
	  return
	endif
	if not keyword_set(quiet) then begin
	  for i=0,c-1 do begin
	    print,' '+strtrim(w[i],2)+': '+txt[w[i]]
	  endfor
	endif
	if arg_present(txt2) then txt2=txt[w]	; Returned matches.

    ;---  Return scalars if single elements  ---
    if n_elements(txt2) eq 1 then txt2=txt2[0]
    if n_elements(w)    eq 1 then w=w[0]
    if n_elements(iw)   eq 1 then iw=iw[0]
 
	end
