;---  xhelpf.pro = Display help text from a file (or array).  ---
;       R. Sterner, 2010 Aug 18

        pro xhelpf, t, tag=tag, after=after,pre=pre, $
            post=pst, error=err, _extra=extra, help=hlp

        if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Widget to display help text from a file or array.'
	  print,' xhelpf, t'
	  print,'   t = Help file name or string array with help text.  in'
	  print,' Keywords:'
          print,'   TAG=tag Give a key delimiting a section of the text'
          print,'      to display.  Display the text lines between'
          print,'      <tag> and </tag>, each which must be on separate'
          print,'      lines (similar to html tags).  The characters'
          print,'      <, >, and / are added and should not be given.'
          print,'      If the start and end tag are different use TAG=tag'
          print,'      for the start tag and AFTER=after for the end tag.'
          print,'      In this case no characters are added so give the'
          print,'      tags just as they appear on the lines.'
          print,'   AFTER=after Used with TAG=tag to give the start and end'
          print,'      delimiters of the text to display.'
          print,'   PRE=pre  Array of text to add to front of displayed text.'
          print,'   POST=pst Array of text to add to   end of displayed text.'
          print,'   ERROR=err Error flag, 0=ok.'
          print,' May also give any keywords used by xhelp since this'
          print,' routine is a wrapper for xhelp.'
          return
        end

        ;----------------------------------------------------
        ;  Get initial text
        ;----------------------------------------------------
        if n_elements(t) eq 1 then begin
          txt = getfile(t,error=err)
          if err ne 0 then return
        endif else txt=t

        ;----------------------------------------------------
        ;  Deal with delimiters
        ;----------------------------------------------------
        if n_elements(tag) eq 0 then begin      ; No delimiter, use all of txt.
          tt = txt
        endif else begin                        ; Delimiter(s) given.
          if n_elements(after) eq 0 then begin
            atag = '<'+tag+'>'
            btag = '</'+tag+'>'
          endif else begin
            atag = tag
            btag = after
          endelse
          txt_keysection,txt,out=tt,after=atag,before=btag,err=err
          if err ne 0 then return
        endelse

        ;----------------------------------------------------
        ;  Deal with pre and post text arrays
        ;----------------------------------------------------
        if n_elements(pre) ne 0 then tt = [pre,tt]
        if n_elements(pst) ne 0 then tt = [tt,pst]

        ;----------------------------------------------------
        ;  Display text
        ;----------------------------------------------------
        xhelp, tt, _extra=extra

        end
