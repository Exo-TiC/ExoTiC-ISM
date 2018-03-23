;-------------------------------------------------------------
;+
; NAME:
;       PLOT_POSBOX
; PURPOSE:
;       Plot position box in window.
; CATEGORY:
; CALLING SEQUENCE:
;       plot_posbox, pos
; INPUTS:
;       pos = Position array = [xmn,ymn,xmx,ymx].   in
;         Default is last used position.
; KEYWORD PARAMETERS:
;       Keywords:
;         FILL=fclr  Fill color (def=no fill).
;         COLOR=clr  Outline color.
;         THICK=thk  Outline thickness.
;         /DEVICE  pos is in device coordinates (else normalzied).
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 2007 Feb 28
;       R. Sterner, 2008 Feb 21 ---  Defaulted pos to last plot pos.
;       R. Sterner, 2008 Mar 06 --- Added FILL=fclr.
;
; Copyright (C) 2007, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro plot_posbox, pos, device=dev, color=clr, thick=thk, $
	  fill=fill, help=hlp
 
	if keyword_set(hlp) then begin
	  print,' Plot position box in window.'
	  print,' plot_posbox, pos'
	  print,'   pos = Position array = [xmn,ymn,xmx,ymx].   in'
	  print,'     Default is last used position.'
	  print,' Keywords:'
	  print,'   FILL=fclr  Fill color (def=no fill).'
	  print,'   COLOR=clr  Outline color.'
	  print,'   THICK=thk  Outline thickness.'
	  print,'   /DEVICE  pos is in device coordinates (else normalzied).'
	  return
	endif
 
	if n_elements(clr) eq 0 then clr=!p.color
	if n_elements(thk) eq 0 then thk=!p.thick
 
	;---  pos was given  ---
	if n_elements(pos) gt 0 then begin
	  xmn = pos[0]
	  ymn = pos[1]
	  xmx = pos[2]
	  ymx = pos[3]
	  if not keyword_set(dev) then begin
	    xmn = fix(xmn*!d.x_size)
	    ymn = fix(ymn*!d.y_size)
	    xmx = fix(xmx*!d.x_size)
	    ymx = fix(ymx*!d.y_size)
	  endif
	;---  pos not given, use last  ---
	endif else begin
	  xmn = fix(!x.window[0]*!d.x_size)
	  xmx = fix(!x.window[1]*!d.x_size)
	  ymn = fix(!y.window[0]*!d.y_size)
	  ymx = fix(!y.window[1]*!d.y_size)
	endelse
 
	if n_elements(fill) ne 0 then begin
	  polyfill,/dev,[xmn,xmx,xmx,xmn,xmn],[ymn,ymn,ymx,ymx,ymn], $
	    color=fill
	endif
 
	plots,[xmn,xmx,xmx,xmn,xmn],[ymn,ymn,ymx,ymx,ymn], $
	  /device,col=clr,thick=thk
 
	end
