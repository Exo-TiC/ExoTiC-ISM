;-------------------------------------------------------------
;+
; NAME:
;       FROM_METERS
; PURPOSE:
;       Convert distances from meters to specified units.
; CATEGORY:
; CALLING SEQUENCE:
;       d = from_meters(dm)
; INPUTS:
;       dm = Distance in meters.     in
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
;             cm = Centimeters
;             inches = Inches
; OUTPUTS:
;       d = Distance in some units.  out
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 2008 Feb 04
;       R. Sterner, 2009 Jan 09 --- Added cm and in.
;
; Copyright (C) 2008, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	function from_meters, d, units=units, help=hlp
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Convert distances from meters to specified units.'
	  print,' d = from_meters(dm)'
	  print,'   dm = Distance in meters.     in'
	  print,'   d = Distance in some units.  out'
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
	  print,'       cm = Centimeters'
	  print,'       inches = Inches'
	  return,''
	endif
 
	if n_elements(units) eq 0 then units='m'	; Def = m.
	un = strlowcase(strmid(units,0,2))		; Look at 1st 2 chars.
 
	case un of				; Convert to other units.
'nm':     return, d/1852.
'mi':     return, d/ 1609.344
'km':     return, d/1000.
'me':     return, d
'm':      return, d
'fe':     return, d/0.3048
'fo':     return, d/0.3048
'ya':     return, d/0.9144
'cm':     return, d*100.
'in':     return, d*39.370079
else:   begin
          print,' Error in from_meters: Unknown units: '+units
          print,'   Defaulting to meters.'
          return, d
        end
        endcase
 
	end
