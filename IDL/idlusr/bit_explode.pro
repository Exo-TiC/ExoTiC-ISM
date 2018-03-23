;-------------------------------------------------------------
;+
; NAME:
;       BIT_EXPLODE
; PURPOSE:
;       Split bits in a byte array into bytes.
; CATEGORY:
; CALLING SEQUENCE:
;       bit_explode, byt_arr, bit_arr
; INPUTS:
;       byt_arr = Input array of bytes.   in
; KEYWORD PARAMETERS:
; OUTPUTS:
;       bit_arr = output array of bits.   out
; COMMON BLOCKS:
;       bit_explode_com
; NOTES:
;       Note: The bits in byt_arr are put in individual
;       bytes in bit_arr.  The results will be 1s and 0s.
; MODIFICATION HISTORY:
;       R. Sterner, 2002 Dec 04 written as bitexplode.pro.
;       R. Sterner, 2010 Apr 30 --- Converted arrays from () to [].
;       R. Sterner, 2011 Aug 26 --- Renamed as bit_explode.pro.
;
; Copyright (C) 2002, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro bit_explode, byt_arr, bit_arr, help=hlp
 
	common bit_explode_com, table
 
	if (n_params(0) lt 2) or keyword_set(hlp) then begin
	  print,' Split bits in a byte array into bytes.'
	  print,' bit_explode, byt_arr, bit_arr'
	  print,'   byt_arr = Input array of bytes.   in'
	  print,'   bit_arr = output array of bits.   out'
	  print,' Note: The bits in byt_arr are put in individual'
	  print,' bytes in bit_arr.  The results will be 1s and 0s.'
	  return
	endif
 
	if n_elements(table) eq 0 then begin
	  table = bytarr(8,256)
	  for i=0,255 do begin
	    t = basecon(i,to=2,dig=8,gr=1)
	    wordarray,t,a
	    table[0,i] = a+0B
	  endfor
	endif
 
	bit_arr = [0B]
	for i=0,n_elements(byt_arr)-1 do begin
	  iy = byt_arr[i]
	  bit_arr = [bit_arr,table[*,iy]]
	endfor
 
	bit_arr = bit_arr[1:*]
 
	end
