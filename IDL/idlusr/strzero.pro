;-------------------------------------------------------------
;+
; NAME:
;       STRZERO
; PURPOSE:
;       Convert a string to a zero terminated byte array.
; CATEGORY:
; CALLING SEQUENCE:
;       b = strzero(txt)
; INPUTS:
;       txt = Scalar text string to convert.   in
; KEYWORD PARAMETERS:
;       Keywords:
;         LENGTH=n Length of returned byte array, including the
;           terminating 0.  If txt is too long it will be
;           truncated to n-1 characters, if too short the output
;           byte array will be 0 padded.
; OUTPUTS:
;       b = returned 0 terminated byte array.  out
;         By default the number of elements of b will
;         be 1 + strlen(b).
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 2007 Dec 14
;
; Copyright (C) 2007, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	function strzero, txt, length=len, help=hlp
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Convert a string to a zero terminated byte array.'
	  print,' b = strzero(txt)'
	  print,'   txt = Scalar text string to convert.   in'
	  print,'   b = returned 0 terminated byte array.  out'
	  print,'     By default the number of elements of b will'
	  print,'     be 1 + strlen(b).'
	  print,' Keywords:'
	  print,'   LENGTH=n Length of returned byte array, including the'
	  print,'     terminating 0.  If txt is too long it will be'
	  print,'     truncated to n-1 characters, if too short the output'
	  print,'     byte array will be 0 padded.'
	  return,''
	endif
 
	n = strlen(txt)				; Length of input string.
	if n_elements(len) eq 0 then len=n+1	; Length of output array.
 
	b = byte(txt)				; String as a byte array.
	hi = (n-1) < (len-2)			; Last char in string to use.
	z = bytarr(len)				; Byte array of 0s.
	z[0] = b[0:hi]				; Embed string.
 
	return, z
 
	end
