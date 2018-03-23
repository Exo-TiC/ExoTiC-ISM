;-------------------------------------------------------------
;+
; NAME:
;       TAG_CLASH
; PURPOSE:
;       Find and fix a potential structure tag clash.
; CATEGORY:
; CALLING SEQUENCE:
;       tag_out = tag_clash(tag_in,s)
; INPUTS:
;       tag_in = Given tag to test.                 in
;       s = Structure to test against.              in
; KEYWORD PARAMETERS:
; OUTPUTS:
;       tag_out = Returned tag fixed to not clash.  out
; COMMON BLOCKS:
; NOTES:
;       Notes: If tag_in is found in structure s then
;       a trailing underscore is added and it is tested
;       again.  This is repeated until the test is passed.
;       If tag is not in s it is just returned.
; MODIFICATION HISTORY:
;       R. Sterner, 2012 Jun 29
;
; Copyright (C) 2012, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
        function tag_clash, tag0, s, help=hlp
 
        if (n_params(0) lt 2) or keyword_set(hlp) then begin
          print,' Find and fix a potential structure tag clash.'
          print,' tag_out = tag_clash(tag_in,s)'
          print,'   tag_in = Given tag to test.                 in'
          print,'   s = Structure to test against.              in'
          print,'   tag_out = Returned tag fixed to not clash.  out'
          print,' Notes: If tag_in is found in structure s then'
          print,' a trailing underscore is added and it is tested'
          print,' again.  This is repeated until the test is passed.'
          print,' If tag is not in s it is just returned.'
          return,''
        endif
 
        s_tags = tag_names(s)
        tag = strupcase(tag0)
 
        repeat begin
          w = where(tag eq s_tags,cnt)
          if cnt gt 0 then tag=tag+'_'
        end until cnt eq 0
 
        return, tag
 
        end
