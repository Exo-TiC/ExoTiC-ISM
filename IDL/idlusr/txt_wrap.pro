;-------------------------------------------------------------------------------
;---  txt_wrap.pro = Wrap long lines of text.  ---
;       R. Sterner, 2010 Jun 03

        pro txt_wrap, txtin, txtout, delimiter=del, len1=len1, len2=len2, $
          indent=indent, help=hlp

        if (n_params(0) lt 2) or keyword_set(hlp) then begin
          print,' Wrap a long line of text, returning a text array.'
          print,' txt_wrap, txtin, txtout'
          print,'   txtin = Input line of text (scalar).      in'
          print,'   txtout = Returned text, may be an array.  out'
          print,' Keywords:'
          print,'   DELIMITER=del Word delimiter (def=white space,'
          print,'    spaces and tabs).'
          print,'   LEN1=len1 Max length of first returned line (def=80).'
          print,'   LEN2=len2 Max length of the rest of the lines (def=len1).'
          print,'   /INDENT Indent with spaces the shorter of the two'
          print,'     lengths (len1 or len2) to match the longer.'
          print,' Note: A long line a text will be split into multiple lines'
          print,'   and returned in a text array.  The first line may have a'
          print,'   different length than the rest of the returned lines, as'
          print,'   set by len1 and len2.  For short lines that do not need'
          print,'   wrapped the original text will be returned.'
          print,'   Tab characters are treated as single characters here,'
          print,'   so use the detab function to convert tabs to spaces first.'
          print,'   If the first line line differs from the rest (len1 NE len2)'
          print,'   then /INDENT will indent the shorter lines.'
          return
        endif

        ;---  Set defaults  ---
        if n_elements(del) eq 0 then del=' '
        if n_elements(len1) eq 0 then len1=80
        if n_elements(len2) eq 0 then len2=len1
        ind1 = ''
        ind2 = ''
        if keyword_set(indent) then begin
          ind1 = spc(len2-len1)
          ind2 = spc(len1-len2)
        endif

        ;---  Deal with text that does not need wrapped  ---
        if strlen(txtin) le len1 then begin
          txtout = txtin
          return
        endif

        ;---  Find locations  ---
        txt = txtin                     ; Working copy.
        fndwrd,txt,n,loc,len,del=del    ; Find word locations and lengths.
        lend = loc + len                ; Word end locations.

        ;---  Find first line  ---
        w = where(lend le len1,cnt)     ; Find text within given length.
        if cnt eq 0 then begin
          print,' Warning in txt_wrap: len1 too small for first word in'
          print,' '+txt
          w = 0                         ; Pick off first word only.
        endif
        lo = w[0]
        hi = max(w)
        txtout = ind1 + getwrd(txt,lo,hi,del=del)       ; Start output array.

        ;---  Process rest of text  ---
loop:   txt = getwrd(txt,hi+1,9999)     ; Drop front of text.
        if txt eq '' then return        ; All done.
        fndwrd,txt,n,loc,len,del=del    ; Find word locations and lengths.
        lend = loc + len                ; Word end locations.

        w = where(lend le len2,cnt)     ; Find text within given length.
        if cnt eq 0 then begin
          print,' Error in txt_wrap: len2 too small for first word in:'
          print,' '+txt
          w = 0                         ; Pick off first word only.
        endif
        lo = w[0]
        hi = max(w)
        txtout = [txtout, ind2 + getwrd(txt,lo,hi)]     ; Start output array.

        goto, loop

        end
