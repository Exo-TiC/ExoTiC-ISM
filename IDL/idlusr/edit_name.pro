;-------------------------------------------------------------
;+
; NAME:
;       EDIT_NAME
; PURPOSE:
;       Edit a given text string to be suitable for a file name.
; CATEGORY:
; CALLING SEQUENCE:
;       txt2 = edit_name(txt)
; INPUTS:
;       txt = Input text string.      in
; KEYWORD PARAMETERS:
;       Keywords:
;         DROP=dtxt  String with characters to drop.
;           The default is :;?,[]{}()!@^&*+=|\/`~
;           and single and double quotes.
; OUTPUTS:
;       txt2 = output text string.    out
; COMMON BLOCKS:
; NOTES:
;       Notes: Spaces are replaces by _.
; MODIFICATION HISTORY:
;       R. Sterner, 2013 Feb 27
;
; Copyright (C) 2013, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
        function edit_name, txt, drop=drop, help=hlp
 
        if (n_params(0) lt 1) or keyword_set(hlp) then begin
          print,' Edit a given text string to be suitable for a file name.'
          print,' txt2 = edit_name(txt)'
          print,'   txt = Input text string.      in'
          print,'   txt2 = output text string.    out'
          print,' Keywords:'
          print,'   DROP=dtxt  String with characters to drop.'
          print,'     The default is :;?,[]{}()!@^&*+=|\/`~'
          print,'     and single and double quotes.'
          print,' Notes: Spaces are replaces by _.'
          return, ''
        endif
 
        ;---  Replace spaces  ---
        txt2 = repchr(txt,' ','_')
 
        ;---  Drop special characters  ---
        if n_elements(drop) eq 0 then drop=":;?,[]{}()!@^&*+=|\/`'~" + '"'
 
        n = strlen(drop)
 
        for i=0,n-1 do begin
          c = strmid(drop,i,1)
          txt2 = delchr(txt2,c)
        endfor
 
        return, txt2
 
        end
