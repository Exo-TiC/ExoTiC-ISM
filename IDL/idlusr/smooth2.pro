;-------------------------------------------------------------
;+
; NAME:
;       SMOOTH2
; PURPOSE:
;       Do multiple smoothing. Gives near Gaussian smoothing.
; CATEGORY:
; CALLING SEQUENCE:
;       b = smooth2(a, w)
; INPUTS:
;       a = array to smooth (1,2, or 3-d).  in
;       w = smoothing window size.          in
; KEYWORD PARAMETERS:
;       Keywords:
;         /FILL_ENDS fill end effects (1-d or 2-d only).
;           This replaces values on the edges with the last
;           completely smoothed value.  This may be a larger
;           area than expected.
; OUTPUTS:
;       b = smoothed array.                 out
; COMMON BLOCKS:
; NOTES:
;       Note: Smooths twice with the given smoothing width, then
;         twice again width half that width.
; MODIFICATION HISTORY:
;       R. Sterner.  8 Jan, 1987.
;       Johns Hopkins University Applied Physics Laboratory.
;       RES  14 Jan, 1987 --- made both 2-d and 1-d.
;       RES 30 Aug, 1989 --- converted to SUN.
;       R. Sterner, 1994 Feb 22 --- cleaned up some.
;       R. Sterner, 2006 Aug 18 --- Added keyword /FILL_ENDS.
;       R. Sterner, 2006 Aug 20 --- Corrected to length to fill.
;       R. Sterner, 2008 Mar 31 --- Limit width to > 1 (not 2).
;       R. Sterner, 2008 Mar 31 --- Fixed fill for 2-d and non-square.
;
; Copyright (C) 1987, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
	function smooth2, i, w, fill_ends=fill_ends, help=hlp
 
	if (n_params(0) lt 2) or keyword_set(hlp)  then begin
	  print,' Do multiple smoothing. Gives near Gaussian smoothing.'
	  print,' b = smooth2(a, w)'
	  print,'   a = array to smooth (1,2, or 3-d).  in'
	  print,'   w = smoothing window size.          in'
	  print,'   b = smoothed array.                 out'
	  print,' Keywords:'
	  print,'   /FILL_ENDS fill end effects (1-d or 2-d only).'
	  print,'     This replaces values on the edges with the last'
	  print,'     completely smoothed value.  This may be a larger'
	  print,'     area than expected.'
	  print,' Note: Smooths twice with the given smoothing width, then'
	  print,'   twice again width half that width.'
	  return, -1
	endif
 
	w1 = w > 1
	w2 = w/2 > 1
 
	i2 = smooth(i, w1)
	i2 = smooth(i2, w1)
	i2 = smooth(i2, w2)
	i2 = smooth(i2, w2)
 
	if keyword_set(fill_ends) then begin
	  sx = w[0]>1			; Smoothing width in X.
	  nx = dimsz(i2,1)>1		; X dimension.
	  ny = dimsz(i2,2)>1		; Y dimension.
	  ;---  Fix ends in x dimension  ---
	  lst = nx - 1			; Last X index.
	  e = (floor(sx/4.)*2)>4	; Number of samples to fill.
	  i2[0,0] = rebin(i2[e,*],e,ny,/samp)         ; Fill start of array.
	  i2[lst-e+1,0] = rebin(i2[lst-e,*],e,ny,/samp) ; Fill end of array.
	  ;---  Fix ends in y dimension  ---
	  if dimsz(i,0) gt 1 then begin
	    if n_elements(w) gt 1 then sy=w[1]>1 else sy=w[0]>1 ; Y win width.
	    lst = ny - 1		; Last Y index.
	    e = (floor(sy/4.)*2)>4	; Number of samples to fill.
	    i2[0,0] = rebin(i2[*,e],nx,e,/samp)  ; Fill start of array.
	    i2[0,lst-e+1] = rebin(i2[*,lst-e],nx,e,/samp) ; Fill end of array.
	  endif
	endif
		
	return, i2
	end
