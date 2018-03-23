;-------------------------------------------------------------
;+
; NAME:
;       ELL_PLOT_PTARR
; PURPOSE:
;       Plot an array of points structures.
; CATEGORY:
; CALLING SEQUENCE:
;       ell_plot_ptarr, arr
; INPUTS:
;       arr = an array of point structures.   in
;         A point is a structure: {lon:lon,lat:lat}.
; KEYWORD PARAMETERS:
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
;       Notes: Plot keywords may be given.
; MODIFICATION HISTORY:
;       R. Sterner, 2008 Mar 29
;
; Copyright (C) 2008, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro ell_plot_ptarr, arr, _extra=extra, help=hlp
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Plot an array of points structures.'
	  print,' ell_plot_ptarr, arr'
	  print,'   arr = an array of point structures.   in'
	  print,'     A point is a structure: {lon:lon,lat:lat}.'
	  print,' Notes: Plot keywords may be given.'
	  return
	endif
 
	n = n_elements(arr)
 
	for i=0,n-2 do begin
	  ell_plot_pt, arr[i], arr[i+1], _extra=extra
	endfor
 
	end
