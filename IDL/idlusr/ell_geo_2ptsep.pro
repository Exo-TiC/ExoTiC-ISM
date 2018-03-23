;-------------------------------------------------------------
;+
; NAME:
;       ELL_GEO_2PTSEP
; PURPOSE:
;       Find distance between two points along a geodesic.
; CATEGORY:
; CALLING SEQUENCE:
;       d = ell_geo_2ptsep(p1, p2)
; INPUTS:
;       p1 = Point 1 on geodesic {lon:lon, lat:lat}. in
;       p2 = Point 2 on geodesic {lon:lon, lat:lat}. in
;         The points are in structures.
; KEYWORD PARAMETERS:
;       Keywords:
;         AZI1=a1 Returned azimuth from p1 to pm.
;         AZI2=a2 Returned azimuth from pm to p1.
; OUTPUTS:
;       d = Returned distance in meters.             out
; COMMON BLOCKS:
; NOTES:
;       Note: p1 and p2 may be the same point and this will
;         still work.  The routine ell_ll2rb will not handle
;         this case so use this instead.
; MODIFICATION HISTORY:
;       R. Sterner, 2008 May 28
;
; Copyright (C) 2008, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	function ell_geo_2ptsep, p1, p2, azi1=a1, azi2=a2, help=hlp
 
	if (n_params(0) lt 2) or keyword_set(hlp) then begin
	  print,' Find distance between two points along a geodesic.'
	  print,' d = ell_geo_2ptsep(p1, p2)'
	  print,'   p1 = Point 1 on geodesic {lon:lon, lat:lat}. in'
	  print,'   p2 = Point 2 on geodesic {lon:lon, lat:lat}. in'
	  print,'     The points are in structures.'
	  print,'   d = Returned distance in meters.             out'
	  print,' Keywords:'
	  print,'   AZI1=a1 Returned azimuth from p1 to pm.'
	  print,'   AZI2=a2 Returned azimuth from pm to p1.'
	  print,' Note: p1 and p2 may be the same point and this will'
	  print,'   still work.  The routine ell_ll2rb will not handle'
	  print,'   this case so use this instead.'
          return,''
        endif
 
	;---  Special case: same point  ---
	if (p1.lon eq p2.lon) and (p1.lat eq p2.lat) then begin
	  a1 = 0.
	  a2 = 0.
	  return, 0d0
	endif
 
	;---  Distance and direction from p1 to p2  ---
	ell_ll2rb, p1.lon,p1.lat, p2.lon,p2.lat,d,a1,a2
	return, d
 
	end
