;-------------------------------------------------------------
;+
; NAME:
;       ELL_POINT_MOV
; PURPOSE:
;       Find a point given range and azimuth from another point.
; CATEGORY:
; CALLING SEQUENCE:
;       p2 = ell_point_mov( p1, r, azi)
; INPUTS:
;       p1 = Starting point as a structure:   in
;            {lon:lon, lat:lat}.
;       r = Range in meters from p1.          in
;       azi = Azimuth from p1.                in
; KEYWORD PARAMETERS:
; OUTPUTS:
;       p2 = Resulting point as a structure:  out
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 2008 May 08
;
; Copyright (C) 2008, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	function ell_point_mov, p1, r, azi, help=hlp
 
	if (n_params(0) lt 3) or keyword_set(hlp) then begin
	  print,' Find a point given range and azimuth from another point.'
	  print,' p2 = ell_point_mov( p1, r, azi)'
	  print,'   p1 = Starting point as a structure:   in'
	  print,'        {lon:lon, lat:lat}.'
	  print,'   r = Range in meters from p1.          in'
	  print,'   azi = Azimuth from p1.                in'
	  print,'   p2 = Resulting point as a structure:  out'
	  return,''
	endif
 
	ell_rb2ll, p1.lon, p1.lat, r, azi, lon, lat
	return, {lon:lon, lat:lat}
 
	end
