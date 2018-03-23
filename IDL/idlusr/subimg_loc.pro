;-------------------------------------------------------------
;+
; NAME:
;       SUBIMG_LOC
; PURPOSE:
;       Locate a subimage within an image.
; CATEGORY:
; CALLING SEQUENCE:
;       subimg_loc, sub
; INPUTS:
;       sub = Subimage to locate.   in
; KEYWORD PARAMETERS:
;       Keywords:
;         IMAGE=img Full image to search.  If not given then
;           the last given image is used.
;         IX=ix, IY=iy Subimage best match offset into full image.
;         CMAX=cmax Returned correlation max value.
;         CORR_ARRAY=c Returned correlation array.
;         INSIDE=[ixc,iyc] Only look inside subimage area for the
;           best match, where (ixc,iyc) is the cnter of the given
;           subimage in pixels.
;         /NOSAD Do not do extra step of Sum of Absolute Differences.
; OUTPUTS:
; COMMON BLOCKS:
;       subimg_loc_com
; NOTES:
;       Notes: For single band images only.
;       Reference:
;          http://werner.yellowcouch.org/Papers/subimg/index.html
; MODIFICATION HISTORY:
;       R. Sterner, 2008 Mar 31
;       R. Sterner, 2012 Apr --- Cleaned up.
;       R. Sterner, 2012 Apr 27 --- Added INSIDE=[ixc,iyc]
;
; Copyright (C) 2008, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro subimg_loc, sub, image=img, ix=ix, iy=iy, nosad=nosad, $
        cmax=cmax, corr_array=c, inside=inside, help=hlp
 
	common subimg_loc_com, fa, z, sx, sy, cm5, cm6, cm7
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Locate a subimage within an image.'
	  print,' subimg_loc, sub'
	  print,'   sub = Subimage to locate.   in'
	  print,' Keywords:'
	  print,'   IMAGE=img Full image to search.  If not given then'
	  print,'     the last given image is used.'
	  print,'   IX=ix, IY=iy Subimage best match offset into full image.'
          print,'   CMAX=cmax Returned correlation max value.'
          print,'   CORR_ARRAY=c Returned correlation array.'
          print,'   INSIDE=[ixc,iyc] Only look inside subimage area for the'
          print,'     best match, where (ixc,iyc) is the cnter of the given'
          print,'     subimage in pixels.'
;	  print,'   /NOSAD Do not do extra step of Sum of Absolute Differences.'
	  print,' Notes: For single band images only.'
	  print,' Reference:'
	  print,'    http://werner.yellowcouch.org/Papers/subimg/index.html'
	  return
	endif
 
	;------------------------------------------------------------------
	;  Subimage and smoothing window size
	;  The smoothing window, wx x wy, is 1/2 the subimage size.
	;------------------------------------------------------------------
	wx = dimsz(sub,1)				; Subimage dimensions.
	wy = dimsz(sub,2)
	wx2 = wx/2
	wy2 = wy/2
 
	;------------------------------------------------------------------
	;  Prepare full image
	;  Normalize the image by the sliding mean and sliding sdev.
	;  Also taper the edges to 0.
	;------------------------------------------------------------------
	if n_elements(img) ne 0 then begin
	  sx = dimsz(img,1)				; Image dimensions.
	  sy = dimsz(img,2)
	  m = smooth(double(img),[wx2,wy2],/edge_trunc)	; Image mean.
	  sd = sqrt(smooth((img-m)^2,[wx2,wy2],/edge_trunc)) ; Image sdev.
	  nimg = ((img-m)/(sd>0.0001))*winlin(sx,sy,wx2,wy2) ; Normalized image.
	  z = img*0D0					; Image sized 0 array.
	  fa = fft(nimg,-1)				; FFT of image.
	endif
 
	;------------------------------------------------------------------
	;  Prepare subimage
	;------------------------------------------------------------------
	ms = smooth(double(sub),[wx2,wy2],/edge_trunc)	; Subimage mean.
	sds = sqrt(smooth((sub-ms)^2,[wx2,wy2],/edge_trunc)) ; Subimage sdev.
	nsub = ((sub-ms)/(sds>0.0001))*winlin(wx,wy,wx2,wy2) ; Normlzd subimg.
	zz = z						; Copy zero image.
	zz[0,0] = nsub					; Insert norm sub.
	fb = fft(zz,-1)					; FFT of subimage.
 
	;------------------------------------------------------------------
	;  Correlate
	;------------------------------------------------------------------
	c = float(fft(fa*conj(fb),1))
 
	;------------------------------------------------------------------
	;  Find shift
        ;
        ;  If INSIDE=[ixc,iyc] given then first zero outside subimage area.
	;------------------------------------------------------------------
        cc = c
        if n_elements(inside) eq 2 then begin
          ixc = inside[0] - wx2                 ; Subimage center (given).
          iyc = inside[1] - wy2
          lox = (ixc - wx2 - 1)>0               ; Bounds just outside subimage.
          hix = (ixc + wx2 + 1)<(sx-1)
          loy = (iyc - wy2 - 1)>0
          hiy = (iyc + wy2 + 1)<(sy-1)
          cc[0:lox,*] = 0                       ; Zero left of subimage.
          cc[hix:*,*] = 0                       ; Zero right of subimage.
          cc[*,0:loy] = 0                       ; Zero below subimage.
          cc[*,hiy:*] = 0                       ; Zero above subimage.
        endif
;stop
;        cmax = max(c)
        cmax = max(cc)
;	w = where(c eq max(c))
;	w = where(c eq cmax)
	w = where(cc eq cmax)
;	one2two, w, c, ix1, iy1
	one2two, w, cc, ix1, iy1
	ix = ix1[0]
	iy = iy1[0]
 
	end
