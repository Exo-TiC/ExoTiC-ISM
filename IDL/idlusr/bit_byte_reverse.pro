;-------------------------------------------------------------
;+
; NAME:
;       BIT_BYTE_REVERSE
; PURPOSE:
;       Return value made by reversing the bits of given byte value.
; CATEGORY:
; CALLING SEQUENCE:
;       rval = bit_byte_reverse(val)
; INPUTS:
;       val = Given byte value (may be an array).  in
;       rval = Returned byte value.                in
; KEYWORD PARAMETERS:
; OUTPUTS:
; COMMON BLOCKS:
;       bit_byte_reverse_com
; NOTES:
;       Note: Only reverses the bits in each byte.
;       The byte order is not changed.  So this routine will
;       not do a complete bit reversal for anything other than
;       a single byte.
;       
;       See bit_reverse to reverse all bits.
; MODIFICATION HISTORY:
;       R. Sterner, 2011 Jun 24
;       R. Sterner, 2011 Aug 22 --- Renamed, rewrote lookup table.
;
; Copyright (C) 2011, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
        function bit_byte_reverse, val, help=hlp
 
        common bit_byte_reverse_com, revtabl
 
        if (n_params(0) eq 0) or keyword_set(hlp) then begin
          print,' Return value made by reversing the bits of given byte value.'
          print,' rval = bit_byte_reverse(val)'
          print,'   val = Given byte value (may be an array).  in'
          print,'   rval = Returned byte value.                in'
          print,' Note: Only reverses the bits in each byte.'
          print,' The byte order is not changed.  So this routine will'
          print,' not do a complete bit reversal for anything other than'
          print,' a single byte.'
          print,' '
          print,' See bit_reverse to reverse all bits.'
          return,''
        endif
 
        ;--------------------------------------------
        ;  Make sure lookup table is defined
        ;
        ;  It is created by converting the numbers
        ;  to a string in base 2, reversing the digits,
        ;  and converting the resulting base 2 string
        ;  back to a number (byte).
        ;--------------------------------------------
        if n_elements(revtabl) eq 0 then begin
          revtabl = bytarr(256)
          br = string(reverse(byte(string(bindgen(256),form='(B8.8)'))))
          reads,br,revtabl,form='(B)'
        endif
 
        ;--------------------------------------------
        ;  Use table lookup to get the new values
        ;
        ;  Byte values range from 0 to 255.  A
        ;  lookup table the bit reversed version
        ;  for each possible value.
        ;--------------------------------------------
        return, revtabl[val]
 
        end
