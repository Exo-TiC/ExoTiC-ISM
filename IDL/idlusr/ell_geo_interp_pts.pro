;-------------------------------------------------------------
;+
; NAME:
;       ELL_GEO_INTERP_PTS
; PURPOSE:
;       Add points interpolated on a geodesic between array points.
; CATEGORY:
; CALLING SEQUENCE:
;       ell_geo_interp_pts, lng1, lat1, lng2, lat2
; INPUTS:
;       lng1, lat1 = Input lng and lat.   in
; KEYWORD PARAMETERS:
;       Keywords:
;         MAX=m  Max allowed separation in meters (def=1000).
;           If adjacent points are farther apart then
;           additional points are inserted between them
;           along a geodesic.
; OUTPUTS:
;       lng2, lat2 = output lng and lat.  out
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 2006 Feb 07
;       R. Sterner, 2010 May 04 --- Converted arrays from () to [].
;       R. Sterner, 2010 Dec 02 --- Returned interpolation indices.
;
; Copyright (C) 2006, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro ell_geo_interp_pts, x1, y1, x2, y2, max=mx, inin=inin, help=hlp
 
	if (n_params(0) lt 4) or keyword_set(hlp) then begin
	  print,' Add points interpolated on a geodesic between array points.'
	  print,' ell_geo_interp_pts, lng1, lat1, lng2, lat2'
	  print,'   lng1, lat1 = Input lng and lat.   in'
	  print,'   lng2, lat2 = output lng and lat.  out'
	  print,' Keywords:'
	  print,'   MAX=m  Max allowed separation in meters (def=1000).'
	  print,'     If adjacent points are farther apart then'
	  print,'     additional points are inserted between them'
	  print,'     along a geodesic.'
          print,'   ININ=indx Returned interpolation indices.  Use with the'
          print,'     interpolate routine to interpolate any array of values'
          print,'     (same size as lng1 and lat1) along the curve to match'
          print,'     the output curve (lng2 and lat2).  May also use to'
          print,'     interpolate multiple such arrays at once if they are'
          print,'     first merged together as columns of a 2-d array.  See'
          print,'     the help for the IDL interpolate routine for details.'
	  return
	endif
 
	;------------------------------------- 
	;  Set working values
	;------------------------------------- 
	if n_elements(mx) eq 0 then mx=1000.	; Max allowed sep in m.
 
	;------------------------------------- 
	;  Fill gaps
	;------------------------------------- 
	n = n_elements(x1)		; # pts in input curve.
	x2 = [0.D0]			; Seed values.
	y2 = [0.D0]
        indx = [0D0]                    ; Interpolation indices seed.

	for i=0,n-2 do begin		; Loop over given points.
	  ell_ll2rb, x1[i], y1[i], x1[i+1], y1[i+1], d, a1, a2
	  if d le mx then begin		; Next point close to last.
	    x2 = [x2,x1[i]]		; Just add to output array.
	    y2 = [y2,y1[i]]
            indx = [indx,i]
	  endif else begin		; Next point too far from last.
	    num = 1 + ceil(d/mx)	; Divide long segment into num points.
	    ell_rb2ll, x1[i], y1[i], maken(0,d,num), a1, lng2, lat2, azi2
	    x2 = [x2,lng2[0:num-2]]	; Add new points to output array.
	    y2 = [y2,lat2[0:num-2]]
            in0 = i+maken(0D0,1D0,num)  ; In between indices.
            indx = [indx,in0[0:num-2]]  ; Add all but last. 
	  endelse
	endfor

	x2 = [x2[1:*],x1[n-1]]		; Drop seed and add last point.
	y2 = [y2[1:*],y1[n-1]]
        inin = [indx[1:*],n-1]
 
	end
