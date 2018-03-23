;---  img_clrcpy.pro = Copy colors from one image to another.   ---
;   R. Sterner, 2010 Mar 12
;------------------------------------------------------------------------------

    pro img_clrcpy, imgs, imgd, clr, selection=sel, sx=sx, sy=sy, $
        new_colors=nclr, help=hlp

    if (n_params(0) lt 3) or keyword_set(hlp) then begin
      print,' Copy specified colors from one image to another.'
      print,' img_clrcpy, imgs, imgd, clr'
      print,'   imgs = Source image.                      in'
      print,'   imgd = Destination image.                 in'
      print,'   clr = Array of colors (may be a scalar).  in'
      print,'     For color images these will be 24-bit colors.'
      print,' Keywords:'
      print,'   SELECTION=sel An optional selection box.'
      print,'     Only work inside this box.  sel = [ix1,iy1,ix2,iy2]'
      print,'     where ix1,iy1 are the image x and y indices of the'
      print,'     lower left corner of the box, and ix2,iy2 are the'
      print,'     indices of the upper right corner.  The entire image'
      print,'     is used by default.'
      print,'   SX=sx, SY=sy Optional selection polygon.'
      print,'     Can use SELECTION or SX, SY or both together.'
      print,'     A polygon is defined in image coordinates in sx and sy.'
      print,'     Only colored pixels inside that polygon (and SELECTION)'
      print,'     are copied.'
      print,'   NEW_COLORS=nclr May change the colors when copied by'
      print,'     giving a list of new color values.  Must be'
      print,'     one new color for each old color if this option is used.'
      return
    endif

    ;---  Check that images are the same size  ---
    img_shape, imgs, nx=nx1, ny=ny1
    img_shape, imgd, nx=nx2, ny=ny2
    if (nx1 ne nx2) or (ny1 ne ny2) then begin
      print,' Error in img_clrcpy: The given images must be the same size.'
      return
    endif

    ;---  Initialize  ---
    if n_elements(nclr) eq 0 then nclr=clr      ; No color change by default.
    if n_elements(sel) eq 0 then begin          ; Use full image by default.
      sel = [0,0,nx1-1,ny1-1]
    endif
    ix1 = sel[0]                                ; Selection box.
    iy1 = sel[1]
    ix2 = sel[2]
    iy2 = sel[3]
    if n_elements(sx) eq 0 then begin           ; Define selection polygon.
      sx = [0,nx1-1,nx1-1,0]
      sy = [0,0,ny1-1,ny1-1]
    endif
    flag = bytarr(nx1,ny1)                      ; Pixel flags.
    in = polyfillv(sx,sy,nx1,ny1)               ; Indices inside selection.
    flag[in] = 1                                ; Set flag to keep pixels.

    ;---  Loop over given colors  ---
    for i=0, n_elements(clr)-1 do begin
      ;---  Look for i'th color in source image  ---
      w = img_wclr(imgs,color=clr[i],count=cnt) ; Look for color.
      if cnt eq 0 then continue                 ; Not found, skip to next.
      ;---  Keep only colored pixels inside selection box  ---
      one2two, w, [nx1,ny1], ix, iy             ; Convert to 2-d indices.
      w = where((ix ge ix1) and (ix le ix2) and $ ; Pick pixels in selection.
                (iy ge iy1) and (iy le iy2), cnt)
      if cnt eq 0 then continue                 ; Skip if none.
      ix = ix[w]                                ; Keep only pixels in box.
      iy = iy[w]
      ;---  Keep only colored pixels inside selection polygon  ---
      w = where(flag[ix,iy] eq 1, cnt)
      if cnt eq 0 then continue                 ; Not found, skip to next.
      ix = ix[w]                                ; Keep only pixels in box.
      iy = iy[w]
      ;---  Convert indices back to 1-d and copy colors  ---
      two2one, ix, iy, [nx1,ny1], w2            ; Back to 1-d indices.
      imgd = img_clrw(imgd,w2,color=nclr[i])    ; Set color.
    endfor

    end
