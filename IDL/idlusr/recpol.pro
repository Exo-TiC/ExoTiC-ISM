;-------------------------------------------------------------
;+
; NAME:
;       RECPOL
; PURPOSE:
;       Convert 2-d rectangular coordinates to polar coordinates.
; CATEGORY:
; CALLING SEQUENCE:
;       recpol, x, y, r, a
; INPUTS:
;       x, y = vector in rectangular form.           in
; KEYWORD PARAMETERS:
;       Keywords:
;         /DEGREES means angle is in degrees, else radians.
; OUTPUTS:
;       r, a = vector in polar form: radius, angle.  out
; COMMON BLOCKS:
; NOTES:
;       Note: To get azimuth in degrees CW from north do:
;             recpol, y, x, r, a, /deg
;             If +X is due East, +Y is due North.
; MODIFICATION HISTORY:
;       R. Sterner. 18 Aug, 1986.
;       Johns Hopkins University Applied Physics Laboratory.
;       RES 13 Feb, 1991 --- added /degrees.
;       R. Sterner, 30 Dec, 1991 --- simplified.
;       R. Sterner, 25 May, 1993 --- Fixed atan (0,0) problem.
;       R. Sterner, 1999 May 03 --- Output angle in degrees now double.
;       R. Sterner, 2010 Mar 08 --- Angle datatype now depends on input.
;       R. Sterner, 2010 May 04 --- Converted arrays from () to [].
;       R. Sterner, 2011 Apr 15 --- Added a note on azimuth.
;
; Copyright (C) 1986, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
 
	pro recpol, x, y, r, a, help=hlp, degrees=degrees
 
	if (n_params(0) lt 4) or keyword_set(hlp) then begin
	  print,' Convert 2-d rectangular coordinates to polar coordinates.'
	  print,' recpol, x, y, r, a'
	  print,'   x, y = vector in rectangular form.           in'
	  print,'   r, a = vector in polar form: radius, angle.  out'
	  print,' Keywords:'
	  print,'   /DEGREES means angle is in degrees, else radians.'
          print,' Note: To get azimuth in degrees CW from north do:'
          print,'       recpol, y, x, r, a, /deg'
          print,'       If +X is due East, +Y is due North.'
	  return
	endif
 
	;----------------------------------------------------------------
	;  Find if incoming is float or double
	;----------------------------------------------------------------
	if size(/type,x) eq 5 then pi=!dpi else pi=!pi
 
	;----------------------------------------------------------------
	;  Angle complicated because atan won't take (0,0) and
	;  also because want to keep angle in 0 to 360 (2 pi) range.
	;----------------------------------------------------------------
	w = where((x ne 0) or (y ne 0), count)	; Where not both X,Y eq 0.
	a = x*0.				; Output angle array.
	if count gt 0 then a[w]=atan(y[w],x[w])	; Find angles.
	w = where(a lt 0, count)		; find A < 0 and fix.
	if count gt 0 then a[w]= a[w]+2*pi	; add 2 pi to angles < 0.
 
	r = sqrt(x^2 + y^2)			; Find radii.
 
;	if keyword_set(degrees) then a = a*!radeg
	if keyword_set(degrees) then a = a*180/pi
 
	return
	end
