;-------------------------------------------------------------
;+
; NAME:
;       ELL_CRV_SPLIT
; PURPOSE:
;       Split a curve with an azimuth (geodesic or loxodromic).
; CATEGORY:
; CALLING SEQUENCE:
;       ell_crv_split, lonc,latc, c, az
; INPUTS:
;       lonc, latc = Arrays of lon,lat for a curve.          in
;       c = Refernce point in a structure (lon:lon,lat:lat}. in
;       az = Azimuth from point c.                           in
; KEYWORD PARAMETERS:
;       Keywords:
;         LONL=lonl, LATL=latl Returned points of curve left of azi.
;         LONR=lonr, LATR=latr Returned points of curve right of azi.
;         NL=nl, NR=nr Number of points in left and right secctions.
;         INT=p Intersection point of the curve and azimuth returned
;           in a structure (lon:lon,lat:lat}.
;         /LOX Use loxodromic azimuth (else geodesic azimuth).
;         ERROR=err Error flag: 0=ok.
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
;       Notes: An azimuth from point c is used to split the given
;         curve into two parts, that left of the azimuth line, and
;         that right of the azimuth line as seen from point c.
;         The interpolated point is included in both sections.
;         This routine assumes one intersection only.
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
	pro ell_crv_split, lonc,latc, c, az, lox=lox, help=hlp, $
	  error=err, lonl=lonl, latl=latl, nl=nl, $
	  lonr=lonr, latr=latr, nr=nr, int=p
 
	if keyword_set(hlp) then begin
hlp:	  print,' Split a curve with an azimuth (geodesic or loxodromic).'
	  print,' ell_crv_split, lonc,latc, c, az'
	  print,'   lonc, latc = Arrays of lon,lat for a curve.          in'
	  print,'   c = Refernce point in a structure (lon:lon,lat:lat}. in'
	  print,'   az = Azimuth from point c.                           in'
	  print,' Keywords:'
	  print,'   LONL=lonl, LATL=latl Returned points of curve left of azi.'
	  print,'   LONR=lonr, LATR=latr Returned points of curve right of azi.'
	  print,'   NL=nl, NR=nr Number of points in left and right secctions.'
	  print,'   INT=p Intersection point of the curve and azimuth returned'
	  print,'     in a structure (lon:lon,lat:lat}.'
	  print,'   /LOX Use loxodromic azimuth (else geodesic azimuth).'
	  print,'   ERROR=err Error flag: 0=ok.'
	  print,' Notes: An azimuth from point c is used to split the given'
	  print,'   curve into two parts, that left of the azimuth line, and'
	  print,'   that right of the azimuth line as seen from point c.'
	  print,'   The interpolated point is included in both sections.'
	  print,'   This routine assumes one intersection only.'
	  return
	endif
 
	;---------------------------------------------
	;  Make sure curve and azimuth intersect
	;---------------------------------------------
	rmx = 100000D0			; Find a 2nd pt on azi (100 km).
	if keyword_set(lox) then begin
	  ell_loxodrome,c.lon,c.lat,/p2,dist=rmx,azi=az,lng2=lon_c2,lat2=lat_c2
	endif else begin
	  ell_rb2ll, c.lon, c.lat, rmx, az, lon_c2, lat_c2
	endelse
	c2 = {lon:lon_c2, lat:lat_c2}	; 2nd azi point.
	crv = {lon:lonc, lat:latc}	; Curve.
	if keyword_set(lox) then begin	; Find side of azi line for each crv pt.
	  side = ell_lox_side(c, c2, crv)
	endif else begin
	  side = ell_geo_side(c, c2, crv)
	endelse
	mn = min(side,max=mx)		; Check for crossing.
	if mn eq mx then begin
	  print,' Error in ell_crv_split: curve is all on one side of azimuth.'
	  err = 1
	  return
	endif
 
	;---------------------------------------------
	;  Find intersection point
	;---------------------------------------------
	w = where(side eq 0, cnt)	; Azi goes intersects a curve point.
	if cnt gt 0 then begin		; Is a curve point the intersection?
	  in = w[0]			; Yes.  Index of side eq 0.
	  p = {lon:lonc[in],lat:latc[in]} ; Point P: intersection point.
	endif else begin		; No.  Interpolate.
	  w = where(side[1:*] ne side, cnt) ; Find crossing.
	  in = w[0]			; Index just before crossing.
	  a = {lon:lonc[in],lat:latc[in]}   ; Crosses between these points.
	  b = {lon:lonc[in+1],lat:latc[in+1]}
	  ell_geoazi_int, a, b, c, az, p, lox=lox, error=err
	endelse
 
	;---------------------------------------------
	;  Assemble sections
	;
	;  Intersection point p is included in both.
	;---------------------------------------------
	;---  Left section  ---
	w = where(side eq -1, cnt)	; Left section points.
	if cnt gt 1 then begin
	  x = lonc[w]			; Left points.
	  y = latc[w]
	  x1 = x[0]			; First left pt.
	  y1 = y[0]
	  x2 = x[cnt-1]			; Last left pt.
	  y2 = y[cnt-1]
	  ell_ll2rb, p.lon,p.lat,x1,y1,r1,a1  ; From p
	  ell_ll2rb, p.lon,p.lat,x2,y2,r2,a1
	  if r1 lt r2 then begin	; First pt closest.
	    lonl = [p.lon, x]
	    latl = [p.lat, y]
	  endif else begin		; Last pt closest.
	    lonl = [x, p.lon]
	    latl = [y, p.lat]
	  endelse
	  nl = cnt + 1
	endif else begin
	  lonl = [p.lon]
	  latl = [p.lat]
	  nl = 1
	endelse
	;---  Right section  ---
	w = where(side eq 1, cnt)	; Right section points.
	if cnt gt 1 then begin
	  x = lonc[w]			; Right points.
	  y = latc[w]
	  x1 = x[0]			; First right pt.
	  y1 = y[0]
	  x2 = x[cnt-1]			; Last right pt.
	  y2 = y[cnt-1]
	  ell_ll2rb, p.lon,p.lat,x1,y1,r1,a1  ; From p
	  ell_ll2rb, p.lon,p.lat,x2,y2,r2,a1
	  if r1 lt r2 then begin	; First pt closest.
	    lonr = [p.lon, x]
	    latr = [p.lat, y]
	  endif else begin		; Last pt closest.
	    lonr = [x, p.lon]
	    latr = [y, p.lat]
	  endelse
	  nr = cnt + 1
	endif else begin
	  lonr = [p.lon]
	  latr = [p.lat]
	  nr = 1
	endelse
	
	end
 
