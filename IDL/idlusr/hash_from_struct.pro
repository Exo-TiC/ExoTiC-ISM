;-------------------------------------------------------------
;+
; NAME:
;       HASH_FROM_STRUCT
; PURPOSE:
;       Convert a nested structure to a nested hash.
; CATEGORY:
; CALLING SEQUENCE:
;       h = hash_from_struct(s)
; INPUTS:
;       s = A structure.    in
; KEYWORD PARAMETERS:
; OUTPUTS:
;       h = Returned hash.  out
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 2012 Jun 28
;       R. Sterner, 2013 Jan 14 --- Added /LOWER_CASE.
;
; Copyright (C) 2012, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
        function hash_from_struct, s, lower_case=lower_case, help=hlp
 
        if (n_params(0) eq 0) or keyword_set(hlp) then begin
          print,' Convert a nested structure to a nested hash.'
          print,' h = hash_from_struct(s)'
          print,'   s = A structure.    in'
          print,'   h = Returned hash.  out'
          print,' Keywords:'
          print,'   /LOWER_CASE Force hash keys to be lower case.'
          print,'      The default is upper case.'
          return, ''
        endif
 
        if size(s,/typ) ne 8 then return, s     ; Not a structure, return it.
 
        foreach t, tag_names(s), i do begin     ; Loop over items in structure.
          v = s.(i)                             ; Next item.
          if size(v,/typ) eq 8 then $
            v=hash_from_struct(v,lower_case=lower_case)   ; Was struct, convert.
          if keyword_set(lower_case) then t=strlowcase(t) ; Force lower case.
          if i eq 0 then out=hash(t,v) else out=out+hash(t,v)
        endforeach
 
        return, out
 
        end
