;-----------------------------------------------------------------------------
;  js_from_iso.pro = Convert a time in ISO 8601 format to JS.
;  R. Sterner, 2014 Feb 07
;  R. Sterner, 2014 Feb 18 --- Now handles more formats.
;-----------------------------------------------------------------------------

        function js_from_iso, t_iso, error=err, help=hlp

        if (n_params(0) lt 1) or keyword_set(hlp) then begin
          print,' Convert a time in ISO 8601 format to JS.'
          print,' js = js_from_iso(t_iso).'
          print,'   t_iso = Input time in ISO 8601 format.  in'
          print,'   js = Time in Julian Seconds.            out'
          print,'        js is seconds after 2000 Jan 1 00:00:00.'
          print,' Keywords:'
          print,'   ERROR=err  0=ok, else could not convert.'
          return,''
        endif

        ;-----------------------------------------------------------------
        ;  Recurse on arrays
        ;-----------------------------------------------------------------
        n = n_elements(t_iso)
        if n gt 1 then begin
           out = dblarr(n)
           for i=0,n-1 do begin
              out[i] = js_from_iso(t_iso[i])
           endfor
           return, out
        endif

        ;-----------------------------------------------------------------
        ;  Check if an ISO 8601 time and find format
        ;
        ;  Allowed cases:
        ;    2014-02-07T13:47:56   ln=19, pt=10, pd= 4, pc=13
        ;    2014-02-07T13:47      ln=16, pt=10, pd= 4, pc=13
        ;    20140207T134756       ln=15, pt= 8, pd=-1, pc=-1
        ;    20140207T1347         ln=13, pt= 8, pd=-1, pc=-1
        ;    2014-02-07            ln=10, pt=-1, pd= 4, pc=-1
        ;    20140207              ln= 8, pt=-1, pd=-1, pc=-1
        ;
        ;  Allowed near-ISO cases:
        ;    2014-02-07 13:47:56                       ln ge 19, pt lt  0, pd= 4, pc=13, nc=2
        ;    2014-02-07 13:47:56 T_somewhere_out_here  ln ge 19, pt gt 15, pd= 4, pc=13, nc=2
        ;    2014-02-07 13:47                          ln ge 16, pt lt  0, pd= 4, pc=13, nc=1
        ;    2014-02-07 13:47 T_somewhere_out_here     ln ge 16, pt gt 15, pd= 4, pc=13, nc=1
        ;
        ;  Not allowed cases:
        ;    13:47:56              ln= 8, pt=-1, pd=-1, pc= 2
        ;    134756                ln= 6, pt=-1, pd=-1, pc=-1
        ;-----------------------------------------------------------------
        ln = strlen(t_iso)      ; ln = length of string.
        pt = strpos(t_iso,'T')  ; pt = position of 'T'.
        pd = strpos(t_iso,'-')  ; pd = position of '-'.
        pc = strpos(t_iso,':')  ; pc = position of ':'.
        w = where(byte(t_iso) eq (byte(':'))[0],nc)     ; nc = ':'s.

        frm = ''
        if (ln eq 19) and (pt eq 10) and (pd eq  4) and (pc eq 13) and (nc eq 2) then frm='yyyy-nn-ddThh:mm:ss'
        if (ln eq 19) and (pt lt  0) and (pd eq  4) and (pc eq 13) and (nc eq 2) then frm='yyyy-nn-dd hh:mm:ss'

        if (ln eq 16) and (pt eq 10) and (pd eq  4) and (pc eq 13) and (nc eq 1) then frm='yyyy-nn-ddThh:mm'
        if (ln eq 16) and (pt lt  0) and (pd eq  4) and (pc eq 13) and (nc eq 1) then frm='yyyy-nn-dd hh:mm'

        if (ln eq 15) and (pt eq  8) and (pd eq -1) and (pc eq -1) then frm='yyyynnddThhmmss'
        if (ln eq 15) and (pt lt  0) and (pd eq -1) and (pc eq -1) then frm='yyyynndd hhmmss'

        if (ln eq 13) and (pt eq  8) and (pd eq -1) and (pc eq -1) then frm='yyyynnddThhmm'
        if (ln eq 13) and (pt lt  0) and (pd eq -1) and (pc eq -1) then frm='yyyynndd hhmm'

        if (ln eq 10) and (pt eq -1) and (pd eq  4) and (pc eq -1) then frm='yyyy-nn-dd'
        if (ln eq  8) and (pt eq -1) and (pd eq -1) and (pc eq -1) then frm='yyyynndd'

        ;-----------------------------------------------------------------
        ;  Time form not recognized
        ;
        ;  May have extra stuff confusing things.  Try using just the
        ;  first 2 words as time and then just the first.  This may allow
        ;  for text after the time string, like a time zone (ignored).
        ;-----------------------------------------------------------------
        if frm eq '' then begin
          ;---  More then 2 parts to given time  ---
          if nwrds(t_iso) ge 3 then begin
            try = js_from_iso(getwrd(t_iso,0,1))        ; Try first two words only.
            if finite(try,/nan) eq 0 then return, try   ; Got a value.
          endif
          ;---  More then 1 part to given time  ---
          if nwrds(t_iso) ge 2 then begin
            try = js_from_iso(getwrd(t_iso,0))          ; Try first word only.
            if finite(try,/nan) eq 0 then return, try   ; Got a value.
          endif
        endif ; frm

        ;-----------------------------------------------------------------
        ;  Error if not a valid ISO time
        ;-----------------------------------------------------------------
        if frm eq '' then begin
          err = 1
          return,!values.d_nan
        endif

        ;-----------------------------------------------------------------
        ;  Convert to JS if possible
        ;-----------------------------------------------------------------
        try = dt_tm_tojs(t_iso,/ymd,form=frm,err=err,/quiet)
        if err ne 0 then return, !values.d_nan else return, try

        end
