;-----------------------------------------------------------------------------
;  test_image_pro.pro = Example image procedure for img_fileviewer.
;  R. Sterner, 2013 Feb 05
;-----------------------------------------------------------------------------

        pro test_image_pro, name, init=init, term=term

        common test_image_pro_com, x0, y0, fa, xa, ya, lun

        if keyword_set(init) then begin
          fa = ['']
          xa = [0]
          ya = [0]
          print,' Initialized.'
          return
        endif

        if keyword_set(term) then begin
          fa = fa[1:*]
          xa = xa[1:*]
          ya = ya[1:*]
          s = {file:fa, x:xa, y:ya}
          out = 'coordinates.txt'
          txtdb_wr,out,s
          print,' TXTDB file complete: ',out
          return
        endif

        if n_elements(x0) ne 0 then begin
          x = x0
          y = y0
        endif

        xcursor,x,y,/dev

        x0 = x
        y0 = y

        fa = [fa,name]
        xa = [xa,x]
        ya = [ya,y]

        wait,0.2

        print,' ---  Name = ',name, x, y


        end
