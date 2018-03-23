;-------------------------------------------------------------
;+
; NAME:
;       TAG_LIST
; PURPOSE:
;       List tags (keys) in a structure or hash.
; CATEGORY:
; CALLING SEQUENCE:
;       tag_list, in
; INPUTS:
;       in = Input structure or hash.  in
; KEYWORD PARAMETERS:
;       Keywords:
;         OUT=txt Returned listing in a text array.
;           If not given then list to screen, else do not.
;         /VERBOSE List to screen even if OUT was requested.
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 2012 Jun 28
;       R. Sterner, 2012 Aug 10 --- Renamed from list_nested.pro
;       R. Sterner, 2012 Sep 20 --- Removed scope_level check for output.
;
; Copyright (C) 2012, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
        pro tag_list, sh, out=txt, verbose=verb, help=hlp
 
        if (n_params(0) eq 0) or keyword_set(hlp) then begin
          print,' List tags (keys) in a structure or hash.'
          print,' tag_list, in'
          print,'   in = Input structure or hash.  in'
          print,' Keywords:'
          print,'   OUT=txt Returned listing in a text array.'
          print,'     If not given then list to screen, else do not.'
          print,'   /VERBOSE List to screen even if OUT was requested.'
          return
        endif
 
        if n_elements(sh) eq 0 then begin
          txt = ''
          return
        endif
 
        ;-------------------------------------------------
        ;  Find what kind of item was given
        ;-------------------------------------------------
        flag = 0                                ; Other.
        if isa(sh,'STRUCT') then flag=1         ; Structure.
        if isa(sh,'HASH'  ) then flag=2         ; Hash.
        innam = scope_varname(sh,level=-1)      ; Name of given item.
 
        ;-------------------------------------------------
        ;  Find name(s) in given item
        ;-------------------------------------------------
        case flag of
0:        nam = innam
1:        nam = tag_names(sh)
2:        nam = sh.keys()
        endcase
 
        ;-------------------------------------------------
        ;  Initialize
        ;-------------------------------------------------
        label = ['','Structure','Hash']
        if scope_level() eq 2 then txt=[' '+innam+':  '+label[flag]] else txt=!null
 
        ;-------------------------------------------------
        ;  Loop over items
        ;-------------------------------------------------
        foreach t, nam, i do begin
          case flag of
0:          v = sh
1:          v = sh.(i)
2:          v = sh[t]
          endcase
          vflag = 0
          if isa(v,'STRUCT') then vflag=1       ; Structure.
          if isa(v,'HASH'  ) then vflag=2       ; Hash.        
          if vflag ne 0 then begin
            tag_list, v, out=vtxt
            txt = [txt,'    '+t+':  '+label[vflag],'    '+vtxt]
          endif else begin
            desc = datatype(v,/desc)
            txt = [txt,'    '+t+':  '+desc]
          endelse
        endforeach
 
        ;-------------------------------------------------
        ;  Output requested?
        ;-------------------------------------------------
;        if scope_level() eq 2 then begin
          if not arg_present(txt) then begin
            more,txt,lines=100
          endif else begin
            if keyword_set(verb) then more,txt,lines=100
          endelse
;        endif
 
        end
