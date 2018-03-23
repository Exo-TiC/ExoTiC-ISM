;-------------------------------------------------------------
;+
; NAME:
;       IGLOBE
; PURPOSE:
;       Plot a globe.
; CATEGORY:
; CALLING SEQUENCE:
;       iglobe, y0, x0, a0
; INPUTS:
;       y0 = Central latitude (deg).  Def=0.        in
;       x0 = Central longitude (deg). Def=0.        in
;       a0 = Angle to rotate globe CW (deg). Def=0. in
; KEYWORD PARAMETERS:
;       Keywords:
;         WATER=[r,g,b]  Color for water as R,G,B.
;         LAND =[r,g,b]  Color for land as R,G,B.
;         BACK =[r,g,b]  Color for background as R,G,B.
;         COAST=[r,g,b]  Color for Coastlines as R,G,B.
;         CGRID=[r,g,b]  Color for Grid as R,G,B.
;         /GRID  display a grid.
;         HOR=0  do not plot horizon (def is plot horizon).
;         /COUNTRIES Plot boundaries for countries.
;         /NOCOLOR Draw black on white background.
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 1999 Oct 06 as an ION example routine
;       R. Sterner, 1999 Oct 10 --- Fixed GRID and added /NOCOLOR.
;       R. Sterner, 1999 Oct 10 --- High res version.
;
; Copyright (C) 1999, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
	pro iglobe_h, y00, x00, a00, water=wtrc, land=lndc, back=bckc, $
	  coast=cstc, countries=countries, grid=grid, nocolor=nocolor, $
	  cgrid=grdc, hor=hor, help=hlp
 
	if keyword_set(hlp) then begin
	  print,' Plot a globe.'
	  print,' iglobe, y0, x0, a0'
	  print,'   y0 = Central latitude (deg).  Def=0.        in'
	  print,'   x0 = Central longitude (deg). Def=0.        in'
	  print,'   a0 = Angle to rotate globe CW (deg). Def=0. in'
	  print,' Keywords:'
	  print,'   WATER=[r,g,b]  Color for water as R,G,B.'
	  print,'   LAND =[r,g,b]  Color for land as R,G,B.'
	  print,'   BACK =[r,g,b]  Color for background as R,G,B.'
	  print,'   COAST=[r,g,b]  Color for Coastlines as R,G,B.'
	  print,'   CGRID=[r,g,b]  Color for Grid as R,G,B.'
	  print,'   /GRID  display a grid.'
	  print,'   HOR=0  do not plot horizon (def is plot horizon).'
	  print,'   /COUNTRIES Plot boundaries for countries.'
	  print,'   /NOCOLOR Draw black on white background.'
	  return
	endif
 
	;--------  Define view  ------------------------
	if n_elements(x00) eq 0 then x00=0
	if n_elements(y00) eq 0 then y00=0
	if n_elements(a00) eq 0 then a00=0
	x0 = pmod(x00,360)
	y0 = y00>(-90)<90
	a0 = a00 mod 360
	if n_elements(hor) eq 0 then hor=1
 
	;---------  Define colors  ---------------------
	if n_elements(bckc) eq 0 then bckc=[255,255,255]	; 0
	if n_elements(cstc) eq 0 then cstc=[000,000,000]	; 1
	if n_elements(wtrc) eq 0 then wtrc=[180,255,255]	; 2
	if n_elements(lndc) eq 0 then lndc=[255,225,205]	; 3
	if n_elements(grdc) eq 0 then grdc=[200,200,200]	; 4
 
	if keyword_set(nocolor) then begin
	  bck = tarclr([255,255,255],set=0)
	  cst = tarclr([0,0,0],set=1)
	  wtr = tarclr([255,255,255],set=2)
	  lnd = tarclr([255,255,255],set=3)
	  grd = tarclr([200,200,200],set=4)
	endif else begin
	  bck = tarclr(bckc,set=0)
	  cst = tarclr(cstc,set=1)
	  wtr = tarclr(wtrc,set=2)
	  lnd = tarclr(lndc,set=3)
	  grd = tarclr(grdc,set=4)
	endelse
 
	;---------  Plot globe  ------------------------
	erase, bck
	map_set,y0,x0,a0,hor=hor,/iso,/cont,/orth, col=cst,/nobord,/noerase, $
            e_hor={fill:1,color:wtr},e_cont={fill:1,color:lnd, hires:1}
	map_set,y0,x0,a0,hor=hor,/iso,/cont,/orth, col=cst,/nobord, $
	    /hires,/noerase
 
	if keyword_set(grid) then begin
          xx = maken(0,360,181)
          for y=-90,90,30 do begin
            yy = maken(y,y,181)
            plots,xx,yy,col=grd   
          endfor
          yy = maken(-90,90,91)
          for x=0,330,30 do begin
            xx = maken(x,x,91)
            plots,xx,yy,col=grd
          endfor
          map_set,y0,x0,a0,hor=hor,/iso,/orth,/nobord,/noerase,/cont,$
	    /hires,color=cst
	endif
 
	if keyword_set(countries) then begin
          map_continents,/coasts, color=cst
          map_continents,/countries,/usa,/hires, color=cst
	endif
 
	end
