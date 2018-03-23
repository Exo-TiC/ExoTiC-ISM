;-------------------------------------------------------------
;+
; NAME:
;       JS_FROM_MATLAB
; PURPOSE:
;       Convert from Matlab time to Julian Seconds.
; CATEGORY:
; CALLING SEQUENCE:
;       js = js_from_matlab(mtime)
; INPUTS:
;       mtime = Matlab time.     in
;         Scalar or array.
; KEYWORD PARAMETERS:
; OUTPUTS:
;       js = Julian Seconds.     out
; COMMON BLOCKS:
; NOTES:
;       Notes:
;         Julian Seconds are seconds since 2000 Jan 1 0:00:00.
;         Matlab time is days since 0000 Jan 1 00:00:00.
;           Matlab time for 2000 Jan 1 0:00:00 = 730486.
; MODIFICATION HISTORY:
;       R. Sterner, 2008 Oct 30
;
; Copyright (C) 2008, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	function js_from_matlab, tm, help=hlp
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Convert from Matlab time to Julian Seconds.'
	  print,'   js = js_from_matlab(mtime)'
	  print,'   mtime = Matlab time.     in'
	  print,'     Scalar or array.'
	  print,'   js = Julian Seconds.     out'
	  print,' Notes:'
	  print,'   Julian Seconds are seconds since 2000 Jan 1 0:00:00.'
	  print,'   Matlab time is days since 0000 Jan 1 00:00:00.'
	  print,'     Matlab time for 2000 Jan 1 0:00:00 = 730486.'
	  return,''
	endif
 
	js = (tm - 730486D0)*86400D0
 
	return, js
	end
