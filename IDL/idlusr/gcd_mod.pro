;-------------------------------------------------------------
;+
; NAME:
;       GCD_MOD
; PURPOSE:
;       Find the greatest common divisor of two integers by modulo.
; CATEGORY:
; CALLING SEQUENCE:
;       c = gcd_mod(a,b)
; INPUTS:
;       a, b = Two integers.                              in
; KEYWORD PARAMETERS:
; OUTPUTS:
;       c = The greatest common divisor of both a and b.  out
; COMMON BLOCKS:
; NOTES:
;       Notes: Uses the Euclidean algorithm as given in Wikipedia.
; MODIFICATION HISTORY:
;       R. Sterner, 2011 Sep 07
;
; Copyright (C) 2011, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
        function gcd_mod, a0, b0, help=hlp
 
        if (n_params(0) lt 2) or keyword_set(hlp) then begin
          print,' Find the greatest common divisor of two integers by modulo.'
          print,' c = gcd_mod(a,b)'
          print,'   a, b = Two integers.                              in'
          print,'   c = The greatest common divisor of both a and b.  out'
          print,' Notes: Uses the Euclidean algorithm as given in Wikipedia.'
          return,''
        endif
 
        a = a0
        b = b0
 
        while b ne 0 do begin
          t = b
          b = a mod b
          a = t
        endwhile
 
        return, a
 
        end
