;-------------------------------------------------------------
;+
; NAME:
;       MAP_OUTSIDE
; PURPOSE:
;       Color image points outside a map area.
; CATEGORY:
; CALLING SEQUENCE:
;       map_outside
; INPUTS:
; KEYWORD PARAMETERS:
;       Keywords:
;         COLOR=clr 24-bit color for area outside map (def=white).
;         INDICES=in 1-d indices of image pixels outside map area.
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
;       Note: Replacement for map_space.
; MODIFICATION HISTORY:
;       R. Sterner, 2008 Jun 24
;
; Copyright (C) 2008, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro map_outside, help=hlp, color=clr, indices=ind
 
	if keyword_set(hlp) then begin
	  print,' Color image points outside a map area.'
	  print,' map_outside'
	  print,'   All args are keywords.'
	  print,' Keywords:'
	  print,'   COLOR=clr 24-bit color for area outside map (def=white).'
	  print,'   INDICES=in 1-d indices of image pixels outside map area.'
	  print,' Note: Replacement for map_space.'
	  return
	endif
 
	;------  Default color  -------
	if n_elements(clr) eq 0 then clr=16777215
 
	;------  Check last plot type  --------
	if !x.type ne 3 then begin
	  print,' Warning in map_outside: last plot was not a map.'
	endif
 
	;------  Window size  ---------
	nx = !d.x_size
	ny = !d.y_size
 
	;------ Check all pixels  -------
	makexy,0,nx-1,1,0,ny-1,1,xx,yy
	tmp = convert_coord(xx,yy,/dev,/to_data)
	ix = tmp[0,*]
	iy = tmp[1,*]
	ind = where(finite(ix,/nan),cnt)
	if cnt eq 0 then return
 
	;------  Read and color image  ------
	img = tvrd(tr=3)
	img2 = img_clrw(img,ind,color=clr)	
	tv,tr=3,img2
 
	end
