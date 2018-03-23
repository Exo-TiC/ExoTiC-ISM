;-------------------------------------------------------------
;+
; NAME:
;       XADJCIRC
; PURPOSE:
;       Interactively adjust one or more circles on an image.
; CATEGORY:
; CALLING SEQUENCE:
;       xadjcirc, rad
; INPUTS:
; KEYWORD PARAMETERS:
;       Keywords:
;         /NEW new circle.  Else use given radii and given center.
;            When using /NEW given radii may be fractions.
;         IX0=ix, IY0=iy  Center of circle (device coord).  in, out.
;            Input IX0, IY0 ignored when /NEW used.
;         /DOTTED show a dotted circle, else solid.
;         THICK=thk  Circle thickness (def=1).
;         /MAG or MAG=mag  Use a magnified cursor (def=5).
; OUTPUTS:
;       rad = array of circle radii (pixels).       in, out
; COMMON BLOCKS:
; NOTES:
;       Notes:  If /NEW drag open a circle using left mouse button.
;       Then left click on center or a circle to move.
;       Right click when done. If rad was a variable new radii will
;       be returned in rad.
; MODIFICATION HISTORY:
;       R. Sterner, 2003 Jul 24, 29
;       R. Sterner, 2004 Sep 14 --- Fixed ix0, iy0 return when /new.
;       R. Sterner, 2009 Jul 30 --- Added /dotted, thick=thk, /mag.
;
; Copyright (C) 2003, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro xadjcirc_update, s, ix0=ix0, iy0=iy0, ind=in, rad=rad, erase=erase
 
	if n_elements(ix0) eq 0 then ix0=s.ix0
	if n_elements(iy0) eq 0 then iy0=s.iy0
 
	if s.flag eq 1 then begin		; Erase last.
	  for i=0,s.nr-1 do begin
	    x2 = s.x*s.sclast*s.rad(i)+s.ix0
	    y2 = s.y*s.sclast*s.rad(i)+s.iy0
	    plots,/dev,x2,y2,color=s.c,thick=s.thk
	  endfor
	  plots,/dev,color=-1,s.ix0,s.iy0,psym=4
	  empty
	endif
 
	if keyword_set(erase) then return
 
	if n_elements(in) ne 0 then begin
	  s.rad(in) = rad
	endif
 
	for i=0,s.nr-1 do begin			; Plot new.
	  x2 = s.x*s.sc*s.rad(i)+ix0
	  y2 = s.y*s.sc*s.rad(i)+iy0
	  plots,/dev,x2,y2,color=s.c,thick=s.thk
	endfor
	plots,/dev,color=-1,ix0,iy0,psym=4
	empty
 
	s.ix0 = ix0
	s.iy0 = iy0
	s.sclast = s.sc
	s.flag = 1
 
	end
 
 
	;---------------------------------------------
	;  xadjcirc = Plot a set of circles.
	;---------------------------------------------
 
	pro xadjcirc, rad, ix0=ix, iy0=iy, new=new, help=hlp, $
	  dotted=dotted, thick=thk, mag=mag
 
	if keyword_set(hlp) then begin
	  print,' Interactively adjust one or more circles on an image.'
	  print,' xadjcirc, rad'
	  print,'   rad = array of circle radii (pixels).       in, out'
	  print,' Keywords:'
	  print,'   /NEW new circle.  Else use given radii and given center.'
	  print,'      When using /NEW given radii may be fractions.'
	  print,'   IX0=ix, IY0=iy  Center of circle (device coord).  in, out.'
	  print,'      Input IX0, IY0 ignored when /NEW used.'
	  print,'   /DOTTED show a dotted circle, else solid.'
	  print,'   THICK=thk  Circle thickness (def=1).'
	  print,'   /MAG or MAG=mag  Use a magnified cursor (def=5).'
	  print,' Notes:  If /NEW drag open a circle using left mouse button.'
	  print,' Then left click on center or a circle to move.'
	  print,' Right click when done. If rad was a variable new radii will'
	  print,' be returned in rad.'
	  return
	endif
 
	;-----  Test radii  -------
	if n_elements(rad) eq 0 then rad=[1.,.7, .3]
	if n_elements(thk) eq 0 then thk=1
	nr = n_elements(rad)
	sc = float(max(rad))
	rad = float(rad)/max(rad)
 
	;----  Make basic circle and plot colors  ----
	n = 100
	a = maken(0,360,n)
	r = maken(1.,1.,n)
	polrec,r,a,x,y,/deg
	if keyword_set(dotted) then begin
	  c = (indgen(n) mod 2)*tarclr(255,255,255)
	endif else begin
	  c = indgen(n)*tarclr(255,255,255)
	endelse
 
	;------  Graphics mode  --------
	device,set_graphics=6			; XOR mode.
	flag = 0				; Nothing to erase yet.
 
	;------  Save values in a structure  -------
	s = {rad:rad, nr:nr, ix0:0, iy0:0, x:x, y:y, flag:flag, c:c, $
	  sc:0.0,sclast:0.0, thk:thk}
 
	;------  Existing circles  --------
	if not keyword_set(new) then begin	; Given circles.
	  if n_elements(ix) eq 0 then ix0=sc else ix0=ix ; Use center if given.
	  if n_elements(iy) eq 0 then iy0=sc else iy0=iy
	  s.ix0 = ix0
	  s.iy0 = iy0
	  s.sc = sc
	  xadjcirc_update, s			; Update plot.
	  goto, edit
	endif
 
	;------  Mag cursor  -----------
	if keyword_set(mag) then begin
	  if mag eq 1 then mg=5 else mg=mag
	  magcrs,0,0,/init,mag=mg,state=ss
	endif
	if n_elements(ix0) eq 0 then begin
	  ix0 = 0
	  iy0 = 0
	endif
	if n_elements(ix1) eq 0 then begin
	  ix1 = 0
	  iy1 = 0
	endif
	if n_elements(ixc) eq 0 then begin
	  ixc = 0
	  iyc = 0
	endif
 
	;------  Pick center  ----------
	repeat begin
	  if keyword_set(mag) then $
	    magcrs,ix0,iy0,/dev,state=ss $
	    else cursor,ix0,iy0,/dev,/change
	endrep until !mouse.button ne 0
 
	if !mouse.button gt 1 then goto, done
 
	s.ix0 = ix0				; Center of circle.
	s.iy0 = iy0
 
	;------  Set radius  --------
	repeat begin
	  if keyword_set(mag) then $
	    magcrs,ix1,iy1,/dev,state=ss $
	    else cursor,ix1,iy1,/dev,/change
;	  cursor,ix1,iy1,/dev,/change
	  s.sc = sqrt((ix1-ix0)^2+(iy1-iy0)^2)	; Radial scale factor.
	  xadjcirc_update, s			; Update plot.
	endrep until !mouse.button ne 1
 
	;-----  Edit loop  --------------------
edit:
	while 1 do begin
 
	  ;-----  Select item to move  ----------
	  while 1 do begin
	    repeat begin				; Watch for a click.
	      if keyword_set(mag) then $
	        magcrs,ixc,iyc,/dev,state=ss $
	        else cursor,ixc,iyc,/dev,/change
;	      cursor,ixc,iyc,/dev,/change
	    endrep until !mouse.button ne 0		; Got a click.
	    if !mouse.button ne 1 then goto, done	; Not left click: Done.
	    r = sqrt((ixc-s.ix0)^2+(iyc-s.iy0)^2)	; Radius of click.
	    rtest = [0.,s.sc*s.rad]			; Possible radii.
	    d = abs(r-rtest)				; Distance from click.
	    w = where(d eq min(d))			; Find min dist.
	    if d(w(0)) lt 5 then break			; Close enough?
	  endwhile
 
	  iw = w(0)-1					; Selected item code.
 
	  ;-----  Move selected item  -----------
	  repeat begin
	    if keyword_set(mag) then $
	      magcrs,ixc,iyc,/dev,state=ss $
	      else cursor,ixc,iyc,/dev,/change
;	    cursor,ixc,iyc,/dev,/change
	    if iw lt 0 then begin			; Move the center.
	      xadjcirc_update,s,ix0=ixc,iy0=iyc		; Update plot.
	      ix = ixc
	      iy = iyc
	    endif else begin				; Move a circle.
	      r = sqrt((ixc-s.ix0)^2+(iyc-s.iy0)^2)	; New radius.
	      xadjcirc_update,s,ind=iw,rad=r/s.sc	; Update plot.
	    endelse
	  endrep until !mouse.button ne 1
 
	endwhile
 
done:	xadjcirc_update,s, /erase
	device,set_graphics=3	; Back to normal graphics mode.
	rad = round(s.rad*s.sc)	; Radii.
	ix = s.ix0		; Center.
	iy = s.iy0
 
	end
