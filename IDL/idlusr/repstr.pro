;-------------------------------------------------------------
;+
; NAME:
;       REPSTR
; PURPOSE:
;       Replace a substring in a text string or array.
; CATEGORY:
; CALLING SEQUENCE:
;       txt2 = repstr(txt1,old,new)
; INPUTS:
;       txt1 = Input text string or array.              in
;       old = String to replace.                        in
;       new = New string.                               in
; KEYWORD PARAMETERS:
;       Keywords:
;         NUMBER=tned Returned total number of strings replaced.
; OUTPUTS:
;       txt2 = Returned modified text string or array.  out
; COMMON BLOCKS:
; NOTES:
;       Notes: All occurances of the old string will be replaced
;         by the new string.
; MODIFICATION HISTORY:
;       R. Sterner, 2008 Mar 20
;
; Copyright (C) 2008, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	function repstr, txt1, old, new, number=tned, help=hlp
 
	if (n_params(0) lt 3) or keyword_set(hlp) then begin
	  print,' Replace a substring in a text string or array.'
	  print,' txt2 = repstr(txt1,old,new)'
	  print,'   txt1 = Input text string or array.              in'
	  print,'   old = String to replace.                        in'
	  print,'   new = New string.                               in'
	  print,'   txt2 = Returned modified text string or array.  out'
	  print,' Keywords:'
	  print,'   NUMBER=tned Returned total number of strings replaced.'
	  print,' Notes: All occurances of the old string will be replaced'
	  print,'   by the new string.'
	  return,''
	endif
 
	tned = 0					; total # replaced.
 
	;---  Find which lines contain the old string  ---
	strfind, txt1, old, /quiet, index=ind, count=cnt
	if cnt eq 0 then return, txt1			; Not there.
 
	;---  Replace string  ---
	txt2 = txt1					; Working copy.
	for i=0,cnt-1 do begin				; Loop over lines.
	  j = ind[i]					; Index of line in txt.
	  txt2[j] = stress(txt2[j],'R',0,old,new,ned)
	  tned = tned + ned				; total # replaced.
	endfor
 
	return, txt2
 
	end
