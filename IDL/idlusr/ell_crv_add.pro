;-------------------------------------------------------------
;+
; NAME:
;       ELL_CRV_ADD
; PURPOSE:
;       Combine two curves orienting second if needed.
; CATEGORY:
; CALLING SEQUENCE:
;       ell_crv_add, lon_tot, lat_tot, lon_add, lat_add
; INPUTS:
;       lon_add, lat_add = Curve to merge in.     in
; KEYWORD PARAMETERS:
; OUTPUTS:
;       lon_tot, lat_tot = Curve being built up.  in, out
; COMMON BLOCKS:
; NOTES:
;       Notes: To curve lon_tot, lat_tot add lon_add, lat_add
;         to the end.  The first curve is assumed to have the
;         correct orientation, if not invalid results may be
;         returned.  The second curve will be reversed if needed.
; MODIFICATION HISTORY:
;       R. Sterner, 2009 Jan 15
;
; Copyright (C) 2009, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro ell_crv_add, lon_tot, lat_tot, lon_add, lat_add, help=hlp
 
	if keyword_set(hlp) then begin
	  print,' Combine two curves orienting second if needed.'
	  print,' ell_crv_add, lon_tot, lat_tot, lon_add, lat_add'
	  print,'   lon_tot, lat_tot = Curve being built up.  in, out'
	  print,'   lon_add, lat_add = Curve to merge in.     in'
	  print,' Notes: To curve lon_tot, lat_tot add lon_add, lat_add'
	  print,'   to the end.  The first curve is assumed to have the'
	  print,'   correct orientation, if not invalid results may be'
	  print,'   returned.  The second curve will be reversed if needed.'
	  return
	endif
 
	;---------------------------------------------
	;  Find best orientation for second curve
	;---------------------------------------------
	nt = n_elements(lon_tot)
	x0 = lon_tot[n-1]		; Last pt of tot.
	y0 = lat_tot[n-1]
	na = n_elements(lon_add)
	x1 = lon_add[0]			; First pt of add.
	y1 = lat_add[0]
	x2 = lon_add[na-1]		; Last pt of add.
	y2 = lat_add[na-1]
	ell_ll2rb, x0,y0, x1,y1, r1, a1
	ell_ll2rb, x0,y0, x2,y2, r2, a1
 
	;---------------------------------------------
	;  Merge curves, orient second curve if needed
	;---------------------------------------------
	if r2 lt r1 then begin
	  lon_tot = [lon_tot, reverse(lon_add)]
	  lat_tot = [lat_tot, reverse(lat_add)]
	endif else begin
	  lon_tot = [lon_tot, lon_add]
	  lat_tot = [lat_tot, lat_add]
	endelse
 
	end
 
