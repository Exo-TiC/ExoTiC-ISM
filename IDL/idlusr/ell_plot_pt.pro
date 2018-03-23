;-------------------------------------------------------------
;+
; NAME:
;       ELL_PLOT_PT
; PURPOSE:
;       Plot a point or segment on current map.
; CATEGORY:
; CALLING SEQUENCE:
;       ell_plot_pt, p1 [, p2]
; INPUTS:
;       p1 = Point to plot.                         in
;       p2 = Optional endpoint of segment to plot.  in
;         Both points are structures {lon:lon,lat:lat}.
;         Structure p1 may be a segment instead of a single
;         point: {lon1:lon1,lat1:lat1,lon2:lon2,lat2:lat2}.
; KEYWORD PARAMETERS:
;       Keywords:
;         PSYM=psym Plot symbol for a point (or segment endpoints).
;         Other plot keywords also allowed.
;         AZI=azi Optional azimuth from p1 (if p1 is a single pt).
;         RADIUS=r Option radius (m) from p1 (if a single point).
;           This will plot a circle about p1.
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
;       Notes: If given two points a segment along a geodesic
;         will be plotted.
; MODIFICATION HISTORY:
;       R. Sterner, 2007 Aug 05
;       R. Sterner, 2007 Sep 19 --- Upgraded to plot a segment also.
;       R. Sterner, 2008 Feb 08 --- Added RADIUS=r.
;       R. Sterner, 2008 Feb 11 --- Allows plot symbols at segment ends.
;
; Copyright (C) 2007, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro ell_plot_pt, pt1, pt2, psym=sym, _extra=extra, help=hlp, $
	  azi=azi, radius=rad
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Plot a point or segment on current map.'
	  print,' ell_plot_pt, p1 [, p2]'
	  print,'   p1 = Point to plot.                         in'
	  print,'   p2 = Optional endpoint of segment to plot.  in'
	  print,'     Both points are structures {lon:lon,lat:lat}.'
	  print,'     Structure p1 may be a segment instead of a single'
	  print,'     point: {lon1:lon1,lat1:lat1,lon2:lon2,lat2:lat2}.'
	  print,' Keywords:'
	  print,'   PSYM=psym Plot symbol for a point (or segment endpoints).'
	  print,'   Other plot keywords also allowed.'
	  print,'   AZI=azi Optional azimuth from p1 (if p1 is a single pt).'
	  print,'   RADIUS=r Option radius (m) from p1 (if a single point).'
	  print,'     This will plot a circle about p1.'
	  print,' Notes: If given two points a segment along a geodesic'
	  print,'   will be plotted.'
	  return
	endif
 
	if n_params(0) eq 1 then begin
	  if n_elements(sym) eq 0 then sym=6
	  if n_tags(pt1) eq 2 then begin
	    plots, pt1.lon, pt1.lat, psym=sym, _extra=extra
	    if n_elements(azi) ne 0 then begin
	      ell_rb2ll, pt1.lon, pt1.lat,10E6,azi,lon,lat
	      ell_geo_pts,pt1,{lon:lon,lat:lat},xx,yy
	      plots,xx,yy, _extra=extra
	    endif
	    if n_elements(rad) ne 0 then begin
	      ell_rb2ll, pt1.lon, pt1.lat,rad,maken(0,360,361),xx,yy
	      plots,xx,yy, _extra=extra
	    endif
	  endif
	  if n_tags(pt1) eq 4 then begin
	    p1 = {lon:pt1.lon1,lat:pt1.lat1}
	    p2 = {lon:pt1.lon2,lat:pt1.lat2}
	    ell_geo_pts,p1,p2,xx,yy
	    plots,xx,yy, _extra=extra
	  endif
	  return
	endif
 
	ell_geo_pts,pt1,pt2,xx,yy
	plots,xx,yy, _extra=extra
	if n_elements(sym) ne 0 then begin
	  plots, pt1.lon, pt1.lat, psym=sym, _extra=extra
	  plots, pt2.lon, pt2.lat, psym=sym, _extra=extra
	endif
 
	end
