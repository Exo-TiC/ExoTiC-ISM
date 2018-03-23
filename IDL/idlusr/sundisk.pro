;-------------------------------------------------------------
;+
; NAME:
;       SUNDISK
; PURPOSE:
;       Compute solar disk coordinates as seen from anywhere.
; CATEGORY:
; CALLING SEQUENCE:
;       sundisk,time, elng, elat, hlng, hlat
; INPUTS:
;       time = UT time (JS or date/time string).           in
;       elng, elat = Ecliptic long,lat of observer (deg).  in
; KEYWORD PARAMETERS:
; OUTPUTS:
;       hlng, hlat = Heliographic long, lat of             out
;         solar disk center (deg).
; COMMON BLOCKS:
; NOTES:
;       Notes: example time in js:
;         js0=dt_tm_tojs('2005 aug 18 3:13')
;       To test find central disk heliographic coordinates
;       as viewed from earth using sunjs, which also gives
;       also central heliographic as seen from earth:
;         sunjs,js0,app_long=elngs,lat0=hlat0,long0=hlng0
;       Earth's longitude is 180 deg from sun's longitude:
;         elnge = elngs - 180.
;       Using sundisk:
;         sundisk,js0,elnge,0.,hlng,hlat
;       Compare: help,hlat0,hlat,hlng0,hlng
; MODIFICATION HISTORY:
;       R. Sterner, 2001 Jan 18
;	R. Sterner, 2001 Mar 07 --- Made longitude rel to earth.
;
; Copyright (C) 2001, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro sundisk, help=hlp, time, elng0, elat, hlng, hlat, $
	  absolute=absolute, debug=debug
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Compute solar disk coordinates as seen from anywhere.'
	  print,' sundisk,time, elng, elat, hlng, hlat'
	  print,'   time = UT time (JS or date/time string).           in'
	  print,'   elng, elat = Ecliptic long,lat of observer (deg).  in'
	  print,'     elng is relative to Earth: 0=current Earth long,'
	  print,'     elng > 0 along earth orbital direction.'
	  print,'   hlng, hlat = Heliographic long, lat of             out'
	  print,'     solar disk center (deg).'
	  print,' Keywords:'
	  print,'   /ABSOLUTE means inputs are absolute ecliptic longitude,'
	  print,'     else ecliptic longitude is relative to Earth-Sun line.'
	  print,'   /DEBUG means list values used to derive result.'
	  print," Notes: example time in js:"
	  print,"   js0=dt_tm_tojs('2005 aug 18 3:13')"
	  print,' To test find central disk heliographic coordinates'
	  print,' as viewed from earth using sunjs, which also gives'
	  print,' also central heliographic as seen from earth:'
	  print,"   sunjs,js0,app_long=elngs,lat0=hlat0,long0=hlng0"
	  print," Earth's longitude is 180 deg from sun's longitude:"
	  print,"   elnge = elngs - 180."
	  print," Using sundisk:"
	  print,"   sundisk,js0,elnge,0.,hlng,hlat"
	  print,' Compare: help,hlat0,hlat,hlng0,hlng'         
	  return
	endif
 
	;---------------------------------------------------
	;  Time.  Enter as Julian Seconds or as a date/time string.
	;---------------------------------------------------
	if datatype(time) eq 'STR' then js0=dt_tm_tojs(time) else js0=time
	jd = js2jd(js0)

	;---------------------------------------------------
	;  Convert relative to absolute longitude.
	;---------------------------------------------------
	if keyword_set(debug) then begin
	  print,' Computing heliocentric longitude and latitude for '+$
	  dt_tm_fromjs(js0)+' UT'
	endif
	if keyword_set(absolute) then begin
	  elng = elng0
	  if keyword_set(debug) then begin
	    print,' for absolute ecliptic long and lat of '+$
	      strtrim(elng,2)+', '+strtrim(elat,2)
	  endif
	endif else begin
	  sunjs,js0,app_long=elngsun,lat0=hlat0,long0=hlng0
	  elngearth = pmod(elngsun+180,360.)
	  elng = pmod(elngearth + elng0,360.)
	  if keyword_set(debug) then begin
	    print,' for ecliptic lat of '+strtrim(elat,2)+$
	      ' and relative ecliptic longitude of '+strtrim(elng0,2)
	    print,"   beyond Earth's ecliptic longitude."
	    print," Computed Sun's longitude is "+strtrim(elngsun,2)
	    print," Earth's longitude is Long_Sun + 180 deg = "+ $
	      strtrim(elngearth,2)
	    print,' The relative longitude of '+strtrim(elng0,2)+' converts to'
	    print,'   absolute ecliptic longitude of '+strtrim(elng,2)
	    print,' The heliocentric long, lat as seen from earth: '+$
	      strtrim(hlng0,2)+', '+strtrim(hlat0,2)
	  endif
	endelse 

	;---------------------------------------------------
	;  Solar values
	;  Celestial Longitude of the ascending node of
	;    the sun's equator is corrected for precession
	;    of the equinoxes.
	;  The solar rotation period is defined to be 25.38 days.
	;---------------------------------------------------
	inc = 7.25					; Inc of S. equator deg.
	k = 73.6667 + 1.3958333*((jd-2396758.)/36525.)  ; Lng of asc. node deg.
	rate = 360.d0/25.38d0	; Solar rotation in deg/day.
 
	;---------------------------------------------------
	;  Coordinate conversion
	;---------------------------------------------------
	ax1 = elng - k		; Deg beyond solar equat. asc node.
	az1 = 90.D0 - elat	; Deg from N. Ecliptic pole.
	polrec3d, 1D0, az1, ax1, /deg, x1, y1, z1
	rot_3d, 1, x1, y1, z1, inc, /deg, x2, y2, z2
	recpol3d, x2, y2, z2, r, az2, ax2, /deg
 
	;---------------------------------------------------
	;  Final Heliographic coordinates
	;---------------------------------------------------
	hlat = float(90. - az2)
	hlng = float(pmod(ax2-rate*(jd-2451543.380275D0), 360.))
 
	if keyword_set(debug) then begin
	  print,' The heliocentric long, lat as seen from target point: '+$
	    strtrim(hlng,2)+', '+strtrim(hlat,2)
	endif

	end
