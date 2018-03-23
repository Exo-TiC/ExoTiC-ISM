;-------------------------------------------------------------
;+
; NAME:
;       CBAR2
; PURPOSE:
;       Make a color bar on screen.
; CATEGORY:
; CALLING SEQUENCE:
;       cbar2
; INPUTS:
; KEYWORD PARAMETERS:
;       Keywords:
;         VMIN=vmn  Minimum value of color bar parameter (def=0).
;         VMAX=vmx  Maximum value of color bar parameter (def=top).
;         CMIN=cmn  Color that represents vmn (def=0).
;         CMAX=cmx  Color that represents vmx (def=top).
;           where top = !d.table_size-1.
;         CCLIP=cc  Actual max color index allowed (def=!d.table_size-1)
;         /HORIZONTAL Colors vary horizontally (def).
;         /VERTICAL   Colors vary vertical.
;         /BOTTOM   Horizontal axis on bottom (def).
;         /TOP      Horizontal axis on top.
;         /RIGHT    Vertical axis on right (def).
;         /LEFT     Vertical axis on left.
;         /AXES_ONLY Plot only the axes and labels, no bar image.
;         COLOR=clr Color of axes and labels.  Use 24 bit color
;           value, may obtain from clr=tarclr(r,g,b,/c24).
;         /KEEP_SCALING Keep color bar axes scaling on exit.
;         LAST_IMAGE=z Return last color bar image.
;         LAST_POS=pos Return last position used.
;         LAST_XSAVE=xs Return last !x used.
;         LAST_YSAVE=xs Return last !y used.
;         LAST_PSAVE=xs Return last !p used.
;           If any LAST_* keywords used then other keywords are ignored.
;         XSAVE=xs, YSAVE=ys, PSAVE=ps returned original scaling.
;           Use /KEEP to plot in cbar coordinates (x=[0,1],y=[vmn,vmx]).
;           May then restore original scale: !x=xs & !y=ys & !p=ps
;         Plus all keywords accepted by PLOT.
; OUTPUTS:
; COMMON BLOCKS:
;       cbar2_com
; NOTES:
;       Notes: Bar is positioned using the POSITION keyword.
;         To display a title use TITLE and so on.
;         Almost the same as cbar with a few added options.
; MODIFICATION HISTORY:
;       R. Sterner, 2007 Sep 20 from cbar.pro.
;
; Copyright (C) 2007, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro cbar2, vmin=vmn, vmax=vmx, cmin=cmn, cmax=cmx, horizontal=hor, $
	  vertical=ver, top=top, bottom=bottom, left=left, right=right, $
	  position=pos, color=col, title=ttl, _extra=extra, keep_scaling=keep, $
	  charsize=csz, device=device, cclip=cclip, charthick=cthk, $
	  xsave=xsave, ysave=ysave, psave=psave, axes_only=axonly, $
	  last_image=zout, last_pos=posout, last_xsave=xsout, $
	  last_ysave=ysout, last_psave=psout, help=hlp
 
	common cbar2_com, last_z, dim, xsv, ysv, psv, last_ps
 
	if keyword_set(hlp) then begin
	  print,' Make a color bar on screen.'
	  print,' cbar2'
	  print,'   All arguments are keywords.'
	  print,' Keywords:'
	  print,'   VMIN=vmn  Minimum value of color bar parameter (def=0).'
	  print,'   VMAX=vmx  Maximum value of color bar parameter (def=top).'
	  print,'   CMIN=cmn  Color that represents vmn (def=0).'
	  print,'   CMAX=cmx  Color that represents vmx (def=top).'
	  print,'     where top = !d.table_size-1.'
	  print,'   CCLIP=cc  Actual max color index allowed (def=!d.table_size-1)'
	  print,'   /HORIZONTAL Colors vary horizontally (def).'
	  print,'   /VERTICAL   Colors vary vertical.'
	  print,'   /BOTTOM   Horizontal axis on bottom (def).'
	  print,'   /TOP      Horizontal axis on top.'
	  print,'   /RIGHT    Vertical axis on right (def).'
	  print,'   /LEFT     Vertical axis on left.'
	  print,'   /AXES_ONLY Plot only the axes and labels, no bar image.'
	  print,'   COLOR=clr Color of axes and labels.  Use 24 bit color'
	  print,'     value, may obtain from clr=tarclr(r,g,b,/c24).'
	  print,'   /KEEP_SCALING Keep color bar axes scaling on exit.'
	  print,'   LAST_IMAGE=z Return last color bar image.'
	  print,'   LAST_POS=pos Return last position used.' 
	  print,'   LAST_XSAVE=xs Return last !x used.' 
	  print,'   LAST_YSAVE=xs Return last !y used.' 
	  print,'   LAST_PSAVE=xs Return last !p used.' 
	  print,'     If any LAST_* keywords used then other keywords are ignored.'
	  print,'   XSAVE=xs, YSAVE=ys, PSAVE=ps returned original scaling.'
	  print,'     Use /KEEP to plot in cbar coordinates (x=[0,1],y=[vmn,vmx]).'
	  print,'     May then restore original scale: !x=xs & !y=ys & !p=ps'
	  print,'   Plus all keywords accepted by PLOT.'
	  print,' Notes: Bar is positioned using the POSITION keyword.'
 	  print,'   To display a title use TITLE and so on.'
	  print,'   Almost the same as cbar with a few added options.'
	  return
	endif
 
	;-------  Return last values  --------
	last_flag = 0
	if arg_present(zout) then begin
	  zout = reform(last_z,dim)
	  last_flag = 1
	endif
	if arg_present(posout) then begin
	  posout = last_ps
	  last_flag = 1
	endif
	if arg_present(xsout) then begin
	  xsout = xsv
	  last_flag = 1
	endif
	if arg_present(ysout) then begin
	  ysout = ysv
	  last_flag = 1
	endif
	if arg_present(psout) then begin
	  psout = psv
	  last_flag = 1
	endif
	if last_flag eq 1 then return
 
	;-------  Set defaults  ---------------
	if n_elements(vmn) eq 0 then vmn = 0.
	if n_elements(vmx) eq 0 then vmx = !d.table_size-1
	if n_elements(cmn) eq 0 then cmn = 0
	if n_elements(cmx) eq 0 then cmx = !d.table_size-1
	if n_elements(cclip) eq 0 then cclip = !d.table_size-1
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
	endif else begin			; Horizontal.
	  dim = [256,1]
	  x = [vmn,vmx]
	  y = [0,1]
	  ax = 1				; Bottom.
	  if keyword_set(top) then ax = 3	; Top.
	  if n_elements(pos) eq 0 then pos = [.2,.4,.8,.6]
	endelse
 
	;-----  Make bar  --------------
	z = reform(scalearray(maken(vmn,vmx,256),vmn,vmx,cmn,cmx),dim)<cclip
 
	;-----  Save values to return on a later call  ---
	last_z = reform(z,dim)
	xsave = !x	; Save incoming X/Y scaling.
	ysave = !y
	psave = !p
	xsv = xsave
	ysv = ysave
	psv = psave
	last_ps = pos
 
	;------  Plot bar  -------------
	tn = [' ',' ']
	plot, x,y,/xstyl,/ystyl,/nodata,/noerase,xticks=1,xtickn=tn,$
	  yticks=1,ytickn=tn,xminor=1,yminor=1,pos=pos, col=col, titl=ttl, $
	  chars=csz, xran=x, yran=y, device=device, charthick=cthk
 
	if not keyword_set(axonly) then imgunder, z
 
	plot, x,y,/xstyl,/ystyl,/nodata,/noerase,xticks=1,xtickn=tn,$
	  yticks=1,ytickn=tn,xminor=1,yminor=1,pos=pos, col=col, titl=ttl, $
	  chars=csz, xran=x, yran=y, device=device, charthick=cthk
 
	;--------  Axis  ------------
	case ax of
1:	axis,xaxis=0,/xstyl,chars=csz,col=col, charthick=cthk,_extra=extra
2:	axis,yaxis=1,/ystyl,chars=csz,col=col, charthick=cthk,_extra=extra
3:	axis,xaxis=1,/xstyl,chars=csz,col=col, charthick=cthk,_extra=extra
4:	axis,yaxis=0,/ystyl,chars=csz,col=col, charthick=cthk,_extra=extra
	endcase
 
	if keyword_set(keep) then return
	!x = xsave	; Restore incoming X/Y scaling.
	!y = ysave
	!p = psave
 
	return
 
	end
