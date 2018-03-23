;------------------------------------------------------------------------------
;  js_from_time.pro = General time converter.
;  R. Sterner, 2014 Feb 10
;
;  Tries to convert from amny time format to JS.
;------------------------------------------------------------------------------

        function js_from_time, t, good_index=ingood, bad_index=inbad, $
          typform=typform, help=hlp

        if (n_params(0) lt 1) or keyword_set(hlp) then begin
          print,' Convert time to Julian Seconds'
          print,' js = js_from_time(t)'
          print,'   t = Time (scalar or array).  in'
          print,'     Text string(s).  Tries to handle any format.'
          print,'   js = Julian Seconds.         out'
          print,'     NaN where time could not be converted.'
          print,' Keywords'
          print,'   GOOD_INDEX=ingood Indices of times that were converted.'
          print,'   BAD_INDEX=inbad Indices of times that were not converted.'
          print,'   TYPFORM=typform Array of numeric type codes and formats.'
          print,'     This may not be needed if the dates contain a month'
          print,'     name or at least 3 characters, or it is ISO 8601.  But'
          print,'     if a date is all numeric and not ISO 8601 compliant than'
          print,'     info may be given on how to handle it.  The info is given'
          print,'     in 2 item strings, YMD order code, and a format string:'
          print,"     like 'DMY ddnnyyyyxhhmmss' for example."
          print,'     The codes and formats are described below.'
          print,'     The known codes are:'
          print,'       YMD Date is all numeric: Year, Month, Day'
          print,'       YDM Date is all numeric: Year, Day, Year'
          print,'       DMY Date is all numeric: Day, Month, Year'
          print,'       MDY Date is all numeric: Month, Day, Year'
          print,'       YDN Date is all numeric: Year, Day of year'
          print,'       DNY Date is all numeric: Day of year, Year'
          print,'     FORMAT=fmt Specify format of input.'
          print,'       A format may be needed to indicate date and time.  Use'
          print,'       the letters y,n,d in the same positions as year, month'
          print,'       and day or y and # for year and day number in the input'
          print,'       string, and the pairs hh, mm, and ss[s...] for hour,'
          print,'       minute, second (the s format must include any decimal'
          print,'       point and places) Any other char may be used as'
          print,'       place holders. Case is ignored. Examples:'
          print,"         for txt='gs_06oct09_0208_multi.png' use"
          print,"             fmt='xx_yynnndd_hhmm_xxxxx.xxx'"
          print,"         for txt='gs_20101600208_multi.png' use"
          print,"             fmt='xx_yyyy###hhmm_xxxxx.xxx'"
          print,"         for txt='OCF_20110930T171924.430136' use"
          print,"             fmt='xxxxyyyynnddxhhmmsssssssss'"
          print,'       If s and/or m are not used they default to 0.'
          print,'       Trailing placeholders are not really needed.'
          print,'       >>>===> Make sure to use n for month (m is for minute).'
          print,'       Non-ISO times given with no colons must use a format.'
          print,'       A date may need a format even if it is not all numeric,'
          print,"       like '2014Feb10'.  Can skip the code and just give a"
          print,"       format, in this case 'yyyynnndd'."
          print,' Notes: Julian Seconds are seconds since 2000 Jan 1 00:00:00.'
          print,'   Any numeric codes and formats given in TYPFORM are applied'
          print,'   in the order found there until the first is found that'
          print,'   works, if any. So a date could be interpreted incorrectly'
          print,'   if it is ambiguous.' 
          return,''
        endif

        ;---------------------------------------------
        ;  Try ISO 8601 compliant first
        ;---------------------------------------------
        js = js_from_iso(t)

        ;---------------------------------------------
        ;  Check if ok
        ;---------------------------------------------
        inbad = where(finite(js,/nan),nbad,comp=ingood) ; Look for bad values.
        if nbad eq 0 then return, js                    ; None, all done.

        ;---------------------------------------------
        ;  Try normal date-time conversion
        ;---------------------------------------------
        for i=0,nbad-1 do begin
          j = inbad[i]
          js_try = dt_tm_tojs(t[j],err=err,/quiet)      ; Try to convert.
          if err eq 0 then js[j]=js_try
        endfor

        ;---------------------------------------------
        ;  Check if ok
        ;---------------------------------------------
        inbad = where(finite(js,/nan),nbad,comp=ingood) ; Look for bad values.
        if nbad eq 0 then return, js                    ; None, all done.

        ;---------------------------------------------
        ;  Try given formats if any
        ;---------------------------------------------
        npairs = n_elements(typform)                    ; Any formats?
        if npairs eq 0 then return,js                   ; Can do no more.

        for i=0,nbad-1 do begin
          j = inbad[i]                                  ; Index of next to try.
          t_try = t[j]                                  ; Next time to try.
          for k=0,npairs-1 do begin                     ; Try formats.
            p = typform[k]                              ; Grab next pair.
            code = strupcase(getwrd(p,0))               ; Numeric code.
            frm  = getwrd(p,1)                          ; Format to try.
            case code of
'YMD':        js_try=dt_tm_tojs(t_try,/YMD,form=frm,err=err,/quiet)
'YDM':        js_try=dt_tm_tojs(t_try,/YDM,form=frm,err=err,/quiet)
'DMY':        js_try=dt_tm_tojs(t_try,/DMY,form=frm,err=err,/quiet)
'MDY':        js_try=dt_tm_tojs(t_try,/MDY,form=frm,err=err,/quiet)
'YDN':        js_try=dt_tm_tojs(t_try,/YDN,form=frm,err=err,/quiet)
'DNY':        js_try=dt_tm_tojs(t_try,/DNY,form=frm,err=err,/quiet)
else:         js_try=dt_tm_tojs(t_try,form=code,err=err,/quiet)
            endcase
            if err eq 0 then js[j]=js_try
          endfor ; k = Formats to try.
        endfor ; i = Bad times.

        ;---------------------------------------------
        ;  Check if ok
        ;---------------------------------------------
        inbad = where(finite(js,/nan),nbad,comp=ingood) ; Look for bad values.
        return, js                                      ; Can do no more.

        end
