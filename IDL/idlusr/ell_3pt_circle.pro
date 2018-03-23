;-------------------------------------------------------------
;+
; NAME:
;       ELL_3PT_CIRCLE
; PURPOSE:
;       Fit a circle to 3 points on an ellipsoid.
; CATEGORY:
; CALLING SEQUENCE:
;       ell_3pt_circle, p1, p2, p3, pc
; INPUTS:
;       p1, p2, p3 = 3 given points.     in
; KEYWORD PARAMETERS:
;       Keywords:
;         RADIUS=rd Returned radius of circle (m).
;         /DEBUG  Debug.  Assumes a map is ready to plot on.
;         ERROR=err 0=ok, else did not fit the circle.
;         NUM_ITERATIONS=cnt Number of iterations to get within
;           tolerance (small, like <4).
; OUTPUTS:
;       pc = Returned center of circle.  out
;         Points are structures: {lon:lon, lat:lat}.
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 2007 Aug 05
;       R. Sterner, 2007 Sep 17 --- Corrected call to ell_point_sep.
;       R. Sterner, 2008 Mar 19 --- Used tol/2 in ell_dist_match.
;       R. Sterner, 2008 Nov 25 --- Returned with error if no fit.
;
; Copyright (C) 2007, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro ell_3pt_circle, p1, p2, p3, pc, radius=rd ,help=hlp, $
	  debug=debug, num_iterations=cnt, error=err
 
	if (n_params(0) lt 4) or keyword_set(hlp) then begin
	  print,' Fit a circle to 3 points on an ellipsoid.'
	  print,' ell_3pt_circle, p1, p2, p3, pc'
	  print,'   p1, p2, p3 = 3 given points.     in'
	  print,'   pc = Returned center of circle.  out'
	  print,'     Points are structures: {lon:lon, lat:lat}.'
	  print,' Keywords:'
	  print,'   RADIUS=rd Returned radius of circle (m).'
	  print,'   /DEBUG  Debug.  Assumes a map is ready to plot on.'
	  print,'   ERROR=err 0=ok, else did not fit the circle.'
	  print,'   NUM_ITERATIONS=cnt Number of iterations to get within'
	  print,'     tolerance (small, like <4).'
	  return
	endif
 
	;---------------------------------------------
	;  Method
	;
	;  From 3 given points form 2 segments.
	;  [1] Find segment bisectors.
	;  [2] Find intersection of the bisectors.
	;  [3] For first segment midpoint find azi to
	;      it from first estimate.
	;  [4] Search at right angles to equalize
	;      distance to segment endpoints.
	;  [5] Find azimuth to segment endpoints and
	;      find mid-azimuth.
	;  [6] Search along this azimuth to equalize
	;      distance to 3rd point and segment
	;      endpoints.
	;  [7] Repeat [3]-[7] to get within tolerence.
	;---------------------------------------------
 
	;---------------------------------------------
	;  Find size to make bisectors
	;  Want to keep segments in one hemisphere.
	;  Size depends on ellipsoid in use.
	;---------------------------------------------
	ell_ll2rb,0,0,0,90,d,a1,a2	; 1/4 circumference.
	rmax = 0.9*d			; Use 90% of max possible.
	tol = 0.001D0			; Small dist tol.
 
	;---------------------------------------------
	;  Find midpoints of 2 sides
	;---------------------------------------------
	m12 = ell_geo_mid(p1, p2, azi2=a12)	; Midpoint of p1, p2.
	m23 = ell_geo_mid(p2, p3, azi2=a23)	; Midpoint of p2, p3.
	
	;---------------------------------------------
	;  Find bisectors
	;---------------------------------------------
	ell_rb2ll, m12.lon,m12.lat,rmax,a12-90,x1,y1	; Points on opposite
	ell_rb2ll, m12.lon,m12.lat,rmax,a12+90,x2,y2	; sides of midpoint.
	b12 = {lon1:x1,lat1:y1,lon2:x2,lat2:y2}
	ell_rb2ll, m23.lon,m23.lat,rmax,a23-90,x1,y1
	ell_rb2ll, m23.lon,m23.lat,rmax,a23+90,x2,y2
	b23 = {lon1:x1,lat1:y1,lon2:x2,lat2:y2}
	if keyword_set(debug) then begin
	  ell_plot_pt,m12,col=255
	  ell_plot_pt,m23,col=255
	  ell_plot_pt,b12,col=255
	  ell_plot_pt,b23,col=255
	endif
	
	;---------------------------------------------
	;  First estimate of center is intersection
	;---------------------------------------------
	ell_geo_int, b12, b23, pcs, flag=flag
;	if flag eq 0 then stop,' STOP ell_3pt_circle: No intersection found.'
	if flag eq 0 then begin
	  print,' Warning in ell_3pt_circle: no fit (ell_geo_int failed).'
	  err = 1
	  return
	endif
 
	;---------------------------------------------
	;  Check if within tolerance
	;---------------------------------------------
	d1 = ell_point_sep(pcs,p1)
	d2 = ell_point_sep(pcs,p2)
	d3 = ell_point_sep(pcs,p3)
	d12 = abs(d1-d2)
	d23 = abs(d2-d3)
	d13 = abs(d1-d3)
 
	;---------------------------------------------
	;  If within tolerance pack up and return
	;---------------------------------------------
	cnt = 0
	if (d12 le tol) and (d23 le tol) and (d13 le tol) then begin
	  pc = pcs
	  rd = mean([d1,d2,d3])
	  if keyword_set(debug) then begin
	    print,' Final estimate of center, ' + $
	      'radius differences in mm: ',1000*[d12,d23,d13]
	    print,' Tolerance (mm): ',1000*tol
	  endif
	  err = 0
	  return
	endif
 
	if keyword_set(debug) then begin
	  print,' ---==< Debug >==---'
	  ell_plot_pt,pcs,col=255
	  print,' First estimate of center, '+$
	    'radius differences in mm: ',d12,d23,d13
	endif
 
	;---------------------------------------------
	;  Equalize distance to p1 and p2
	;
	;  First find direction (=a1) from intersection
	;  point (=pcs) to segment 1,2 midpoint (=m12).
	;  Search azi through pcs is a1+90.
	;  Point pm is same distance to p1 and p2.
	;  azi_eq is the azimuth that keeps distances
	;  equal over short distance.
	;---------------------------------------------
;	cnt = 0
 
loop:
	cnt = cnt + 1
	if cnt gt 4 then stop,' STOP ell_3pt_circle: Not converging yet.'
	ell_ll2rb,pcs.lon,pcs.lat,m12.lon,m12.lat,d,a1	; Azi pcs to m12.
	ell_dist_match, p1, p2, pcs, a1+90, pm, azi=aa, tol=tol/2.
	azi_eq = mean(fixang(aa)) mod 360		; Mid azimuth.
	if keyword_set(debug) then begin
	  ell_plot_pt,p1,col=tarclr(0,0,255)
	  ell_plot_pt,p2,col=tarclr(0,0,255)
	  ell_plot_pt,pcs,azi=a1+90,col=tarclr(0,0,255)
	  d1 = ell_point_sep(pm,p1)
	  d2 = ell_point_sep(pm,p2)
	  d12 = 1000*abs(d1-d2)
	  print,' -----  Iteration # '+strtrim(cnt,2)+'  ------'
	  print,' Finding search start point, match dist to p1, p2:'
	  print,' Dist match error (mm): ',d12
	  print,'   Azi pm to p1: ',aa[0]
	  print,'   Azi pm to p2: ',aa[1]
	  print,'   Search azi = ',azi_eq
	endif
 
	;---------------------------------------------
	;  Equalize distance to p2 and p3
	;
	;  Search along azimuth azi_eq.
	;---------------------------------------------
	ell_dist_match, p2, p3, pm, azi_eq, pm2, azi=aa2, tol=tol/2.,err=err
	if err ne 0 then begin
	  print,' Warning in ell_3pt_circle: no fit (ell_dist_match failed).'
	  err = 1
	  return
	endif
	if keyword_set(debug) then begin
	  d1 = ell_point_sep(pm2,p1)
	  d2 = ell_point_sep(pm2,p2)
	  d3 = ell_point_sep(pm2,p3)
	  d12 = 1000*abs(d1-d2)
	  d23 = 1000*abs(d2-d3)
	  print,' -----  Iteration # '+strtrim(cnt,2)+'  ------'
	  print,' Dist match error d12, d23 (mm): ',d12, d23
	  ell_plot_pt,pm,azi=azi_eq,col=tarclr(0,255,0)
	endif
	;---------------------------------------------
	;  Check if within tolerance
	;---------------------------------------------
	d1 = ell_point_sep(pm2,p1)
	d2 = ell_point_sep(pm2,p2)
	d3 = ell_point_sep(pm2,p3)
	d12 = abs(d1-d2)
	d23 = abs(d2-d3)
	d13 = abs(d1-d3)
 
	;---------------------------------------------
	;  If within tolerance pack up and return
	;---------------------------------------------
	if (d12 le tol) and (d23 le tol) and (d13 le tol) then begin
	  pc = pm2
	  rd = mean([d1,d2,d3])
	  if keyword_set(debug) then begin
	    print,' Final estimate of center, '+$
	      'radius differences in mm: ',1000*[d12,d23,d13]
	    print,' Tolerance (mm): ',1000*tol
	  endif
	endif else begin
	  if keyword_set(debug) then begin
	    print,' Radius differences in mm',1000*[d12,d23,d13]
	    print,' Tolerance (mm): ',1000*tol
	    print,' >>>===> Iterating ...'
	  endif
	  pcs = pm2
	  goto, loop
	endelse
 
	err = 0
 
	end
