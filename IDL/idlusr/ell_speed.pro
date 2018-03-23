;-------------------------------------------------------------
;+
; NAME:
;       ELL_SPEED
; PURPOSE:
;       Compute speed and course between given points.
; CATEGORY:
; CALLING SEQUENCE:
;       ell_speed, lon,lat,tim, lon2,lat2,tim2,spd,crs
; INPUTS:
;       lon, lat = Input lon and lat array.  in
;       tim = Input time at each point (JS). in
; OUTPUTS:
;       lon2, lat2 = Output lon, lat at midpoints.  out
;       tim2 = Time at midpoints (JS).              out
;       spd = Speed (m/s) at midpoints.             out
;       crs = Course at midpoints.                  out
; COMMON BLOCKS:
; NOTES:  JS are Julian Seconds, seconds since 2000 Jan 1 0:00:00.
; MODIFICATION HISTORY:
;       R. Sterner, 2014 Jul 25
;
; Copyright (C) 2014, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro ell_speed, x, y, t, lonm, latm, timm, spdm, crsm, $
        speedp=spdp, coursep=crsp, help=hlp
 
	if (n_params(0) lt 3) or keyword_set(hlp) then begin
	  print,' Return speed and course given lon, lat, and time.'
	  print,' ell_speed, lon, lat, tim, lon2, lat2, tim2, sp, cr'
	  print,'   lon, lat = lon and lat array.       in'
      print,'   tim = time array in Julian Seconds. in'
	  print,'   lonm, latm = lon, lat at midpoints. out'
      print,'   timm = times at midpoints.          out'
      print,'   spdm = Speed at mipoints (m/s).     out'
      print,'   crsm = Course at mipoints.          out'
      print,' Keywords:'
      print,'   SPEEDP=spdp  Returned speed at each point (m/s).'
      print,'   COURSEP=crsp Returned course at each point.'
      print,'     The values on each end are not valid and should'
      print,'     not be used.  They are included to match the input'
      print,'     array sizes.'
	  return
	endif
 
	;---  Number of points in input  ---
	n = n_elements(x)

    ;---  Set up output arrays  ---
    lonm = fltarr(n-1)
    latm = fltarr(n-1)
    timm = dblarr(n-1)
    spdm = fltarr(n-1)
    crsm = fltarr(n-1)

    ;---  Loop over pairs of input points  ---
	for i=0,n-2 do begin
      x1 = x[i]         ; Point 1.
      y1 = y[i]
      x2 = x[i+1]       ; Point 2.
      y2 = y[i+1]
      t1 = t[i]         ; Time 1.
      t2 = t[i+1]       ; Time 2.
      tm = (t1+t2)/2.   ; Mid-time.
      ;---  Handle zero distance case  ---
	  if (x1 eq x2) and (y1 eq y2) then begin
	    d = 0
        a1 = 0.
        spd = 0.
        crs = 0.
        xm = x1
        ym = y1
      ;---  Non-zero distance case  ---
	  endif else begin
	    ell_ll2rb, x1, y1, x2, y2, d, a1, a2
        dt = t2 - t1
        spd = d/dt
        crs = a1
        ell_rb2ll, x1, y1, d/2., a1, xm, ym
	  endelse

      ;---  Save results  ---
      lonm[i] = xm
      latm[i] = ym
      timm[i] = tm
      spdm[i] = spd
      crsm[i] = crs

	endfor

    ;---  Return averaged speed and course at points  ---
    if arg_present(spdp) then begin
      spd = (spdm[1:*]+spdm)/2.
      polrec,1.,crsm,/deg,u,v
      ua = (u[1:*]+u)/2.
      va = (v[1:*]+v)/2.
      recpol,ua,va,r,crs,/deg
      spdp = [-1.,spd,-1.]
      crsp = [-1.,crs,-1.]
    endif
 
	end
