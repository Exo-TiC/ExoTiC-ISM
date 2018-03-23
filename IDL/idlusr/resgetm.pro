;------------------------------------------------------------------------------
;  resgetm.pro = resget for multiple variables.
;  R. Sterner, 2014 Mar 26
;------------------------------------------------------------------------------

        pro resgetm, vlist, out, file=file, help=hlp

        if (n_params(0) lt 2) or keyword_set(hlp) then begin
          print,' Do a resget for multiple names.'
          print,' resgetm, list, out'
          print,'   vlist = List of variables to get.    in'
          print,'   out = Returned structure with data.  out'
          print,' Keywords:'
          print,'   FILE=resfile  Name of resfile to use.'
          print,'     Will open it if needed.'
          return
        endif

        for i=0, n_elements(vlist)-1 do begin
          resget,vlist[i],val,file=file
          if i eq 0 then begin
            out = create_struct(vlist[i],val)
          endif else begin
            out = create_struct(out,vlist[i],val)
          endelse
        endfor

        end
