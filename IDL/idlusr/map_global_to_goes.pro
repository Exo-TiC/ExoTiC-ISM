;------------------------------------------------------------------------------
;  map_global_to_goes.pro = Map a global data set image to match a GOES view.
;  R. Sterner, 2013 Mar 11
;------------------------------------------------------------------------------

        pro map_global_to_goes, img0, lon=lon0, east=east, west=west, $
            revlat=revlat, shiftlon=shiftlon, width=wid, act=act, $
            label=lbl, png=png, help=hlp

        if (n_params(0) lt 1) or keyword_set(hlp) then begin
          print,' Map a global data set image to match a GOES view.'
          print,' map_global_to_goes, img'
          print,'   img = Image to remap.                      in'
          print,'     Image is assumed to be global with'
          print,'     Lon: -180 to +180'
          print,'     Lat: -90 to +90'
          print,'   The img may be 8-bit or 24-bit but scaled for view.'
          print,' Keywords:'
          print,' WIDTH=wid Display window width in pixels (def=500).'
          print,'  /EAST    Match GOES EAST (Default).  Lon =  -75.'
          print,'  /WEST    Match GOES WEST.            Lon = -135.'
          print,'  LON=lon  Longitude of center of view. West lon is < 0.'
          print,'    Use only one of the above 3 keywords.'
          print,'  /REVLAT Reverese data in latitude.'
          print,'  /SHIFTLON Shift longitude by 1/2 image x size.'
          print,'    Use if img lon is 0 to 360 instead f -180 to 180.'
          print,'  ACT=act Name of an absolute color table to apply.'
          print,'  LABEL=lbl  Label to display on image.'
          print,'  PNG=png Save image with the given name.'
          return
        endif

        ;----------------------------------------------------------
        ;  Deal with longitude
        ;----------------------------------------------------------
        lon = -75
        if keyword_set(west) then lon=-135
        if n_elements(lon0) gt 0 then lon=lon0

        ;----------------------------------------------------------
        ;  Deal with latitude orientation
        ;----------------------------------------------------------
        img = img0
        if keyword_set(revlat) then begin
          img_shape, img, true=tr               ; Image interleave dimension.
          case tr of                            ; Reverse y dimension.
0:          img=reverse(img,2)
1:          img=reverse(img,3)
2:          img=reverse(img,3)
3:          img=reverse(img,2)
          endcase
        endif

        ;----------------------------------------------------------
        ;  Deal with longitude alignment
        ;----------------------------------------------------------
        if keyword_set(shiftlon) then begin
          img_shape, img, nx=nx                 ; Image x size.
          img = img_shift(img,-nx/2)            ; Shift by 1/2 x size.
        endif

        ;----------------------------------------------------------
        ;  Set up display window
        ;----------------------------------------------------------
        if n_elements(wid) eq 0 then wid=500    ; Window size.
        window,/free,xs=wid,ys=wid              ; Make window.

        ;----------------------------------------------------------
        ;  Make map and display data
        ;----------------------------------------------------------
        map_set2, 0, lon, /satellite, sat_p=[6.6,0,0], /hor, norbord
        img2 = img_map_image(img,ix,iy,comp=1,/nodisplay)
        if n_elements(act) ne 0 then img2=act_apply(img2,file=act)
        img_shape, img2, tr=tr
        tv,img2,ix,iy,true=tr
        map_space,col=0
        map_continents,/cont,col=0,thick=2
        map_grid, col=200, londel=10, latdel=10, glinestyle=0
        map_put_scale

        ;----------------------------------------------------------
        ;  Image label
        ;----------------------------------------------------------
        if n_elements(lbl) gt 0 then begin
          xyouts, 8,8,/dev,lbl,chars=1.5,col=-1
        endif

        ;----------------------------------------------------------
        ;  Save image
        ;----------------------------------------------------------
        if n_elements(png) gt 0 then begin
          pngscreen, png
        endif

        end
