;-------------------------------------------------------------
;+
; NAME:
;       ZEXTREMES
; PURPOSE:
;       Find extremes in a 3-D array in the Z direction only.
; CATEGORY:
; CALLING SEQUENCE:
;       zextremes, a
; INPUTS:
;       a = 3-d array to search.                   in
; KEYWORD PARAMETERS:
;       Keywords:
;         FLAG=f Extremes to find: -1: minima, +1: maxima.
;         IX=ix, IY=iy,IZ=iz  3-D indices of requested extremes.
;         COUNT=n  Number of extremes found.
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 2008 May 15
;
; Copyright (C) 2008, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro zextremes, a, flag=flag, ix=ix, iy=iy, iz=iz, count=cnt, help=hlp
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Find extremes in a 3-D array in the Z direction only.'
	  print,' zextremes, a'
	  print,'   a = 3-d array to search.                   in'
	  print,' Keywords:'
	  print,'   FLAG=f Extremes to find: -1: minima, +1: maxima.'
	  print,'   IX=ix, IY=iy,IZ=iz  3-D indices of requested extremes.'
	  print,'   COUNT=n  Number of extremes found.'
	  return
	endif
 
	if dimsz(a,0) ne 3 then begin
	  print,' Error in zextremes: Must give a 3-d array.'
	  return
	endif
 
	if n_elements(flag) eq 0 then begin
	  print,' Error in zextremes: Must give the keyword FLAG=flag.'
	  print,'   -1: minima, +1: maxima, 0: both.'
	  return
	endif
 
	nx = dimsz(a,1)				; Size in X.
	ny = dimsz(a,2)				; Size in Y.
	dz = a-shift(a,0,0,1)			; Z differences.
	sn = fix(dz gt 0) - fix(dz lt 0)	; Signs of differences.
	jm = (shift(sn,0,0,1)-sn)>(-1)<1	; Jumps in sign.
	jm[*,*,0:1] = 0				; Avoid edge effect.
 
	w = where(jm eq flag, cnt)		; Find requested extremes.
	one2three,w,a,ix,iy,iz			; 1-d to 3-d indices.
	iz = iz - 1				; Correct index.
 
	end
