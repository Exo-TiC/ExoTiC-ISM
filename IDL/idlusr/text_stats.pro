;-------------------------------------------------------------
;+
; NAME:
;       TEXT_STATS
; PURPOSE:
;       For entered text give a line, word, and character count.
; CATEGORY:
; CALLING SEQUENCE:
;       text_stats, [out]
; INPUTS:
; KEYWORD PARAMETERS:
;       Keywords:
;         XSIZE=xsz Text entry width in characters (def=132).
;         YSIZE=ysz Text entry height in lines (def=20).
; OUTPUTS:
;       out = Optionally returned text.  out
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 2012 Aug 06
;
; Copyright (C) 2012, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
        pro text_stats, out, xsize=xsz, ysize=ysz, help=hlp
 
        if keyword_set(hlp) then begin
          print,' For entered text give a line, word, and character count.'
          print,' text_stats, [out]'
          print,'   out = Optionally returned text.  out'
          print,' Keywords:'
          print,'   XSIZE=xsz Text entry width in characters (def=132).'
          print,'   YSIZE=ysz Text entry height in lines (def=20).'
          return
        end
 
        if n_elements(xsz) eq 0 then xsz=132
        if n_elements(ysz) eq 0 then ysz=20
 
        xtxtin,out,xsize=xsz,ysize=ysz,/text_count, $
          title='Enter text and click the "Text count" button'
 
        end
