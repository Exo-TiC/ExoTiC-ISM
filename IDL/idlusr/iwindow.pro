;==================================================
;	iwindow = image window
;	R. Sterner, 1998 Jun 30
;==================================================

;==================================================
;       Print routine
;		ss = Image struture,  pr = printer to use.
;		file = PS file name, maxsize = max EPS side (inches)
;==================================================
        pro iwindow_print, info, pr, file=file, noplot=noplot, $
	  eps=eps, maxsize=mxsz

	;-------  Set defaults  -------------
	if n_elements(file) eq 0 then file='idl.ps'
	if n_elements(noplot) eq 0 then noplot=0
	if n_elements(mxsz) eq 0 then mxsz=info.epsmax	; Inches.

	;------  Screen size and aspect ratio  -----------
	nx = !d.x_size			; Screen size.
	ny = !d.y_size
	hw = float(ny)/float(nx)	; Actual Height/Width ratio.

	;---  Find largest output window with same aspect ratio  -----
	;-------  Landscape mode  -----------
	if nx gt ny then begin
	  dy0 = 7.			; Page height (inches).
	  dx0 = 9.5			; Page width (inches).
	  xeps = mxsz			; EPS x size (max side).
	  yeps = hw*xeps		; EPS y size.
	;-------  Portrait mode  ------------
	endif else begin
	  dx0 = 7.5			; Page height (inches).
          dy0 = 10.			; Page width (inches).
	  yeps = mxsz			; EPS y size (max side).
	  xeps = yeps/hw		; EPS x size.
	endelse

        hw0 = dy0/dx0			; Max allowed ratio.
	if hw gt hw0 then begin	; Max height, find width.
	  dy = dy0
	  dx = dy/hw
	endif else begin		; Max width, find height.
	  dx = dx0
	  dy = dx*hw
	endelse
	x1 = (dx0-dx)/2.		; Page window.
	x2 = (dx0+dx)/2.
	y1 = (dy0-dy)/2.
	y2 = (dy0+dy)/2.

	;-------  Landscape mode  -----------
	if (nx gt ny) and (not keyword_set(eps)) then begin
	  psinit,pr,/land,/color, window=[x1,x2,y1,y2], file=file
	;-------  Portrait mode  ------------
	endif else begin
	  psinit,pr,/full, /color, window=[x1,x2,y1,y2], file=file
	endelse

	;-------  EPS mode  -----------------
	nostamp = 0
	if keyword_set(eps) then begin
	  device,/encap,xsiz=xeps,ysiz=yeps,/inch
	  nostamp = 1
	endif

;	info.obj->draw			; Redraw object.
;	tv, info.ss.image
	if scale then tvscl,ss.image,order=order else tv,ss.image,order=order
	if info.ann ne '' then call_procedure, info.ann, info.ss

	psterm, noplot=noplot, nostamp=nostamp		; Print.

	end


;==================================================
;       Print event handler
;==================================================
        pro iwindow_pr, ev

        widget_control, ev.id, get_uval=uval		  ; Get event name.
	widget_control, ev.top, get_uval=info, /no_copy	  ; Get object.

	pr = getwrd(uval,1,99)		; Print command.
	iwindow_print, info, pr	; Send object and printer.

	widget_control, ev.top, set_uval=info, /no_copy	  ; Put object back.

	end


;==================================================
;       Process buttons event handler
;==================================================
        pro iwindow_proc, ev

        widget_control, ev.id, get_uval=uval

	cmd = getwrd(uval,1,99)
	err = execute(cmd)

	end


;==================================================
;	Process some of the menu options.
;==================================================
	pro iwindow_opt, ev

	widget_control, ev.top, get_uval=info
	widget_control, ev.id, get_uval=uval

	;-------  Set up a default file name  ----------
	f = 'y$n$0d$_h$m$s$'
        out = dt_tm_fromjs(dt_tm_tojs(systime()),form=f)


	case uval of

'EXIT':	begin
	  widget_control, ev.top, /dest
          return
        end

'INFO':	begin
	  txt = ['']
	  if tag_test(info.ss, 'custom_info') then $
	    txt = call_function(info.ss.custom_info, info.ss)
	  sz=size(info.ss.image) & nx=strtrim(sz(1),2) & ny=strtrim(sz(2),2)
	  txt = ['Image info',txt,'Size: '+nx+' x '+ny]
	  if info.ann ne '' then txt = [txt, 'Annotate routine: '+info.ann]
	  if tag_test(info.ss, 'custom_info') then $
	    txt = [txt,'Info function: '+info.ss.custom_info]
	  if tag_test(info.ss, 'custom_save') then $
	    txt = [txt,'Save function: '+info.ss.custom_save]
	  xmess, txt
          return
        end

'CLT':	begin
	  xloadct
	end

	;-------  SNAPSHOT  ------------
'CUST':	begin
          def = out+'.gif'
          call_procedure, info.ss.custom_save, info.ss, def=def
        end

'GIF':	begin
	  def = out+'.gif'
	  xmess,'Snapshot in GIF '+def, wid=wid,/nowait
	  gifscreen, def
	  widget_control, wid, /dest
	end

'PS':	begin
	  def = out+'.ps'
	  xmess,'Snapshot in PS '+def, wid=wid,/nowait
	  iwindow_print, info, 0, file=def, /noplot
	  widget_control, wid, /dest
	end

'EPS':	begin
	  def = out+'.eps'
	  xmess,'Snapshot in EPS '+def, wid=wid,/nowait
	  iwindow_print, info, 0, file=def, /noplot, /eps
	  widget_control, wid, /dest
	end

	;-------  SAVE_AS  ------------
'SCUST':begin
          def = out+'.gif'
	  f = dialog_pickfile(file=def,title='Enter CUSTOM image name for save')
	  if f ne '' then begin
            call_procedure, info.ss.custom_save, info.ss, def=f
	    xmess,'Image saved in CUSTOM file '+f
          endif
        end

'SGIF':	begin
	  def = out+'.gif'
	  f = dialog_pickfile(file=def,title='Enter a GIF image name for save')
	  if f ne '' then begin
	    gifscreen, f
	    xmess,'Image saved in GIF file '+f
	  endif
	end

'SPS':	begin
	  def = out+'.ps'
	  f = dialog_pickfile(file=def,title='Enter a PS file name for save')
	  if f ne '' then begin
	    iwindow_print, info, 0, file=f, /noplot
	    xmess,'Image saved in PS file '+f
	  endif
	end

'SEPS':	begin
	  def = out+'.eps'
	  f = dialog_pickfile(file=def,title='Enter a PS file name for save')
	  if f ne '' then begin
	    iwindow_print, info, 0, file=f, /noplot, /eps
	    xmess,'Image saved in EPS file '+f
	  endif
	end

else:
	endcase

	end


;==================================================
;	Main program
;==================================================

	pro iwindow, ss0, win=win, scale=scale, order=order, $
	  title=title, epsmax=epsmax, annotate=ann, help=hlp

	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Display image from image structure in a smart window.'
	  print,' iwindow, imgstr'
	  print,'   imgstr = Image structure to display.    in'
	  print,'     Minimum: {image:img}
	  print,'     Must have a image tag.'
	  print,'     May have a custom_save tag = name of custom save routine.'
	  print,'     May have a custom_info tag = name of custom info routine.'
	  print,'     May also have anything else custom save routine'
	  print,'       knows about (like a header).'
	  print,' Keywords:'
	  print,'   TITLE=ttl Window title (def=none).'
	  print,'   SCALE=scl 1=use tvscl, else use tv.'
	  print,'   /ORDER means reverse image in y.'
	  print,'   WIN=win  returned window ID.'
	  print,'   EPSMAX=mx  Length of max EPS plot side (inches, def=7).'
	  print,'     (Only used if EPS output requested).'
	  print,'   ANNOTATE=ann  Name of a procedure called after the'
	  print,'     image display to add annotation.  Optional.  Must take'
	  print,'     imgstr as an argument (does not need to use it).'
	  print,'     use normalized coordinates if printouts wanted.'
	  return
	endif

	if datatype(ss0) ne 'STC' then begin
	  if (datatype(ss0) ne 'BYT') or ( (size(ss0))(0) ne 2) then begin
	    xmess,[' Error in iwindow: must give image in a structure',$
	      'or at least give a byte image']
	    return
	  endif
	  ss = {image:ss0}	; Embed a simple byte image into needed struct.
	endif else ss=ss0

	sz = size(ss.image)
	xsize=sz(1) & ysize=sz(2)

	;-----  Defaults  -----------
	if n_elements(title) eq 0 then title=' '
	if n_elements(scale) eq 0 then scale=0
	if n_elements(order) eq 0 then order=0
	if n_elements(epsmax) eq 0 then epsmax=7.
	if n_elements(ann) eq 0 then ann=''

	;------  Set up a resizeable window  -------
	tlb = widget_base(titl=title,mbar=bar,tlb_frame_att=3)
	drawid = widget_draw(tlb,xs=xsize,ys=ysize)

	;------  Fill in menu bar pull down menus  --------
	id_m = widget_button(bar,val='FILE',/menu,$
	  event_pro='iwindow_opt')
	  id = widget_button(id_m,val='Info',uval='INFO')
	  id = widget_button(id_m,val='Exit',uval='EXIT')
	id_mod = widget_button(bar,val='MODIFY',/menu,$
	  event_pro='iwindow_opt')
	  id = widget_button(id_mod,val='Load Color Table',uval='CLT')
	  id = widget_button(id_mod,val='Change EPS size',uval='EPSMAX')
	id_m = widget_button(bar,val='SAVE_IMAGE',/menu,$
	  event_pro='iwindow_opt')
	  if tag_test(ss,'custom_save') then $
	    id = widget_button(id_m,val='CUSTOM snapshot',uval='CUST')
	  id = widget_button(id_m,val='GIF snapshot',uval='GIF')
	  id = widget_button(id_m,val='PS snapshot',uval='PS')
	  id = widget_button(id_m,val='EPS snapshot',uval='EPS')
	  if tag_test(ss,'custom_save') then $
	    id = widget_button(id_m,val='Named CUSTOM',uval='SCUST')
	  id = widget_button(id_m,val='Named GIF',uval='SGIF')
	  id = widget_button(id_m,val='Named PS',uval='SPS')
	  id = widget_button(id_m,val='Named EPS',uval='SEPS')
	;------  Add print and process buttons if setup file exists  --------
        ;------  Check for user defined buttons  --------
        ;  If xview.txt exists in home directory read it.  It
        ;  defines custom buttons using the following format:
        ;  print: button_label / printer_number
        ;  process: button_label / procedure_name
        ;  . . .
        ;  You can have any number of print: and process: lines.
        ;  Null lines and lines with * as first char are ignored.
        ;  Ex:
        ;  print: Phaser 340 paper / 5
        ;  print: Phaser 340 trans / 6
        ;  process: Negative / imgneg
        ;-----------------------------------------------------
        a = getfile(filename(getenv('HOME'),'xview.txt',/nosym), err=err,/q)
	if err eq 0 then begin
          a = drop_comments(a)
          one = strupcase(strmid(a,0,3))
          wpri = where(one eq 'PRI',cpri)       ; Print buttons.
          wpro = where(one eq 'PRO',cpro)       ; Process buttons.
          if cpri gt 0 then begin
            pdp = widget_button(bar, value='  PRINT ', /menu,$
              event_pro='iwindow_pr')
            for i=0,cpri-1 do begin
              t = a(wpri(i))
              v = getwrd(getwrd(t,del='/'),1,del=':')     ; Label.
              n = getwrd(t,/last,del='/')                 ; Printer #.
              id = widget_button(pdp,value=v,uval='CPRINT '+n)
            endfor
          endif
          if cpro gt 0 then begin
            pdp = widget_button(id_mod, value='  PROCESS ', /menu,$
              event_pro='iwindow_proc')
            for i=0,cpro-1 do begin
              t = a(wpro(i))
              v = getwrd(getwrd(t,del='/'),1,del=':')     ; Label.
              n = getwrd(t,/last,del='/')                 ; Command.
              id = widget_button(pdp,value=v,uval='CPROC '+n)
            endfor
          endif
	endif

	;------  Activate window and plot initial display  -----
	oldwin = !d.window		; Original window.
	widget_control, tlb, /real
	widget_control, drawid, get_val=win
	wset, win
	if scale then tvscl,ss.image,order=order else tv,ss.image,order=order
;	tvscl, ss.image
;	if ann ne '' then err=execute(ann)
	if ann ne '' then call_procedure, ann, ss
	wset, oldwin

	;-------  Store the needed info  ----------
	info = {ss:ss, win:win, drawid:drawid, epsmax:epsmax, $
	  scale:scale, order:order, ann:ann}
	widget_control, tlb, set_uval=info, /no_copy

	xmanager, 'iwindow', tlb, event_handler='iwindow_event',/no_block

	end
