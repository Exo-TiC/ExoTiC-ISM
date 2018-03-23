;------------------------------------------------------------------------------
;  img_fft_blur.pro = Blur an image using ffts.
;  R. Sterner, 2013 Dec 24
;------------------------------------------------------------------------------

        function img_fft_blur, img, k0, help=hlp

        if (n_params(0) lt 2) or keyword_set(hlp) then begin
          print,' Blur an image with a kernel using FFTs.'
          print,' img_out = img_fft_blur(img_in, kernel)'
          print,'   img_in = Input image (B&W or Color).   in'
          print,'   kernel = Blurring kernel (2-D).        in'
          print,'   img_out = Returned blurred image.      out'
          return,''
        endif

        img_shape, img, true=tr                  ; Image interleave.

        ;----------------------------------------------
        ;  2-D image
        ;----------------------------------------------
        if tr eq 0 then begin
          t = convol_fft(img,k0)
          if datatype(img) ne 'BYT' then return, t
          return, bytscl(t)
        endif

        ;----------------------------------------------
        ;  Color image
        ;----------------------------------------------
        img_split, img, r, g, b                 ; Split into color channels.
        r2 = convol_fft(r,k0)
        g2 = convol_fft(g,k0)
        b2 = convol_fft(b,k0)
        out = bytscl(img_merge(r2,g2,b2,true=tr))
        return, out

        end
