;-------------------------------------------------------------
;+
; NAME:
;       IMG_FILEVIEWER
; PURPOSE:
;       View an array of images.
; CATEGORY:
; CALLING SEQUENCE:
;       img_fileviewer, imgarr
; INPUTS:
;       imgarr = an array of image file names.  in
; KEYWORD PARAMETERS:
;       Keywords:
;         /SMALL means use a smaller display area.
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
;       Note: The scroll wheel will move through the images
;       when the cursor is in the image area.
; MODIFICATION HISTORY:
;       R. Sterner, 2010 Aug 30 from imgarr_viewer.pro.
;       R. Sterner, 2011 Jan 02 --- Changed keyword /BIG to /NOSWIN and enlarged.
;       R. Sterner, 2011 Mar 21 --- Changed /NOSWIN to /SMALL, big now default.
;       R. Sterner, 2012 Jun 15 --- Added image functions.
;       R. Sterner, 2012 Jun 26 --- Made loop index, s.indx, long.
;       R. Sterner, 2012 Dec 26 --- Set window for < and >.
;       R. Sterner, 2013 Feb 05 --- Changed the wait time between images to 0.
;       R. Sterner, 2013 Feb 05 --- Allowed image functions to be turned off.
;       R. Sterner, 2013 Feb 05 --- Added image procedures.  Turn on in the
;         "Set values" menu.  See details in the help.  Will run this procedure
;         after each image is displayed until turned off.
;       R. Sterner, 2014 May 20 --- Allowed wildcard to be given instead of array.
;
; Copyright (C) 2010, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro img_fileviewer_disp, img, s
 
        ;---  Read requested image  ---
        a = read_image(img)
        img_shape, a, nx=nx, ny=ny, tr=tr
	xscr = nx<s.xmx
	yscr = ny<s.ymx
        widget_control, s.id_draw, draw_xsize=nx,draw_ysize=ny

        ;---  Handle image functions  ---
        fn = s.fn
        if fn[0] ne '' then begin
          n = nwrds(fn)
          for i=0,n-1 do begin
            a = call_function(getwrd(fn,i),a)
            img_shape, a, nx=nx, ny=ny, tr=tr   ; In case function changes true.
          endfor
        endif
        tv,a,true=tr
        widget_control, s.id_txt,set_value=img

        ;--- Handle image procedure  ---
        rout = s.rout
        if rout eq '' then return
        call_procedure, rout, img
 
	end
 
 
	;======================================================
	;  imgarr_viewer_event
	;======================================================
 
	pro  img_fileviewer_event, ev
 
	widget_control, ev.top, get_uval=s
 
	if tag_names(ev,/struct) eq 'WIDGET_TIMER' then begin
	  if s.mvflag eq 0 then return		; Check if stopped.
	  in = (s.indx + 1)     		; Step to next image index.
          if in gt s.hi then in=s.lo            ; Wrap back.
	  if in eq s.lo then wait,s.ps		; Pause a bit before first.
	  widget_control, s.id_slid, set_val=in	; Show image number on slider.
	  wset, s.win				; Set to display window.
	  img_fileviewer_disp,s.stk[in], s	; Display image.
	  if s.mvflag eq 1 then $		; Set next timer event.
	    widget_control,s.twid,timer=s.wt
	  s.indx = in				; Remember new index.
	  widget_control, ev.top, set_uval=s	; Save updated values.
	  return
	endif
 
	widget_control, ev.id, get_uval=uval	; Grab event name from uval.
 
	if uval eq 'STOP' then begin
	  s.mvflag = 0				; Set movie flag to off.
	  widget_control, s.id_slid, sens=1	; Ungray slider.
	  widget_control, ev.top, set_uval=s	; Save updated values.
	  return
	endif
 
	if uval eq 'GO' then begin
	  s.mvflag = 1				; Set movie flag to on.
	  widget_control, s.id_slid, sens=0	; Gray  slider.
	  widget_control, s.twid, timer=s.wt	; Set a new timer event.
	  widget_control, ev.top, set_uval=s	; Save updated values.
	  return
	endif
 
	if uval eq 'SLID' then begin
	  widget_control, s.id_slid, get_val=in	; Grab slider value
	  s.indx = in				; which is new image index.
	  wset, s.win				; Set to display window and
	  img_fileviewer_disp,s.stk[in], s	; ; Display image.
	  widget_control, ev.top, set_uval=s	; Save updated values.
	  return
	endif
 
	if uval eq '<' then begin
	  in = (s.indx-1)>s.lo			; Decrement index.
	  s.indx = in				; Save.
	  wset, s.win				; Set to display window.
	  widget_control,s.id_slid,set_val=in	; Update slider.
	  img_fileviewer_disp,s.stk[in], s	; ; Display image.
	  widget_control, ev.top, set_uval=s	; Save updated values.
	  return
	endif
 
	if uval eq '>' then begin
	  in = (s.indx+1)<s.hi  		; Increment index.
	  s.indx = in				; Save.
	  wset, s.win				; Set to display window.
	  widget_control,s.id_slid,set_val=in	; Update slider.
	  img_fileviewer_disp,s.stk[in], s	; ; Display image.
	  widget_control, ev.top, set_uval=s	; Save updated values.
	  return
	endif
 
	if uval eq 'WT' then begin	        ; Wait time between frames.
	  def = strtrim(s.wt,2)			; Use current as default.
	  xtxtin, txt, title='Enter wait time in sec (def='+def+'):',$
            def=def
	  if txt eq '' then return		; No change.
	  s.wt = txt+0.				; Store new value.
	  widget_control, ev.top, set_uval=s	; Save updated values.
	  return
	endif
 
	if uval eq 'PS' then begin	        ; Pause time after last frame.
	  def = strtrim(s.ps,2)			; Use current as default.
	  xtxtin, txt, title='Enter pause time in sec (def='+def+'):',$
            def=def
	  if txt eq '' then return		; No change.
	  s.ps = txt+0.				; Store new value.
	  widget_control, ev.top, set_uval=s	; Save updated values.
	  return
	endif
 
	if uval eq 'FN' then begin	        ; Image function(s).
	  def = strtrim(s.fn,2)			; Use current as default.
          if def eq '' then def='none'
          n = nwrds(def)                        ; How many functions?
          ttl = ['Enter one or more functions to apply to the images.',$
                 'Multiple functions will be applied in the order listed.',$
                 'Each must take an image argument and return an image.',$
                 'The current function'+plural(n)+' '+plural(n,'is ','are ')+def]
	  xtxtin, txt, title=ttl, def=def       ; Get new function(s).
          if strlowcase(txt) eq 'none' then txt=''
;	  if txt eq '' then return		  ; No change.
	  s.fn = strtrim(txt,2)			  ; Store new function.
	  widget_control, ev.top, set_uval=s	  ; Save updated values.
          widget_control, s.id_txt,get_value=img  ; Get last image name.
 
          catch, error                          ; Error handler.
          if error ne 0 then begin
            n = nwrds(s.fn)
            mtxt = ['Error in img_fileviewer calling function'+plural(n)+':', $
              'Function'+plural(n)+' '+plural(n,'was','were')+' '+s.fn, $
              'Check spelling or path.',$
              'Resetting to none.']
            s.fn = ''                           ; Set back to no function.
	    s.mvflag = 0			; Set movie flag to off.
	    widget_control, s.id_slid, sens=1	; Ungray slider.
	    widget_control, ev.top, set_uval=s	; Save updated values.
            catch, /cancel                      ; Cancel error handler.
            xmess, mtxt                         ; Display error message.
          endif
 
          img_fileviewer_disp, img, s       ; Show last image with function(s).
	  return
	endif
 
	if uval eq 'RT' then begin	        ; Image procedure after display.
	  def = strtrim(s.rout,2)		; Use current as default.
          if def eq '' then def='none'
          ttl = ['Enter a procedure to run after an image is displayed.',$
                 'It must take the image file name as the only argument,',$
                 'even if it does not use it.  Clear or enter none to turn',$
                 'this off.  The current procedure is '+def]
	  xtxtin, txt, title=ttl, def=def       ; Get new function(s).
          if strlowcase(txt) eq 'none' then txt=''
	  s.rout = strtrim(txt,2)		  ; Store new function.
	  widget_control, ev.top, set_uval=s	  ; Save updated values.
          widget_control, s.id_txt,get_value=img  ; Get last image name.
 
          catch, error                          ; Error handler.
          if error ne 0 then begin
            mtxt = ['Error in img_fileviewer calling image procedure '+s.rout, $
              'Check spelling or path.',$
              'Resetting to none.']
            s.rout = ''                         ; Set back to no function.
	    s.mvflag = 0			; Set movie flag to off.
	    widget_control, s.id_slid, sens=1	; Ungray slider.
	    widget_control, ev.top, set_uval=s	; Save updated values.
            catch, /cancel                      ; Cancel error handler.
            xmess, mtxt                         ; Display error message.
          endif
 
          img_fileviewer_disp, img, s       ; Show last image with function(s).
	  return
	endif

	if uval eq 'DISP' then begin
	  def = strtrim(s.indx,2)		; Use current as default.
	  xtxtin, txt, title='Enter image index to display (def='+def+'):',$
            def=def
	  if txt eq '' then return		; No change.
          in = (txt+0)<s.hi>s.lo                ; New image index.
	  s.indx = in				; Save.
	  widget_control,s.id_slid,set_val=in	; Update slider.
	  img_fileviewer_disp,s.stk[s.indx],s	; Display image.
	  widget_control, ev.top, set_uval=s	; Save updated values.
	  return
	endif
 
	if uval eq 'RN' then begin
	  def = '0 '+strtrim(s.num-1,2)         ; Use current as default.
	  xtxtin, txt, title='Enter image index range to display (def='+def+'):',$
            def=def
	  if txt eq '' then return		; No change.
          lo = (getwrd(txt,0)+0L)>0             ; New lo.
          hi = (getwrd(txt,1)+0L)<(s.num-1)     ; New hi.
	  s.lo = lo				; Save.
          s.hi = hi
          in = s.indx                           ; Current image index.
          in = in<s.hi>s.lo                     ; Keep in new range.
	  s.indx = in				; Save.
          widget_control,s.id_slid,set_slider_min=lo,set_slider_max=hi
	  widget_control,s.id_slid,set_val=in	; Update slider.
	  img_fileviewer_disp,s.stk[s.indx],s	; Display image.
	  widget_control, ev.top, set_uval=s	; Save updated values.
	  return
	endif
 
	if uval eq 'QUIT' then begin
	  widget_control, ev.top, /destroy	; All done, just destroy top.
	  return
	endif
 
	if getwrd(uval) eq 'UHELP' then begin
          txt = s.htxt
          tag = getwrd(uval,1)			; Grab the help tag from uval.
	  atag = '<'+tag+'>'			; Construct the help text
	  btag = '</'+tag+'>'			; delimiters.
	  txt_keysection,txt,after=atag,before=btag, $ ; Grab the help text.
	    /quiet, err=err
	  if err ne 0 then begin			; Deal with an error.
	    xmess,['Error in menu layout text: Could not find matching',$
  		   'delimiting tags.  Was looking for', $
		   atag+ ' and '+btag+' in the help text.']
	    return
	  endif
	  xhelp,txt,/bottom			; Display the help text.
	  return
	endif
 
	if uval eq 'DRAW' then begin
          in = s.indx - ev.clicks               ; Change index by scroll wheel.
          in = in<s.hi>s.lo                     ; Keep in range.
	  s.indx = in				; Save.
	  widget_control,s.id_slid,set_val=in	; Update slider.
	  img_fileviewer_disp,s.stk[s.indx],s	; Display image.
	  widget_control, ev.top, set_uval=s	; Save updated values.
          widget_control, ev.id, /clear_events  ; Clear other wheel events.
	  return
	endif
 
        print,' --------------------------------------------'
        print,'         Unhandled event:'
        hlp,ev,/st
        print,' --------------------------------------------'
 
	end
 
 
	;======================================================
	;  img_viewer = Image array viewer.
	;  R. Sterner, 2001 Oct 03
        ;  Renamed and modified 2010 Aug 30.
	;======================================================
 
	pro img_fileviewer, imgarr0, small=small, help=hlp
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' View an array of images.'
	  print,' img_fileviewer, imgarr'
	  print,'   imgarr = an array of image file names.  in'
          print,' Keywords:'
          print,'   /SMALL means use a smaller display area.'
          print,' Note: The scroll wheel will move through the images'
          print,' when the cursor is in the image area.'
	  return
	endif

        ;---  Handle wildcards  ---
        if n_elements(imgarr0) eq 1 then begin
          imgarr = file_search(imgarr0,count=n)
          if n eq 0 then begin
            print,' Error in img_fileviewer: No images forund for '+imgarr0
            return
          endif
        endif else begin
          imgarr = imgarr0
        endelse

        ;---  Handle the case of a single image  ---
        if n_elements(imgarr) eq 1 then begin
          imgarr = [imgarr,imgarr]      ; To avoid problems below.
        endif
 
        ;-------  Initial  setup  -------
        num = n_elements(imgarr)
        a = read_image(imgarr[0])
        img_shape, a, nx=nx, ny=ny, tr=tr
 
	ssiz = (4*num)<250>100                          ; Slider bar size.
	device, get_screen_size=ss                      ; Get screen size.
        if not keyword_set(small) then begin
	  xmx = ss[0]*0.95                              ; Max allowed default
	  ymx = ss[1]*0.85                               ;   window size.
        endif else begin
	  xmx = ss[0]*2/3                               ; Max allowed default
	  ymx = ss[1]*2/3                               ;   window size.
        endelse
	xscr = nx<xmx
	yscr = ny<ymx
 
	;------  Build widget  ------------------
	top = widget_base(/col)
	b = widget_base(top,/row)
        ;---  Control buttons  ---
	id = widget_button(b,val='Quit',uval='QUIT')
	id = widget_button(b,val='Stop',uval='STOP')
	id = widget_button(b,val='Go',uval='GO')
        ;---  Image selection  ---
	id_slid = widget_slider(b,min=0,max=num-1,uval='SLID', $
	  /drag,xsize=ssiz)
	id = widget_button(b,val=' < ',uval='<')
	id = widget_button(b,val=' > ',uval='>')
        ;---  Set values menu  ---
	b2 = widget_base(b,/row)
	men = widget_button(b2,val='Set values',menu=2)
	  id = widget_button(men,val='Change image index displayed',uval='DISP')
	  id = widget_button(men,val='Change time step between images',uval='WT')
	  id = widget_button(men,val='Change pause time at end of sequence',uval='PS')
	  id = widget_button(men,val='Change image range to display',uval='RN')
	  id = widget_button(men,val='Set function or functions to modify image',uval='FN')
	  id = widget_button(men,val='Set procedure to run after image is displayed',uval='RT')
        ;---  Image name  ---
        b = widget_base(top,/row)
        id_txt = widget_text(b,xsize=60)
        ;---  Get help text  ---
        text_block, /quiet, htxt
;<menu>
;main Help
;  ovr Overview
;  con Control Buttons
;  sel Image selection
;  set Set values menu
;  dis Image display
;</menu>
;
;<ovr>
;img_fileviewer is used to display a list of images.
;They may be displayed one by one, single stepping forward
;or backward, or as an animated sequence.  A subset of the
;given images may be displayed as a looping animation.
;</ovr>
;
;<con>
;The control buttons are:
;  Quit: Exit this routine.
;  Stop: Stop the animated display of a sequence.
;  Go: Start an animated display of a sequence.
;</con>
;
;<sel>
;Image selection:
;  Slider bar: This gives a coarse selection over the current
;      image range.
;  Mouse scroll wheel will move through images if the cursor
;      is over the image.
;  >: Step forward to the next image in the current image range.
;  <: Step backward to the previous image in the current image range.
;  Also in the "Set values" drop-down menu there is an
;  option to "Change image index displayed" to allow any index
;  in the current image range to be displayed.
;  In the same drop-down menu is an option to specify a image range
;  which by default is all the images.
;</sel>
;
;<set>
;The "Set values" menu allows the following to be set:
;  "Change image index displayed":
;      An index into the given list of images may be entered here.
;      The index will be constrained to be in the current image
;      range, which initially is all the images in the list.
;      Images outside the current range will not be displayed.
;  "Change time step between image":
;      The time to wait between images sets the speed of the display.
;      Enter 0 for the fastest animation.  Default is 0.2 sec.
;  "Change pause at end of sequence":
;      An animation will pause at the end of the current range.
;      The pause time is set here.  The default is 1 sec.
;  "Change image range to display":
;      This is the range of images to animate, by default all of them.
;      A smaller range may be set and it will display the specified
;      images in a loop.
;  "Set function to modify image":
;      A function may be given that will be applied to the image before
;      it is displayed.  This could be a built in or user function, for
;      example, hist_equal.  Multiple functions may be given and they will
;      be applied in the order listed.  Each function must take the image
;      as an argument and return a modified image.  Give the word none or
;      clear the text to turn this off.
;  "Set procedure to run after image is displayed":
;      A procedure may be given that will be called after each image is
;      displayed.  It must take as the first argument the name of the image
;      file, even if it does not use it.  Give the word none or
;      clear the text to turn this off.  This procedure may also have other
;      arguments, like INIT=init, TERM=term to initialize and terminate it,
;      which may be done from the IDL command line, even after starting
;      img_fileviewer.  An example image procedure named "test_image_pro.pro"
;      is available in the same library as img_fileviewer.
;</set>
;
;<dis>
;The display area shows the image file name and then below it the image.
;The size of the display area will change to match the image size.
;The file name may be too big to completely show but it is all there
;and may be copied to paste elsewhere.
;</dis>
        add_helpmenu, b, htxt, cmd='UHELP'
 
	if (xscr eq nx) and (yscr eq ny) then begin
	  id_draw = widget_draw(top,xsize=nx,ysize=ny,/wheel_events,uval='DRAW')
	endif else begin
	  id_draw = widget_draw(top,xsize=nx,ysize=ny,x_scr=xscr, y_scr=yscr,/wheel_events,uval='DRAW')
	endelse
 
	;------  Realize widget  --------------
	widget_control, top,/real
 
	;------  Draw window ID  --------------
	widget_control, id_draw, get_val=win
	wset, win
 
	;------  Start timer  -------
	twid = b			; Use a base widget as timer.
	mvflag = 0			; Set play movie flag to off.
	indx = 0			; Image index (# images=num).
	wt = 0.0			; Wait between display steps.
	ps = 1.0			; Pause at end of imgarr.
        fn = ''                         ; Function to apply to image.
        rout = ''                       ; Procedure to call after each image.
 
	;-------  Pack up info  ----------------
	s = {id_draw:id_draw, win:win, stk:imgarr, indx:0L, num:num, $
	     twid:twid, mvflag:mvflag, wt:wt, ps:ps, fn:fn, id_slid:id_slid, $
	     lo:0L, hi:num-1L, htxt:htxt, rout:rout, $
	     id_txt:id_txt, xmx:xmx, ymx:ymx, dum:0 }
	widget_control, top, set_uval=s
	img_fileviewer_disp,imgarr[0], s	; Display image.
 
	;------  Activate  -----------
	xmanager, 'img_fileviewer', top, /no_block
 
	end
