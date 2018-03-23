;-------------------------------------------------------------
;+
; NAME:
;       ELL_GEO_MINDIST_PT
; PURPOSE:
;       Find the point on the given geodesic closest to a given point.
; CATEGORY:
; CALLING SEQUENCE:
;       ell_geo_mindist_pt, p1, p2, pt
; INPUTS:
;       p1, p2 = Start and end point on a geodesic.  in
;       pt = A reference point not on the geodesic.  in
;         All points are structures: {lon:lon, lat:lat}.
; KEYWORD PARAMETERS:
;       Keywords:
;         OUT=pmin The closest point on the geodesic to point pt.
;           If pmin is not between p1 and p2 it is set to the
;           closer of p1 or p2 and flag will be 1 or 2.
;         DIST=d Distance (m) from pmin to pt.
;         AZI=[a1,a2]  a1=azimuth from pmin to pt,
;                      a2=azimuth from pt to pmin.
;         FLAG=flag 0=closest point is between p1 and p2,
;                   1=closest point is p1,
;                   2=closest point is p2.
;                   3=search not bounded by p1 and p2.
;         /UNBOUND Do not bound solution between p1 and p2.
;         /DEBUG Debug.
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 2008 Feb 11
;       R. Sterner, 2008 May 05 --- /UNBOUND.
;
; Copyright (C) 2008, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro ell_geo_mindist_pt, p10, p20, pt, out=pmin, flag=flag, $
	  dist=dst, azi=azi, unbound=unbound, debug=debug, help=hlp
 
	if (n_params(0) lt 3) or keyword_set(hlp) then begin
	  print,' Find the point on the given geodesic closest to a given point.'
	  print,' ell_geo_mindist_pt, p1, p2, pt'
	  print,'   p1, p2 = Start and end point on a geodesic.  in'
	  print,'   pt = A reference point not on the geodesic.  in'
	  print,'     All points are structures: {lon:lon, lat:lat}.'
	  print,' Keywords:'
	  print,'   OUT=pmin The closest point on the geodesic to point pt.'
	  print,'     If pmin is not between p1 and p2 it is set to the'
	  print,'     closer of p1 or p2 and flag will be 1 or 2.'
	  print,'   DIST=d Distance (m) from pmin to pt.'
	  print,'   AZI=[a1,a2]  a1=azimuth from pmin to pt,'
	  print,'                a2=azimuth from pt to pmin.'
	  print,'   FLAG=flag 0=closest point is between p1 and p2,'
	  print,'             1=closest point is p1,'
	  print,'             2=closest point is p2.'
	  print,'             3=search not bounded by p1 and p2.'
	  print,'   /UNBOUND Do not bound solution between p1 and p2.'
	  print,'   /DEBUG Debug.'
	  return
	endif

;-------------------------------------------------------------------------
;  Find point on geodesic where the azimuth to the reference point
;  is 90 deg from the azimuth to p2.
;
;  Define Relative Cross-Azimuth, ca.  Let the cross-angle be the angle
;  at right angles to the geodeis at the test point (which is on the
;  geodesic).  The ca is the angle of the reference point, pt from the
;  cross-angle.  The sign of ca is - if the cross-angle must be rotated
;  in the - azimuth direction to be twoard the ref pt.  If the cross-angle
;  is due north then ca would be the azimuth of the ref point.
;  ca is 0 for the point on the geodesic closest to the reference point.
;  As the test point moves along the geodesic ca will go through 0, so
;  a zero crossing search may be used.  The geodesic endpoints must bound
;  the closest point, so ca must have opposite signs at the geodesic
;  endpoints.  If this is not true, and the unbounded keyword is set,
;  then move one endpoint until it is true if possible.
;-------------------------------------------------------------------------
 
	;---  Find initial azimuths  ---
	p1 = p10						; Copy.
	p2 = p20
	ell_ll2rb, p1.lon,p1.lat,p2.lon,p2.lat,r12,a12,a21	; Azi p1 to p2.
	tol = 0.001D0/r12					; Tol. for t.
	ell_ll2rb, p1.lon,p1.lat,pt.lon,pt.lat,r1p,a1p,ap1	; Azi p1 to pt.
	ell_ll2rb, p2.lon,p2.lat,pt.lon,pt.lat,r2p,a2p,ap2	; Azi p2 to pt.
 
	;------------------------------------------------------------
	;  Find relative cross-azimuths from p1 and p2
	;
	;  Want the relative cross-azimuths of the target point to be:
	;  Negative as seen from p1 if target is in same hemisphere
	;  as p2, positive if opposite.  So - if target toward p2,
	;  + if away from p2.  Want same signs for p2 so + if target
	; toward p1, - if away.
	;------------------------------------------------------------
	flag = 0
	ca1 = ang_diff(a12+90,a1p)	; Rel x-azi from p1.
	ca2 = ang_diff(a21-90,a2p)	; Rel x-azi from p2.
	if keyword_set(debug) then begin
	  print,' ca1 = ',ca1
	  print,' ca2 = ',ca2
	endif
	;----------------------------------------
	;  Bounded to between p1 and p2.
	;----------------------------------------
	if not keyword_set(unbound) then begin
	  if (ca1 mod 180) eq 0 then begin		; p1 is solution.
	    flag = 0
	    pmin = p1
	    dst = r1p
	    azi = [a1p,ap1]
	    return
	  endif
	  if (ca2 mod 180) eq 0 then begin		; p2 is solution.
	    flag = 0
	    pmin = p2
	    dst = r2p
	    azi = [a2p,ap2]
	    return
	  endif
	  if (ca1 lt 0) and (ca2 lt 0) then begin	; Off but p2 closest.
	    flag = 2
	    pmin = p2
	    dst = r2p
	    azi = [a2p,ap2]
	    return
	  endif
	  if (ca1 gt 0) and (ca2 gt 0) then begin	; Off but p1 closest.
	    flag = 1
	    pmin = p1
	    dst = r1p
	    azi = [a1p,ap1]
	    return
	  endif
	;----------------------------------------
	;  Unbounded (by p1 and p2).
	;  Try to get opposite signs for endpoints.
	;----------------------------------------
	endif else begin
	  if sign(ca1) eq sign(ca2) then begin		; Want opposite signs.
;	    ca12 = ang_diff(a12+90,a12)		; Rel x-azi from p1 of p2.
	    ca21 = ang_diff(a21-90,a21)		; Rel x-azi from p2 of p1.
;	    sn12 = sign(ca12)			; Sign of ca12.
;	    sn21 = sign(ca21)			; Sign of ca21.
	    fct = 2.
	    if sign(ca1) eq sign(ca21) then begin	; Move p1 out.
;	    if abs(ca1) lt abs(ca2) then begin		; Move p1 out.
	      if keyword_set(debug) then print,' Moving p1 to bound solution.'
	      for i=1,3 do begin
	        ell_rb2ll, p2.lon, p2.lat, fct*r12,a21,tlon,tlat
		p1 = {lon:tlon,lat:tlat}
		ell_ll2rb, p1.lon,p1.lat,p2.lon,p2.lat,r12,a12,a21; Azi p1rp2.
		ell_ll2rb, p1.lon,p1.lat,pt.lon,pt.lat,r1p,a1p,ap1 ; Azi to pt.
	        ca1 = ang_diff(a12+90,a1p)
	        if sign(ca1) ne sign(ca2) then goto, rdy
		fct = fct*2
	      endfor
	      stop,' Could not bound solution (moved p1), stop.'
	    endif else begin				; Move p2 out.
	      if keyword_set(debug) then print,' Moving p2 to bound solution.'
	      for i=1,3 do begin
	        ell_rb2ll, p1.lon, p1.lat, fct*r12,a12,tlon,tlat
		p2 = {lon:tlon,lat:tlat}
		ell_ll2rb, p1.lon,p1.lat,p2.lon,p2.lat,r12,a12,a21 ; Azi p1rp2.
		ell_ll2rb, p2.lon,p2.lat,pt.lon,pt.lat,r2p,a2p,ap2 ; Azi pt.
		ca2 = ang_diff(a21-90,a2p)
	        if sign(ca1) ne sign(ca2) then goto, rdy
		fct = fct*2
	      endfor
	      stop,' Could not bound solution (moved p2), stop.'
	    endelse
	  endif
rdy:
	  flag = 3
	endelse
 
	;---  Initialize search  ---
	t1 = 0.						; Distance parameters.
	t2 = 1.
	cnt = 0
	tz0 = t1
	if keyword_set(debug) then begin
	  print,' Starting linear search for closest point.'
	  print,' Parameter t goes from 0 at p1 to 1 at p2.'
	  print,' 1 mm is a change of t of ',tol
	  print,' Relative cross-azimuth, ca, is 0 at closest point.'
	endif
 
loop:
	cnt += 1					; Iteration count.
	if keyword_set(debug) then begin
	  print,' cnt: ',cnt
	  print,' t1, ca1: ',t1,ca1
	  print,' t2, ca2: ',t2,ca2
	endif
	if cnt ge 100 then stop,' Iteration count too high, STOP.'
	tz = t1 + ca1*(t2-t1)/(ca1-ca2)			; Estimated parameter.
	ell_rb2ll, p1.lon, p1.lat, tz*r12,a12,tlon,tlat	; Test point.
	mm = abs(tz-tz0)/tol
	if keyword_set(debug) then print,' mm from last test point: ',mm
	if mm lt 1 then begin				; Within 1 mm of last?
	  pmin = {lon:tlon,lat:tlat}			; Solution.
	  ell_ll2rb, tlon,tlat,pt.lon,pt.lat,dst,a1,a2	; Azi to pt.
	  azi = [a1,a2]
	  return
	endif
	ell_ll2rb, tlon,tlat,p2.lon,p2.lat,r,at2,a	; Azi to p2.
	ell_ll2rb, tlon,tlat,pt.lon,pt.lat,r,atp,a	; Azi to pt.
	ca = ang_diff(at2+90,atp)			; Rel x-azi from test.
	if ca gt 0 then begin
	  ca2 = ca
	  t2 = tz
	endif else begin
	  ca1 = ca
	  t1 = tz
	endelse
	tz0 = tz					; Previous t.
	goto, loop
 
	end
