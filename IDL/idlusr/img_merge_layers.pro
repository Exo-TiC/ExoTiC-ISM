;-------------------------------------------------------------
;+
; NAME:
;       IMG_MERGE_LAYERS
; PURPOSE:
;       Merge two images as layers with transparency.
; CATEGORY:
; CALLING SEQUENCE:
;       img3 = img_merge_layers(img1, img2, trans)
; INPUTS:
;       img1 = Lower layer image.            in
;       img2 = Upper layer image.            in
;       trans = Transparency of upper layer. in
;          This is a 2-D array the same size as the images
;          giving the transparency for each point.
;          Must be 0 to 1, 0 means lower layer not visible at all,
;          1 means lower layer completely visible.
; KEYWORD PARAMETERS:
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
;       Notes: img1 and img2 may be 2-D (B&W) or 3-D (color).
;         If img1 is a 2-D byte array it is treated like a 3-D
;         color image that is in shades of gray.
; MODIFICATION HISTORY:
;       R. Sterner, 2012 Aug 17
;
; Copyright (C) 2012, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
        function img_merge_layers, img1,img2, trns, help=hlp
 
        if (n_params(0) lt 3) or keyword_set(hlp) then begin
          print,' Merge two images as layers with transparency.'
          print,' img3 = img_merge_layers(img1, img2, trans)'
          print,'   img1 = Lower layer image.            in'
          print,'   img2 = Upper layer image.            in'
          print,'   trans = Transparency of upper layer. in'
          print,'      This is a 2-D array the same size as the images'
          print,'      giving the transparency for each point.'
          print,'      Must be 0 to 1, 0 means lower layer not visible at all,'
          print,'      1 means lower layer completely visible.'
          print,' Notes: img1 and img2 may be 2-D (B&W) or 3-D (color).'
          print,'   If img1 is a 2-D byte array it is treated like a 3-D'
          print,'   color image that is in shades of gray.'
          return,''
        endif
 
        ;----------------------------------------------------------
        ;  Check values for input items
        ;----------------------------------------------------------
        if n_elements(img1) eq 0 then begin
          print,' Error in img_merge_layers: img1 undefined.'
          return,''
        endif
        if n_elements(img2) eq 0 then begin
          print,' Error in img_merge_layers: img2 undefined.'
          return,''
        endif
        if n_elements(trns) eq 0 then begin
          print,' Error in img_merge_layers: trans undefined.'
          return,''
        endif
        img_shape, img1, nx=nx1, ny=ny1, true=tr1
        img_shape, img2, nx=nx2, ny=ny2, true=tr2
        img_shape, trns, nx=nxt, ny=nyt, true=trt
        typ = size(img1,/type)          ; Data type for image 1.
        if trt ne 0 then begin
          print,' Error in img_merge_layers: Transparency array must be 2-D'
          return,''
        endif
        if (nx1 ne nx2) or (ny1 ne ny2) then begin
          print,' Error in img_merge_layers: Images must be the same size.'
          return,''
        endif
        if (nxt ne nx1) or (nyt ne ny1) then begin
          print,' Error in img_merge_layers: Transparency arry size must match.'
          return,''
        endif
        if (typ ne 1) and ((tr1<tr2) eq 0) and ((tr1>tr2) ne 0) then begin
          print,' Error in img_merge_layers: Images must be the same type.'
          return,''
        endif
        trans = trns>0<1                ; Force transparency to be 0 to 1.
 
        ;----------------------------------------------------------
        ;  Handle 2-D case
        ;
        ;  If the 2-D image was type byte then drop through and
        ;  use the 3-D code below.  Allows easy entry of a
        ;  background gray shaded image.
        ;----------------------------------------------------------
        if tr1 eq 0 then begin
          if typ ne 1 then begin                ; Let byte type drop through.
            img3 = img1*trans + img2*(1.-trans) ; Merge images.
            return, fix(img3,type=typ)          ; Return same type as img1.
          endif else tr1=3
        endif
 
        ;----------------------------------------------------------
        ;  3-D case
        ;
        ;  If img2 is 2-D it will be split into equal color
        ;  components.
        ;----------------------------------------------------------
        img_split, img1, r1, g1, b1
        img_split, img2, r2, g2, b2
        r3 = r1*trans + r2*(1.-trans)
        g3 = g1*trans + g2*(1.-trans)
        b3 = b1*trans + b2*(1.-trans)
        img3 = img_merge(r3,g3,b3,true=tr1)
        return, fix(img3,type=typ)            ; Return same type as img1.
 
        end
