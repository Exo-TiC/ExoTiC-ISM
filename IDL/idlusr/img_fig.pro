;----  img_fig.pro = Make a figure from a given image  ---
;       R. Sterner, 2012 Sep 21

####################################################
; Use IDL New Graphics to do this if possible.
####################################################

        pro img_fig, img, charsize=csz, title=ttl, save=png, $
          hbar=hbar, vbar=vbar, newrange=newrange, act_file=act_file, $
          text=txt_main, btext=txt_bot, rtext=txt_rgt, layout=layout, help=hlp

        if (n_params(0) lt 1) or keyword_set(hlp) then begin
          print,' Make a figure from the given image.'
          print,' img_fig, img'
          print,'   img = Input image (B&W or Color).  in'
          print,' Keywords:'
          print,'   CHARSIZE=csz Text size (def=1).'
          print,'     Effects size of title and main text.'
          print,'   TITLE=ttl Main title (def=none).'
          print,'   /HBAR or /VBAR  Horizontal (def) or Vertical color bar.'
          print,'   NEWRANGE=newrng Color bar new range keyword.'
          print,'     See act_cbar help for details.'
          print,'   ACT_FILE=afile Absolute color table file if needed.'
          print,'     Default is to use the last one used in the IDL session.'
          print,'   TEXT=txt String array with main block of text to display.'
          print,'   BTEXT=btxt Line of text to display small along bottom.'
          print,'   RTEXT=rtxt Line of text to display small along right.'
          print,'   LAYOUT=layout Structure with layout details to override'
          print,'     default values.'
          print,'   SAVE=png Save figure to given PNG file.'
          return
        endif

        ;------------------------------------------------------------
        ;  Display window size and layout
        ;    wx = Window total size in x.
        ;    wy = Window total size in y.
        ;------------------------------------------------------------

        ;------------------------------------------------------------
        ;  Set defaults
        ;------------------------------------------------------------
        x_mar1 = 30     ; Left margin (pixels).
        x_mar2 = 30     ; Right margin (pixels).
        y_mar1 = 30     ; Bottom margin (pixels).
        y_mar2 = 30     ; Top margin (pixels).

        ;------------------------------------------------------------
        ;  Deal with incoming image
        ;------------------------------------------------------------
        img_shape, img, nx=nx, ny=ny, tr=tr


stop
        end
