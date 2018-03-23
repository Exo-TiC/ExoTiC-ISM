;-------------------------------------------------------------
;+
; NAME:
;       PLOT_RNGBOX
; PURPOSE:
;       Draw a range box on a plot.
; CATEGORY:
; CALLING SEQUENCE:
;       plot_rngbox, xrn, yrn
; INPUTS:
;       xrn = X range array.   in
;       yrn = Y range array.   in
; KEYWORD PARAMETERS:
;       Keywords:
;         COLOR=clr Plot color (def=!p.color).
;           -2 = Dashed B&W.
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 2008 Apr 23
;
; Copyright (C) 2008, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro plot_rngbox, xrn, yrn, color=clr, help=hlp
 
	if (n_params(0) lt 2) or keyword_set(hlp) then begin
	  print,' Draw a range box on a plot.'
	  print,' plot_rngbox, xrn, yrn'
	  print,'   xrn = X range array.   in'
	  print,'   yrn = Y range array.   in'
	  print,' Keywords:'
	  print,'   COLOR=clr Plot color (def=!p.color).'
	  print,'     -2 = Dashed B&W.'
	  return
	endif
 
	if n_elements(clr) eq 0 then clr=!p.color
	tmp = convert_coord(xrn,yrn,/data,/to_dev)
	ix = tmp[0,*]
	iy = tmp[1,*]
	ix1 = ix[0]
	iy1 = iy[0]
	idx = ix[1]-ix[0]+1
	idy = iy[1]-iy[0]+1
	tvbox,ix1,iy1,idx,idy,clr,/noerase
 
	end
