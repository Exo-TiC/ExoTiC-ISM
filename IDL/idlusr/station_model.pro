;-------------------------------------------------------------
;+
; NAME:
;       STATION_MODEL
; PURPOSE:
;       Meteorology station plot (wind barbs, ...).
; CATEGORY:
; CALLING SEQUENCE:
;       station_model, x, y, knots, dir
; INPUTS:
;       x = Longitude array.                   in
;       y = Latitude array.                    in
;       knots = Array of wind speeds in knots. in
;       azi = Array of wind directions from.   in
; KEYWORD PARAMETERS:
;       Keywords:
;         COLOR=clr symbol color (def = !p.color).
;         SIZE=sz symbol size factor (def=1).
;         THICKNESS=thk symbol thickness (def=1).
;         CLOUDCOVER=cloud: 0=clear, 1=scattered, 2=broken,
;           3=overcast, 4=obscured, 5=missing.
;         FILL=fclr Fill station circle with color fclr.
;           Default is no fill.
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 2004 Dec 17
;       R. Sterner, 2008 Feb 21 --- Allowed station circle fill.
;       R. Sterner, 2010 Jun 09 --- Converted arrays from () to [].
;       R. Sterner, 2013 Apr 11 --- Correct for map grid rotation.
;       R. Sterner, 2013 May 03 --- Added azimuth range: DAZI1,DAZI2,DCOLOR.
;
; Copyright (C) 2004, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro station_model, x, y, knots, azi_from, size=sz, _extra=extra, $
	  cloudcover=cloud, fill=fclr, nomap=nomap, $
          dazi1=dazi1, dazi2=dazi2, dcolor=dclr, help=hlp
 
	if (n_params(0) lt 4) or keyword_set(hlp) then begin
	  print,' Meteorology station plot (wind barbs, ...).'
	  print,' station_model, x, y, knots, azi_from'
	  print,'   x = Longitude array.                       in'
	  print,'   y = Latitude array.                        in'
	  print,'   knots = Array of wind speeds in knots.     in'
	  print,'   azi_from = Array of wind directions from.  in'
	  print,' Keywords:'
	  print,'   COLOR=clr symbol color (def = !p.color).'
	  print,'   SIZE=sz symbol size factor (def=1).'
	  print,'   THICKNESS=thk symbol thickness (def=1).'
	  print,'   CLOUDCOVER=cloud: 0=clear, 1=scattered, 2=broken,'
	  print,'     3=overcast, 4=obscured, 5=missing.'
	  print,'   FILL=fclr Fill station circle with color fclr.'
	  print,'     Default is no fill.'
          print,'   DAZI1=dazi1 Degrees from azi_from #1.'
          print,'   DAZI2=dazi2 Degrees from azi_from #2.'
          print,'   DCOLOR=dclr Color to plot azi range indicators.'
          print,'     dazi1 and dazi2 can be used to display a range of'
          print,'     azimuths for the wind to show uncertainty.'
          print,'     To indicate a range dazi1 would typically be < 0 and'
          print,'     dazi2 > 0. dazi1 is the range in the -azi direction,'
          print,'     dazi2 is the range in the +azi direction.'
          print,'   /NOMAP Do not correct for map grid rotation angle.'
          print,'     The correction is applied by default if a map'
          print,'     projection is in effect.'
	  return
	endif
 
	if n_elements(sz) eq 0 then sz=1.
 
	;------------------------------------------
        ;  Correct for map grid rotation angle
        ;
        ;  From each wind barb point step toward
        ;  dir by a bit less than 1 km.  Convert
        ;  start and end points to device coords
        ;  and then find direction in device
        ;  coordinates.  This corrects for a non-
        ;  linear map grid.  Note, swapping x and
        ;  y in recpol gives azimuth.
	;------------------------------------------
        if (!x.type eq 3) and (not keyword_set(nomap)) then begin
          rb2ll, x, y, 1E-3, azi_from, /deg, x2, y2
          tmp = convert_coord(x,y,/data,/to_dev)
          ix = tmp[0,*] & iy = tmp[1,*]
          tmp = convert_coord(x2,y2,/data,/to_dev)
          ix2 = tmp[0,*] & iy2 = tmp[1,*]
          recpol,/deg,iy2-iy,ix2-ix,r,dir
        endif else dir=azi_from
 
	;------------------------------------------
	;  Deal with station circle outline color
	;  if circle is filled.
	;------------------------------------------
	if n_elements(fclr) ne 0 then begin
	  clr = !p.color
	  if n_elements(extra) gt 0 then begin
	    c = tag_value(extra,'color',minlen=3,err=err)
	    if err eq 0 then clr=c
	  endif
	endif
 
	;------------------------------------------
        ;  Deal with azimuth range
        ;    Set exists flags and plot color.
	;------------------------------------------
        dazi1_flag = n_elements(dazi1) ne 0
        dazi2_flag = n_elements(dazi2) ne 0
        if n_elements(dclr) eq 0 then dclr=!p.color

	;------------------------------------------
	;  Turtle object
	;------------------------------------------
	t = obj_new('rturtle', scale=sz*5., _extra=extra)
 
	;------------------------------------------
	;  Loop through arrays
	;------------------------------------------
	n = n_elements(x)
	for i=0, n-1 do begin
 
	  ;----  Set symbol center and orientation by wind direction  -----
	  t->set, ref=[x[i],y[i]],/data, orient=-dir[i]
 
	  ;----  Station circle -------
	  if n_elements(fclr) eq 0 then begin	; Unfilled (def).
	    t->circle, 1
	  endif else begin
	    t->circle,1,color=fclr,/fill,ocolor=clr,/outline  ; Filled.
	  endelse
          t.save                                ; Save location and direction.
 
	  ;-----  Cloud Cover  -----------
	  if n_elements(cloud) gt 0 then begin
	    case cloud[i] of
0:	    begin
	    end
1:	    begin
	      t->chord, 0, ang=0, /abs, radius=1
	    end
2:	    begin
	      t->chord, [-.3,.3], ang=0, /abs, radius=1
	    end
3:	    begin
	      t->circle, 1, /fill
	    end
4:	    begin
	      t->chord, 0, ang=40, /abs, radius=1
	      t->chord, 0, ang=-40, /abs, radius=1
	    end
5:	    begin
	      t->movetoxy, -.4,-.4,/abs
	      t->drawtoxy,-.4,.4,/abs
	      t->drawtoxy, 0,0,/abs
	      t->drawtoxy,.4,.4,/abs
	      t->drawtoxy,.4,-.4,/abs
	    end
else:
	    endcase
	  endif

          ;-----  Handle any direction range  ---
          delta = !null
          if dazi1_flag then delta=[delta,90-dazi1[i]]  ; Wind from 90.
          if dazi2_flag then delta=[delta,90-dazi2[i]]
          t.get, color=clr0             ; Save current color.
          t.set, color=dclr             ; Set delta color.
          foreach dd, delta do begin    ; Do any directions.
            t.set, ang=dd
            t.move, 1, 0
            t.draw, 6, 0
            t.restore
          endforeach
          t.set, color=clr0             ; Restore color.
 
	  ;-----  Start wind barb  -------
	  k = knots[i]			; Wind speed.
	  if k lt 1. then begin		; Calm.
	    t->circle, .5		; Inner circle.
	    continue
	  endif else begin		; Not calm.
	    t->movetoxy, 0, 1		; Staff.
	    t->draw, 6, 0		; Positioned at end of staff.
	  endelse
	  k = k+2.5			; Center wind ranges.
 
	  dy = 0.8			; Step in y between barbs.
	  bang = 120.			; Barb angle.
 
	  ;------  Pennants  ------------
	  np = fix(k/50.)		; # pennants.
	  k = k - 50.*np		; Remainder.
	  for j=1,np do begin		; Plot pennants.
	    t->movexy,2,0,/start	; Start pennant polygon.
	    t->draw,3,bang-270.,tox=0,/close,/fill	; Complete pennant.
	  endfor
	  if np gt 0 then t->movexy,0,-dy	; Next barb start.
	  t->set, ang=90		; Point toward local y.
 
	  ;------  Full barbs  --------
	  nb = fix(k/10.)		; # full barbs.
	  k = k - 10.*nb		; Remainder.
	  for j=1,nb do begin		; Plot full barbs.
	    t->save			; Save current poistion.
	    t->draw,3,bang-180.,tox=2	; Plot barb.
	    t->restore			; Back to saved position.
	    t->movexy,0,-dy		; Next barb start.
	    t->set, ang=90		; Point toward local y.
	  endfor
 
	  ;------  Half barbs  --------
	  nb2 = fix(k/5.)		; # full barbs.
	  k = k - 5.*nb2		; Remainder.
	  if nb2 gt 1 then begin
	    print,' Error in wind bards.'
	    break
	  endif
	  if nb2 eq 1 then t->draw,3,bang-180.,tox=1	; Plot half barb.
 
	endfor
 
	;------------------------------------------
	;  Clean up
	;------------------------------------------
	obj_destroy, t
 
	end
