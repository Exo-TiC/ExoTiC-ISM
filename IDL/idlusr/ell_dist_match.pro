;-------------------------------------------------------------
;+
; NAME:
;       ELL_DIST_MATCH
; PURPOSE:
;       Find point with equal distance to 2 reference points.
; CATEGORY:
; CALLING SEQUENCE:
;       ell_dist_match, p1, p2, p3, azi, pm
; INPUTS:
;       p1, p2 = Reference points.             in
;       p3 = Starting search point.            in
;         Points are structures:
;           {lon:lon, lat:lat}.
;       azi = Azimuth of geodesic through p3.  in
; KEYWORD PARAMETERS:
;       Keywords:
;         AZIMUTH=[a1,a2] Final azimuths from point pm
;           to points p1 and p2.
;         TOL=tol Tolerance in meters (def=0.001).
;         ERROR=err Error flag: 0=ok.
; OUTPUTS:
;       pm = Distance matching point.          out
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 2007 Aug 05
;       R. Sterner, 2007 Sep 21
;       R. Sterner, 2008 Nov 25 --- Detected undefined tp and returned error.
;       R. Sterner, 2010 Jan 03 --- Fixed an undefined err, Dropped help,/st,...
;
; Copyright (C) 2007, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro ell_dist_match, p1, p2, p3, azi, pm, azimuth=aa, help=hlp, $
	  tol=tol, error=err
 
	if (n_params(0) lt 5) or keyword_set(hlp) then begin
	  print,' Find point with equal distance to 2 reference points.'
	  print,' ell_dist_match, p1, p2, p3, azi, pm'
	  print,'   p1, p2 = Reference points.             in'
	  print,'   p3 = Starting search point.            in'
	  print,'     Points are structures:'
	  print,'       {lon:lon, lat:lat}.'
	  print,'   azi = Azimuth of geodesic through p3.  in'
	  print,'   pm = Distance matching point.          out'
	  print,' Keywords:'
	  print,'   AZIMUTH=[a1,a2] Final azimuths from point pm'
	  print,'     to points p1 and p2.'
	  print,'   TOL=tol Tolerance in meters (def=0.001).'
	  print,'   ERROR=err Error flag: 0=ok.'
	  return
	endif
 
	;-------------------------------------------------
	;  Initialize
	;-------------------------------------------------
	err = 0
	if n_elements(tol) eq 0 then tol=0.001
	t = p3						; Test point.
	az = azi					; Azimuth to move.
	ell_ll2rb, t.lon,t.lat,p1.lon,p1.lat, d1,a1	; Dist to p1.
	ell_ll2rb, t.lon,t.lat,p2.lon,p2.lat, d2,a2	; Dist to p2.
	if abs(d1-d2) lt tol then begin			; Happen to match?
	  pm = t					; Yes, found pm.
	  return
	endif
	step = abs(d1-d2)				; Initial search step.
 
	;-------------------------------------------------
	;  Find 2 points bracketing target
	;-------------------------------------------------
	diff = d2 - d1					; Want to zero this.
	if diff gt 0 then begin				; p2 too far.
	  tp = t					; Have + side pt.
	  ;---  Find which way to move  ---
	  ell_rb2ll, p3.lon,p3.lat,step, $		; Step toward azi.
	    az,lon,lat,aa
	  ell_ll2rb, lon,lat,p1.lon,p1.lat, d1,a1	; Dist to p1.
	  ell_ll2rb, lon,lat,p2.lon,p2.lat, d2,a2	; Dist to p2.
	  diff2 = d2 - d1				; New diff.
	  if diff2 gt diff then az=az-180		; Reverse direction.
	  ;---  Search for tm  ---
;	  for i=1,30 do begin				; Find - side pt.
	  for i=1,17 do begin				; Find - side pt.
;	    ell_rb2ll, p3.lon,p3.lat,i*step, $		; Step away pt 1.
	    ell_rb2ll, p3.lon,p3.lat,2L^i*step, $	; Step away pt 1.
	      az,lon,lat,aa
	    ell_ll2rb, lon,lat,p1.lon,p1.lat, d1,a1	; Dist to p1.
	    ell_ll2rb, lon,lat,p2.lon,p2.lat, d2,a2	; Dist to p2.
	    if (d2-d1) lt 0 then begin			; Found - side pt.
	      tm = {lon:lon,lat:lat}			; Pack it up.
	      break					; Exit loop.
	    endif
	  endfor
	endif else begin				; p2 too close.
	  tm = t					; Have - side pt.
	  ;---  Find which way to move  ---
	  ell_rb2ll, p3.lon,p3.lat,step, $		; Step toward azi.
	    az,lon,lat,aa
	  ell_ll2rb, lon,lat,p1.lon,p1.lat, d1,a1	; Dist to p1.
	  ell_ll2rb, lon,lat,p2.lon,p2.lat, d2,a2	; Dist to p2.
	  diff2 = d2 - d1				; New diff.
	  if diff2 lt diff then az=az-180		; Reverse direction.
	  ;---  Search for tp  ---
;	  for i=1,30 do begin				; Find + side pt.
	  for i=1,17 do begin				; Find + side pt.
;	    ell_rb2ll, p3.lon,p3.lat,i*step, $		; Step toward pt 1.
	    ell_rb2ll, p3.lon,p3.lat,2L^i*step, $	; Step toward pt 1.
	      az,lon,lat,aa
	    ell_ll2rb, lon,lat,p1.lon,p1.lat, d1,a1	; Dist to p1.
	    ell_ll2rb, lon,lat,p2.lon,p2.lat, d2,a2	; Dist to p2.
	    if (d2-d1) gt 0 then begin			; Found + side pt.
	      tp = {lon:lon,lat:lat}			; Pack it up.
	      break					; Exit loop.
	    endif
	  endfor
	endelse
 
;help,/st,tm,tp
	if n_elements(tp) eq 0 then begin
	  print,' Error in ell_dist_match: Point tp undefined.'
	  whocalledme, dir, file, line=line
	  print,' Called by ',dir,'/',file,' line ',line
	  err = 1
	  return
	endif
 
	;-------------------------------------------------
	;  Do binary search
	;
	;  Point tm is too close to pt p2
	;  Point tp is too far from pt p2.
	;  az is direction toward pt p1.
	;  The points tm and tp are on the geodesic
	;  through pt p3 with given azimuth.
	;  Do a midpoint search.  The sequence of
	;  midpoints will all be on the same geodesic.
	;-------------------------------------------------
	flag = 0					; No solution yet.
	for i=1,100 do begin				; Loop.
	  tx = ell_geo_mid(tm,tp)			; Midpoint.
	  ell_ll2rb, tx.lon,tx.lat,p1.lon,p1.lat, d1,a1	; Dist to p1.
	  ell_ll2rb, tx.lon,tx.lat,p2.lon,p2.lat, d2,a2	; Dist to p2.
	  diff = d2 - d1				; Diff in m.
	  if abs(diff) lt tol then begin		; Found target.
	    pm = tx					; Set output.
	    aa = [a1,a2]				; Return azimuths.
	    flag = 1					; Flag as found.
	    break					; Exit loop.
	  endif
	  if diff gt 0 then begin			; Pt p2 too far.
	    tp = tx
	  endif else begin				; Pt p2 too close.
	    tm = tx
	  endelse
	endfor
	if flag eq 0 then begin
	  print,' Error in ell_dist_match: No solution found.'
	  print,' Dist diff = ',diff
	  stop
	endif
 
	end
