;------------------------------------------------------------------------------
;  winnew.pro = Make a new window, either for X or Z.
;  R. Sterner, 2011 May 04
;------------------------------------------------------------------------------

        pro winnew, xs, ys, index=ind, small=small, big=big, status=stat, $
          zbuff=zbuff, help=hlp, _extra=extra

        if keyword_set(hlp) then begin
          print,' Create a new plot window on screen or Z buffer.'
          print,' winnew, xsize, ysize'
          print,'   xsize, ysize = Window size in pixels.'
          print,' Keywords:'
          print,'   INDEX=in Window index to make (Def=0, ignored for Z).'
          print,'   /SMALL Make window 1/4 screen size.'
          print,'   /BIG   Make window 90% screen size.'
          print,'     Default window size is 1/2 screen size.'
          print,'   /ZBUFF Use the Z Buffer.'
          print,'   STATUS=stat Returned window status in a structure:'
          print,'     DEV = Plot device (like X or Z buffer)'
          print,'     INDEX = Window index (-1 for Z buffer)'
          print,'     XSIZE = Window X size in pixels.'
          print,'     YSIZE = Window Y size in pixels.'
          print,'     FACT_CSZ = Character size factor (0.75 for Z buffer).'
          return
        endif

        ;-----------------------------------------------------
        ;  What device?
        ;-----------------------------------------------------
        dev = !d.name                                      ; Get plot device.

        ;-----------------------------------------------------
        ;  Z Buffer
        ;-----------------------------------------------------
        if (dev eq 'Z') or (keyword_set(zbuff)) then begin
          if n_elements(xs) eq 0 then xs=640               ; Default X size.
          if n_elements(ys) eq 0 then ys=512               ; Default Y size.

          zwindow, xsize=xs, ysize=ys, _extra=extra

          stat = {dev:dev, index:-1, xsize:xs, ysize:ys, fact_csz:0.75}
         return
        endif

        ;-----------------------------------------------------
        ;  X Windows
        ;-----------------------------------------------------
        device, get_screen_size=ss                         ; Get screen size.
        xmx = round(0.90*ss[0])                            ; Max allowed X size.
        ymx = round(0.90*ss[1])                            ; Max allowed Y size.

        if n_elements(xs) eq 0 then begin                  ; X size not given.
          xs = round(0.50*ss[0])                           ; Default X size.
          if keyword_set(small) then xs=round(0.25*ss[0])  ; Small X size.
          if keyword_set(big)   then xs=xmx                ; Big X size.
        endif

        if n_elements(ys) eq 0 then begin                  ; Y size not given.
          ys = round(0.50*ss[1])                           ; Default Y size.
          if keyword_set(small) then ys=round(0.25*ss[1])  ; Small Y size.
          if keyword_set(big)   then ys=ymx                ; Big Y size.
        endif

        if n_elements(ind) eq 0 then ind=0                 ; Default win index.

        if (xs le xmx) and (ys le ymx) then begin
          window, ind, xsize=xs, ysize=ys, _extra=extra    ; Make screen window.
        endif else begin
          swindow, xsize=xs, ysize=ys, index=indx, _extra=extra
          ind = indx[0]
        endelse

        ind = !d.window                                    ; Actual win index.
        stat = {dev:dev, index:ind, xsize:xs, ysize:ys, fact_csz:1.00}

        end
