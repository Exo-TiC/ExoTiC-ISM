;-------------------------------------------------------------
;+
; NAME:
;       TAG_MODIFY
; PURPOSE:
;       Modify a structure using given functions.
; CATEGORY:
; CALLING SEQUENCE:
;       tag_modify, s, txt
; INPUTS:
;       txt = Modify text with functions to use. in
;             Each line in txt is of the form tag = f(_value)
;             where tag is one of the structure tags and
;             f() is some function of that value of that tag.
;             _value is replaced by the initial value of s.tag,
;             so this really means: s.tag=f(s.tag)
;             See Notes below for examples.
; KEYWORD PARAMETERS:
;       Keywords:
;         ERROR=err Error flag: 0=ok.
;         COUNT=cnt Number of structure tags modified.
;         /INIT means extract the modify lines from txt first.
;               They will between lines bounded by
;               <modify> and </modify> (each on separate lines).
; OUTPUTS:
;       s = Structure to modify.                 in, out
;           May be a structure array.
; COMMON BLOCKS:
; NOTES:
;       Notes: Some example modify lines:
;                sat_lat = _value/8192.*!radeg
;                sat_lon = _value/8192.*!radeg
;                sath_angle = _value/8192.*!radeg
;                sat_cross_angle = _value/8192.*!radeg
;                sat_altitude = _value/1000.
;                Eph_timecode = _value/1024.
;                Sensor_timecode = _value/1024.
;              Only the given tags will be modified (if found).
;              The modify functions could call other routines
;              (functions) if needed.
; MODIFICATION HISTORY:
;       R. Sterner, 2011 Aug 26
;
; Copyright (C) 2011, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
        pro tag_modify, s, txt0, init=init, error=err, $
            count=modcnt, help=hlp
 
        if (n_params(0) lt 2) or keyword_set(hlp) then begin
          print,' Modify a structure using given functions.'
          print,' tag_modify, s, txt'
          print,'   s = Structure to modify.                 in, out'
          print,'       May be a structure array.'
          print,'   txt = Modify text with functions to use. in'
          print,'         Each line in txt is of the form tag = f(_value)'
          print,'         where tag is one of the structure tags and'
          print,'         f() is some function of that value of that tag.'
          print,'         _value is replaced by the initial value of s.tag,'
          print,'         so this really means: s.tag=f(s.tag)'
          print,'         See Notes below for examples.'
          print,' Keywords:'
          print,'   ERROR=err Error flag: 0=ok.'
          print,'   COUNT=cnt Number of structure tags modified.'
          print,'   /INIT means extract the modify lines from txt first.'
          print,'         They will between lines bounded by'
          print,'         <modify> and </modify> (each on separate lines).'
          print,' Notes: Some example modify lines:'
          print,'          sat_lat = _value/8192.*!radeg'
          print,'          sat_lon = _value/8192.*!radeg'
          print,'          sath_angle = _value/8192.*!radeg'
          print,'          sat_cross_angle = _value/8192.*!radeg'
          print,'          sat_altitude = _value/1000.'
          print,'          Eph_timecode = _value/1024.'
          print,'          Sensor_timecode = _value/1024.'
          print,'        Only the given tags will be modified (if found).'
          print,'        The modify functions could call other routines'
          print,'        (functions) if needed.'
          return
        endif
 
        err = 0
 
        ;---------------------------------------------------
        ;  Make sure the modify txt is ready to use
        ;---------------------------------------------------
        ;---  Isolate the modify text lines  ---
        if keyword_set(init) then begin
          txt_keysection,txt0,out=txt,after='<modify>',before='</modify>',$
            /quiet,count=cnt
          if cnt eq 0 then begin
            print,' Error in tag_modify: Could not find a section'
            print,'   delimited by <modify> and </modify>.'
            print,'   Check for typos or an error in the modify text.'
            err = 1
            return
          endif
        endif else begin
          txt = txt0
        endelse
        ;---  Break into tags and functions  ---
        nmod = n_elements(txt)
        tags = getwrd(txt,0)            ; Get tags.
        func = getwrd(txt,1,del='=')    ; Get functions.
 
        ;---------------------------------------------------
        ;  Apply modify text to structure
        ;---------------------------------------------------
        modcnt = 0                                ; Number of tags modified.
        for i=0,nmod-1 do begin                   ; Loop over tags to modify.
          _value = tag_value(s,tags[i],err=err2)  ; Get current value.
          if err2 eq 0 then begin                 ; If tag found then modify.
            r = execute('val='+func[i])           ; Execute modify function.
            if r eq 1 then begin                  ; If successful
              tag_add, s, tags[i], val            ; Update value in structure.
              modcnt = modcnt + 1                 ; Count this change.
            endif ; r
          endif ; err2
        endfor ; i
 
        return
 
        end
