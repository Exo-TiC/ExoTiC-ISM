;-------------------------------------------------------------
;+
; NAME:
;       ELL_GEOAZI_INT
; PURPOSE:
;       Find intersection point of a geodesic and an azimuth line.
; CATEGORY:
; CALLING SEQUENCE:
;       ell_geoazi_int, a, b, c, az, p
; INPUTS:
;       a, b = Points on geodesic.     in
;         Geodesic ab must cross circle (one intersection).
;       c = Circle center.             in
;       az = Azimuth of circle radius. in
; KEYWORD PARAMETERS:
;       Keywords:
;         /LOX Use loxodromic azimuth, else geodesic azimuth.
;         ERROR=err Error flag: 0=ok.
;         COUNT=cnt Binary search iteration count.
; OUTPUTS:
;       p = Intersection point.        out
;         Points are structures: {lon:lon, lat:lat}.
; COMMON BLOCKS:
; NOTES:
;       Notes: Points A and B are connected by a geodesic.
;         Point is the intersection of this geodesic with an
;         azimuth line from point C.  The azimuth is assumed to
;         be a geodesic azimuth unless the keyword /LOX is set,
;         in which case it is a loxodromic azimuth.
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
	pro ell_geoazi_int, a0, b0, c, az, p, lox=lox, error=err, $
	  count=cnt, help=hlp
 
	if (n_params(0) lt 4) or keyword_set(hlp) then begin
	  print,' Find intersection point of a geodesic and an azimuth line.'
	  print,' ell_geoazi_int, a, b, c, az, p'
	  print,'   a, b = Points on geodesic.     in'
	  print,'     Geodesic ab must cross circle (one intersection).'
	  print,'   c = Circle center.             in'
	  print,'   az = Azimuth of circle radius. in'
	  print,'   p = Intersection point.        out'
	  print,'     Points are structures: {lon:lon, lat:lat}.'
	  print,' Keywords:'
	  print,'   /LOX Use loxodromic azimuth, else geodesic azimuth.'
	  print,'   ERROR=err Error flag: 0=ok.'
	  print,'   COUNT=cnt Binary search iteration count.'
	  print,' Notes: Points A and B are connected by a geodesic.'
	  print,'   Point is the intersection of this geodesic with an'
	  print,'   azimuth line from point C.  The azimuth is assumed to'
	  print,'   be a geodesic azimuth unless the keyword /LOX is set,'
	  print,'   in which case it is a loxodromic azimuth.'
	  return
	endif
 
	;-------------------------------------------------
	;  Initialize
	;-------------------------------------------------
	tol = 0.001D0		; 1 mm.
	a = a0			; Working copies.
	b = b0
 
	;-------------------------------------------------
	;  Check initial status
	;-------------------------------------------------
	ell_ll2rb, c.lon, c.lat, a.lon, a.lat, ra, aza, a2
	ell_ll2rb, c.lon, c.lat, b.lon, b.lat, rb, azb, a2
	rmx = ra > rb				; Max dist.
	if keyword_set(lox) then begin
	  ell_loxodrome,c.lon,c.lat,/p2,dist=rmx,azi=az,lng2=lon_c2,lat2=lat_c2
	endif else begin
	  ell_rb2ll, c.lon, c.lat, rmx, az, lon_c2, lat_c2
	endelse
	c2 = {lon:lon_c2, lat:lat_c2}
	if keyword_set(lox) then begin
	  side_a = ell_lox_side(c, c2, a)
	  side_b = ell_lox_side(c, c2, b)
	endif else begin
	  side_a = ell_geo_side(c, c2, a)
	  side_b = ell_geo_side(c, c2, b)
	endelse
 
	if side_a eq 0 then begin
	  p = a
	  return
	endif
	if side_b eq 0 then begin
	  p = b
	  return
	endif
 
	;-------------------------------------------------
	;  Make sure A on one side, B on the other
	;-------------------------------------------------
	if (side_a*side_b) eq 1 then begin
	  err = 1
	  print,' Error in ell_geoazi_int: Both points on same side of azimuth.'
	  return
	endif
	if side_a eq 1 then swap, a, b		; Want A on - side.
 
	;-------------------------------------------------
	;  Binary search
	;-------------------------------------------------
	cnt = 0
	m = a					; Initialize m.
loop:	m_last = m
	m = ell_geo_mid(a,b)			; Midpoint.
	if keyword_set(lox) then begin
	  side_m = ell_lox_side(c, c2, m)
	endif else begin
	  side_m = ell_geo_side(c, c2, m)
	endelse
	cnt += 1
	diff = ell_point_sep(m_last,m,/check)	; Check shift dist.
	if diff le tol then begin
	  p = m
	  err = 0
	  return
	endif
	if side_m lt 0 then begin
	  a = m
	endif else begin
	  b = m
	endelse
	if cnt gt 80 then stop,' STOP: ell_geoazi_int unconverged in 80 steps.'
	goto, loop
 
	end
 
