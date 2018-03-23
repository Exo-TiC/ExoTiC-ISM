;-------------------------------------------------------------
;+
; NAME:
;       ELL_GEO_PT_SEP
; PURPOSE:
;       Return geodesic separations of adjacent points in an array.
; CATEGORY:
; CALLING SEQUENCE:
;       ell_geo_pt_sep, x, y, d
; INPUTS:
;       x, y = Input lng and lat array.  in
; KEYWORD PARAMETERS:
;       Keywords:
;         /LIST list separations (m) between point pairs.
;         NAME=nam Option list of point names.
; OUTPUTS:
;       d = returned separations in m.   out
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 2006 Feb 07
;       R. Sterner, 2009 Jan 14 --- Handled the 0 distance case.
;       R. Sterner, 2009 Jan 15 --- Made double.
;       R. Sterner, 2010 May 04 --- Converted arrays from () to [].
;       R. Sterner, 2014 Jul 25 --- Now returns Azi and back Azi.
;
; Copyright (C) 2006, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro ell_geo_pt_sep, x, y, rr, name=name, list=list, $
      azi=azi, bazi=bazi, help=hlp
 
	if (n_params(0) lt 3) or keyword_set(hlp) then begin
	  print,' Return geodesic separations of adjacent points in an array.'
	  print,' ell_geo_pt_sep, x, y, d'
	  print,'   x, y = Input lng and lat array.  in'
	  print,'   d = returned separations in m.   out'
	  print,' Keywords:'
      print,'   AZI=azi    Returned forward azimuth between points.'
      print,'   BAZI=bazi  Returned back azimuth between points.'
	  print,'   /LIST list separations (m) between point pairs.'
	  print,'   NAME=nam Option list of point names.'
	  return
	endif
 
	;------  Compute separations between adjacent points  -----
	n = n_elements(x)
	rr   = dblarr(n-1)
    azi  = fltarr(n-1)
    bazi = fltarr(n-1)
	for i=0,n-2 do begin
	  if (x[i] eq x[i+1]) and (y[i] eq y[i+1]) then begin
	    d = 0
        a1 = 0.
        a2 = 180.
	  endif else begin
	    ell_ll2rb, x[i], y[i], x[i+1], y[i+1], d, a1, a2
	  endelse
	  rr[i]   = d
      azi[i]  = a1
      bazi[i] = a2
	endfor
 
	;------  List separations  -----
	if keyword_set(list) then begin
	  if n_elements(name) eq 0 then begin
	    dig = strtrim(fix(alog10(n))+1,2)
	    fmt = '(I'+dig+'.'+dig+')'
	    name = string(indgen(n),form=fmt)
	  endif
	  pair = name+' to '+name[1:*]
	  mxlen = max(strlen(pair))
	  print,' '
	  print,' Distances between pairs of points (m and nautical miles)'
	  for i=0,n-2 do begin
	    sep_m = rr[i]
	    txt_m = string(sep_m,form='(F12.3)')
	    txt_nmile = string(sep_m/1852D0,form='(F13.7)')
	    print,' '+pair[i]+spc(mxlen,pair[i]) + $
	    '  '+txt_m+'  '+txt_nmile
	  endfor
	endif
 
	end
