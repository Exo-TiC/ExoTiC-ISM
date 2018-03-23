;-------------------------------------------------------------
;+
; NAME:
;       MAKESTR
; PURPOSE:
;       Make a nested structure for testing.
; CATEGORY:
; CALLING SEQUENCE:
;       s = makestr(nlev, [ntags])
; INPUTS:
;       nlev = Levels of nesting (max=9).  in
;       ntags = Number of tags at each level (max=9).
;          Optional, the default is 3.
; KEYWORD PARAMETERS:
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 2012 Aug 10
;
; Copyright (C) 2012, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
        function makestr, nlev0, ntags0, prefix=prfx, lev=lev, help=hlp
 
        if (n_params(0) lt 1) or keyword_set(hlp) then begin
          print,' Make a nested structure for testing.'
          print,' s = makestr(nlev, [ntags])'
          print,'   nlev = Levels of nesting (max=9).  in'
          print,'  ntags = Number of tags at each level (max=9).'
          print,'     Optional, the default is 3.'
          return,''
        endif
 
        ;--------------------------------------------------------
        ;  Initialize
        ;--------------------------------------------------------
        if n_elements(ntags0) eq 0 then ntags=3 else ntags=ntags0
        if n_elements(prfx) eq 0 then prfx=''
        if n_elements(lev) eq 0 then lev=1
        if prfx eq '' then sep='' else sep='_'
        nlev = nlev0<9                          ; Limit to 9 max.
        ntags = ntags<9
 
        ;--------------------------------------------------------
        ;  Loop over ntags tags
        ;
        ;  At the lowest level the value is
        ;    a string = the address of the tag.
        ;  If not at the lowest level then the value is
        ;    a structure with ntags tags.
        ;--------------------------------------------------------
        for i=0,ntags-1 do begin              ; Loop over ntags.
          labl = strtrim(lev,2)+strtrim(i+1,2)  ; Label for tag.
          tag = 't' + labl                    ; Tag name.
          if nlev eq 1 then begin             ; Lowest level.
            val = prfx + sep + labl           ; Value.
          endif else begin                    ; Not at lowest level.
            val = makestr(nlev-1,ntags0, prefix=prfx+sep+labl, lev=lev+1)
          endelse
          if i eq 0 then begin                ; If first tag
            s = create_struct(tag, val)       ; then create structure,
          endif else begin                    ; else
            s = create_struct(s, tag, val)    ; add to it.
          endelse
        endfor 
 
        return, s
 
        end
