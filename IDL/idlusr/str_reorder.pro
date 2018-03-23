;-------------------------------------------------------------
;+
; NAME:
;       STR_REORDER
; PURPOSE:
;       Reorder the columns of a text array.
; CATEGORY:
; CALLING SEQUENCE:
;       txt2 = str_reorder(txt,order)
; INPUTS:
;       txt = Input text array.    in
;       order = order string.      in
;         A list of column ranges, like '0-9,15-19,10-14'
;         A range has a start and end column or may be a
;         single column.  First column is 0.
;         Ranges are clipped to text width.
; KEYWORD PARAMETERS:
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
;       Notes: Ranges or single columns may be repeated. Ranges
;         may reverse text just by listing the end column first.
; MODIFICATION HISTORY:
;       R. Sterner, 2011 Sep 01
;
; Copyright (C) 2011, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
        function str_reorder, txt, order, help=hlp
 
        if (n_params(0) lt 2) or keyword_set(hlp) then begin
          print,' Reorder the columns of a text array.'
          print,' txt2 = str_reorder(txt,order)'
          print,'   txt = Input text array.    in'
          print,'   order = order string.      in'
          print,"     A list of column ranges, like '0-9,15-19,10-14'"
          print,'     A range has a start and end column or may be a'
          print,'     single column.  First column is 0.'
          print,'     Ranges are clipped to text width.'
          print,' Notes: Ranges or single columns may be repeated. Ranges'
          print,'   may reverse text just by listing the end column first.'
          return,''
        endif
 
        ;--------------------------------------------------------
        ;  Initialize
        ;--------------------------------------------------------
        b = byte(txt)                           ; Convert text to a byte array.
        last = dimsz(b,1)-1                     ; Last column index.
        wordarray,order,c,del=',',number=n      ; Break list into ranges.
        c = repchr(c,'-')                       ; Drop dash.
        w = where(strpos(c,' ') lt 0,cnt)       ; Find single columns.
        if cnt gt 0 then c[w]=c[w]+' '+c[w]     ; Dublicate single columns.
 
        ;--------------------------------------------------------
        ;  Construct output array
        ;--------------------------------------------------------
        for i=0,n-1 do begin                    ; Loop over ranges.
          c1 = (getwrd(c[i],0)+0)<last>0        ; Grab first column.
          c2 = (getwrd('',1)+0)<last>0          ; Grab  last column.
          lo = c1<c2                            ; Min column.
          hi = c1>c2                            ; Max column.
          s = b[lo:hi,*]                        ; Grab section.
          if c1 gt c2 then s=reverse(s,1)       ; Reverse section.
          if i eq 0 then begin                  ; First section.
            out = s
          endif else begin
             out = [out,s]                      ; Add section to output.
          endelse
        endfor
 
        return,string(out)                      ; Convert to string and return.
 
        end
