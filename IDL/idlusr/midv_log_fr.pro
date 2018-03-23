;------------------------------------------------------------------------------
;  midv_log_fr.pro = Return a log friendly midpoint between given values.
;  R. Sterner, 2010 Nov 29
;------------------------------------------------------------------------------

        function midv_log_fr, arr, help=hlp

        if (n_params(0) lt 1) or keyword_set(hlp) then begin
          print,' Return a log friendly midpoint between given values.'
          print,' v = midv_log_fr(arr)'
          print,'   arr = Array of values.                        in'
          print,'   v = Returned log friendly midpoint of array.  out'
          print,' Notes: Tries to return a value near the log'
          print,' midpoint that is a nice number.  May not be'
          print,' the exact log midpoint between the array min and max.'
          print,' Examples:'
          return,'  midv_log_fr([.02,5]) gives 0.3'
          return,'  midv_log_fr([.07,100]) gives 3'
          return,'  midv_log_fr([7,2000]) gives 100'
        endif

        lo = min(arr)
        hi = max(arr)
        vm = midv(alog10([lo,hi]))              ; Actual log midpoint.
        vx = alog10(makexlog(lo,hi,1.))         ; Array of log friendly vals.

        d = abs(vm-vx)                          ; Distance in log space.
        w = where(d eq min(d))                  ; Find closest to real midpoint.
        va = 10^vx[w[0]]                        ; Chosen value.

        return, va

        end
