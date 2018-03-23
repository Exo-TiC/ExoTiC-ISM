;-------------------------------------------------------------
;+
; NAME:
;       VAR2BYT
; PURPOSE:
;       Convert numeric variables to the equivalent array of bytes.
; CATEGORY:
; CALLING SEQUENCE:
;       var2byt, v1, [v2, ..., v9]
; INPUTS:
;       v1,... = variables to convert.    in
; KEYWORD PARAMETERS:
;       Keywords:
;         BUFF=buff  resulting concatenated byte array.
; OUTPUTS:
; COMMON BLOCKS:
;       var2byt_com
; NOTES:
;       Notes: Extract the bytes in a given set of numeric
;         variables and concatenate them into a byte array.
;         The numeric values may be retrieved using field
;         extraction.  Will convert an array but the array
;         dimensions must be known to recover the variable
;         from the byte array.
; MODIFICATION HISTORY:
;       R. Sterner, 2007 Dec 13
;
; Copyright (C) 2007, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro var2byt, v1, v2, v3, v4, v5, v6, v7, v8, v9, $
	  buff=buff, bytes=nb, help=hlp
 
	common var2byt_com, btab
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Convert numeric variables to the equivalent array of bytes.'
	  print,' var2byt, v1, [v2, ..., v9]'
	  print,'   v1,... = variables to convert.    in'
	  print,' Keywords:'
	  print,'   BUFF=buff  resulting concatenated byte array.'
	  print,' Notes: Extract the bytes in a given set of numeric'
	  print,'   variables and concatenate them into a byte array.'
	  print,'   The numeric values may be retrieved using field'
	  print,'   extraction.  Will convert an array but the array'
	  print,'   dimensions must be known to recover the variable'
	  print,'   from the byte array.'
	  return
	endif
 
	;---  initialize byte length table  ---
	if n_elements(btab) eq 0 then begin
	;        Bytes           Typ
	  btab = [ 0, $		;  0 = Undefined
		   1, $		;  1 = Byte
		   2, $		;  2 = Int
		   4, $		;  3 = Long
		   4, $		;  4 = Float
	           8, $		;  5 = Double
		   8, $		;  6 = Complex
		  -1, $		;  7 = String
		  -1, $		;  8 = Struct
		  16, $		;  9 = Dcomplex
		  -1, $		; 10 = Pointer
		  -1, $		; 11 = Objref
		   2, $		; 12 = Uint
		   4, $		; 13 = Ulong
		   8, $		; 14 = Long64
		   8 ]		; 15 = Ulong64
	endif
 
	bb = [0B]			; Init buffer.
 
	for i=1, n_params(0)<9 do begin
	  case i of
1:	    v = v1
2:	    v = v2
3:	    v = v3
4:	    v = v4
5:	    v = v5
6:	    v = v6
7:	    v = v7
8:	    v = v8
9:	    v = v9
	  endcase
	  nel = n_elements(v)		; Total number of elements in var.
	  nb = btab[size(v,/type)]*nel	; Total number of bytes in var.
	  b = fix(v,0,nb,type=1)	; Convert var to bytes.
	  bb = [bb,b]			; Concatenate.
	endfor
 
	buff = bb[1:*]			; Drop array seed value.
 
	end
