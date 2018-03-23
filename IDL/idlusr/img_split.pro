;-------------------------------------------------------------
;+
; NAME:
;       IMG_SPLIT
; PURPOSE:
;       Returns the color components of a color image.
; CATEGORY:
; CALLING SEQUENCE:
;       img_split, img, c1, c2, c3
; INPUTS:
;       img = Input image.  in
; KEYWORD PARAMETERS:
;       Keywords:
;         /HSV means return HSV color components (def RGB).
;         TRUE=tr Returned interleave dimension (0 means 2-D image).
;           May send this in for cases that are ambiguous.
;         NX=nx, NY=ny Returned image dimensions.
;         ALPHA=a Returned alpha channel if any (else -1).
;           0 is full transparency, 255 is no transparency.
;         ERROR=err error flag: 0=ok, 1=not 2-D or 3-D,
;           2=wrong number of color channels for 3-D array.
;           3=Ambiguous, cannot determine interleave dimension.
; OUTPUTS:
;       c1 = component 1.   out
;       c2 = component 2.   out
;       c3 = component 3.   out
;          By default c1,c2,c3 = Red, Green, Blue.
;          /HSV requests Hue, Saturation, Value.
; COMMON BLOCKS:
; NOTES:
;       Note: Deals with 2-D or 3-D image arrays.
;         A 1-D array is treated like a NX x 1 array.
; MODIFICATION HISTORY:
;       R. Sterner, 2001 Mar 27
;       R. Sterner, 2001 Jun 18 --- Renamed from img_rgb.pro
;       R. Sterner, 2001 Jun 21 --- Renamed from img_splitrgb.pro
;       R. Sterner, 2001 Jun 21 --- Added new keyword /HSV.
;       R. Sterner, 2010 May 04 --- Converted arrays from () to [].
;       R. Sterner, 2010 Sep 08 --- Now allows 1-D arrays.
;       R. Sterner, 2011 May 12 --- Handled Alpha channel.
;       R. Sterner, 2011 Jul 18 --- Rewrote the interleave finder.
;       R. Sterner, 2011 Jul 18 --- Allowed TRUE=tr to be given.
;       R. Sterner, 2012 Jan 24 --- Make sure nch is defined.
;
; Copyright (C) 2001, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro img_split, img, r, g, b, true=typ, nx=nx, ny=ny, $
	  hsv=hsv, alpha=a, error=err, help=hlp
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Returns the color components of a color image.'
	  print,' img_split, img, c1, c2, c3'
	  print,'   img = Input image.  in'
	  print,'   c1 = component 1.   out'
	  print,'   c2 = component 2.   out'
	  print,'   c3 = component 3.   out'
	  print,'      By default c1,c2,c3 = Red, Green, Blue.'
	  print,'      /HSV requests Hue, Saturation, Value.'
	  print,' Keywords:'
	  print,'   /HSV means return HSV color components (def RGB).'
	  print,'   TRUE=tr Returned interleave dimension (0 means 2-D image).'
	  print,'     May send this in for cases that are ambiguous.'
	  print,'   NX=nx, NY=ny Returned image dimensions.'
          print,'   ALPHA=a Returned alpha channel if any (else -1).'
          print,'     0 is full transparency, 255 is no transparency.'
	  print,'   ERROR=err error flag: 0=ok, 1=not 2-D or 3-D,'
	  print,'     2=wrong number of color channels for 3-D array.'
	  print,'     3=Ambiguous, cannot determine interleave dimension.'
	  print,' Note: Deals with 2-D or 3-D image arrays.'
          print,'   A 1-D array is treated like a NX x 1 array.'
	  return
	endif
 
	err = 0         ; Error flag.
        a = -1          ; Assume no alpha channel.
 
	;--------  Find image dimensions  --------------
	sz = size(img)
	ndim = sz[0]
	if ndim gt 3 then begin
	  err = 1
	  print,' Error in img_split: given array has more than 3 dimensions.'
	  return
	endif
 
	;--------  1-D image  --------------------------
	if ndim eq 1 then begin
	  r = img	; Assume gray scale, all same.
	  g = img
	  b = img
	  typ = 0
	  nx = sz[1]
	  ny = 1L
	  goto, done
	endif
 
	;--------  2-D image  --------------------------
	if ndim eq 2 then begin
	  r = img	; Assume gray scale, all same.
	  g = img
	  b = img
	  typ = 0
	  nx = sz[1]
	  ny = sz[2]
	  goto, done
	endif
 
	;--------------------------------------------------------
	;  3-D image
	;
	;  Try to determine interleave dimension.  This is
	;  not always possible. For example, if dimensions
	;  are [3,100,3], or [3,4,5]. In such cases set TRUE=tr
	;  to the correct value.
	;--------------------------------------------------------
	nch = 0			                ; Assume error.
	if n_elements(typ) eq 0 then begin	; Try to find true.
	  szd = size(img,/dim)			; Dimensions.
	  w3 = where(szd eq 3,cnt3)		; Look for a 3.
	  if cnt3 gt 1 then begin		; More than one 3, not good.
	    err = 3
	    print,' Error in img_split: Cannot determine interleave dimension.'
	    print,' Image dimensions:',strtrim(szd,2)
	    whocalledme,pdir,pfil,line=plin
	    print,' Called from '+pdir+pfil+'  line '+strtrim(plin,2)
	    return
	  endif
	  w4 = where(szd eq 4,cnt4)		; Look for a 4.
	  if cnt4 gt 1 then begin		; More than one 4, not good.
	    err = 3
	    print,' Error in img_split: Cannot determine interleave dimension.'
	    print,' Image dimensions:',strtrim(szd,2)
	    whocalledme,pdir,pfil,line=plin
	    print,' Called from '+pdir+pfil+'  line '+strtrim(plin,2)
	    return
	  endif
	  if (cnt3 eq 1) and (cnt4 eq 1) then begin  ; One 3 and one 4, bad.
	    err = 3
	    print,' Error in img_split: Cannot determine interleave dimension.'
	    print,' Image dimensions:',strtrim(szd,2)
	    whocalledme,pdir,pfil,line=plin
	    print,' Called from '+pdir+pfil+'  line '+strtrim(plin,2)
	    return
	  endif
;	  nch = 0			  ; Assume error.
	  if cnt3 eq 1 then nch=3	  ; Was 3.
	  if cnt4 eq 1 then nch=4	  ; Was 4.
;x        nch = min(size(img,/dim))       ; Number of channels (3 or 4).
          if (nch lt 3) or (nch gt 4) then begin
	    err = 2
	    print,' Error in img_split: image must have a dimension of 3 or 4.'
	    print,' Image dimensions:',strtrim(szd,2)
	    whocalledme,pdir,pfil,line=plin
	    print,' Called from '+pdir+pfil+'  line '+strtrim(plin,2)
	    return
	  endif
	  if sz[1] eq nch then typ=1      ; Set channel interleave dimension.
	  if sz[2] eq nch then typ=2
	  if sz[3] eq nch then typ=3
	endif ; typ
 
	case typ of
1:	begin
	  r = reform(img[0,*,*])
	  g = reform(img[1,*,*])
	  b = reform(img[2,*,*])
          if nch eq 4 then a=reform(img[3,*,*])
	  nx = sz[2]
	  ny = sz[3]
	end
2:	begin
	  r = reform(img[*,0,*])
	  g = reform(img[*,1,*])
	  b = reform(img[*,2,*])
          if nch eq 4 then a=reform(img[*,3,*])
	  nx = sz[1]
	  ny = sz[3]
	end
3:	begin
	  r = reform(img[*,*,0])
	  g = reform(img[*,*,1])
	  b = reform(img[*,*,2])
          if nch eq 4 then a=reform(img[*,*,3])
	  nx = sz[1]
	  ny = sz[2]
	end
	endcase
 
done:	if keyword_set(hsv) then begin
	  color_convert, r, g, b, h, s, v, /rgb_hsv
	  r = h		; Copy HSV into returned variables.
	  g = s
	  b = v
	endif
 
	return
 
	end
