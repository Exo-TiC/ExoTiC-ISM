;-------------------------------------------------------------
;+
; NAME:
;       DEEP_COPY
; PURPOSE:
;       Copy an item using deep copy.
; CATEGORY:
; CALLING SEQUENCE:
;       out = deep_copy(in)
; INPUTS:
;       in  = Input variable.            in
;         If this is not a compound
;         type it is returned as is.
; KEYWORD PARAMETERS:
; OUTPUTS:
;       out = Returned deep copy of in.  out
; COMMON BLOCKS:
; NOTES:
;       Notes: Compound data types are structure, pointer, list
;         and hash.  Each either is a or can contain references to
;         data in memory.  Any changes to a copy that contains such
;         a reference will change any other variable that contains
;         that reference.  A deep copy will construct a copy from
;         the original items so it is an independent copy which
;         may be changed.
;       
;         Objects (other than lists and hashes) will not be deep
;         copied with this routine because there is not a standard
;         way to access or rebuild the internal data.  They will
;         be copied in the normal way (shallow copy).
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
        function deep_copy, in, help=hlp
 
        if (n_params(0) lt 1) or keyword_set(hlp) then begin
          print,' Copy an item using deep copy.'
          print,' out = deep_copy(in)'
          print,'   in  = Input variable.            in'
          print,'     If this is not a compound'
          print,'     type it is returned as is.'
          print,'   out = Returned deep copy of in.  out'
          print,' Notes: Compound data types are structure, pointer, list'
          print,'   and hash.  Each either is a or can contain references to'
          print,'   data in memory.  Any changes to a copy that contains such'
          print,'   a reference will change any other variable that contains'
          print,'   that reference.  A deep copy will construct a copy from'
          print,'   the original items so it is an independent copy which'
          print,'   may be changed.'
          print,' '
          print,'   Objects (other than lists and hashes) will not be deep'
          print,'   copied with this routine because there is not a standard'
          print,'   way to access or rebuild the internal data.  They will'
          print,'   be copied in the normal way (shallow copy).'
          return,''
        endif
 
        ;--------------------------------------------------------------
        ;  Determine data type of incoming item
        ;--------------------------------------------------------------
        typ = size(/type,in)            ; Data type of incoming item.
        if typ lt  8 then return, in    ; Numeric.
        if typ eq  9 then return, in    ; Dcomplex.
        if typ gt 11 then return, in    ; Unsigned.
        tnam = ''
        if typ eq  8      then tnam='Struct'
        if typ eq 10      then tnam='Pointer'
        if isa(in,'list') then tnam='List'
        if isa(in,'hash') then tnam='Hash'
        if tnam eq '' then begin
          print,' Internal error in deep_copy:'
          print,'   Unrecognized data type for input.'
          help,in
          stop
        endif
 
        ;--------------------------------------------------------------
        ;  Process a structure
        ;
        ;  Deal with named and anonymous structures.
        ;  A named structure is initialized with all items zeroed out.
        ;--------------------------------------------------------------
        if tnam eq 'Struct' then begin
          snam = tag_names(in,/structure_name)          ; Named structure?
          n = n_tags(in)                                ; Number of tags.
          ;---  Named structure  ---
          if snam ne '' then begin
            out = create_struct(name=snam)              ; Start output struct.
            for i=0, n-1 do begin                       ; Loop over items.
              out.(i) = deep_copy(in.(i))               ; Copy from in to out.
            endfor
          ;---  Anonymous structure  ---
          endif else begin
            tag = tag_names(in)                         ; Tag names.
            for i=0,n-1 do begin                        ; Loop over tags.
              val = deep_copy(in.(i))                   ; Get next value.
              if i eq 0 then begin                      ; First loop?
                out = create_struct(tag[i],val)         ; Start output struct.
              endif else begin                          ; Not first loop.
                out = create_struct(out,tag[i],val)     ; Add next item.
              endelse
            endfor
          endelse
          return, out                                   ; All done. 
        endif
 
        ;--------------------------------------------------------------
        ;  Process a pointer
        ;--------------------------------------------------------------
        if tnam eq 'Pointer' then begin
          val = deep_copy(*in)                          ; Dereference pointer.
          return, ptr_new(val)                          ; Return a pointer.
        endif
 
        ;--------------------------------------------------------------
        ;  Process a list
        ;--------------------------------------------------------------
        if tnam eq 'List' then begin
          n = n_elements(in)                            ; Number of elements.
          out = list(length=n)                          ; Start output list.
          for i=0,n-1 do begin                          ; Loop over elements.
            out[i] = deep_copy(in[i])                   ; Copy from in to out.
          endfor
          return, out                                   ; All done.
        endif
 
        ;--------------------------------------------------------------
        ;  Process a hash
        ;--------------------------------------------------------------
        if tnam eq 'Hash' then begin
          n = in.count()                                ; Number of entries.
          keys = in.keys()                              ; Hash key names.
          out = hash()                                  ; Start out hash.
          foreach k, keys do begin                      ; Loop over keys.
            out[k] = deep_copy(in[k])                   ; Copy from in to out.
          endforeach
          return, out                                   ; All done.
        endif
 
        end
