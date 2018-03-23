;-------------------------------------------------------------
;+
; NAME:
;       STRREV
; PURPOSE:
;       Reverse a string or string array.
; CATEGORY:
; CALLING SEQUENCE:
;       out = strrev(in)
; INPUTS:
;       in = Input string or string array.              in
; KEYWORD PARAMETERS:
; OUTPUTS:
;       out = Returned reverse string or string array.  out
; COMMON BLOCKS:
; NOTES:
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
        function strrev, in, help=hlp
 
        if (n_params(0) lt 1) or keyword_set(hlp) then begin
          print,' Reverse a string or string array.'
          print,' out = strrev(in)'
          print,'   in = Input string or string array.              in'
          print,'   out = Returned reverse string or string array.  out'
          return,''
        endif
 
        b = byte(in)
        w = where(b eq 0,cnt)
        if cnt gt 0 then b[w] = 32B
 
        return, string(reverse(b))
 
        end
