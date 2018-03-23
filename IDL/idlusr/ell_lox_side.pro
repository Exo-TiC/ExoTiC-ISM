;-------------------------------------------------------------
;+
; NAME:
;       ELL_LOX_SIDE
; PURPOSE:
;       Find which side of a loxodrome a given point located on.
; CATEGORY:
; CALLING SEQUENCE:
;       side = ell_lox_side( p1, p2, pt)
; INPUTS:
;       p1 = Start point of the loxodrome {lon:lon1, lat:lat1}. in
;       p2 = End point of the loxodrome {lon:lon2, lat:lat2}.   in
;       pt = Point to check {lon:lont, lat:latt}.               in
;          If lont and latt are arrays side will be an array also.
;       side = Side code (pt as seen from p1):
;         -1 means pt is left of p2.
;          0 means pt is aligned with p2.
;         +1 means pt is right of p2.
; KEYWORD PARAMETERS:
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 2009 Jan 15
;
; Copyright (C) 2009, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	function ell_lox_side, p1, p2, pt, help=hlp
 
	if (n_params(0) lt 3) or keyword_set(hlp) then begin
	  print,' Find which side of a loxodrome a given point located on.'
	  print,' side = ell_lox_side( p1, p2, pt)'
	  print,'   p1 = Start point of the loxodrome {lon:lon1, lat:lat1}. in'
	  print,'   p2 = End point of the loxodrome {lon:lon2, lat:lat2}.   in'
	  print,'   pt = Point to check {lon:lont, lat:latt}.               in'
	  print,'      If lont and latt are arrays side will be an array also.'
	  print,'   side = Side code (pt as seen from p1):'
	  print,'     -1 means pt is left of p2.'
	  print,'      0 means pt is aligned with p2.'
	  print,'     +1 means pt is right of p2.'
	  return,''
	endif
 
	;------------------------------------------------
	;  Find loxodromic azimuth from p1 to p2
	;------------------------------------------------
	ell_loxodrome, p1.lon, p1.lat, lng2=p2.lon, lat2=p2.lat, /ad, azi=a12
 
	;------------------------------------------------
	;  Find loxodromic azimuth from p1 to pt
	;------------------------------------------------
	ell_loxodrome, p1.lon, p1.lat, lng2=pt.lon, lat2=pt.lat, /ad, azi=a1t
 
	;------------------------------------------------
	;  Correct for 0/360 discontinuety
	;------------------------------------------------
	n = n_elements(a1t)		; Is a1t an array?
	if n gt 1 then begin		; Yes.
	  a12 = dblarr(n) + a12		; Make a12 match.
	endif
	d = a12 - a1t
	w = where(d lt -180, cnt)
	if cnt gt 0 then a1t[w] = a1t[w] - 360
	w = where(d gt 180, cnt)
	if cnt gt 0 then a12[w] = a12[w] - 360
 
	;------------------------------------------------
	;  Now determine the side
	;------------------------------------------------
	d = a1t - a12
	w = where(d eq 180, cnt)
	if cnt gt 0 then d[w]=0.
	return, sign(d)
 
	end
