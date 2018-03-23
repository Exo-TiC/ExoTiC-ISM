;-------------------------------------------------------------
;+
; NAME:
;       ACT_CBAR
; PURPOSE:
;       Make a color bar for an absolute color table.
; CATEGORY:
; CALLING SEQUENCE:
;       act_cbar, vmin, vmax
; INPUTS:
;       vmin  Minimum value of color bar parameter.  in
;       vmax  Maximum value of color bar parameter.  in
;         Default bar range is original barmin, barmax.
;         Give 0,0 to get default.
; KEYWORD PARAMETERS:
;       Keywords:
;         /HORIZONTAL Colors vary horizontally (def).
;         /VERTICAL   Colors vary vertical.
;         /BOTTOM   Horizontal axis on bottom (def).
;         /TOP      Horizontal axis on top.
;         /RIGHT    Vertical axis on right (def).
;         /LEFT     Vertical axis on left.
;         SLOPE=slope, OFFSET=offset Convert color table units.
;           These keywords allow a single color table to be displayed
;           in different units by converting the original table units.
;           Color tables are defined in terms of colors at certain
;           values where the values are in some units.
;           Unit conversion: NEW = OLD*slope + offset
;           Avoid this for log color tables.
;           Be careful mixing this conversion with the NEWRANGE keyword.
;         UNITS=units Instead of giving SLOPE and OFFSET may give
;           units for some color tables that have units conversions.
;           For example, the color table act_temp_k.txt is an
;           absolute color table with the following units.
;           Set units to one of these: 'deg C', 'deg F', 'deg K'
;           This allows the same color table to be applied to an
;           array with values in the corresponding units.
;         NEWRANGE=nran The original color table as given by the
;           FILE keyword has a data range and a display range,
;           usually the same but need not be (the table might
;           also color out of range flag values for example).
;           Using the data as an absolute color table, only part
;           of the full color table range might cover the given
;           data array.  The same color table can be remapped to
;           a new range using the NEWRANGE keyword:
;             NEWRANGE=[data_lo, data_hi] which applies the
;           full display range to data_lo to data_hi.
;           To use only part of the original color table the desired
;           section may also be given:
;             NEWRANGE=[data_lo, data_hi, newmin, newmax]
;           which will use the colors between newmin and newmax
;           to color data in the range data_lo to data_hi, where
;           newmin and newmax refer to the original color table,
;           not the remapped color table.
;           To use the color table to autoscale the data do
;           NEWRANGE=[min(z),max(z)]  which makes the color table
;           relative.  The new scaling is not remembered on next
;           call so the original color table is not changed.
;           NEWRANGE=[0,0] uses the default color table range.
;         /CLIP clip data to specified range (see act_apply).
;         /KEEP_SCALING Keep color bar axes scaling on exit.
;         XSAVE=xs, YSAVE=ys, PSAVE=ps returned original scaling.
;           Use /KEEP to plot in cbar coordinates (x=[0,1],y=[vmn,vmx]).
;           May then restore original scale: !x=xs & !y=ys & !p=ps
;         Plus all keywords accepted by PLOT.
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
;       Notes: The color table is set using act_apply.
;         Bar is positioned using the POSITION keyword.
;         To display a title use TITLE and so on.
; MODIFICATION HISTORY:
;       R. Sterner, 2007 Dec 21
;       R. Sterner, 2008 Jan 15 --- Added a min eq max check.  No bar.
;       R. Sterner, 2008 May 21 --- Changed above test to give default bar.
;       R. Sterner, 2008 May 22 --- Added /CLIP.
;       R. Sterner, 2008 Jun 05 --- Fixed NEWRANGE when vmin & vmax = 0.
;       R. Sterner, 2008 Nov 25 --- Better help text for NEWRANGE.
;       R. Sterner, 2010 Jul 06 --- Added SLOPE=slope, OFFSET=offset for units conversion.
;       R. Sterner, 2010 Nov 11 --- Made this routine aware of log color tables.
;       R. Sterner, 2010 Nov 29 --- Added keyword /KEEP_SCALING, and [X|Y|P]SAVE.
;       R. Sterner, 2010 Dec 14 --- Fixed for the case vmn=vmx=0.
;       R. Sterner, 2010 Dec 14 --- If /clip given now clips given vmin,vmax to barmin,barmax.
;       R. Sterner, 2010 Dec 31 --- Added UNITS=units keyword.  Applied to barmin/max.
;       R. Sterner, 2011 Jan 02 --- Fixed the case with vmin, vmax = 0, 0.
;       R. Sterner, 2011 Jan 07 --- The no units case got broken, fixed.
;       R. Sterner, 2011 May 13 --- Made color bar values array be 5 pixels wide (was 2).
;                                   Was confusing img_shape.pro.
;       R. Sterner, 2012 Sep 21 --- Newrange now sets default if only 2 values given.
;       R. Sterner, 2012 Dec 04 --- Mentioned that NEWRANGE=[-1,-1] matches vmin, vmax.
;       R. Sterner, 2014 Apr 01 --- Fixed the case NEWRANGE=[0,0] to use default bar range.
;
; Copyright (C) 2007, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro act_cbar, vmn0, vmx0, horizontal=hor, $
	  vertical=ver, top=top, bottom=bottom, left=left, right=right, $
	  position=pos, color=col, title=ttl, _extra=extra,  $
	  charsize=csz, device=device, charthick=cthk, units=units, $
	  newrange=nran, clip=clip, help=hlp, slope=slope0, offset=offset0, $
          keep_scaling=keep, xsave=xsave, ysave=ysave, psave=psave
 
	if (n_params(0) lt 2) or keyword_set(hlp) then begin
	  print,' Make a color bar for an absolute color table.'
	  print,' act_cbar, vmin, vmax'
	  print,'   vmin  Minimum value of color bar parameter.  in'
	  print,'   vmax  Maximum value of color bar parameter.  in'
	  print,'     Default bar range is original barmin, barmax.'
	  print,'     Give 0,0 to get default.'
	  print,' Keywords:'
	  print,'   /HORIZONTAL Colors vary horizontally (def).'
	  print,'   /VERTICAL   Colors vary vertical.'
	  print,'   /BOTTOM   Horizontal axis on bottom (def).'
	  print,'   /TOP      Horizontal axis on top.'
	  print,'   /RIGHT    Vertical axis on right (def).'
	  print,'   /LEFT     Vertical axis on left.'
          print,'   SLOPE=slope, OFFSET=offset Convert color table units.'
          print,'     These keywords allow a single color table to be displayed'
          print,'     in different units by converting the original table units.'
          print,'     Color tables are defined in terms of colors at certain'
          print,'     values where the values are in some units.'
          print,'     Unit conversion: NEW = OLD*slope + offset'
          print,'     Avoid this for log color tables.'
          print,'     Be careful mixing this conversion with the NEWRANGE keyword.'
          print,'   UNITS=units Instead of giving SLOPE and OFFSET may give'
          print,'     units for some color tables that have units conversions.'
          print,'     For example, the color table act_temp_k.txt is an'
          print,'     absolute color table with the following units.'
          print,"     Set units to one of these: 'deg C', 'deg F', 'deg K'"
          print,'     This allows the same color table to be applied to an'
          print,'     array with values in the corresponding units.'
	  print,'   NEWRANGE=nran The original color table as given by the'
	  print,'     FILE keyword has a data range and a display range,'
	  print,'     usually the same but need not be (the table might'
	  print,'     also color out of range flag values for example).'
	  print,'     Using the data as an absolute color table, only part'
	  print,'     of the full color table range might cover the given'
	  print,'     data array.  The same color table can be remapped to'
	  print,'     a new range using the NEWRANGE keyword:'
	  print,'       NEWRANGE=[data_lo, data_hi] which applies the'
	  print,'     full display range to data_lo to data_hi.'
          print,'     To match vmin, vmax: NEWRNAGE=[-1,-1] works.'
	  print,'     To use only part of the original color table the desired'
	  print,'     section may also be given:'
	  print,'       NEWRANGE=[data_lo, data_hi, newmin, newmax]'
	  print,'     which will use the colors between newmin and newmax'
	  print,'     to color data in the range data_lo to data_hi, where'
	  print,'     newmin and newmax refer to the original color table,'
	  print,'     not the remapped color table.'
	  print,'     To use the color table to autoscale the data do'
	  print,'     NEWRANGE=[min(z),max(z)]  which makes the color table'
	  print,'     relative.  The new scaling is not remembered on next'
	  print,'     call so the original color table is not changed.'
          print,'     NEWRANGE=[0,0] uses the default color table range.'
	  print,'   /CLIP clip data to specified range (see act_apply).'
          print,'   /KEEP_SCALING Keep color bar axes scaling on exit.'
          print,'   XSAVE=xs, YSAVE=ys, PSAVE=ps returned original scaling.'
          print,'     Use /KEEP to plot in cbar coordinates (x=[0,1],y=[vmn,vmx]).'
          print,'     May then restore original scale: !x=xs & !y=ys & !p=ps'
	  print,'   Plus all keywords accepted by PLOT.'
	  print,' Notes: The color table is set using act_apply.'
	  print,'   Bar is positioned using the POSITION keyword.'
 	  print,'   To display a title use TITLE and so on.'
	  return
	endif
 
	;-------  Check for zero length data range  ------
	vmn = vmn0
	vmx = vmx0
        barmin = act_info('barmin')+0.
        barmax = act_info('barmax')+0.
 
        ;--------  Need to scale barmin and barmax before using  -----
        ;---  Involves slope, offset, units  ---
        if n_elements(slope0) ne 0 then slope=slope0
        if n_elements(offset0) ne 0 then offset=offset0
        ;---  Handle given UNITS=units  ----
        if n_elements(units) ne 0 then begin
          if (act_info('new_units'))[0] ne '' then begin
            new_units = act_info('new_units')
            slope_ctab = act_info('slope')
            offset_ctab = act_info('offset')
            w = where(units eq new_units,cnt)
            if cnt eq 1 then begin
              w = w[0]
              slope = slope_ctab[w] + 0.D0
              offset = offset_ctab[w] + 0.D0
            endif ; Requested units matches a color table units.
          endif ; Color table has new units.
        endif ; UNITS requested.
        if n_elements(slope) ne 0 then begin    ; Do units conversion.
          if n_elements(offset) eq 0 then offset=0.
          barmin = barmin*slope + offset        ; Convert data limits.
          barmax = barmax*slope + offset
        endif
 
	if vmn eq vmx then begin		; If no range use default.
	  vmn = barmin                          ; Default range.
	  vmx = barmax
	  if n_elements(nran) ge 2 then begin   ; Newrange sets new  default.
	    vmn = nran[0]
	    vmx = nran[1]
            if (vmn eq 0) and (vmx eq 0) then begin ; Handle case newrange=[0,0]
              vmn = barmin
              vmx = barmax
            endif
	  endif
	endif
 
        ;-------  Clip given vmin and vmax  --------
        if keyword_set(clip) then begin
          vmn = vmn>barmin
          vmx = vmx<barmax
        endif
 
        ;-------  Log or Linear?  -------
        log = act_info('log') + 0
        if log eq 1 then begin  ; LOG color table.
          vmn = alog10(vmn)
          vmx = alog10(vmx)
        endif
 
	;-------  Set defaults  ---------------
	if n_elements(col) eq 0 then col = !p.color
	if n_elements(ttl) eq 0 then ttl = ''
	if n_elements(csz) eq 0 then csz = !p.charsize
	if n_elements(cthk) eq 0 then cthk = !p.charthick
	if n_elements(device) eq 0 then device = 0
 
	;----  Set orientation dependent parameters  ----------
	if keyword_set(ver) then begin		; Vertical.
	  dim = [1,256]
	  x = [0,1]
	  y = [vmn,vmx]
	  ax = 2				; Right.
	  if keyword_set(left) then ax = 4	; Left.
	  if n_elements(pos) eq 0 then pos = [.4,.2,.6,.8]
          xlog = 0
          ylog = log
	endif else begin			; Horizontal.
	  dim = [256,1]
	  x = [vmn,vmx]
	  y = [0,1]
	  ax = 1				; Bottom.
	  if keyword_set(top) then ax = 3	; Top.
	  if n_elements(pos) eq 0 then pos = [.2,.4,.8,.6]
          xlog = log
          ylog = 0
	endelse
 
	;------  Plot bar  -------------
	xsave = !x	; Save incoming X/Y scaling.
	ysave = !y
	psave = !p
 
	tn = [' ',' ']
 
	;---  Start plot  ---
	plot, x,y,/xstyl,/ystyl,/nodata,/noerase,xticks=1,xtickn=tn,$
	  yticks=1,ytickn=tn,xminor=1,yminor=1,pos=pos, col=col, titl=ttl, $
	  chars=csz, xran=x, yran=y, device=device, charthick=cthk
 
	;---  Make bar  ---
	if keyword_set(ver) then begin		; Vertical.
	  px = round(!d.y_size*!y.window)	; Plot window Y size in pixels.
	  n = px[1] - px[0]			; # pixels in plot window.
	  makenxy,0,1,5,vmn,vmx,n,tt,zz		; zz = color bar ramp (Ver).
	endif else begin			; Horizontal.
	  px = round(!d.x_size*!x.window)	; Plot window X size in pixels.
	  n = px[1] - px[0]			; # pixels in plot window.
	  makenxy,vmn,vmx,n,0,1,5,zz,tt		; zz = color bar ramp (Hor).
	endelse
        if log eq 1 then zz=10^zz               ; Do if log color table.
 
	;---  Color bar and display it  ---
	img = act_apply(zz,newrange=nran,clip=clip,$
          slope=slope,offset=offset,units=units)
	imgunder, img
 
	;---  Plot axes over bar  ---
	plot, x,y,/xstyl,/ystyl,/nodata,/noerase,xticks=1,xtickn=tn,$
	  yticks=1,ytickn=tn,xminor=1,yminor=1,pos=pos, col=col, titl=ttl, $
	  chars=csz, xran=x, yran=y, device=device, charthick=cthk
 
	;--------  Axis  ------------
	case ax of
1:	axis,xaxis=0,/xstyl,chars=csz,col=col, charthick=cthk,_extra=extra, xlog=log
2:	axis,yaxis=1,/ystyl,chars=csz,col=col, charthick=cthk,_extra=extra, ylog=log
3:	axis,xaxis=1,/xstyl,chars=csz,col=col, charthick=cthk,_extra=extra, xlog=log
4:	axis,yaxis=0,/ystyl,chars=csz,col=col, charthick=cthk,_extra=extra, ylog=log
	endcase
 
        if keyword_set(keep) then return
	!x = xsave	; Restore incoming X/Y scaling.
	!y = ysave
	!p = psave
 
	return
 
	end
