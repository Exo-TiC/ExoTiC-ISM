;-------------------------------------------------------------
;+
; NAME:
;       ANG_MID
; PURPOSE:
;       Return the angle midway between two angles.
; CATEGORY:
; CALLING SEQUENCE:
;       am = ang_mid(a1,a2)
; INPUTS:
;       a1, a2 = two angles.    in
; KEYWORD PARAMETERS:
; OUTPUTS:
;       am = Return mid-angle.  out
; COMMON BLOCKS:
; NOTES:
;       Note: all angles are in degrees.
; MODIFICATION HISTORY:
;       R. Sterner, 2008 Feb 08
;
; Copyright (C) 2008, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	function ang_mid, a1, a2, help=hlp
 
	if (n_params(0) lt 2) or keyword_set(hlp) then begin
	  print,' Return the angle midway between two angles.'
	  print,' am = ang_mid(a1,a2)'
	  print,'   a1, a2 = two angles.    in'
	  print,'   am = Return mid-angle.  out'
	  print,' Note: all angles are in degrees.'
	  return,''
	endif
 
	d = abs(a1-a2)
	m=(a1+a2)/2.
	if d gt 180 then m = m - 180
	if m lt 0 then m = m + 360
	return, m
 
	end
