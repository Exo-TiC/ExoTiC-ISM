;-------------------------------------------------------------
;+
; NAME:
;       ELL_DECPLACES
; PURPOSE:
;       Show size of decimal places at a given point.
; CATEGORY:
; CALLING SEQUENCE:
;       ell_decplaces, lon, lat
; INPUTS:
;       lon, lat = Location (deg).   in
; KEYWORD PARAMETERS:
;       Keywords:
;         OUT=txt Result returned in a text array.
;         FILE=file Name of text file to save results in.
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
;       Notes: For each decimal place in lon and lat shows distance.
; MODIFICATION HISTORY:
;       R. Sterner, 2009 Jan 09
;
; Copyright (C) 2009, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro ell_decplaces, lon1, lat1, file=file, out=txt, help=hlp
 
	if (n_params(0) lt 2) or keyword_set(hlp) then begin
	  print,' Show size of decimal places at a given point.'
	  print,' ell_decplaces, lon, lat'
	  print,'   lon, lat = Location (deg).   in'
	  print,' Keywords:'
	  print,'   OUT=txt Result returned in a text array.'
	  print,'   FILE=file Name of text file to save results in.'
	  print,' Notes: For each decimal place in lon and lat shows distance.'
	  return
	endif
 
	dec = ['1.       ', $
	       '.1       ', $
	       '.01      ', $
	       '.001     ', $
	       '.0001    ', $
	       '.00001   ', $
	       '.000001  ', $
	       '.0000001 ', $
	       '.00000001']
 
	tprint,/init
	tprint,' '
	tprint,' Size of each decimal place in lon and lat'
	tprint,' at lon = '+strtrim(lon1,2)+', lat = '+strtrim(lat1,2) 
 
	;---  Lon  ---
	tprint,' '
	tprint,' Lon:'
	for i=0,8 do begin
	  lon2 = lon1 + double(dec[i])
	  lat2 = lat1
	  ell_ll2rb, lon1, lat1, lon2,lat2, r, a1, a2
	  tprint,i,'  ',dec[i],'  ',$
	    from_meters(r,units='km'),' km  ',$
	    from_meters(r,units='m'),' m  ', $
	    from_meters(r,units='cm'),' cm  ', $
	    from_meters(r,units='miles'),' mi  ', $
	    from_meters(r,units='feet'),' fe  ', $
	    from_meters(r,units='inches'),' in', $
	    form='(i4,3A,6(G9.4,A))'
	endfor
 
	tprint,' '
	tprint,' Lat:'
	for i=0,8 do begin
	  lon2 = lon1
	  lat2 = lat1 + double(dec[i])
	  ell_ll2rb, lon1, lat1, lon2,lat2, r, a1, a2
	  tprint,i,'  ',dec[i],'  ',$
	    from_meters(r,units='km'),' km  ',$
	    from_meters(r,units='m'),' m  ', $
	    from_meters(r,units='cm'),' cm  ', $
	    from_meters(r,units='miles'),' mi  ', $
	    from_meters(r,units='feet'),' fe  ', $
	    from_meters(r,units='inches'),' in', $
	    form='(i4,3A,6(G9.4,A))'
	endfor
 
	if arg_present(txt) then begin
	  tprint,out=txt
	  return
	endif
	if n_elements(file) ne 0 then begin
	  tprint,save=file
	  return
	endif
	tprint,/print
 
	end
