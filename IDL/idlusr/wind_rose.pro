;-------------------------------------------------------------
;+
; NAME:
;       WIND_ROSE
; PURPOSE:
;       Plot a single wind rose on current map.
; CATEGORY:
; CALLING SEQUENCE:
;       wind_rose, lon, lat, rose
; INPUTS:
;       lon, lat = Lon and lat of wind info.   in
;       rose = wind rose array.  Radius of     in
;         each bin is probably direction is
;         in that bin.  Must scale by SIZE=sz
;         to get a useful plot.
; KEYWORD PARAMETERS:
;       Keywords:
;         COLOR=clr wind rose color (def = !p.color).
;         SIZE=sz wind rose radius in pixels (def=20).
;           This is the radius a probability of 1 would have.
;           Expect to use larger values to get a useful plot.
;         THICKNESS=thk wind rose thickness (def=1).
;         /FILL lpot a filled wind rose (thk ignored).
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 2008 Jul 16
;       R. Sterner, 2008 Jul 22 --- Dropped normalize.
;
; Copyright (C) 2008, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro wind_rose, lon, lat, rose, fill=fill, $
	  size=sz, color=clr, thickness=thk, help=hlp
 
	if (n_params(0) lt 3) or keyword_set(hlp) then begin
	  print,' Plot a single wind rose on current map.'
	  print,' wind_rose, lon, lat, rose'
	  print,'   lon, lat = Lon and lat of wind info.   in'
	  print,'   rose = wind rose array.  Radius of     in'
	  print,'     each bin is probably direction is'
	  print,'     in that bin.  Must scale by SIZE=sz'
	  print,'     to get a useful plot.'
	  print,' Keywords:'
	  print,'   COLOR=clr wind rose color (def = !p.color).'
	  print,'   SIZE=sz wind rose radius in pixels (def=20).'
	  print,'     This is the radius a probability of 1 would have.'
	  print,'     Expect to use larger values to get a useful plot.'
	  print,'   THICKNESS=thk wind rose thickness (def=1).'
	  print,'   /FILL lpot a filled wind rose (thk ignored).'
	  return
	endif
 
	;---  Defaults  ---
	if n_elements(sz) eq 0 then sz=20.
	if n_elements(clr) eq 0 then clr=!p.color
	if n_elements(thk) eq 0 then thk=1
 
	;---  initialize  ---
;	r = rose/total(rose)	; Normalize so sum eq 1.
;	r = r*sz
	r = rose*sz
	n = n_elements(rose)
	da = 360./n
	da2 = da/2
	t = convert_coord(lon,lat,/data,/to_dev)
	x = t[0]
	y = t[1]
 
	;---  Generate Arcs  ---
	a1 = -da2 + da*findgen(n)	; Start angle.
	a2 = a1 + da			; End angle.
	a1 = 90 - a1
	a2 = 90 - a2
	arcs, r,a1,a2,x,y,/dev,xout=xp,yout=yp,/noplot
 
	;---  Plot  ---
	if keyword_set(fill) then begin
	  polyfill, /dev,xp,yp,col=clr
	endif else begin
	  plots,/dev,xp,yp,col=clr,thick=thk
	endelse
 
	end
