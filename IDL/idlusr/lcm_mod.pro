;-------------------------------------------------------------
;+
; NAME:
;       LCM_MOD
; PURPOSE:
;       Find the least common multiple of two integers with gcd_mod.
; CATEGORY:
; CALLING SEQUENCE:
;       c = lcm_mod(a,b)
; INPUTS:
;       a, b = Two integers.                              in
; KEYWORD PARAMETERS:
; OUTPUTS:
;       c = The least common multiple of both a and b.    out
; COMMON BLOCKS:
; NOTES:
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
        function lcm_mod, a, b, help=hlp
 
        if (n_params(0) lt 2) or keyword_set(hlp) then begin
          print,' Find the least common multiple of two integers with gcd_mod.'
          print,' c = lcm_mod(a,b)'
          print,'   a, b = Two integers.                              in'
          print,'   c = The least common multiple of both a and b.    out'
          return,''
        endif
 
        return, a/gcd_mod(a,b)*b
 
        end
