;-------------------------------------------------------------
;+
; NAME:
;       TVHUE
; PURPOSE:
;       Display given 2-d array as specified hue in current image.
; CATEGORY:
; CALLING SEQUENCE:
;       tvhue, arr
; INPUTS:
;       arr = 2-d array to display.   in
; KEYWORD PARAMETERS:
;       Keywords:
;         HUE=h  Hue for array arr (def=0).
;         /SCALE scale image (all components together) to 0-255.
;         /CSCALE scale each color component to 0-255.
;         /CLIP  clip each color component to 255 before /scale.
;         WT=wt  Weight array arr before using (def=1).
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
;       Notes: /CSCALE overrides /CLIP.  /CLIP when used with
;         WT=wt may give the most expected results.
;         This is somewhat like using the channel keyword in the
;         TV command but a bit more general.
; MODIFICATION HISTORY:
;       R. Sterner, 2008 Jun 26
;
; Copyright (C) 2008, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro tvhue, arr, hue=h, scale=sc, cscale=csc, clip=cl, wt=wt, help=hlp
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Display given 2-d array as specified hue in current image.'
	  print,' tvhue, arr'
	  print,'   arr = 2-d array to display.   in'
	  print,' Keywords:'
	  print,'   HUE=h  Hue for array arr (def=0).'
	  print,'   /SCALE scale image (all components together) to 0-255.'
	  print,'   /CSCALE scale each color component to 0-255.'
	  print,'   /CLIP  clip each color component to 255 before /scale.'
	  print,'   WT=wt  Weight array arr before using (def=1).'
	  print,' Notes: /CSCALE overrides /CLIP.  /CLIP when used with'
	  print,'   WT=wt may give the most expected results.'
	  print,'   This is somewhat like using the channel keyword in the'
	  print,'   TV command but a bit more general.'
	  return
	endif
 
	;---  Defaults  ---
	if n_elements(h) eq 0 then h=0.
	if n_elements(wt) eq 0 then wt=1.
	nx = dimsz(arr,1)
	ny = dimsz(arr,2)
 
	;---  Split current screen window into color components  ---
	if !d.window ge 0 then begin
	  flag = 1		; Existing image.
	  if !d.x_size ne nx then flag=0 
	  if !d.y_size ne ny then flag=0 
	endif else begin	; No current image.
	  flag = 0		; No existing image.
	endelse
	if flag eq 1 then begin
	  img = tvrd(tr=3)		
	  img_split, img, rr, gg, bb
	endif else begin	; No current image.
	  rr = bytarr(nx,ny)
	  gg = rr
	  bb = rr
	endelse
 
	;---  Deal with given hue  ---
	color_convert,h,1,1,r,g,b,/hsv_rgb	; Hue to RGB.
	wt_r = r/255.				; RGB weights for hue.
	wt_g = g/255.
	wt_b = b/255.
 
	;---  Sum in new array  ---
	arr2 = arr*wt
	rr = rr + arr2*wt_r	; Merge array into output image.
	gg = gg + arr2*wt_g
	bb = bb + arr2*wt_b
 
	;---  Scale each color component  ---
	if keyword_set(csc) then begin
	  rr = bytscl(rr)
	  gg = bytscl(gg)
	  bb = bytscl(bb)
	endif
 
	;---  Clip each color component to 255  ---
	if keyword_set(cl) then begin
	  rr = rr<255
	  gg = gg<255
	  bb = bb<255
	endif
 
	;---  Merged image  ---
	img = [[[rr]],[[gg]],[[bb]]]
 
	;---  Scale all color components together ---
	if keyword_set(sc) then img=bytscl(img)
 
	;---  Display result  ---
	if flag eq 0 then img_disp,img else tv,tr=3,img
 
	end
