;-------------------------------------------------------------
;+
; NAME:
;       BIT_REVERSE
; PURPOSE:
;       Reverse all the bits in the given item.
; CATEGORY:
; CALLING SEQUENCE:
;       out = bit_reverse(in)
; INPUTS:
;       in = Numeric input item.  May be an array.           in
; KEYWORD PARAMETERS:
; OUTPUTS:
;       out = Returned item, in with all the bits reversed.  out
; COMMON BLOCKS:
; NOTES:
;       Notes: The input argument, in, may be any data type.
;       The returned result, out, will be the same data type.
;       The input may be an array, 1-D or 2-D.  The bits are
;       reversed in the X dimension of the array only.  This
;       allows a set of records to be processed together.
; MODIFICATION HISTORY:
;       R. Sterner, 2011 Aug 22
;
; Copyright (C) 2011, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
        function bit_reverse, in, help=hlp
 
        if (n_params(0) lt 1) or keyword_set(hlp) then begin
          print,' Reverse all the bits in the given item.'
          print,' out = bit_reverse(in)'
          print,'   in = Numeric input item.  May be an array.           in'
          print,'   out = Returned item, in with all the bits reversed.  out'
          print,' Notes: The input argument, in, may be any data type.'
          print,' The returned result, out, will be the same data type.'
          print,' The input may be an array, 1-D or 2-D.  The bits are'
          print,' reversed in the X dimension of the array only.  This'
          print,' allows a set of records to be processed together.'
          return,''
        endif
 
        ;------------------------------------------------------
        ;  Convert to a byte array if needed
        ;------------------------------------------------------
        typ = datatype(in, 2, numbytes=nbytes)  ; Get data type & total bytes.
        if typ eq 1 then begin                  ; Already bytes, just copy.
          b = in                                ; Want byte array in b.
        endif else begin                        ; Must convert to bytes.
          dims = size(in,/dimensions)           ; Get dimensions.
          b = byte(in,0,nbytes)                 ; Convert to byte array b.
        endelse
 
        ;------------------------------------------------------
        ;  Reverse bits:
        ;    Reverse the bits in each byte.
        ;    Then reverse the order of the bytes
        ;      in the x dimension only.
        ;------------------------------------------------------
        b = bit_byte_reverse(b)         ; Reverse bits in byte.
        b = reverse(b,1)                ; Reverse byte order (1-D or 2-D).
 
        ;------------------------------------------------------
        ;  Convert bytes back to original data type
        ;------------------------------------------------------
        if typ eq 1 then begin           ; Was bytes.
          out = b                        ; Just copy.
        endif else begin                 ; Non-byte data type.
          if dims[0] eq 0 then begin     ; Was a scalar.
            out = fix(b,0,type=typ)      ; Convert bytes to original type.
          endif else begin               ; Was array.
            out = fix(b,0,dims,type=typ) ; Convert bytes to original type.
          endelse
        endelse
 
        return,out
 
        end
