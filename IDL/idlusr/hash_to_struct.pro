;-------------------------------------------------------------
;+
; NAME:
;       HASH_TO_STRUCT
; PURPOSE:
;       Convert a nested hash to a nested structure.
; CATEGORY:
; CALLING SEQUENCE:
;       s = hash_to_struct(h)
; INPUTS:
;       h = An IDL hash.         in
; KEYWORD PARAMETERS:
;       Keywords:
;         /VERBOSE list conversion progress.
; OUTPUTS:
;       s = Returned structure.  out
; COMMON BLOCKS:
; NOTES:
;       Notes:
;          The hash method, ToStruct, only converts the top level
;          items to a structure.  Any nested hashes stay as hashes.
;          This routine recursively converts a nested hash.  It only
;          converts hashes used as values, not hashes that are
;          inside a structure.
;          Any hash values that are !NULL are ignored.
;       
; MODIFICATION HISTORY:
;       R. Sterner, 2012 Jun 28
;       R. Sterner, 2012 Jun 29 --- Used tag_clash to handle tag clashes.
;
; Copyright (C) 2012, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
        function hash_to_struct, h, verbose=verb, help=hlp
 
        if (n_params(0) eq 0) or keyword_set(hlp) then begin
          print,' Convert a nested hash to a nested structure.'
          print,' s = hash_to_struct(h)'
          print,'   h = An IDL hash.         in'
          print,'   s = Returned structure.  out'
          print,' Keywords:'
          print,'   /VERBOSE list conversion progress.'
          print,' Notes:'
          print,'    The hash method, ToStruct, only converts the top level'
          print,'    items to a structure.  Any nested hashes stay as hashes.'
          print,'    This routine recursively converts a nested hash.  It only'
          print,'    converts hashes used as values, not hashes that are'
          print,'    inside a structure.'
          print,'    Any hash values that are !NULL are ignored.'
          print,' '
          return,''
        endif
 
        if size(h,/typ) ne 11 then return, h            ; Not a hash, just return it.
 
 
        ;----------------------------------
        ;  Verbose
        ;----------------------------------
        if keyword_set(verb) then begin
          print,' '
          innam = scope_varname(h,level=-1)      ; Name of given item.
          n = n_elements(h)
          print,'Input value, '+innam+', has '+strtrim(n,2)+ $
            ' item'+plural(n)
        endif
 
        ;----------------------------------------------------
        ;  Loop over each item in the hash
        ;----------------------------------------------------
        foreach k, h.keys() do begin
          v = h[k]                                      ; Next item.
          ;----------------------------------
          ;  Verbose output
          ;----------------------------------
          if keyword_set(verb) then begin
            help,k,v
            print,'# elements:', n_elements(v)
          endif
          ;----------------------------------
          ;  Ignore if a !NULL value
          ;
          ;  If v is a hash then v eq !NULL
          ;    is a list and is true if
          ;    any item in v is !NULL.
          ;  Only want to check a scalar, so
          ;    want n_elements to be 1.  But
          ;    n_elements(!NULL) is 0 so
          ;    have to allow for 0 or 1 (le).
          ;----------------------------------
          if n_elements(v) le 1 then begin              ; Scalar or !NULL.
            if v eq !NULL then begin
              if keyword_set(verb) then print,k+' is !NULL, Ignored.  <---'
              continue
            endif
          endif
          ;----------------------------------
          ;  If value is a hash then convert
          ;    it recursively.
          ;----------------------------------
          if size(v,/typ) eq 11 then begin
            if keyword_set(verb) then begin
              print,' '
              print,'Recursive hash to struct ...'
            endif
            v=hash_to_struct(v,verb=verb)               ; Was a hash, convert.
          endif
          ;----------------------------------
          ;  Must create the strcuture on
          ;    first item.  Else make sure
          ;    the tag is something not in
          ;    the structure already and add.
          ;----------------------------------
          if n_elements(out) eq 0 then out=create_struct(k,v) else begin
            k = tag_clash(k,out)                        ; Fix any tag conflicts.
            out=create_struct(out,k,v)                  ; Add new item to structure.
          endelse
        endforeach
        ;----------------------------------------------------
        ;  End loop over each item in the hash
        ;----------------------------------------------------
 
        return, out
 
        end
