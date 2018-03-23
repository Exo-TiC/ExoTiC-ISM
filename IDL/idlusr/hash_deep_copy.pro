;-------------------------------------------------------------
;+
; NAME:
;       HASH_DEEP_COPY
; PURPOSE:
;       Copy a hash using deep copy.
; CATEGORY:
; CALLING SEQUENCE:
;       out = hash_deep_copy(in)
; INPUTS:
;       in  = Input hash.              in
;         If this is not a hash it is
;         returned as is.
; KEYWORD PARAMETERS:
; OUTPUTS:
;       out = Output deep copy of in.  out
; COMMON BLOCKS:
; NOTES:
;       Notes: An IDL hash is really a reference to the hash data in
;         memory.  So a copy of a hash still points to the same data
;         and any changes to that copy will change the data which will
;         show up as changes to any other hashes that are related.
;         A deep copy will construct a copy from the original items
;         so it is an independent copy which may be changed.
; MODIFICATION HISTORY:
;       R. Sterner, 2013 Apr 15
;
; Copyright (C) 2013, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
        function hash_deep_copy, in, help=hlp
 
        if (n_params(0) lt 1) or keyword_set(hlp) then begin
          print,' Copy a hash using deep copy.'
          print,' out = hash_deep_copy(in)'
          print,'   in  = Input hash.              in'
          print,'     If this is not a hash it is'
          print,'     returned as is.'
          print,'   out = Output deep copy of in.  out'
          print,' Notes: An IDL hash is really a reference to the hash data in'
          print,'   memory.  So a copy of a hash still points to the same data'
          print,'   and any changes to that copy will change the data which will'
          print,'   show up as changes to any other hashes that are related.'
          print,'   A deep copy will construct a copy from the original items'
          print,'   so it is an independent copy which may be changed.'
          return,''
        endif
 
        if isa(in,'hash') eq 0 then return, in  ; Not a hash, just return it.
 
        keys = in.keys()                        ; Get keys in hash.
        out = hash()                            ; Start output hash.
 
        foreach k, keys do begin                ; Loop over hash keys.
          val = in[k]                           ; Value for this key.
          if isa(val,'hash') then val=hash_deep_copy(val)
          out[k] = val
        endforeach
 
        return, out
 
        end
