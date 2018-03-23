;-------------------------------------------------------------
;+
; NAME:
;       IMG_DISP
; PURPOSE:
;       Display a given image.
; CATEGORY:
; CALLING SEQUENCE:
;       img_disp, img
; INPUTS:
;       img = Input image.  in
;         2-d array, 3-d array, or file name.
;         May also be an existing window index.
;         A 1-D array is treated like a NX x 1 or 1 x NY array.
;         A 1-D color image has dimensions n,1,3 in any order.  If
;         the 1 is last it may be lost, add it back using reform.
; KEYWORD PARAMETERS:
;       Keywords:
;         /SCALE Bytescl image for display.
;         MAG=mag  Mag factor (def=1).
;         SMAG=smag  Like MAG but smooth image first if smag LE 0.5
;           mag or smag may be 2-d for x and y mag factors,
;           in that case any embedded scaling will be ignored.
;         ROTATE=rot as used by the IDL ROTATE function (0-7).
;         REBIN_MAG=rmag Use rebin to change the original image
;           dimensions before doing a rotate or mag or smag.
;           This mag factor, rmag, is applied to both dimensions.
;         TITLE=ttl Image window title.  Defaults to name and size.
;           Can change later: if current window do:
;           widget_control,swinfo(/base),base_set_title=newtitle
;         /ADDSIZE means image size to end of title text.
;         /CURRENT Use current window if correct size.
;           May also say CURRENT=n to look back n windows for
;           a size match.
;         /NOSHOW Means do not bring window to the front.
;         WINDOW=win  Specify which window to use.  If it does not
;           exist then make it.  TITLE only works for new windows.
;         /ORDER display the image reversed in Y.
;         XPOS=x, YPOS=y  Optional window position.
;         X_SCR=x_scr X size of scrolling region.
;         Y_SCR=y_scr Y size of scrolling region.
;           Def = up to 90% of screen size.
;         /SMALL  Use a smaller window.
;         /PIXMAP means use a pixmap.
;        GROUP_LEADER=grp  specified group leader.  When the
;          group leader widget is destroyed this widget is also.
;         INFO=info Embedded scaling info in a structure (null if none).
;         ERROR=err error flag: 0=ok, 1=not 2-D or 3-D,
;           2=wrong number of color channels for 3-D array.
;           3=file not read.
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
;       Note: Normally used for byte images but may also be
;         be used for INT and UINT images. These will scale
;         -32768 to 32677 and 0 to 65536 to 0 to 255 for display.
;         So even if an INT image is already 0 to 255 it will
;         not display correctly without /SCALE.  To manually
;         scale a flag image (0,1) use *255B.
;         Displays in an swindow (scrolling window widget).
;         Can delete using swdelete.
; MODIFICATION HISTORY:
;       R. Sterner, 2002 Jun 03
;       R. Sterner, 2002 Jun 11 --- Allowed INT and UINT images.
;       R. Sterner, 2003 Mar 13 --- Added XPOS, YPOS, X_SCR, Y_SCR keywords.
;       R. Sterner, 2003 Mar 21 --- Added GROUP_LEADER.
;       R. Sterner, 2003 Apr 02 --- Always use swindow (allows title change).
;       R. Sterner, 2003 Apr 21 --- Allowed CURRENT=n to match last n windows.
;       R. Sterner, 2003 Apr 21 --- Can add image size to title.
;       R. Sterner, 2004 May 20 --- Added window index to default title.
;       R. Sterner, 2005 Jan 17 --- Added /pixmap.
;       R. Sterner, 2006 Jan 25 --- Added /quiet to swindow call.
;       R. Sterner, 2006 Jan 25 --- Allowed x and y mag factors.
;       R. Sterner, 2006 Mar 16 --- Fixed bug in trying to set title for a
;       normal window (not swindow).
;       R. Sterner, 2007 May 08 --- Added /SCALE.
;       R. Sterner, 2007 Oct 18 --- Added WINDOW=win.
;       R. Sterner, 2007 Nov 08 --- Added /NOSWIN.
;       R. Sterner, 2008 Jan 25 --- Added ROTATE=rot.
;       R. Sterner, 2008 Mar 27 --- Added REBIN_MAG=rmag.
;       R. Sterner, 2008 May 15 --- Added var name to title if interactive.
;       R. Sterner, 2008 Jun 24 --- Made scale apply to image or file.
;       R. Sterner, 2008 Jun 25 --- Allowed existing window index.
;       R. Sterner, 2008 Jul 01 --- Noted INT images in help text.
;       R. Sterner, 2008 Sep 29 --- Ignored NaN for /SCALE.
;       R. Sterner, 2010 Feb 22 --- Added set_scale and map_set_scale.
;       R. Sterner, 2010 Feb 23 --- Embedded info in a structure (null if none).
;       R. Sterner, 2010 Apr 09 --- Changed SCINFO to INFO.
;       R. Sterner, 2010 May 07 --- Converted arrays from () to [].
;       R. Sterner, 2010 Sep 08 --- Now allows 1-D arrays (B&W or Color).
;       R. Sterner, 2011 Mar 10 --- Changed /NOSWIN to /SMALL and made default.
;       R. Sterner, 2011 Mar 10 --- Added /NOSHOW.
;       R. Sterner, 2013 Jan 10 --- Allowed extra dimensions of 1.
;       R. Sterner, 2014 Jun 30 --- Fixed GROUP_LEADER to work.
;
; Copyright (C) 2002, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro img_disp, imag, title=ttl0, current=curr, xpos=xpos, ypos=ypos, $
	  order=order, mag=mag, smag=smag, error=err, addsize=addsize, $
	  x_scr=x_scr, y_scr=y_scr, pixmap=pixmap0, group_leader=grp, $
	  scale=scale, window=winuse, small=small, $
	  rotate=rot, rebin_mag=rmag, info=info, noshow=noshow, help=hlp
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Display a given image.'
	  print,' img_disp, img'
	  print,'   img = Input image.  in'
	  print,'     2-d array, 3-d array, or file name.'
	  print,'     May also be an existing window index.'
          print,'     A 1-D array is treated like a NX x 1 or 1 x NY array.'
          print,'     A 1-D color image has dimensions n,1,3 in any order.  If'
          print,'     the 1 is last it may be lost, add it back using reform.'
	  print,' Keywords:'
	  print,'   /SCALE Bytescl image for display.'
	  print,'   MAG=mag  Mag factor (def=1).'
	  print,'   SMAG=smag  Like MAG but smooth image first if smag LE 0.5'
	  print,'     mag or smag may be 2-d for x and y mag factors,'
	  print,'     in that case any embedded scaling will be ignored.'
	  print,'   ROTATE=rot as used by the IDL ROTATE function (0-7).'
	  print,'   REBIN_MAG=rmag Use rebin to change the original image'
	  print,'     dimensions before doing a rotate or mag or smag.'
	  print,'     This mag factor, rmag, is applied to both dimensions.'
	  print,'   TITLE=ttl Image window title.  Defaults to name and size.'
	  print,'     Can change later: if current window do:'
	  print,'     widget_control,swinfo(/base),base_set_title=newtitle' 
	  print,'   /ADDSIZE means image size to end of title text.'
	  print,'   /CURRENT Use current window if correct size.'
	  print,'     May also say CURRENT=n to look back n windows for'
	  print,'     a size match.'
	  print,'   /NOSHOW Means do not bring window to the front.'
	  print,'   WINDOW=win  Specify which window to use.  If it does not'
	  print,'     exist then make it.  TITLE only works for new windows.'
	  print,'   /ORDER display the image reversed in Y.'
	  print,'   XPOS=x, YPOS=y  Optional window position.'
	  print,'   X_SCR=x_scr X size of scrolling region.'
	  print,'   Y_SCR=y_scr Y size of scrolling region.'
	  print,'     Def = up to 90% of screen size.'
	  print,'   /SMALL  Use a smaller window.'
	  print,'   /PIXMAP means use a pixmap.'
	  print,'  GROUP_LEADER=grp  specified group leader.  When the'
	  print,'    group leader widget is destroyed this widget is also.'
	  print,'   INFO=info Embedded scaling info in a structure (null if none).'
	  print,'   ERROR=err error flag: 0=ok, 1=not 2-D or 3-D,'
	  print,'     2=wrong number of color channels for 3-D array.'
	  print,'     3=file not read.'
	  print,' Note: Normally used for byte images but may also be'
	  print,'   be used for INT and UINT images. These will scale'
	  print,'   -32768 to 32677 and 0 to 65536 to 0 to 255 for display.'
	  print,'   So even if an INT image is already 0 to 255 it will'
	  print,'   not display correctly without /SCALE.  To manually'
	  print,'   scale a flag image (0,1) use *255B.'
	  print,'   Displays in an swindow (scrolling window widget).'
	  print,'   Can delete using swdelete.'
	  return
	endif
 
        ;------  Image is from a file  ---------
	if datatype(imag) eq 'STR' then begin	; Image file name.
	  ;----  Try to read image  -----------
	  img0 = read_image(imag, r, g, b)
	  ;----  Image not read?  -------------
	  if n_elements(img0) eq 1 then begin
	    print,' Error in img_disp: Image not read: '+imag
	    err = 3
	    return
	  endif
	  img = img0
	  ;----  Deal with IDL PNG bug  --------
	  filebreak, imag, ext=ext
	  if strlowcase(ext) eq 'png' then begin  ; Handle IDL 5.3 png bug.
	    if !version.release lt 5.4 then img=img_rotate(img,7)
	  endif
	  ;----  Deal with palette image  ----------
	  if n_elements(r) gt 0 then begin	; 8-bit palette image.
	    if n_elements(smag) ne 0 then begin	; Requested smoothing.
	      rr = r[img]			; Must smooth RGB components.
	      gg = g[img]			; so get components and
	      bb = b[img]			; merge.
	      img = img_merge(rr,gg,bb)
	    endif
	  endif
	  ttx = '   From file'
        ;------  Image is from a window or an array  ---------
	endif else begin
	  if n_elements(imag) eq 1 then begin	; Window index.
	    if win_open(imag) eq 0 then begin
	      print,' Error in img_disp: Given image window is not open: '+$
	        strtrim(imag,2)
	      return
	    endif
	    win0 = !d.window
	    wset, imag
	    img = tvrd(tr=3)			; Read from given window.
	    wset, win0
	    ttx = '   From window '+strtrim(imag,2)
	  endif else begin			; Image array.
            dm = size(imag,/dimensions)
;	    img = imag
	    img = reform(imag,dm)               ; Avoid dropping any trailing 1.
	    ttx = '   From array'
	  endelse
	endelse
 
	if keyword_set(scale) then img=bytscl(img,/nan)
 
	;-------  Rebin  ------
	if n_elements(rmag) ne 0 then begin
	  img = img_resize(img,mag=rmag,/rebin)
	endif
 
	;-------  Rotate image  -----
	if n_elements(rot) eq 0 then rot=0
	if rot ne 0 then img=img_rotate(img,rot)
 
	;-------  Allow images of type INT and UINT  --------
	;---  Translate to byte: min->0, max->255  ----------
	typ = datatype(img)
	if (typ eq 'INT') or (typ eq 'UIN') then begin
	  tb = byte(round(maken(0.,255.,65336)))
	  if typ eq 'INT' then add=32768L else add=0
	  img = tb[img+add] 
	endif
 
	;--------  Mag factor  -----------------
	magfact = 1
	if n_elements(mag) ne 0 then begin
;	  if mag ne 1 then img = img_resize(img, mag=mag)
	  if min(mag eq 1) eq 0 then img=img_resize(img, mag=mag)
	  if n_elements(mag) eq 1 then $
	    magfact=mag else magfact=-1
	endif
 
	;--------  SMag factor  -----------------
	if n_elements(smag) ne 0 then begin
	  if min(smag) le 0 then return
	  sm = round(1./min(smag))
	  img = img_smooth(img,sm)
;	  if smag ne 1 then img = img_resize(img, mag=smag)
	  if min(smag eq 1) eq 0 then img=img_resize(img, mag=smag)
	  if n_elements(smag) eq 1 then $
	    magfact=smag else magfact=-1
	endif
 
	;----  Get size limits  --------
;	img_shape, img, nx=xs, ny=ys, true=tr, err=err; Image shape.
        ;--- Using reform will allow extra dimensions of 1  ---
	img_shape, reform(img), nx=xs, ny=ys, true=tr, err=err; Image shape.
	if err ne 0 then return
	device,get_screen_size=sz0
	if not keyword_set(small) then begin
	  sz = 0.98*sz0
	  x_scr0 = xs
	  y_scr0 = ys
	endif else begin
	  sz = 0.90*sz0
	  x_scr0 = 0
	  y_scr0 = 0
	endelse
	xmx = round(sz[0])
	ymx = round(sz[1])
	if n_elements(x_scr) eq 0 then x_scr=x_scr0 else x_scr=xs<xmx<x_scr
	if n_elements(y_scr) eq 0 then y_scr=y_scr0 else y_scr=ys<ymx<y_scr
	if n_elements(xpos) eq 0 then xpos=50
	if n_elements(ypos) eq 0 then ypos=50
	;---  Get scroll size that would be used, no window made  ----
	swindow, xs=xs,ys=ys, x_scr=x_scr, y_scr=y_scr, get_scroll=scr
	xoff = xpos
	yoff = sz0[1]-(scr[1]+ypos)
 
	;----  Pixmap?  -----------------------------------
	pixmap = keyword_set(pixmap0)
 
	;--------  Set window title  ----------------------
	sztxt = '  '+strtrim(xs,2)+' x '+strtrim(ys,2)	; Image size text.
	if n_elements(ttl0) eq 0 then begin		; Window title.
	  if datatype(imag) eq 'STR' then begin
	    filebreak, imag, nvfile=nam
	    ttl = nam + ':'
	  endif else ttl=''
	  ttl = ttl+sztxt
	endif else begin
	  ttl = ttl0
	  if keyword_set(addsize) then ttl=ttl+sztxt
	endelse
 
	;--------  Display window  ----------------------
	if n_elements(winuse) ne 0 then begin
	  if not win_open(winuse) then begin		; No such win, make it.
	    if n_elements(ttl0) eq 0 then begin		; Default title:
	      ttl = ttl + '  ' + strtrim(!d.window,2)	; Update with win index.
	    endif else begin				; Title given.
	      if keyword_set(addsize) then $		; /ADDSIZE: also win.
	        ttl=ttl+'  '+strtrim(!d.window,2)
	    endelse
	    window,winuse,xs=xs,ys=ys,title=ttl
	  endif
	  wset, winuse					; Set specified window.
	  if not keyword_set(noshow) then wshow		; Force to front.
	endif else begin
	  if n_elements(curr) ne 0 then begin		; Use current.
	    winlist,size=[xs,ys],win=win,/quiet,look=curr ; Look for win match.
	    if win eq -1 then begin			; Need new.
	      swindow, xs=xs,ys=ys, pixmap=pixmap, group=grp,$
	        xoff=xoff, yoff=yoff, x_scr=x_scr, y_scr=y_scr,/quiet
	    endif else begin
	      wset, win					; Set to matched window.
	      if not keyword_set(noshow) then wshow	; Force to front.
	    endelse
	  endif else swindow, xs=xs,ys=ys, $		; Use new.
	          pixmap=pixmap,xoff=xoff,yoff=yoff, $
		      x_scr=x_scr,y_scr=y_scr, /quiet, group=grp
	endelse ; winuse.
 
	;--------  Add title --------------------------
	if n_elements(ttl0) eq 0 then begin		; Default title:
	  ttl = ttl + '  ' + strtrim(!d.window,2)	; Update with win index.
	  if scope_level() eq 2 then begin		; Called interatcively?
	    if datatype(imag) ne 'STR' then begin	; If variable add name.
	      ttl = (scope_varname(imag,lev=1))[0] + '  ' + ttl
	    endif
	  endif
	  ttl = ttl + ttx
	endif else begin				; Title given.
	  if keyword_set(addsize) then $		; /ADDSIZE: also win.
	    ttl=ttl+'  '+strtrim(!d.window,2)
	endelse
	if pixmap eq 0 then begin
	  win_base = swinfo(/base)
	  if win_base ge 0 then $
	    widget_control,win_base,base_set_title=ttl ; Set window title.
	endif
 
	;--------  2-D image  --------------------------
	if tr eq 0 then begin
	  if n_elements(r) gt 0 then begin	; 2-D 8-bit palette image.
	    device, get_decomp=decomp
	    device,decomp=0
	    tvlct,r,g,b
	    tv,img,order=order
	    device,decomp=decomp
	  endif else begin			; 2-D gray scale image.
	    tv,img,order=order
	  endelse
;	  return
	;--------  3-D image  --------------------------
	endif else begin
	  tv, img, true=tr,order=order
	endelse
 
	;---------  Set scaling  ---
	if magfact gt 0 then begin
	  info = ''
	  set_scale,image=img0,/quiet,mag=magfact,out=info, err=err2
	  if err2 eq 0 then return
	  map_set_scale,image=img0,mag=magfact, err=err2, out=info
	endif
 
	end
