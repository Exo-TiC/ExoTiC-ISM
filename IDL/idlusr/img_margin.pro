;-------------------------------------------------------------
;+
; NAME:
;       IMG_MARGIN
; PURPOSE:
;       Add a margin to an image.
; CATEGORY:
; CALLING SEQUENCE:
;       out = img_margin(in, m, [ix1,ix2,iy1,iy2])
; INPUTS:
;       in = Input image.  May be 8 or 24 bit.       in
;       m = Size of margin to add.  May be [mx,my].  in
; KEYWORD PARAMETERS:
; OUTPUTS:
;       ix1,ix2,iy1,iy2 = Returned indices to pick   out
;         off original area:
;           in = out[ix1:ix2,iy1:iy2] ; For 8-bit.
;       out = Returned image with added margin.      out
; COMMON BLOCKS:
; NOTES:
;       Notes: The image itself is used to add the margins in a
;         way to avoid discontinuities.
; MODIFICATION HISTORY:
;       R. Sterner, 2009 Jul 09
;       R. Sterner, 2010 Oct 19 --- Added COLOR keyword.
;
; Copyright (C) 2009, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	function img_margin, a, m, ix1, ix2, iy1, iy2, color=clr, help=hlp
 
	if (n_params(0) lt 2) or keyword_set(hlp) then begin
	  print,' Add a margin to an image.'
	  print,' out = img_margin(in, m, [ix1,ix2,iy1,iy2])'
	  print,'   in = Input image.  May be 8 or 24 bit.       in'
	  print,'   m = Size of margin to add.  May be [mx,my].  in'
	  print,'   ix1,ix2,iy1,iy2 = Returned indices to pick   out'
	  print,'     off original area:'
	  print,'       in = out[ix1:ix2,iy1:iy2] ; For 8-bit.'
	  print,'   out = Returned image with added margin.      out'
          print,' Keywords:'
          print,'   COLOR=clr Color for added margin.  Default is to use'
          print,'     the image itself to add the margins.'
	  print,' Notes: The image itself is used to add the margins in a'
	  print,'   way to avoid discontinuities.'
	  return,''
	endif
 
	;---  deal with margin  ---
	if n_elements(m) eq 1 then begin
	  mx = m[0]
	  my = m[0]
	endif
	if n_elements(m) eq 2 then begin
	  mx = m[0]
	  my = m[1]
	endif
	if n_elements(mx) eq 0 then begin
	  print,' Error in img_margin: Margin must have 1 or 2 elements.'
	  return,a
	endif
 
	img_shape,a,tr=tr,nx=nx,ny=ny   ; Shape of input image.
	img_split,a,r,g,b		; R,G,B components of input.
 
	;---  Original area pick off indices  ---
	ix1 = mx
	ix2 = ix1 + nx - 1
	iy1 = my
	iy2 = iy1 + ny - 1
 
        ;---  Constant color margin  ---
        if n_elements(clr) gt 0 then begin
          big = img_make(mx+nx+mx,my+ny+my,true=tr,color=clr)
          c = img_insimg(big,a,xstart=mx,ystart=my)
          return, c
        endif

        ;---  Make margin using image itself  ---
	;---  Do stack in Y  ---
	ay = img_rotate(a,7)		; Flip image in Y.
	img_split,ay,r2,g2,b2		; R,G,B components of flipped.
	rb = [[r2],[r],[r2]]		; Stack in Y.
	gb = [[g2],[g],[g2]]
	bb = [[b2],[b],[b2]]
	b = img_merge(rb,gb,bb,tr=tr)	; Merge.
	jy1 = ny - my			; Y pickoff indices.
	jy2 = jy1 + my + ny + my - 1
	dy = jy2 - jy1 + 1		; Needed Y size.
	b = img_subimg(b,0,jy1,nx,dy)	; Pick off needed section.
 
	;---  Do stack in X  ---
	bx = img_rotate(b,5)		; Flip in X.
	img_split,b,r,g,b		; R,G,B components of Y stack.
	img_split,bx,r2,g2,b2		; R,G,B components of flipped.
	rc = [r2,r,r2]			; Stack in X.
	gc = [g2,g,g2]
	bc = [b2,b,b2]
	c = img_merge(rc,gc,bc,tr=tr)	; Merge.
	jx1 = nx - mx			; X pickoff indices.
	jx2 = jx1 + mx + nx + mx - 1
	dx = jx2 - jx1 + 1		; Needed X size.
	c = img_subimg(c,jx1,0,dx,dy)	; Pick off needed section.
 
	return, c
 
	end
