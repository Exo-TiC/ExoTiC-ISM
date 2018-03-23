;---  img_make.pro = Make an image of the specified type and color  ----
;       R. Sterner, 2010 Oct 19

        function img_make, nx, ny, true=tr, color=clr, help=hlp

        if (n_params(0) lt 2) or keyword_set(hlp) then begin
          print,' Make an image of the specified type and color.'
          print,' img = img_make(nx,ny)'
          print,'   nx = New image x size.  in'
          print,'   ny = New image y size.  in'
          print,' Keywords:'
          print,'   TRUE=tr  Dimension over which the color is interleaved.'
          print,'      Must be 1, 2, or 3 for a color image,'
          print,'      or 0 for an 8-bit image.  Default tr is 0.'
          print,'   COLOR=clr Image color, 24-bit color value or 8 bit if'
          print,'      true=0.  Default clr is 0.'
          return,''
        endif

        if n_elements(clr) eq 0 then clr=0
        if n_elements(tr)  eq 0 then tr =0

        ;---  8-bit image  ---
        if tr eq 0 then begin
          return, bytarr(nx,ny) + byte(clr)
        endif

        ;---  24-bit color  ---
        c2rgb, clr, r, g, b
        rr = bytarr(nx,ny) + r
        gg = bytarr(nx,ny) + g
        bb = bytarr(nx,ny) + b
        return, img_merge(rr,gg,bb,true=tr)

        end


