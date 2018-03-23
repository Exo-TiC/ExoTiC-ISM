;-------  vumov24.pro = 24 bit res file movie viewer  ----
;	R. Sterner, 2005 Aug 02
 
;--------------------------------------------------------------------
;	vumov_embedded_cmds = Deal with custom commands
;	embedded in the movie res file.
;--------------------------------------------------------------------
 
	pro vumov24_embedded_cmds, c_base, cmd
 
	cmd = strarr(10)
	but = strarr(10)
	start = 0
	for i=0,9 do begin
	  resget,'command',from=start,found=found,err=err,txt
	  if err ne 0 then goto, done
	  cmd(i) = txt
	  start = found+1
	endfor
done:	if i eq 0 then return
	start = 0
	for j=0,i-1 do begin
          resget,'button',from=start,found=found,err=err,txt
          if err ne 0 then goto, done2
          but(j) = txt
          start = found+1
        endfor
done2:  if i ne j then begin
	  xmess,['Movie res file embedded commands and',$
	         'button labels are not consistent.  Check',$
		 'res file for errors.  No custom labels added.']
	  return
	endif
	nbut = i			; # custom commands found.
	if nbut eq 1 then begin		; Just 1.
	  id = widget_button(c_base, val=but(0), uval='CUST 0')
	endif else begin		; More than 1.
	  b = widget_button(c_base, val='Custom', menu=2)
	  for i=0, nbut-1 do begin
	    id=widget_button(b, val=but(i), uval='CUST '+strtrim(i,2))
	  endfor
	endelse
 
	return
	end
 
;--------------------------------------------------------------------
;	vumov24_frame = Display a frame
;	aa = assoc var.    s = info structure.
;--------------------------------------------------------------------
	pro vumov24_frame, aa, s, array
 
	;----  Error handler  -----
	catch, io_err

	if io_err then begin
	  print,!error_state.msg
	  return
	endif

	;----  Read image  ------
	a = aa(s.index)
	;----  Update slider  -----
	if s.set(1) eq 1 then widget_control, s.id_slid,set_val=s.index
	;----  Display image  -----
	wset,s.win
	wshow
;	tv,a,order=s.order
	img_disp,/current,a,order=s.order
	;----  Display ID or time if given  -------
	if s.set(0) eq 0 then return
	;----  If ID available it has priority over time  -----
	if s.id_flag eq 1 then begin
	  widget_control, s.id_time, set_val=array(s.index)
	  return
	endif
	;----  Display time if available  -------
	if s.time_flag eq 1 then begin
	  dt = dt_tm_fromjs(array(s.index))
	  widget_control, s.id_time, set_val=dt
	endif
 
	end
 
;--------------------------------------------------------------------
;	vumov24_event = Event handler.
;--------------------------------------------------------------------
	pro vumov24_event, ev
 
	;------------------------------------------------
	;  aa = assoc var into res file.
	;  t_last = last time?
	;  last_file = name of last movie file.
	;  array = time_js or id_array.
	;------------------------------------------------
	common vumov24_event_com, aa, t_last, last_file, $
	  array, lun, path
 
	widget_control, ev.id, get_uval=uval	; Event name.
	widget_control, ev.top, get_uval=s	; Info structure.
 
	if uval eq 'TIMER' then begin
	  if s.mode eq 0 then return
	  vumov24_frame, aa, s, array
	  if s.set(2) eq 1 then begin
	    t_now = systime(1)
	    frate = string(1./(t_now-t_last),form='(F5.1)')
	    widget_control, s.id_frame, set_val=frate
	    t_last = t_now
	  endif
	  sindex = s.index
	  s.index = (s.index + s.step) mod s.num
	  if sindex gt s.index then tm=s.sec2 else tm=s.sec  ; End of loop?
	  widget_control, ev.top, set_uval=s
	  widget_control, s.b_timer, timer=tm	; Yes, next timer.
	  return
	endif
 
	if uval eq 'OPEN' then begin
	  ;-----  Stop movie  ------
	  s.mode = 0
	  widget_control, ev.top, set_uval=s
	  ;-----  Drop old window if any  -----
	  swdelete				; Drop any existing window.
	  loadct,0				; Want B&W color table.
	  ;-----  Open file  ------
	  if n_elements(last_file) eq 0 then last_file=''
infile:
	  file = dialog_pickfile(filter='*.res',file=last_file,$
	    get_path=path,path=path)
	  if file eq '' then return		; None entered.
	  resclose, /quiet			; Close any open res file.
	  resopen,file,head=h,err=err
	  if err ne 0 then begin
	    xmess,'Could not open '+file
	    goto, infile
	  endif
	  ;-----  Display file name  -------
	  filebreak,file,name=ttl
	  widget_control, ev.top,tlb_set_title='View Movie: '+ttl
	  ;-----  Find number of frames  --------------
	  w = where(strupcase(strmid(h,0,5)) eq 'FRAME',cnt)	; All frames.
	  if cnt gt 0 then begin
	    t = h(w)				; Pull frame entries in header.
	  endif else begin
	    print,' Warning in vumov24: Could not find FRAME_* entries.'
	    print,' Assuming all entries are numbered frames.'
	    t = h(0:n_elements(h)-2)		; Drop last header line (END).
	  endelse
	  p = strpos(t(0),'_')			; Find frame numbers.
	  nn = strmid(t,p+1,99)+0L		; Find frame numbers as numbers.
	  num = 1+max(nn)-min(nn)		; # frames.
	  last_file = file			; Remember file as default.
	  first = getwrd(t(0))			; First frame tag.
	  resget,first,img,address=offset	; Find first frame.
	  img_shape, img, nx=xsize,ny=ysize
	  ;------  Deal with ID text array if available  -----
	  resget,'ID',array, err=err
	  if err eq 0 then begin
	    s.id_flag = 1			; ID will display in time area.
	    widget_control, s.b_time, map=1	; Show time area.
	  ;------  Deal with time if no ID -----------
	  endif else begin
	    resget,'TIME',array, err=err
	    if err eq 0 then begin
	      s.time_flag = 1			; Have time.
	      widget_control, s.b_time, map=1	; Show time area.
	    endif else begin
	      s.time_flag = 0			; No time found.
	      widget_control, s.b_time, map=0	; Hide time area.
	    endelse
	  endelse
	  ;-----  define assoc variable  -----
	  if s.lun ne 0 then free_lun, s.lun
	  openr,lun,file,/get_lun
;	  aa = assoc(lun, tmp, offset)		; Set up assoc.
	  aa = assoc(lun, img, offset)		; Set up assoc.
	  ;----  Set up window  ----
	  if (xsize gt 1000) or (ysize gt 900) then begin
	    swindow,xs=xsize,ys=ysize,x_scr=(xsize<1000),y_scr=(ysize<900)
	  endif else begin
	    window,xs=xsize,ys=ysize
	  endelse
	  s.win = !d.window			; Movie window.
	  ;----  Store values and set widget -----
	  s.lun = lun				; Save lun.
	  s.num = num				; Save number of frames.
	  widget_control, s.b_buttons, sensitive=1
	  widget_control, s.id_slid, sensitive=1, set_slider_max=num-1
	  widget_control, s.id_slid2, sensitive=1
	  ;----  Show next frame  -----
	  vumov24_frame, aa, s, array
	  ;----  Init frame timer  -------
	  t_last = systime(1)
	  ;----  Look for custom commands in res file  -------
	  vumov24_embedded_cmds, s.c_base, cmd
	  s.cmd = cmd
	  widget_control, ev.top, set_uval=s	; Save updated info.
	  resclose
	  return
	endif
 
	if uval eq 'SLID' then begin
	  widget_control, s.id_slid, get_val=i
	  s.index = i
	  widget_control, ev.top, set_uval=s
	  vumov24_frame, aa, s, array
	  return
	endif
 
	if uval eq 'SLID2' then begin
	  widget_control, s.id_slid2, get_val=i
	  s.sec = 10^(i/100.)
	  widget_control, ev.top, set_uval=s
	  return
	endif
 
	if uval eq '<1' then begin
	  s.index = (s.index - 1)>0
	  widget_control, ev.top, set_uval=s
	  vumov24_frame, aa, s, array
	  return
	endif
 
	if uval eq '>1' then begin
	  s.index = (s.index + 1)<(s.num-1)
	  widget_control, ev.top, set_uval=s
	  vumov24_frame, aa, s, array
	  return
	endif
 
	if uval eq 'GO' then begin
	  s.mode = 1
	  widget_control, ev.top, set_uval=s
	  widget_control, s.b_timer, timer=s.sec
	  return
	endif
 
	if uval eq 'STOP' then begin
	  vumov24_frame, aa, s, array
	  s.mode = 0
	  widget_control, ev.top, set_uval=s
	  return
	endif
 
	if uval eq 'OPT1' then begin
	  set = s.set
	  opt = xoption(title='Set options','OK', $
            subopt=['Update time','Update slider','Update frame rate'], $
	    subset=set,xoff=50,yoff=100)
	  s.set = set
	  widget_control, ev.top, set_uval=s
	  if s.set(0) eq 0 then widget_control,s.id_time,sens=0 else $
	    widget_control,s.id_time,sens=1
	  return
	endif
 
	if uval eq 'OPT2' then begin
	  xtxtin,new,title='Change frame step size:', $
	    def=strtrim(s.step,2), group=ev.top
	  if new eq '' then return
	  s.step = new+0
	  widget_control, ev.top, set_uval=s
	  return
	endif
 
	if uval eq 'OPT3' then begin
	  xtxtin,new,title='Change frame delay seconds:', $
	    def=strtrim(s.sec,2), group=ev.top
	  if new eq '' then return
	  s.sec = new+0.
	  widget_control, ev.top, set_uval=s
	  i = fix(100*alog10(s.sec))>(-300)<0
	  widget_control, s.id_slid2, set_val=i
	  return
	endif
 
	if uval eq 'OPT35' then begin
	  xtxtin,new,title='Change pause at end (sec):', $
	    def=strtrim(s.sec2,2), group=ev.top
	  if new eq '' then return
	  s.sec2 = new+0.
	  widget_control, ev.top, set_uval=s
	  return
	endif
 
	if uval eq 'OPT4' then begin	; Plain cursor.
	  wshow
	  win = !d.window
	  if win eq s.win then begin	; Movie window.
	    crossi,/dev,/xmode
	  endif else begin		; Custom window.
	    crossi,/xmode
	  endelse
	  return
	endif
 
	if uval eq 'OPT5' then begin	; Mag cursor.
	  wshow
          win = !d.window
          if win eq s.win then begin    ; Movie window.
            crossi,/mag,/dev,/xmode
          endif else begin              ; Custom window.
	    crossi,/mag,/xmode
	  endelse
	  return
	endif
 
	if uval eq 'EXIT' then begin
	  widget_control, ev.top, /dest
	  if s.lun ne 0 then free_lun, s.lun
	  device, decomp=s.decomp
	  return
	endif
 
	;------  Multi-item uvals processed here  ------
	cmd = getwrd(uval,1)			; Second word.
	uval = getwrd(uval)			; First word.
 
	if uval eq 'CUST' then begin
	  catch, error
	  if error ne 0 then begin
	    xmess,['Error calling custom routine ',s.cmd(cmd+0)]
	    return
	  endif
	  call_procedure, s.cmd(cmd+0), last_file, s.index
	  return
	endif
 
	end
 
 
;--------------------------------------------------------------------
;	vumov24 = Main routine.
;--------------------------------------------------------------------
 
	pro vumov24, buttons=but, commands=cmd, order=order, help=hlp
 
	if keyword_set(hlp) then begin
	  print,' View a res file movie.'
	  print,' vumov24'
	  print,'   No args.'
	  print,' Keywords:'
	  print,'   ORDER=ord, or /ORDER controls y reversal (1=reverse y).'
	  print,'   BUTTONS=txt  Label text for custom buttons.'
	  print,'     Each button entry must have a command entry.'
	  print,'   COMMAND=cmd  Names of custom routines.'
	  print,'     txt and cmd can be scalars or arrays.'
	  print,'     The given routines must take two args, file and'
	  print,'     frame number. File is the res file name, frame number'
	  print,'     is the movie frame.  The res file may be accessed by'
	  print,'     the routine without interferring.'
	  print,' Notes:  FORMAT OF THE MOVIE RES FILE.'
	  print,'   The movie file is an ordinary res file (see resopen,'
	  print,'   resput,rescom, resclose, resget).'
	  print,'   The movie frames are named FRAME_0, FRAME_1, and so on.'
	  print,'   Frames must be numbered consecutively (need not start at'
	  print,'   0).  A special case of numbers as tags (nothing else in'
	  print,'   the file, none of the optional items) will also work.'
	  print,'   Optional is an array of times as JS called TIME_JS.'
	  print,'   Also optional is a text array called ID which will display'
	  print,'   in place of the time if both given.'
	  print,'   Other data is allowed in the movie res file and may'
	  print,'   be used by the custom routines if desired.'
	  print,'   The custom commands may be embedded directly in the movie'
	  print,'   res file if desired.  Just include the keyword pair'
	  print,'   BUTTON and COMMAND for each custom command.  These values'
	  print,'   will be picked out of the file when opened and used as if'
	  print,'   given in the command line.  Do not give on command also.'
	  return
	endif
 
	if n_elements(order) eq 0 then order=0
 
	;------------------------------------------------------------
	;	Widget layout
	;------------------------------------------------------------
	top = widget_base(/col,title='View Movie',$
	  xoff=50,yoff=100)
 
	;-------  Upper row of buttons  -------------
	b_timer = widget_base(top,/row, uval='TIMER')
	id_open = widget_button(b_timer,val='Open',uval='OPEN')
	b_buttons = widget_base(b_timer,/row)
	id = widget_button(b_buttons,val='Go',uval='GO')
	id = widget_button(b_buttons,val='Stop',uval='STOP')
	id = widget_button(b_buttons,val='<1',uval='<1')
	id = widget_button(b_buttons,val='1>',uval='>1')
	;-----  Custom processing  ------------------
	c_base = widget_base(b_buttons)
	nbut = n_elements(but)
	if nbut gt 0 then begin		; Some custom commands.
	  if nbut eq 1 then begin	; Just 1.
	    id = widget_button(c_base, val=but, uval='CUST 0')
	  endif else begin		; More than 1.
	    b = widget_button(c_base, val='Custom', menu=2)
	    for i=0, nbut-1 do begin
	      id=widget_button(b, val=but(i), uval='CUST '+strtrim(i,2))
	    endfor
	  endelse
	endif else cmd=['']
	cmd2 = strarr(10)		; Embed commands in a 10 element arr.
	cmd2(0) = cmd
	;--------------------------------------------
	id2 = widget_button(b_timer,val='Options',menu=2)
	id = widget_button(id2,val='Updates on/off',uval='OPT1')
	id = widget_button(id2,val='Step size in frames',uval='OPT2')
	id = widget_button(id2,val='Frame delay time',uval='OPT3')
	id = widget_button(id2,val='Pause at end',uval='OPT35')
	id = widget_button(id2,val='Cross-hair cursor',uval='OPT4')
	id = widget_button(id2,val='Cross-hair cursor with mag',uval='OPT5')
	id = widget_button(b_timer,val='Exit',uval='EXIT')
	id = widget_label(b_timer,val='   ')
	id_frame = widget_label(b_timer,val='---.-')
	;--------  Slider  ---------------------------
	id_slid = widget_slider(top, uval='SLID',/drag, title='Frame')
	id_slid2 = widget_slider(top, uval='SLID2',/drag, title='Speed', $
	  min=-300,max=0)
	;--------  Date and time  ------------
	b_time = widget_base(top,/row)
	id_time = widget_label(b_time,val=' ',/dynamic)
	widget_control,b_time,map=0			; Unmap time area.
 
	;--------  Pack info  ------------------------
	device, get_decomp=decomp
	device, decomp=0
	info = { $
	  time_flag:0, id_flag:0, b_time:b_time, id_time:id_time, $
	  id_slid:id_slid, id_slid2:id_slid2, step:1, win:0, $
	  b_timer:b_timer, mode:0, id_frame:id_frame, $
	  sec:0.01, sec2:0.5, lun:0L, index:0, b_buttons:b_buttons, num:100, $
	  set:[1,1,1], $
	  cmd:cmd2, order:order, c_base:c_base, decomp:decomp }
 
	;--------  Activate  --------------------------
	widget_control, top, /real, set_uval=info
	widget_control, b_buttons, sensitive=0
	widget_control, id_slid, sensitive=0
	widget_control, id_slid2, sensitive=0, set_val=-300
	widget_control, id_open, /input_focus
 
	xmanager,'vumov24', top, /no_block
 
	end
