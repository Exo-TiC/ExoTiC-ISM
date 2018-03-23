;-------------------------------------------------------------
;+
; NAME:
;       TO_METERS
; PURPOSE:
;       Convert distances in selected units to meters.
; CATEGORY:
; CALLING SEQUENCE:
;       dm = to_meters(d)
; INPUTS:
;       d = Distance in some units.         in
; KEYWORD PARAMETERS:
;       Keywords:
;         UNITS=units Units for d.
;           Case ignored, only first 2 letters used.
;           Known units are:
;             nmiles = Nautical miles
;             miles = Statute miles
;             kms = Kilometers
;             meters (or m) = Meters
;             yards = Yards
;             feet (or foot) = Feet
;         keyword will over-ride embedded units.
; OUTPUTS:
;       dm = returned distance in meters.   out
; COMMON BLOCKS:
; NOTES:
;       Notes: Units may be included after distance value
;         instead of in UNITS if d is a string.  The UNITS
; MODIFICATION HISTORY:
;       R. Sterner, 2007 Dec 07
;       R. Sterner, 2008 Feb 04 --- Added UNITS keyword.
;       R. Sterner, 2010 Aug 13 --- Made floating for m or meters.
;       R. Sterner, 2011 Jul 11 --- Improved message if no units given.
;       R. Sterner, 2013 Feb 13 --- Allowed arrays.
;
; Copyright (C) 2007, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	function to_meters, d, units=units0, help=hlp
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Convert distances in selected units to meters.'
	  print,' dm = to_meters(d)'
	  print,'   d = Distance in some units.         in'
          print,'       May be an array.'
	  print,'   dm = returned distance in meters.   out'
	  print,' Keywords:'
	  print,'   UNITS=units Units for d.'
	  print,'     Case ignored, only first 2 letters used.'
	  print,'     Known units are:'
	  print,'       nmiles = Nautical miles'
	  print,'       miles = Statute miles'
	  print,'       kms = Kilometers'
	  print,'       meters (or m) = Meters'
	  print,'       yards = Yards'
	  print,'       feet (or foot) = Feet'
	  print,' Notes: Units may be included after distance value'
	  print,'   instead of in UNITS if d is a string.  The UNITS'
	  print,'   keyword will over-ride embedded units.'
          print,'   If d is an array of strings only the units (if any) of the'
          print,'   first element is used, the others are ignored.' 
          print,'   The UNITS keyword works when d is an array.'
	  return,''
	endif
 
	units = getwrd(d,1,99)				; Grab all but 1st word.
	if n_elements(units0) ne 0 then units=units0	; Use keyword if given.
	un = strlowcase(strmid(units,0,2))		; Look at 1st 2 chars.
 
	case un[0] of					; Convert other units.
'nm':     return, d*1852.
'mi':     return, d* 1609.344
'km':     return, d*1000.
'me':     return, d*1.
'm':      return, d*1.
'fe':     return, d*0.3048
'fo':     return, d*0.3048
'ya':     return, d*0.9144
'':     begin
          print,' to_meters: No units found, assuming meters.'
          return, d
        end
else:   begin
          print,' Error in to_meters: Unknown units: '+units
          print,'   Defaulting to meters.'
          return, d
        end
        endcase
 
	end
