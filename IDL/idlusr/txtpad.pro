;-------------------------------------------------------------
;+
; NAME:
;       TXTPAD
; PURPOSE:
;       Pad a text array with spaces so all elements are same length.
; CATEGORY:
; CALLING SEQUENCE:
;       txt2 = txtpad(txt)
; INPUTS:
;       txt = Input text array.             in
; KEYWORD PARAMETERS:
; OUTPUTS:
;       txt2 = Returned padded text array.  out
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 2008 Nov 20
;
; Copyright (C) 2008, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	function txtpad, txt, help=hlp
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Pad a text array with spaces so all elements are same length.'
	  print,' txt2 = txtpad(txt)'
	  print,'   txt = Input text array.             in'
	  print,'   txt2 = Returned padded text array.  out'
	  return,''
	endif
 
	b = byte(txt)			; Convert to bytes.
	w = where(b eq 0,cnt)		; Find 0s.
	if cnt gt 0 then b[w]=32B	; Replace with ascii 32 = space.
	return, string(b)		; Convert back to string.
 
	end
