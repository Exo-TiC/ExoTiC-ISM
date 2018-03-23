;-------------------------------------------------------------
;+
; NAME:
;       ELL_LL2RB
; PURPOSE:
;       For two points on an ellipsoid return range and bearing.
; CATEGORY:
; CALLING SEQUENCE:
;       ell_ll2rb, lon1, lat1, lon2, lat2, dist, azi1, azi2
; INPUTS:
;       lon1, lat1 = Point 1 geodetic long and lat (deg).  in
;       lon2, lat2 = Point 2 geodetic long and lat (deg).  in
; KEYWORD PARAMETERS:
; OUTPUTS:
;       dist = Distance along surface of ellipsoid (m).    out
;       azi1 = forward geodetic azimuth (pt1 to pt2, deg). out
;       azi1 = reverse geodetic azimuth (pt2 to pt1, deg). out
;         If point 2 eq point 1 then azi1, azi2 both returned as 0.
; COMMON BLOCKS:
; NOTES:
;       Notes: Use ellipsoid,set=name to set working ellipsoid.  Uses
;       T. Vincenty's method. Converted to IDL from FORTRAN code at
;       ftp://www.ngs.noaa.gov/pub/pcsoft/for_inv.3d/source/inverse.for
;       Example:
;         lon1 = 144.42486788D0 & lat1 = -37.95103341D0
;         lon2 = 143.92649552D0 & lat2 = -37.65282113D0
;         ell_ll2rb, lon1, lat1, lon2, lat2, dist, azi1, azi2
;         help, dist, azi1, azi2
;       Computed:
;         dist = 54972.271 meters
;         azi1 = 306.86816 deg
;         azi2 = 127.17363 deg
;       
;       Reference: Direct and Inverse Solutions of Geodesics on the
;       Ellipsoid with Applications of Nested Equations.
;       T. Vincenty, Survey Review XXII, 176, April 1975. p 88-93.
;       
;       The Vicenty formulae should be good over distances from a few
;       cm to nearly 20,000 km with millimeter accuracy.
;       ell_rb2ll is inverse.
;       ll2rb is spherical version.
; MODIFICATION HISTORY:
;       R. Sterner, 2001 Sep 04
;       R. Sterner, 2002 May 01 --- Generalized ellipsoid.
;       R. Sterner, 2006 Jan 10 --- Fixed minor error noted by Bob Jensen.
;       R. Sterner, 2006 Feb 07 --- Added to help text to avoid 0 distance.
;       R. Sterner, 2006 Mar 19 --- Added reference to help text.
;       R. Sterner, 2010 May 04 --- Converted arrays from () to [].
;       R. Sterner, 2011 Apr 26 --- Handled point 2 EQ point 1 (finally).
;       R. Sterner, 2011 Apr 26 --- Cleaned up the code some.
;       R. Sterner, 2014 Jun 10 --- Added fix by Rick Chapman to avoid a hang.
;
; Copyright (C) 2001, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro ell_ll2rb, lon1, lat1, lon2, lat2, dst, azi1, azi2, help=hlp
 
	if (n_params(0) lt 6) or keyword_set(hlp) then begin
	  print,' For two points on an ellipsoid return range and bearing.'
	  print,' ell_ll2rb, lon1, lat1, lon2, lat2, dist, azi1, azi2'
	  print,'   lon1, lat1 = Point 1 geodetic long and lat (deg).  in'
	  print,'   lon2, lat2 = Point 2 geodetic long and lat (deg).  in'
	  print,'   dist = Distance along surface of ellipsoid (m).    out'
	  print,'   azi1 = forward geodetic azimuth (pt1 to pt2, deg). out'
	  print,'   azi1 = reverse geodetic azimuth (pt2 to pt1, deg). out'
          print,'     If point 2 eq point 1 then azi1, azi2 both returned as 0.'
	  print," Notes: Use ellipsoid,set=name to set working ellipsoid.  Uses"
	  print," T. Vincenty's method. Converted to IDL from FORTRAN code at"
	  print,' ftp://www.ngs.noaa.gov/pub/pcsoft/for_inv.3d/source/inverse.for'
	  print,' Example:'
	  print,'   lon1 = 144.42486788D0 & lat1 = -37.95103341D0'
	  print,'   lon2 = 143.92649552D0 & lat2 = -37.65282113D0'
	  print,'   ell_ll2rb, lon1, lat1, lon2, lat2, dist, azi1, azi2'
	  print,'   help, dist, azi1, azi2'
	  print,' Computed:'
	  print,'   dist = 54972.271 meters'
	  print,'   azi1 = 306.86816 deg'
	  print,'   azi2 = 127.17363 deg'
	  print,' '
	  print,' Reference: Direct and Inverse Solutions of Geodesics on the'
	  print,' Ellipsoid with Applications of Nested Equations.'
	  print,' T. Vincenty, Survey Review XXII, 176, April 1975. p 88-93.'
	  print,' '
	  print,' The Vicenty formulae should be good over distances from a few'
	  print,' cm to nearly 20,000 km with millimeter accuracy.'
	  print,' ell_rb2ll is inverse.'
	  print,' ll2rb is spherical version.'
	  return
	endif
 
        ;-----------------------------------------------------------------------
        ;  Comments from the original FORTRAN code
        ;-----------------------------------------------------------------------
        ; *** SOLUTION OF THE GEODETIC INVERSE PROBLEM AFTER T.VINCENTY
        ; *** MODIFIED RAINSFORD'S METHOD WITH HELMERT'S ELLIPTICAL TERMS
        ; *** EFFECTIVE IN ANY AZIMUTH AND AT ANY DISTANCE SHORT OF ANTIPODAL
        ; *** STANDPOINT/FOREPOINT MUST NOT BE THE GEOGRAPHIC POLE
        ;
        ; *** A IS THE SEMI-MAJOR AXIS OF THE REFERENCE ELLIPSOID
        ; *** F IS THE FLATTENING (NOT RECIPROCAL) OF THE REFERENCE ELLIPSOID
        ; *** LATITUDES AND LONGITUDES IN RADIANS POSITIVE NORTH AND EAST
        ; *** FORWARD AZIMUTHS AT BOTH POINTS RETURNED IN RADIANS FROM NORTH
        ;
        ; *** PROGRAMMED FOR CDC-6600 BY LCDR L.PFEIFER NGS ROCKVILLE MD 18FEB75
        ; *** MODIFIED FOR IBM SYSTEM 360 BY JOHN G GERGEN NGS ROCKVILLE MD 7507
        ;-----------------------------------------------------------------------
 
        ;-----------------------------------------------------------------------
        ;  Deal with repeated points
        ;
        ;  w0 = Indices of points in lon2, lat2 that equal lon1, lat1.
        ;  cnt0 = Number of such points.
        ;  w1 = Indices of points in lon2, lat2 not equal to lon1, lat1.
        ;  cnt1 = Number of such points.
        ;  num = Number of points in lon2, lat2.
        ;-----------------------------------------------------------------------
        w0 = where((lon2 eq lon1) and (lat2 eq lat1), cnt0, comp=w1, ncomp=cnt1)
        num  = n_elements(lon2)
        if num eq 1 then begin          ; Keep scalars as scalars.
          dst  = 0.0D0
          azi1 = 0.0D0
          azi2 = 0.0D0
        endif else begin
          dst  = dblarr(num)
          azi1 = dblarr(num)
          azi2 = dblarr(num)
        endelse
        if cnt1 eq 0 then return        ; No points 2 NE point 1.
 
        ;-----------------------------------------------------------------------
	;  WGS84 constants (www.wgs84.com)
        ;    a = 6378137.0D0		Semimajor axis (m).
        ;    f = 1.D0/298.257223563D0	Flattening factor.
        ;-----------------------------------------------------------------------
	ellipsoid, get=ell		; Get working ellipsoid.
	a = ell.a			; Semimajor axis (m).
	f = 1.D0/ell.f1			; Flattening factor.
 
        ;-----------------------------------------------------------------------
	;  Initial values
        ;-----------------------------------------------------------------------
	dtor = !dpi/180D0		; Double degrees to radians.
	eps = 0.5D-13			; Tolerance.
	glon1 = lon1[w1]*dtor           ; Convert to radians.
	glat1 = lat1[w1]*dtor
	glon2 = lon2[w1]*dtor
	glat2 = lat2[w1]*dtor
 
	r = 1D0 - f
	tu1 = r*sin(glat1)/cos(glat1)
	tu2 = r*sin(glat2)/cos(glat2)
	cu1 = 1/sqrt(1+tu1*tu1)
	su1 = cu1*tu1
	cu2 = 1/sqrt(1+tu2*tu2)
	s = cu1*cu2
	baz = s*tu2
	faz = baz*tu1
	x = glon2 - glon1

        d = x  ; <-- Added by R. Sterner.  Part of Fix by Rick Chapman.
 
        ;-----------------------------------------------------------------------
	;  Iterate
        ;-----------------------------------------------------------------------
	repeat begin
	  sx = sin(x)
	  cx = cos(x)
	  tu1 = cu2*sx
	  tu2 = baz - su1*cu2*cx
	  sy = sqrt(tu1*tu1 + tu2*tu2)
	  cy = s*cx + faz
	  y = atan(sy,cy)
	  sa = s*sx/sy
	  c2a = -sa*sa + 1
	  cz = faz + faz
          ; FORTRAN was: if c2a gt 0 then cz=-cz/c2a + cy
	  w = where(c2a gt 0, cnt)
	  if cnt gt 0 then cz[w]=-cz[w]/c2a[w] + cy[w]
	  e = cz*cz*2 - 1
	  c = ((-3*c2a+4)*f+4)*c2a*f/16
          d_old = d     ; <-- Fix by Rick Chapman.
	  d = x
	  x = ((e*cy*c + cz)*sy*c + y)*sa
	  x = (1 - c)*x*f + glon2-glon1
	endrep until max(abs(d_old-x)) le eps   ; <--- Fix by Rick Chapman.
;	endrep until max(abs(d-x)) le eps
 
        ;-----------------------------------------------------------------------
	;  Finish up
        ;-----------------------------------------------------------------------
	faz = atan(tu1,tu2)
	baz = atan(cu1*sx, baz*cx-su1*cu2) + !dpi
	x = sqrt((1/r/r - 1)*c2a + 1) + 1
	x = (x-2)/x
	c = 1 - x
	c = (x*x/4 + 1)/c
	d = (0.375*x*x - 1)*x
	x = e*cy
	s = 1 - 2*e	; Corrected 2006 Jan 10 RES.  Was: s = 1 - e*e
	dst[w1] = ((((sy*sy*4 - 3)*s*cz*d/6 - x)*d/4 + cz)*sy*d + y)*c*a*r
 
	azi1[w1] = faz/dtor
        ; FORTRAN was: if azi1 lt 0 then azi1 = azi1 + 360
	w = where(azi1 lt 0, cnt) & if cnt gt 0 then azi1[w] = azi1[w] + 360
	azi2[w1] = baz/dtor
        ; FORTRAN was: if azi2 lt 0 then azi2 = azi2 + 360
	w = where(azi2 lt 0, cnt) & if cnt gt 0 then azi2[w] = azi2[w] + 360
 
	end
