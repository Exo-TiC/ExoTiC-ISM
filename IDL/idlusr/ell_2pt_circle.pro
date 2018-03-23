;-------------------------------------------------------------
;+
; NAME:
;       ELL_2PT_CIRCLE
; PURPOSE:
;       Find a circle of specified radius through 2 points on an ellipsoid.
; CATEGORY:
; CALLING SEQUENCE:
;       ell_2pt_circle, p1, p2, ref, rd
; INPUTS:
;       p1, p2 = 2 given points.                      in
;       ref = Reference point on circle center side.  in
;         Points are structures: {lon:lon, lat:lat}.
;       rd = Radius of circle to fit (m).             in
; KEYWORD PARAMETERS:
;       Keywords:
;         CENTER=pc Returned circle center (point structure).
;         /OPPOSITE means find circle with center on opposite side
;           of geodesic p1 to p2 than ref point.
;         /DEBUG  Debug.
;         NUM_ITERATIONS=cnt  Returned # iterations.
;         RAD2DIFF=r2d Difference of radius from p2 from rd (m).
;         /BINARY use binary search method, else linear search.
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 2008 Feb 08
;       R. Sterner, 2008 Feb 11 --- Added linear search.
;       R. Sterner, 2009 Dec 29 --- Now tries binary if linear fails.
;
; Copyright (C) 2008, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro ell_2pt_circle, p1, p2, ref, rd, center=pc, opposite=opp, err=err, $
	  help=hlp, num_iterations=cnt, rad2diff=r2diff, debug=debug, binary=binary
 
	if (n_params(0) lt 4) or keyword_set(hlp) then begin
	  print,' Find a circle of specified radius through 2 points on an ellipsoid.'
	  print,' ell_2pt_circle, p1, p2, ref, rd'
	  print,'   p1, p2 = 2 given points.                      in'
	  print,'   ref = Reference point on circle center side.  in'
	  print,'     Points are structures: {lon:lon, lat:lat}.'
	  print,'   rd = Radius of circle to fit (m).             in'
	  print,' Keywords:'
	  print,'   CENTER=pc Returned circle center (point structure).'
	  print,'   /OPPOSITE means find circle with center on opposite side'
	  print,'     of geodesic p1 to p2 than ref point.'
	  print,'   /DEBUG  Debug.'
	  print,'   NUM_ITERATIONS=cnt  Returned # iterations.'
	  print,'   RAD2DIFF=r2d Difference of radius from p2 from rd (m).'
	  print,'   /BINARY use binary search method, else linear search.'
	  return
	endif
 
	err = 0
	tol = 0.001					; Tolerance (m).
	cnt = 0						; Iteration count.
 
	;---------------------------------------------------------------
	;  Check if there is such a circle
	;---------------------------------------------------------------
	ell_ll2rb,p1.lon,p1.lat,p2.lon,p2.lat,r,azi1,a2
	if r/2. gt rd then begin
	  print,' Error in ell_2pt_circle: given radius is LT 1/2 dist between points.'
	  err = 1
	  return
	endif
 
	;---------------------------------------------------------------
	;  Find which side to use
	;---------------------------------------------------------------
	side = ell_geo_side( p1, p2, ref)
	if keyword_set(opp) then side = -side
 
	;---------------------------------------------------------------
	;  Find two initial azimuths
	;  azi1 is from p1 to p2 and was found above.
	;  After this section it is known that
	;  azi1 dist is too small, azi2 dist is too big.
	;  Binary search to tolerence.
	;---------------------------------------------------------------
	ell_rb2ll, p1.lon, p1.lat, rd, azi1, tlon, tlat	; Find test point.
	ell_ll2rb,p2.lon,p2.lat,tlon,tlat,r2,a1,a2	; Check test pt for p2.
	diff1 = r2-rd					; Azi1 diff.
	if (abs(diff1) lt 0.001) then begin		; Check if azi1 works.
	  pc = {lon:tlon,lat:tlat}			; Yes, return circle center.
	  return
	endif
	azi2 = azi1 + side*90				; azi1 and azi2 bracket answer.
	ell_rb2ll, p1.lon, p1.lat, rd, azi2, tlon, tlat	; Find test point.
	ell_ll2rb,p2.lon,p2.lat,tlon,tlat,r2,a1,a2	; Check test pt for p2.
	diff2 = r2-rd					; Azi2 diff.
	if keyword_set(binary) then goto, binary
 
	;---------------------------------------------------------------
	;  Do linear search method on azimuth from p1
	;---------------------------------------------------------------
	if keyword_set(debug) then begin
	  print,' Starting linear search for circle center.'
	  print,' azi1 = ',azi1
	  print,' azi2 = ',azi2
	endif
loop2:
	cnt += 1					; Count iteration.
	aziz = azi2 + diff2*(azi1-azi2)/(diff2-diff1)	; Estimated azimuth.
	ell_rb2ll, p1.lon, p1.lat, rd, aziz, tlon, tlat	; Find test point.
	ell_ll2rb,p2.lon,p2.lat,tlon,tlat,r2,a1,a2	; Check test pt for p2.
	diff = r2-rd					; Radius difference.
	if (abs(diff) lt 0.001) then begin		; Check if azi1 works.
	  if keyword_set(debug) then print,' Center found to ',diff,' meters.'
	  pc = {lon:tlon,lat:tlat}			; Yes, return circle center.
	  r2diff = diff
	  return
	endif
	if diff lt 0 then begin				; Update search limits.
	  azi1 = aziz
	  diff1 = diff
	endif else begin
	  azi2 = aziz
	  diff2 = diff
	endelse
	if keyword_set(debug) then begin
	  print,' Iteration ',cnt,'  --------------'
	  print,' Diff was ',diff
	  print,' azi1 = ',azi1
	  print,' azi2 = ',azi2
	endif
	if cnt ge 100 then begin
	  print,' Warning in ell_2pt_circle: Iteration count too high for linear.'
	  print,'   Trying binary search.'
	  ell_2pt_circle, p1, p2, ref, rd, center=pc, opposite=opp, err=err, $
	    num_iterations=cnt, rad2diff=r2diff, debug=debug, /binary
    	  return  ; If binary works, good, else stops there.
	endif
	goto, loop2
 
 
	;---------------------------------------------------------------
	;  Do binary search on azimuth from p1
	;---------------------------------------------------------------
binary:	if keyword_set(debug) then begin
	  print,' Starting binary search for circle center.'
	  print,' azi1 = ',azi1
	  print,' azi2 = ',azi2
	endif
loop:
	cnt += 1					; Count iteration.
	azim = ang_mid(azi1,azi2)			; Mid-azi.
	ell_rb2ll, p1.lon, p1.lat, rd, azim, tlon, tlat	; Find test point.
	ell_ll2rb,p2.lon,p2.lat,tlon,tlat,r2,a1,a2	; Check test pt for p2.
	diff = r2-rd					; Radius difference.
	if (abs(diff) lt 0.001) then begin		; Check if azi1 works.
	  if keyword_set(debug) then print,' Center found to ',diff,' meters.'
	  pc = {lon:tlon,lat:tlat}			; Yes, return circle center.
	  r2diff = diff
	  return
	endif
	if r2 lt rd then azi1=azim else azi2=azim
	if keyword_set(debug) then begin
	  print,' Iteration ',cnt,'  --------------'
	  print,' Diff was ',diff
	  print,' azi1 = ',azi1
	  print,' azi2 = ',azi2
	endif
	if cnt ge 100 then stop,' ell_2pt_circle: Iteration count too high for binary.'
	goto, loop
 
	end
