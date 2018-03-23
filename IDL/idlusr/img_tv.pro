;-------------------------------------------------------------
;+
; NAME:
;       IMG_TV
; PURPOSE:
;       Add an image with transparency to existing displayed image.
; CATEGORY:
; CALLING SEQUENCE:
;       img_tv, img, ix, iy
; INPUTS:
;       img = image to display (2-d or 3-d).               in
;         Parts of img to be displayed must be
;         scaled correctly.
;       ix, iy = optional image start position (def=0,0).  in
; KEYWORD PARAMETERS:
;       Keywords:
;         TRANS=tval Value in a to consider transparent (def=none).
;           If img is 2-d then tval must be a value in img.
;           If img is a 24-bit color image then tval must be
;           a 24-bit color value that occurs in img.
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
;       Notes: This routine makes it easier to insert an embedded
;         smaller image into a displayed image.  The image should
;         be ready for display in the non-transparent areas.  The
;         transparent value may be out of that range.  For 24-bit
;         color images give the 24-bit color value that is
;         transparent.  Works on the current window.
; MODIFICATION HISTORY:
;       R. Sterner, 2010 Feb 18
;
; Copyright (C) 2010, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro img_tv, a, ix, iy, trans=tval, help=hlp
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Add an image with transparency to existing displayed image.'
	  print,' img_tv, img, ix, iy'
	  print,'   img = image to display (2-d or 3-d).               in'
	  print,'     Parts of img to be displayed must be'
	  print,'     scaled correctly.'
	  print,'   ix, iy = optional image start position (def=0,0).  in'
	  print,' Keywords:'
	  print,'   TRANS=tval Value in a to consider transparent (def=none).'
	  print,'     If img is 2-d then tval must be a value in img.'
	  print,'     If img is a 24-bit color image then tval must be'
	  print,'     a 24-bit color value that occurs in img.'
	  print,' Notes: This routine makes it easier to insert an embedded'
	  print,'   smaller image into a displayed image.  The image should'
	  print,'   be ready for display in the non-transparent areas.  The'
	  print,'   transparent value may be out of that range.  For 24-bit'
	  print,'   color images give the 24-bit color value that is'
	  print,'   transparent.  Works on the current window.'
	  return
	endif
 
	;------------------------------------------------
	;  Defaults
	;------------------------------------------------
	if n_elements(ix) eq 0 then ix=0
	if n_elements(iy) eq 0 then iy=0
 
	;------------------------------------------------
	;  Read back the matching section of the screen
	;------------------------------------------------
	img_shape, a, nx=nx,ny=ny,tr=tr	; New image size and type.
	rx = nx < (!d.x_size - ix)	; Readable area in bounds.
	ry = ny < (!d.y_size - iy)
	b = tvrd(ix,iy,rx,ry,tr=3)	; Read as much as possible.
 
	;------------------------------------------------
	;  Transparency not given, show all
	;------------------------------------------------
	if n_elements(tval) eq 0 then begin
	  tv, a, ix, iy, true=tr	; Just show complete image.
	  return
	endif
 
	;------------------------------------------------
	;  Find visible parts of new image
	;  and insert into screen image
	;------------------------------------------------
	if tr eq 0 then begin		; 2-d image.
	  w = where(a ne tval, cnt)	; Look for transparent pixels.
	endif else begin		; 3-d image (24-bit color).
	  img_split,a,ar,ag,ab		; Split into components.
	  c = rgb2c(ar,ag,ab)		; Convert to 24-bit values.
	  w = where(c ne tval, cnt)	; Look for transparent pixels.
	endelse
 
	;------------------------------------------------
	;  Insert new image into screen image
	;------------------------------------------------
	img_split, b, br, bg, bb	; Split screen image.
	if tr eq 0 then begin		; 2-d image.
	  br[w] = a[w]
	  bg[w] = a[w]
	  bb[w] = a[w]
	endif else begin		; 3-d image (24-bit color).
	  br[w] = ar[w]			; Copy visible from new to screen.
	  bg[w] = ag[w]
	  bb[w] = ab[w]
	endelse
 
	;------------------------------------------------
	;  Display merged result
	;------------------------------------------------
	b2 = img_merge(br,bg,bb)
	tv, b2, ix, iy, tr=3
 
	end
