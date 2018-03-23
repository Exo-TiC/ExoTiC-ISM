;-------------------------------------------------------------
;+
; NAME:
;       SYMASYM
; PURPOSE:
;       Resolve an array into symmetric & anti-symmetric components.
; CATEGORY:
; CALLING SEQUENCE:
;       symasym, in, sym, asym
; INPUTS:
;       in = input array (1-d or 2-d).          in
; KEYWORD PARAMETERS:
;       Keywords:
;         /X  means do symmetry/antisymmetry in X dimension.
;         /Y  means do symmetry/antisymmetry in Y dimension.
;            These keywords only apply to 2-d data.
; OUTPUTS:
;       sym = symmetric component of in.        out
;       asym = anti-symmetric component of in.  out
; COMMON BLOCKS:
; NOTES:
;       Notes: The sym/asym components for 2-d arrays are by
;         default radially symmetric/antisymmetric from the array
;         center.  Use the keyword /X or /Y to force resolution
;         in a single dimension.
; MODIFICATION HISTORY:
;       R. Sterner, 1996 Jun 21
;
; Copyright (C) 1996, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro symasym, in, sym, asym, x=x, y=y, help=hlp
 
	if (n_params(0) lt 3) or keyword_set(hlp) then begin
	  print,' Resolve an array into symmetric & anti-symmetric components.'
	  print,' symasym, in, sym, asym'
	  print,'   in = input array (1-d or 2-d).          in'
	  print,'   sym = symmetric component of in.        out'
	  print,'   asym = anti-symmetric component of in.  out'
	  print,' Keywords:'
	  print,'   /X  means do symmetry/antisymmetry in X dimension.'
	  print,'   /Y  means do symmetry/antisymmetry in Y dimension.'
	  print,'      These keywords only apply to 2-d data.'
	  print,' Notes: The sym/asym components for 2-d arrays are by'
	  print,'   default radially symmetric/antisymmetric from the array'
	  print,'   center.  Use the keyword /X or /Y to force resolution'
	  print,'   in a single dimension.'
	  return
	endif
 
	sz = size(in)
	if keyword_set(x) then goto, resx
	if keyword_set(y) then goto, resy
 
	f = fft(in,-1)				; FFT.
	r = float(f)				; Real part.
	i = imaginary(f)			; Imaginary part.
	sym = float(fft(complex(r,i*0),1))	; Symmetric component.
	asym = float(fft(complex(r*0,i),1))	; Anti-symmetric component.
	return
 
resx:	if sz(0) ne 2 then begin
	  print,' Error in symasym: must have a 2-d array to use /X.'
	  return
	endif
	sym = fltarr(sz(1),sz(2))		; Storage.
	asym = fltarr(sz(1),sz(2))
	for j=0,sz(2)-1 do begin
	  f = fft(in(*,j),-1)			; FFT of j'th line.
	  r = float(f)				; Real part.
	  i = imaginary(f)			; Imaginary part.
	  sym(0,j)=float(fft(complex(r,i*0),1))	; Symmetric component.
	  asym(0,j)=float(fft(complex(r*0,i),1)); Anti-symmetric component.
	endfor
	return
 
resy:	if sz(0) ne 2 then begin
	  print,' Error in symasym: must have a 2-d array to use /Y.'
	  return
	endif
	sym = fltarr(sz(1),sz(2))		; Storage.
	asym = fltarr(sz(1),sz(2))
	for j=0,sz(1)-1 do begin
	  f = fft(in(j,*),-1)			; FFT of j'th column.
	  r = float(f)				; Real part.
	  i = imaginary(f)			; Imaginary part.
	  sym(j,0)=float(fft(complex(r,i*0),1))	; Symmetric component.
	  asym(j,0)=float(fft(complex(r*0,i),1)); Anti-symmetric component.
	endfor
	return
 
	end
