;-------------------------------------------------------------
;+
; NAME:
;       STR_PARSE
; PURPOSE:
;       Parse tag=str_val pairs in an input string.
; CATEGORY:
; CALLING SEQUENCE:
;       str_parse, txt, out
; INPUTS:
;       txt = Input text to parse.              in
;         Syntax: "tag1=val1, tag2=val2 ..."
;         Commas are optional.  Values must be delimited by
;         quotes, single or double.  Unquoted values are ignored.
;         Any Extra text will be ignored. Values may contain
;         quotes.
; KEYWORD PARAMETERS:
;       Keywords:
;         /QUIET do not print error messages.
;         ERROR=err  Error flag: 0=ok.
;         MSG=msg  Error message.
; OUTPUTS:
;       out = returned structure with results.  out
;         out={count:cnt,tag:tags,val:vals}
; COMMON BLOCKS:
; NOTES:
;       Notes: txt may have multiple tag=str_val pairs, each is
;         located based on an = character.  Errors will indicate
;         missing quotes, extra text is quietly ignored.
; MODIFICATION HISTORY:
;       R. Sterner, 2012 Apr 18
;
; Copyright (C) 2012, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
        pro str_parse, txt, out, error=err, msg=msg, quiet=quiet, help=hlp
 
        if (n_params(0) lt 2) or keyword_set(hlp) then begin
          print,' Parse tag=str_val pairs in an input string.'
          print,' str_parse, txt, out'
          print,'   txt = Input text to parse.              in'
          print,'     Syntax: "tag1=val1, tag2=val2 ..."'
          print,'     Commas are optional.  Values must be delimited by'
          print,'     quotes, single or double.  Unquoted values are ignored.'
          print,'     Any Extra text will be ignored. Values may contain'
          print,'     quotes.'
          print,'   out = returned structure with results.  out'
          print,'     out={count:cnt,tag:tags,val:vals}'
          print,' Keywords:'
          print,'   /QUIET do not print error messages.'
          print,'   ERROR=err  Error flag: 0=ok.'
          print,'   MSG=msg  Error message.'
          print,' Notes: txt may have multiple tag=str_val pairs, each is'
          print,'   located based on an = character.  Errors will indicate'
          print,'   missing quotes, extra text is quietly ignored.'
 
          return
        endif
 
        ;------------------------------------------------------------------
        ;  Initialize
        ;------------------------------------------------------------------
        t = txt                         ; Working copy.
        t = repchr(t,',')               ; Remove commas.
        err = 0                         ; No error flag yet.
        msg = ''                        ; No error message yet.
        tags = ['']                     ; Returned tags.
        vals = ['']                     ; Returned values.
        cnt = 0                         ; Pair count.
        out = {count:cnt, tag:tags, val:vals}
 
        ;------------------------------------------------------------------
        ;  Look for an equal character, assume tag is just before and
        ;  value just after (but allow spaces).
        ;------------------------------------------------------------------
loop:
        pe = strpos(t,'=')              ; Find next =.
        if pe lt 0 then goto, done      ; No more pairs.
        strput, t, ' ', pe              ; Replace = with a space.
        frnt = strmid(t,0,pe)
        tag = getwrd(frnt,/last)        ; Last word is the tag.
        strput,t,spc(strlen(frnt)),0    ; Blank out tag.
        p1 = strpos(t,"'",pe+1)         ; Find next delimiter single quote.
        p2 = strpos(t,'"',pe+1)         ; Find next delimiter double quote.
        if p1 lt 0 then p1=9999         ; Want none to give a big value.
        if p2 lt 0 then p2=9999
        pq1 = p1<p2                     ; Find closest quote (opening).
        if pq1 eq 9999 then begin       ; No more quotes.
          msg = ' Syntax error after '+strtrim(pe,2)+', missing opening quote.'
          if not keyword_set(quiet) then print,msg
          err = 1
          goto, done
        endif
        qt = ''                         ; Maybe no quotes.
        if p1 eq pq1 then qt="'"        ; Was a single quote.
        if p2 eq pq1 then qt='"'        ; Was a double quote.
        pq2 = strpos(t,qt,pq1+1)        ; Find closing quote.
        if pq2 lt 0 then begin          ; Syntax error: No closing quote.
          msg = ' Syntax error after '+strtrim(pq1,2)+', missing closing quote.'
          if not keyword_set(quiet) then print,msg
          err = 1
          goto, done
        endif
        val = strmid(txt,pq1+1,pq2-pq1-1) ; Grab string value.
        strput,t,spc(pq2-pq1+1),pq1     ; Blank out extracted text.
        tags = [tags,tag]               ; Save pair. 
        vals = [vals,val]
        cnt = cnt + 1                   ; Count pair.
        goto, loop
 
done:
        if cnt gt 0 then begin
          tags = tags[1:*]              ; Drop seed values.
          vals = vals[1:*]
        endif
        out = {count:cnt, tag:tags, val:vals}
 
        end
