;-------------------------------------------------------------
;+
; NAME:
;       EMBED
; PURPOSE:
;       Embed an array in a larger array.
; CATEGORY:
; CALLING SEQUENCE:
;       b = embed(a,w)
; INPUTS:
;       a = input array (2-d).                      in
;       w = number of elements to add around edge.  in
; KEYWORD PARAMETERS:
;       Keywords:
;         OUTPUT_SIZE=[nx,ny] Optional output array size
;           instead of giving w.  Input array will be centered
;           in the returned result.  w is not needed if this is used.
;           Only need to give a single value for a square output.
;         VALUE=v.  Value for added border (def=0).
;         IX0=ix0 IY0=iy0 Returned embed indices (pixels).
;           This is the lower left corner of the original image
;           in the output image.
;         IX1=ix1 IY1=iy1 Returned embed indices (pixels).
;           This is the upper right corner of the original image
;           in the output image.
;         /EDGE Extend original image edge pixels.
; OUTPUTS:
;       b = resulting larger array with a centered. out
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 13 Dec, 1990
;       R. Sterner, 2009 Sep 03 --- Added OUTPUT_SIZE, IX0, IY0.
;       R. Sterner, 2009 Sep 09 --- Added /EDGE.
;       R. Sterner, 2010 May 04 --- Converted arrays from () to [].
;
; Copyright (C) 1990, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
	function embed, a, dw0, value=val, output_size=outsz, help=hlp, $
	  ix0=ix0, iy0=iy0, ix1=ix1, iy1=iy1, edge=edge
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Embed an array in a larger array.'
	  print,' b = embed(a,w)'
	  print,'   a = input array (2-d).                      in'
	  print,'   w = number of elements to add around edge.  in'
	  print,'   b = resulting larger array with a centered. out'
	  print,' Keywords:'
	  print,'   OUTPUT_SIZE=[nx,ny] Optional output array size'
	  print,'     instead of giving w.  Input array will be centered'
	  print,'     in the returned result.  w is not needed if this is used.'
	  print,'     Only need to give a single value for a square output.'
	  print,'   VALUE=v.  Value for added border (def=0).'
	  print,'   IX0=ix0 IY0=iy0 Returned embed indices (pixels).' 
	  print,'     This is the lower left corner of the original image'
	  print,'     in the output image.'
	  print,'   IX1=ix1 IY1=iy1 Returned embed indices (pixels).' 
	  print,'     This is the upper right corner of the original image'
	  print,'     in the output image.'
	  print,'   /EDGE Extend original image edge pixels.'
	  return, -1
	endif
 
	;---  Get size and data type of input array  ---
	s = size(a)
	nx = s[1]
	ny = s[2]
	typ = s[s[0]+1]
 
	;---  default padding value is 0  ---
	if n_elements(val) eq 0 then val = 0
 
	;---  Given margin  ---
	if n_elements(outsz) eq 0 then begin
	  dw = dw0>0
	  b = make_array(nx+2*dw, ny+2*dw, type=typ, value=val)
	  b[dw,dw] = a
	  ix0=dw & iy0=dw
	endif else begin
	;---  Given output image size  ---
	  mx = outsz[0]
	  if n_elements(outsz) eq 1 then my=mx else my=outsz[1]
	  ix0 = floor((mx-nx)/2)
	  iy0 = floor((my-ny)/2)
	  b = make_array(mx, my, type=typ, value=val)
	  b[ix0,iy0] = a
	endelse
	ix1 = ix0 + nx - 1
	iy1 = iy0 + ny - 1
 
	;---  Extend edge pixels  ---
	if not keyword_set(edge) then return, b
 
	;---  Left side  ---
	b[0,0] = rebin(b[ix0,*],ix0,mx)
	;---  Right side  ---
	b[ix1+1,0] = rebin(b[ix1,*],mx-1-ix1,my)
	;---  Bottom  ---
	b[0,0] = rebin(b[*,iy0],mx,iy0)
	;---  Top  ---
	b[0,iy1+1] = rebin(b[*,iy1],mx,my-1-iy1)
 
	return, b
 
	end
