;-------------------------------------------------------------
;+
; NAME:
;       WINLIN
; PURPOSE:
;       Make a weighting array with linear tapering for windowing.
; CATEGORY:
; CALLING SEQUENCE:
;       wt = winlin(sx,sy,wx,wy)
; INPUTS:
;       nx, ny = Dimensions of the output array.  in
;       wx, wy = tapering width in x and y.       in
; KEYWORD PARAMETERS:
; OUTPUTS:
;       wt = Returned weighting array.            out
;         The array is 1 in the interior and linearly tapers to
;         0 at the edges in bands wx wide in X at the left and
;         right sides, and wy wide at the bottom and top.
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 2008 Mar 31
;
; Copyright (C) 2008, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	function winlin, nx, ny, wx, wy, help=hlp
 
	if (n_params(0) lt 4) or keyword_set(hlp) then begin
	  print,' Make a weighting array with linear tapering for windowing.'
	  print,' wt = winlin(sx,sy,wx,wy)'
	  print,'   nx, ny = Dimensions of the output array.  in'
	  print,'   wx, wy = tapering width in x and y.       in'
	  print,'   wt = Returned weighting array.            out'
	  print,'     The array is 1 in the interior and linearly tapers to'
	  print,'     0 at the edges in bands wx wide in X at the left and'
	  print,'     right sides, and wy wide at the bottom and top.'
	  return, ''
	endif
 
	fx = ((nx/2-abs(findgen(nx)-nx/2))<wx)/wx
	fy = ((ny/2-abs(findgen(ny)-ny/2))<wy)/wy
	return, fx#fy
 
	end
