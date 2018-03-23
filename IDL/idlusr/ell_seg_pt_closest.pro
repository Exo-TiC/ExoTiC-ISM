;-------------------------------------------------------------
;+
; NAME:
;       ELL_SEG_PT_CLOSEST
; PURPOSE:
;       Find point on segment closest to a given point.
; CATEGORY:
; CALLING SEQUENCE:
;       ell_seg_pt_closest, p1, p2, p3, p4
; INPUTS:
;       p1, p2 = Segment start and end point.          in
;       p3 = Given point off the segment.              in
; KEYWORD PARAMETERS:
;       Keywords:
;         FLAG=flag 0: closest pt is between segment endpoints.
;                   1: Closest pt is outside segment on p1 side.
;                   2: Closest pt is outside segment on p2 side.
;         COUNT=cnt Iteration counts.
; OUTPUTS:
;       p4 = Returned point on segment closest to p3.  out
;         Each point is a structure: {log:lon, lat:lat}.
; COMMON BLOCKS:
; NOTES:
;       Notes: Uses ellipsoidal distances and returns result to
;         within 1 mm.
; MODIFICATION HISTORY:
;       R. Sterner, 2007 Aug 29
;
; Copyright (C) 2007, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro ell_seg_pt_closest, p1, p2, p3, p4, flag=flag, count=cnt, help=hlp
 
	if (n_params(0) lt 4) or keyword_set(hlp) then begin
	  print,' Find point on segment closest to a given point.'
	  print,' ell_seg_pt_closest, p1, p2, p3, p4'
	  print,'   p1, p2 = Segment start and end point.          in'
	  print,'   p3 = Given point off the segment.              in'
	  print,'   p4 = Returned point on segment closest to p3.  out'
	  print,'     Each point is a structure: {log:lon, lat:lat}.'
	  print,' Keywords:'
	  print,'   FLAG=flag 0: closest pt is between segment endpoints.'
	  print,'             1: Closest pt is outside segment on p1 side.'
	  print,'             2: Closest pt is outside segment on p2 side.'
	  print,'   COUNT=cnt Iteration counts.'
	  print,' Notes: Uses ellipsoidal distances and returns result to'
	  print,'   within 1 mm.'
	  return
	endif
 
	;--------------------------------------------------------------
	;  Method:
	;  Using perpendiculars from the segment endpoints, first
	;  make sure the given point actually has a closest point
	;  on the given segment.  This is done by finding which
	;  sides of the perpendiculars the given point is on.
	;  Then do a binary search using sides to find the closest
	;  point.
	;--------------------------------------------------------------
 
	cnt = 0					; Iteration count.
 
	;--------------------------------------------------------------
	;  Length and direction of segment
	;--------------------------------------------------------------
	ell_ll2rb, p1.lon,p1.lat, p2.lon,p2.lat, d0, a1, a2
 
	;--------------------------------------------------------------
	;  On which side of the segment is the given point?
	;--------------------------------------------------------------
	side = ell_geo_side(p1,p2,p3)
 
	;---  If given point is on or aligned with segment  ---
	if side eq 0 then begin	
	  ell_ll2rb, p1.lon,p1.lat, p3.lon,p3.lat,d1,t1,t2  ; Dist p1 to p3.
	  ell_ll2rb, p2.lon,p2.lat, p3.lon,p3.lat,d2,t1,t2  ; Dist p2 to p3.
	  if abs((d1+d2)-d0) le 0.001 then begin	    ; p4 = p3.
	    flag = 0					    ; On segment.
	    p4 = p3                                         ; Given is result.
	    return
	  endif
	  if d1 lt d2 then begin			    ; p1 is closest.
	    flag = 1
	    p4 = p1
	  endif else begin				    ; p2 is closest.
	    flag = 2
	    p4 = p2
	  endelse
	  return
	endif
 
	;--------------------------------------------------------------
	;  Check that there is a closest point on segment
	;--------------------------------------------------------------
	ell_rb2ll, p1.lon,p1.lat,1000,a1+side*90,lon,lat,az
	pp1 = {lon:lon,lat:lat}		; Perpendicular point from p1.
	ell_rb2ll, p2.lon,p2.lat,1000,a2-side*90,lon,lat,az
	pp2 = {lon:lon,lat:lat}		; Perpendicular point from p2.
	side1 = ell_geo_side(p1,pp1,p3)	; Side from p1.
	side2 = ell_geo_side(p2,pp2,p3)	; Side from p2.
 
	if side1 eq side2 then begin	; Closest pt outside segment.
	  if side1 eq side then begin	; p1 is closest.
	    flag = 1
	    p4 = p1
	  endif else begin		; p2 is closest.
	    flag = 2
	    p4 = p2
	  endelse
	  return
	endif
 
	;--------------------------------------------------------------
	;  There is a closest point on the segment
	;--------------------------------------------------------------
	if side1 eq 0 then begin	; p1 is solution.
	  flag = 1
	  p4 = p1
	  return
	endif
	if side2 eq 0 then begin	; p2 is solution.
	  flag = 2
	  p4 = p2
	  return
	endif
	flag = 0			; Closest point is between endpoints.
 
	;--------------------------------------------------------------
	;  Search for solution
	;--------------------------------------------------------------
	pa = p1					; Init search points.
	sidea = side1
	pb = p2
	sideb = side2
	pm_last = pa				; Init last midpoint.
 
	;--- Bisect to get new midpoint  ---
loop:	pm = ell_geo_mid(pa, pb, azi2=am)	; New midpoint.
	cnt = cnt + 1
 
	;---  test if done  ---
	if ell_point_sep(pm, pm_last) le 0.001 then begin  ; Find solution.
	  p4 = pm
	  return
	endif
	;---  New perpendicular  ---
	ell_rb2ll, pm.lon,pm.lat,1000,am-side*90,lon,lat,az
	ppm = {lon:lon,lat:lat}		; Perpendicular point from pm.
	sidem = ell_geo_side(pm,ppm,p3)	; Side from pm.
	if side eq 0 then begin		; pm is solution.
	  p4 = pm
	  return
	endif
	;---  Update one side or other of segment  ---
	if sidem eq sidea then begin	; New pt A.
	  pa = pm
	endif else begin		; New pt B.
	  pb = pm
	endelse
	pm_last = pm			; Save pt M.
	goto, loop			; Iterate.
 
	end
