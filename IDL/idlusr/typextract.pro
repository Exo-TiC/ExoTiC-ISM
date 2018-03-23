;-------------------------------------------------------------
;+
; NAME:
;       TYPEXTRACT
; PURPOSE:
;       Extract a specified datatype from binary data in byte array.
; CATEGORY:
; CALLING SEQUENCE:
;       num = typextract(txt, offset, bindat)
; INPUTS:
;       txt = datatype description in a text string.   in
;       offset = offset in bytes into bindat.          in
;       bindat = binary data in a byte array.          in
; KEYWORD PARAMETERS:
;       Keywords:
;         BITS=bits Returned total number of bits in given item.
;         ERROR=err  Error flag: 0=ok, else error.
; OUTPUTS:
;       num = extracted numeric item.                  out
; COMMON BLOCKS:
; NOTES:
;       Note: datatypes are: BYT, INT, LON, FLT, DBL, COMPLEX,
;         DCOMPLEX, UINT, ULON, LONG64, ULONG64.
;         Any array dimensions follow the data type in parantheses.
;         Examples: "UINT","FLT","BYT(3,4)","LON(100)".
;         The inverse of datatype.  Note array syntax is
;         not quite like the IDL array functions, use byt(3,4)
;         for this routine instead of bytarr(3,4).
;         See also typ2num.
; MODIFICATION HISTORY:
;       R. Sterner, 2002 Oct 11
;       R. Sterner, 2010 Jun 07 --- Converted arrays from () to [].
;       R. Sterner, 2011 May 27 --- Added portable data descriptions: I8, I16, I32, ...
;       R. Sterner, 2011 May 31 --- Can now handle character strings.
;
; Copyright (C) 2002, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	function typextract, input, offset, bindat, bits=bits, $
	  error=err, help=hlp
 
	if (n_params(0) lt 3) or keyword_set(hlp) then begin
	  print,' Extract a specified datatype from binary data in byte array.'
	  print,' num = typextract(txt, offset, bindat)'
	  print,'   txt = datatype description in a text string.   in'
          print,'     See examples in Notes section below.'
	  print,'   offset = offset in bytes into bindat.          in'
	  print,'   bindat = binary data in a byte array.          in'
	  print,'   num = extracted numeric item.                  out'
	  print,' Keywords:'
	  print,'   BITS=bits Returned total number of bits in given item.'
	  print,'   ERROR=err  Error flag: 0=ok, else error.'
	  print,' Note: datatypes are: BYT, INT, LON, FLT, DBL, COMPLEX,'
	  print,'   DCOMPLEX, UINT, ULON, LONG64 (or LON64), ULONG64 (or ULON64).'
          print,'   Strings are handled by CHxxx where xxx is the string length.'
	  print,'   Any array dimensions follow the data type in parantheses.'
	  print,'   Examples: "UINT","FLT","BYT(3,4)","LON(100)".'
	  print,'   The inverse of datatype.  Note array syntax is'
	  print,'   not quite like the IDL array functions, use byt(3,4)'
	  print,'   for this routine instead of bytarr(3,4).'
          print,'   Elements of a string array must all be the same length. Example:'
          print,'     CH8(4,5) would specify a 4 by 5 array of 8 character strings.'
          print,'   Note the number following the type is in bytes for character'
          print,'   strings (CH), but in bits for all other data types.'
          print,'   In addition a set of portable data types are available:'
          print,'     I8, I16, I32, I64, UI8, UI16, UI32, UI32, F32, F64, C64, C128'
          print,'   I* are signed integers, UI* are unsigned integers, '
          print,'   F* are floats, C* are complex.  I8 does not exist in IDL,'
          print,'   it will return a byte value.  These items are intended to'
          print,'   allow language and machine independent data descriptions.'
          print,'   So using these types byt(3,4) would be ui8(3,4).'
	  print,'   See also typ2num.'
          print,' '
          print,'   Some example values for txt, the dtatype description string:'
          print,"   'LON', 'ulon(3,4)', 'I32', 'UI16(2,5)', 'ch8(4,5)', 'F32'"
	  return,''
	endif
 
	;----------------------------------------------------------
	;  Get datatype and any dimensions
	;----------------------------------------------------------
	p = strpos(input,'(')		; Position of opening paren if any.
	n_arr = 1L			; Will have total # elements.
	;---  Array  ----------
	if p ge 0 then begin			; Dimension was given.
	  typ = strupcase(strmid(input,0,p))	; Datatype.
	  dim = strmid(input,p+1,99)		; Dimensions.
	  wordarray,dim,tmp,del=', '		; Put dims in text array.
	  dimarr = tmp+0			; Array of dimensions.
	  for i=0,n_elements(dimarr)-1 do n_arr=n_arr*dimarr[i] ; # elements.
	;---  Scalar  ----------
	endif else begin			; No dimension given.
	  typ = strupcase(input)		; Datatype.
	  dim = ''				; Null dimension.
	endelse
        ;---  Deal with strings  ---
        if strmid(typ,0,2) eq 'CH' then begin
          len = strmid(typ,2) + 0
          n_arr = len*n_arr                     ; Total # bytes needed.
          typ = 'CH'
        endif
	  
	;----------------------------------------------------------
        ;  Deal with portable data types
	;----------------------------------------------------------
        case typ of
        ;---  Unsigned integer numbers  ---
'UI8':	typ = 'BYT'
'UI16':	typ = 'UINT'
'UI32':	typ = 'ULON'
'UI64':	typ = 'ULON64'
        ;---  Signed integer numbers  ---
'I8':	typ = 'BYT'     ; IDL does not have signed 8 bit integers.
'I16':	typ = 'INT'
'I32':	typ = 'LON'
'I64':	typ = 'LON64'
        ;---  Floating numbers  ---
'F32':	typ = 'FLT'
'F64':	typ = 'DBL'
        ;---  Complex numbers  ---
'C64':	typ = 'COMPLEX'
'C128':	typ = 'DCOMPLEX'
else:
        endcase

	;----------------------------------------------------------
	;  Do extraction from given byte array
	;----------------------------------------------------------
	if datatype(bindat) ne 'BYT' then begin
	  err = 1
	  print,' Error in typextract: Must give bindat as a byte array.'
	  return,''
	endif
	nbin = n_elements(bindat)		; # bytes in bindat.
	n_avail = nbin - offset			; Available bytes.
	case typ of
'BYT':	   begin
	     nbits = 8*n_arr
	     if (nbits/8) gt n_avail then goto, over
	     x = byte(bindat,offset,n_arr)
	   end
'INT':	   begin
	     nbits = 16*n_arr
	     if (nbits/8) gt n_avail then goto, over
	     x = fix(bindat,offset,n_arr)
	   end
'LON':     begin
	     nbits = 32*n_arr
	     if (nbits/8) gt n_avail then goto, over
	     x = long(bindat,offset,n_arr)
	   end
'FLT':     begin
	     nbits = 32*n_arr
	     if (nbits/8) gt n_avail then goto, over
	     x = float(bindat,offset,n_arr)
	   end
'DBL':     begin
	     nbits = 64*n_arr
	     if (nbits/8) gt n_avail then goto, over
	     x = double(bindat,offset,n_arr)
	   end
'COMPLEX': begin
	     nbits = 64*n_arr
	     if (nbits/8) gt n_avail then goto, over
	     x = complex(bindat,offset,n_arr)
	   end
'DCOMPLEX':begin
	     nbits = 128*n_arr
	     if (nbits/8) gt n_avail then goto, over
	     x = dcomplex(bindat,offset,n_arr)
	   end
'UINT':	   begin
	     nbits = 16*n_arr
	     if (nbits/8) gt n_avail then goto, over
	     x = uint(bindat,offset,n_arr)
	     end
'ULON':    begin
	     nbits = 32*n_arr
	     if (nbits/8) gt n_avail then goto, over
	     x = ulong(bindat,offset,n_arr)
	   end
'LON64':  begin
	     nbits = 64*n_arr
	     if (nbits/8) gt n_avail then goto, over
	     x = long64(bindat,offset,n_arr)
	   end
'ULON64': begin
	     nbits = 64*n_arr
	     if (nbits/8) gt n_avail then goto, over
	     x = ulong64(bindat,offset,n_arr)
	   end
'LONG64':  begin  ; LON64 ???
	     nbits = 64*n_arr
	     if (nbits/8) gt n_avail then goto, over
	     x = long64(bindat,offset,n_arr)
	   end
'ULONG64': begin  ; ULON64 ???
	     nbits = 64*n_arr
	     if (nbits/8) gt n_avail then goto, over
	     x = ulong64(bindat,offset,n_arr)
	   end
'CH':      begin
             nbits = 8*n_arr            ; # bits requested.
	     if n_arr gt n_avail then goto, over
             hi = offset + n_arr - 1    ; Handle subset of bindat.
             bb = bindat[offset:hi]     ; Bytes needed.
             if dim ne '' then $        ; Array or scalar?
               b=reform(bb,[len,product(dimarr)]) else b=bb
             x = string(b)              ; Convert to string.
           end
else:	   begin
	     if not keyword_set(quiet) then $
	       print,' Unknown numeric datatype: ',typ
	     err = 1
	     return,''
	   end
	endcase
 
	;----------------------------------------------------------
	;  Reshape to correct dimensions
	;----------------------------------------------------------
	bits = nbits				; Copy # bits.
	err = 0
	;---------  Scalar item  ----------------
	if dim eq '' then begin
	  return, x[0]				; Return scalar number.
	;--------  Array  ------------------------
	endif else begin
	  x = reform(x,dimarr,/overwrite)	; Reshape array.
	  return, x
	endelse
 
	;----------------------------------------------------------
	;  Extraction over-run
	;----------------------------------------------------------
over:
	  err = 1
	  print,' Error in typextract: Trying to extract more than available.'
	  print,'   '+strtrim(n_avail,2)+' bytes left in bindat.'
	  print,'   Asking for '+strtrim(nbits/8,2)
	  return,''
 
 
	end
