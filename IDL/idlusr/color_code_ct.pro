;-------------------------------------------------------------
;+
; NAME:
;       COLOR_CODE_CT
; PURPOSE:
;       Color code data based on a color table.
; CATEGORY:
; CALLING SEQUENCE:
;       clr = color_code_ct(val)
; INPUTS:
;       val = Array of values to color code.   in
; KEYWORD PARAMETERS:
;       Keywords:
;         CLT=clt  IDL color table number (def=4).
;         VMIN=vmn, VMAX=vmx Restrict val to these limits
;           (def=min, max).
; OUTPUTS:
;       clr = Array of 24-bit color values.    out
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 2008 Sep 09, for Amir Najmi.
;       R. Sterner, 2010 Apr 30 --- Converted arrays from () to [].
;
; Copyright (C) 2008, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	function color_code_ct, val, vmin=v1, vmax=v2, clt=clt, help=hlp
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Color code data based on a color table.'
	  print,' clr = color_code_ct(val)'
	  print,'   val = Array of values to color code.   in'
	  print,'   clr = Array of 24-bit color values.    out'
	  print,' Keywords:'
	  print,'   CLT=clt  IDL color table number (def=4).'
	  print,'   VMIN=vmn, VMAX=vmx Restrict val to these limits'
	  print,'     (def=min, max).'
	  return, ''
	endif
 
	if n_elements(clt) eq 0 then clt=13
	if n_elements(v1) eq 0 then v1=min(val)
	if n_elements(v2) eq 0 then v2=max(val)
 
	loadct, clt
	tvlct,r,g,b,/get
 
	val2 = val>v1<v2
;	in = 255*(val2/max(val2))
	in = scalearray(val,v1,v2)>0<255
	rr = r[in] + 0
	gg = g[in] + 0
	bb = b[in] + 0
 
	n = n_elements(val)
	clr = lonarr(n)
	for i=0L,n-1 do clr[i]=tarclr(rr[i],gg[i],bb[i])
 
	return,clr
	end
