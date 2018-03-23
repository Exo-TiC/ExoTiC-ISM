;-------------------------------------------------------------
;+
; NAME:
;       MAP_LATLNG_RECT
; PURPOSE:
;       Plot a rectangular area of lat/long on a map.
; CATEGORY:
; CALLING SEQUENCE:
;       map_latlng_rect, lon1, lon2, lat1, lat2
; INPUTS:
;       lon1, lon2 = longitudes (degrees) of sides.   in
;       lat1, lat2 = latitudes (degrees) of sides.    in
; KEYWORD PARAMETERS:
;       Keywords:
;         NUMBER=n   Number of points on each side (def=100).
;         COLOR=clr  Plot color (def=!p.color).
;         THICKNESS=thk Plot thickness (def=!p.thick).
;         LINESTYLE=sty Plot linestyle (def=!p.linestyle).
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 2000 Jun 29
;       R. Sterner, 2008 Mar 21 --- Corrected help text.
;       R. Sterner, 2014 Apr 15 --- Added /xmode.
;       R. Sterner, 2014 Apr 18 --- Added /erase.
;
; Copyright (C) 2000, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro map_latlng_rect, x1,x2,y1,y2, $
	  number=num, color=clr,thickness=thk,linestyle=sty, help=hlp, $
          xmode=xmode, erase=erase

        ;---  Save last potted box  ---
        common map_latlng_rect_com, x10, x20, y10, y20
 
	if (n_params(0) lt 4) or keyword_set(hlp) then begin
	  print,' Plot a rectangular area of lat/long on a map.'
	  print,' map_latlng_rect, lon1, lon2, lat1, lat2'
	  print,'   lon1, lon2 = longitudes (degrees) of sides.   in'
	  print,'   lat1, lat2 = latitudes (degrees) of sides.    in'
	  print,' Keywords:'
	  print,'   NUMBER=n   Number of points on each side (def=100).'
	  print,'   COLOR=clr  Plot color (def=!p.color).'
	  print,'   THICKNESS=thk Plot thickness (def=!p.thick).'
	  print,'   LINESTYLE=sty Plot linestyle (def=!p.linestyle).'
          print,'   /XMODE Plot in XOR mode.'
          print,'   /ERASE erase last plotted box (only for /xmode).'
	  return
	endif
 
	;--------  Defaults  ----------------------------
	if n_elements(num) eq 0 then num = 100
	if n_elements(clr) eq 0 then clr = !p.color
	if n_elements(thk) eq 0 then thk = !p.thick
	if n_elements(sty) eq 0 then sty = !p.linestyle

        ;---  Deal with /xmode  ---
        if keyword_set(xmode) then begin
          device,get_graphic=mode
          device,set_graphic=6
        endif

        ;---  Erase last plotted box  ---
        if keyword_set(erase) and keyword_set(xmode) then begin
          if n_elements(x10) ne 0 then begin
            map_latlng_rect, x10,x20,y10,y20, /xmode, $
	    number=num, color=clr,thickness=thk,linestyle=sty
          endif
          if keyword_set(xmode) then device,set_graphic=mode
          return
        endif
 
	;--------  Find and plot points  -----------------
	x = maken(x1,x2,num)	; South.
	y = maken(y1,y1,num)
	oplot,x,y,color=clr,thick=thk,linestyle=sty
	x = maken(x2,x2,num)	; East.
	y = maken(y1,y2,num)
	oplot,x,y,color=clr,thick=thk,linestyle=sty
	x = maken(x1,x2,num)	; North.
	y = maken(y2,y2,num)
	oplot,x,y,color=clr,thick=thk,linestyle=sty
	x = maken(x1,x1,num)	; West.
	y = maken(y1,y2,num)
	oplot,x,y,color=clr,thick=thk,linestyle=sty
 
        ;---  Deal with /xmode  ---
        if keyword_set(xmode) then device,set_graphic=mode

        ;---  Save this box  ---
        x10 = x1
        x20 = x2
        y10 = y1
        y20 = y2

	return
	end
