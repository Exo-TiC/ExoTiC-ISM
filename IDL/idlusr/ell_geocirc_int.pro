;-------------------------------------------------------------
;+
; NAME:
;       ELL_GEOCIRC_INT
; PURPOSE:
;       Find intersection point of a geodesic and circle.
; CATEGORY:
; CALLING SEQUENCE:
;       ell_geocirc_int, a, b, c, r, p
; INPUTS:
;       a, b = Points on geodesic.  in
;         Geodesic ab must cross circle (one intersection).
;       c = Circle center.          in
;       r = Circle radius in m.     in
; KEYWORD PARAMETERS:
;       Keywords:
;         ERROR=err Error flag: 0=ok.
; OUTPUTS:
;       p = Intersection point.     out
;         Points are structures: {lon:lon, lat:lat}.
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 2009 Jan 13
;
; Copyright (C) 2009, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro ell_geocirc_int, a0, b0, c, r, p, error=err, help=hlp
 
	if (n_params(0) lt 4) or keyword_set(hlp) then begin
	  print,' Find intersection point of a geodesic and circle.'
	  print,' ell_geocirc_int, a, b, c, r, p'
	  print,'   a, b = Points on geodesic.  in'
	  print,'     Geodesic ab must cross circle (one intersection).'
	  print,'   c = Circle center.          in'
	  print,'   r = Circle radius in m.     in'
	  print,'   p = Intersection point.     out'
	  print,'     Points are structures: {lon:lon, lat:lat}.'
	  print,' Keywords:'
	  print,'   ERROR=err Error flag: 0=ok.'
	  return
	endif
 
	;-------------------------------------------------
	;  Initialize
	;-------------------------------------------------
	tol = 0.001D0		; 1 mm.
 
	a = a0			; Working copies.
	b = b0
 
	;---  Check initial status  ---
	ell_ll2rb, c.lon, c.lat, a.lon, a.lat, ra, a1, a2
	ell_ll2rb, c.lon, c.lat, b.lon, b.lat, rb, a1, a2
	if abs(ra-r) lt tol then begin		; Pt A is result.
	  p = a
	  return
	endif
	if abs(rb-r) lt tol then begin		; Pt B is result.
	  p = b
	  return
	endif
	;---  Make sure A inside, B outside  ---
	if ra lt r then begin			; Pt A inside.
	  if rb lt r then begin			; Pt B is too, error.
	    err = 1
	    print,' Error in ell_geocirc_int: Both points inside circle.'
	    return
	  endif
	endif else begin			; Pt A outside.
	  if rb gt r then begin			; Pt B is too, error.
	    err = 1
	    print,' Error in ell_geocirc_int: Both points outside circle.'
	    return
	  endif
	  swap, a, b				; Switch A and B.
	endelse
 
	;-------------------------------------------------
	;  Binary search
	;
	;  Upgrade ell_geo_mid to give a fraction (def=0.5D0)
	;  and change this search to a 0 crossing search.
	;-------------------------------------------------
	cnt = 0
loop:	m = ell_geo_mid(a,b)			; Midpoint.
	ell_ll2rb, c.lon, c.lat, m.lon, m.lat, rm, a1, a2
	cnt += 1
	diff = abs(rm-r)
	if diff le tol then begin
	  p = m
	  err = 0
	  return
	endif
	if rm lt r then begin
	  a = m
	endif else begin
	  b = m
	endelse
	if cnt gt 80 then stop,' STOP: ell_geocirc_int unconverged in 80 steps.'
	goto, loop
 
	end
 
