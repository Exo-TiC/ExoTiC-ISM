;-------------------------------------------------------------
;+
; NAME:
;       ELL_PLOT_SEG
; PURPOSE:
;       Plot a color coded data segment on current map.
; CATEGORY:
; CALLING SEQUENCE:
;       ell_plot_seg, p1, p2
; INPUTS:
;       p1 = Start of segment to plot.     in
;       p2 = Endpoint of segment to plot.  in
;         Both points are structures {lon:lon,lat:lat}.
; KEYWORD PARAMETERS:
;       Keywords:
;         COLOR=clr Array of 24-bit colors of data along segment.
;         WIDTH=wd Width of segment in meters.
;         NUM=num  Number of steps across width.
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
;       Notes: If plotted color band has holes trying using
;         thick=2 (or 3).
;         Assumes data values (given by the clr array) are evenly
;           spaced in range from pt1 to pt2.
;         Example:
;           map_set,39,-77,scale=4e6,/cont,/usa
;           x1=-80 & y1=37
;           x2=-73 & y2=41
;           v = makey(500)*50-75
;           clr=color_code(v)
;           ell_plot_seg,{lon:x1,lat:y1},{lon:x2,lat:y2},color=clr, $
;             width=10000,num=100,thick=2
;           map_set,39,-77,scale=4e6,/cont,/usa,/noerase
; MODIFICATION HISTORY:
;
; Copyright (C) 2008, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro ell_plot_seg, pt1, pt2,  color=clr, num=num, width=wd, $
	  _extra=extra, help=hlp
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Plot a color coded data segment on current map.'
	  print,' ell_plot_seg, p1, p2'
	  print,'   p1 = Start of segment to plot.     in'
	  print,'   p2 = Endpoint of segment to plot.  in'
	  print,'     Both points are structures {lon:lon,lat:lat}.'
	  print,' Keywords:'
	  print,'   COLOR=clr Array of 24-bit colors of data along segment.'
	  print,'   WIDTH=wd Width of segment in meters.'
	  print,'   NUM=num  Number of steps across width.'
	  print,' Notes: If plotted color band has holes trying using'
	  print,'   thick=2 (or 3).'
	  print,'   Assumes data values (given by the clr array) are evenly'
	  print,'     spaced in range from pt1 to pt2.'
	  print,'   Example:'
	  print,'     map_set,39,-77,scale=4e6,/cont,/usa'
	  print,'     x1=-80 & y1=37'
	  print,'     x2=-73 & y2=41'
	  print,'     v = makey(500)*50-75'
	  print,'     clr=color_code(v)'
	  print,'     ell_plot_seg,{lon:x1,lat:y1},{lon:x2,lat:y2},color=clr, $'
	  print,'       width=10000,num=100,thick=2'
	  print,'     map_set,39,-77,scale=4e6,/cont,/usa,/noerase'
	  return
	endif
 
	n = n_elements(clr)			; Number of colors.
 
	x1 = pt1.lon				; Star end end points.
	y1 = pt1.lat
	x2 = pt2.lon
	y2 = pt2.lat
	ell_ll2rb, x1,y1,x2,y2,r,a1,a2		; Range and bearings.
	a11 = a1 - 90				; Pt 1 offset azi.
	a22 = a2 + 90				; Pt 2 offset azi.
	r2 = wd/2.				; Band halfwidth (m).
	rr = maken(-r2,r2,num)			; Centered band.
	
	for i=0,num-1 do begin			; Loop through offsets.
	  p1 = ell_point_mov(pt1,rr[i],a11)	; Offset pt 1.
	  p2 = ell_point_mov(pt2,rr[i],a22)	; Offset pt 2.
	  ell_geo_pts,p1,p2,xx,yy,n=n		; Make pts between.
	  plots,xx,yy, color=clr, _extra=extra	; Plot them.
	endfor ; i
 
	end
