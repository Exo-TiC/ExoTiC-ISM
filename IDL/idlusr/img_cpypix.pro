;-------------------------------------------------------------
;+
; NAME:
;       IMG_CPYPIX
; PURPOSE:
;       Copy pixels from one 24-bit image to another.
; CATEGORY:
; CALLING SEQUENCE:
;       imgr = img_cpypix(imgs,imgd,w)
; INPUTS:
;       imgs = Source image.                 in
;       imgd = Destination image.            in
;       w = Array of 1-d indices to modify.  in
; KEYWORD PARAMETERS:
;       Keywords:
;         ERROR=err Error flag: 0=ok.  On error destination
;           image is returned.
; OUTPUTS:
;       imgr = Resulting image.              out
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 2009 Jun 16
;       R. Sterner, 2010 May 12 --- Converted arrays from () to [].
;
; Copyright (C) 2009, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	function img_cpypix, imgs, imgd, w, error=err,help=hlp
 
	if (n_params(0) lt 3) or keyword_set(hlp) then begin
	  print,' Copy pixels from one 24-bit image to another.'
	  print,' imgr = img_cpypix(imgs,imgd,w)'
	  print,'   imgs = Source image.                 in'
	  print,'   imgd = Destination image.            in'
	  print,'   w = Array of 1-d indices to modify.  in'
	  print,'   imgr = Resulting image.              out'
	  print,' Keywords:'
	  print,'   ERROR=err Error flag: 0=ok.  On error destination'
	  print,'     image is returned.'
	  return,''
	endif
 
	err = 0
 
	;-------  Check for valid input values  --------------
	if w[0] eq -1 then return, imgs
 
	;------  Split input image  ---------------
	img_split, imgs, rs, gs, bs, tr=trs	; Split source image.
	img_split, imgd, rd, gd, bd, tr=trd	; Split destination image.
	flags = trs gt 0			; 24-bit? 1=yes.
	flagd = trd gt 0			; 24-bit? 1=yes.
	flag_sum = flags + flagd		; Sum of flags.
 
	;------  Copy pixles specified by index array  -----------
	rd[w] = rs[w]				; Red channel (or 8-bit image).
	if flag_sum eq 0 then return, rd	; Both 8-bit.
	if flag_sum eq 1 then begin		; One 8-bit, other 24-bit.
	  err = 1				; Must both be 8 or 24 bit.
	  return, imgd				; Return destination image.
	endif
	gd[w] = gs[w]				; Green channel.
	bd[w] = bs[w]				; Blue channel.
 
	;-------  Merge color channels back into a 24-bit image  -------
	return, img_merge(rd,gd,bd,true=trd)
 
	end
