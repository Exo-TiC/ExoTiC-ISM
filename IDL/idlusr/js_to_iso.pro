;-----------------------------------------------------------------------------
;  js_to_iso.pro = Convert a time in JS to ISO 8601 format.
;  R. Sterner, 2014 Feb 06
;-----------------------------------------------------------------------------

        function js_to_iso, js, fraction=frac, decimal=dec, compact=com, $
          date=date, time=time, help=hlp

        if (n_params(0) lt 1) or keyword_set(hlp) then begin
          print,' Convert a time in JS to ISO 8601 format.'
          print,' t_iso = js_to_iso(js)'
          print,'   js = Time in Julian Seconds.               in'
          print,'        js is seconds after 2000 Jan 1 00:00:00.'
          print,'   t_iso = Returned time in ISO 8601 format.  out'
          print,' Keywords:'
          print,'   /FRACTION Display fraction of a second (def=no fraction).'
          print,'   DECIMAL=dp Decimal places to display (def=3).'
          print,'   /COMPACT Use compact form: no -, no :.'
          print,'   /DATE Return date only.'
          print,'   /TIME Return time only.'
          return,''
        endif

        ;----------------------------------------------
        ;  There are 3 main cases:
        ;    Date only, Time only, Both
        ;----------------------------------------------
        flag = 3
        if keyword_set(date) then flag=1
        if keyword_set(time) then flag=2

        case flag of
        ;---  Both date and time  ---
3:      begin
          if keyword_set(com) then frm='Y$0n$0d$Th$m$s$' $
          else frm='Y$-0n$-0d$Th$:m$:s$'
          if keyword_set(frac) then frm=frm+'f$'
        end
        ;---  Time only  ---
2:      begin
          if keyword_set(com) then frm='h$m$s$' $
          else frm='h$:m$:s$'
          if keyword_set(frac) then frm=frm+'f$'
        end
        ;---  Date only  ---
1:      begin
          if keyword_set(com) then frm='Y$0n$0d$' $
          else frm='Y$-0n$-0d$'
        end
        endcase

        return, dt_tm_fromjs(js,form=frm,fraction=frac,decimal=dec)

        end
