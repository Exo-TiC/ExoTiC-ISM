;-------  xloglut.pro = Log lookup table widget  -------------
;	R. Sterner, 1999 Mar 16
;	From eqv2.pro
;-------------------------------------------------------------
 
;-------------------------------------------------------------
;	Index of routines
;
;       xloglut_tv = Display image
;       xloglut_sp2v = Function to convert slider position to value.
;       xloglut_sv2p = Function to convert slider value to position.
;       xloglut_show_win = Show plot window.  For external use.
;       xloglut_get_val = Retrieve parameter values.  For external use.
;       xloglut_set_val = Set parameter values.  For external use.
;	xloglut_event = Event handler
;	xloglut = Main Equation viewer version II routine	
;
;-------------------------------------------------------------
 
 
;===============================================================
;       xloglut_tv = Display image.
;===============================================================
 
        pro xloglut_tv, _d
 
	wset, _d.win			; Set to plot window.
 
	;------  Get reverse flag  ---------
	widget_control, _d.wid_rev, get_val=rev & rev = rev(0)
	rev = rev eq 'YES'
 
        ;-----  Set parameters to their values ------
        for _i = 0, n_elements(_d.pname)-1 do begin
          _t = _d.pname(_i)+'='+string(_d.pval(_i))
          _err = execute(_t)
        endfor
 
	low_in = round(low_in)
	low_out = round(low_out)
	high_in = round(high_in)
	high_out = round(high_out)

	tab = loglut(low_in, high_in, glo=low_out, ghi=high_out, $
	  /round, rev=rev, exp=exponent)
	out = tab(_d.img)

        ;---------  Display image  -------------
	tv, out
 
        return
        end
 
 
;===============================================================
;       xloglut_sp2v = Convert slider position to value.
;===============================================================
 
        function xloglut_sp2v, p, smax, pmin, pmax, int=int
	if keyword_set(int) then begin
          return, fix((p/float(smax))*(pmax-pmin) + pmin)
	endif else begin
          return, (p/float(smax))*(pmax-pmin) + pmin
	endelse
        end
 
;===============================================================
;       xloglut_sv2p = Convert slider value to position.
;===============================================================
 
        function xloglut_sv2p, v, smax, pmin, pmax
        p = fix(.5+float(smax)*(v-pmin)/(pmax-pmin))
        return, p>0<smax
        end
 
;===============================================================
;       xloglut_show_win = Show plot window.  For external use.
;===============================================================
 
        pro xloglut_show_win, top
 
	widget_control, top, get_uval=info
	wset, info.dsave.window
	wshow
 
        end
 
;===============================================================
;       xloglut_get_val = Retrieve parameter values.  For external use.
;===============================================================
 
        pro xloglut_get_val, top, val, unlock=unlock
 
	widget_control, top, get_uval=info
	val = info.pval
	;-----  Unlock specified values  ---------
	if n_elements(unlock) ge 0 then begin
	  for i=0, n_elements(unlock)-1 do begin
	    widget_control, info.id_pbase(unlock(i)), sensitive=1
	    widget_control, info.id_slid(unlock(i)), sensitive=1
	  endfor
	endif
 
        end
 
;===============================================================
;       xloglut_set_val = Set parameter values.  For external use.
;===============================================================
 
        pro xloglut_set_val, top, val, lock=lock
 
	widget_control, top, get_uval=info
	info.pval = val
	;-----  Update widget values and slider positions  -------
	for i=0, n_elements(val)-1 do begin
	  widget_control, info.id_pval(i),set_val=strtrim(val(i),2)
	  widget_control, info.id_slid(i),set_val=xloglut_sv2p(val(i), $
	    info.smax,info.pmin(i),info.pmax(i))
	endfor
	;-----  Update plot  -----------
	xloglut_tv,info
	;-----  Lock specified values  ---------
	if n_elements(lock) ge 0 then begin
	  for i=0, n_elements(lock)-1 do begin
	    widget_control, info.id_pbase(lock(i)), sensitive=0
	    widget_control, info.id_slid(lock(i)), sensitive=0
	  endfor
	endif
	;-----  Save new info  ---------
	widget_control, top, set_uval=info
 
        end

;==============================================================
;	xloglut_event = Event handler
;==============================================================
 
	pro xloglut_event, ev
 
	common xloglut_help_com, h_1,h_2,h_3,h_4,h_5,h_6,h_7,h_8,h_9,h_10
 
	widget_control, ev.id, get_uval=name0	; Get name of action.
        widget_control, ev.top, get_uval=d      ; Get data structure.
        name = strmid(name0,0,3)                ; First 3 chars.
        if nwrds(name0) gt 1 then begin
          name2 = getwrd(name0,1,99)
        endif
 
	wset, d.win			; Select plot window.
 
;	if name eq 'OK' then begin
;	  print,' Sending OK button event to ',d.ok
;	  ok_event = {OK, id:ev.id, top:ev.top, handler:0L}
;	  widget_control, d.ok, send_event=ok_event
;          return
;        endif
; 
;	if name eq 'WIN' then begin
;	  wshow
;          return
;        endif
; 
;	if name eq 'PRO' then begin
;          if !d.window lt 0 then return
;          err = execute(name2)
;          return
;	end

        if name eq 'QUI' then begin
          widget_control, /dest, ev.top
          return
        endif

	if name eq 'LIS' then begin
          ;------  Get reverse flag  ---------
          widget_control, d.wid_rev, get_val=rev & rev = rev(0)

          ;-----  Set parameters to their values ------
          for i = 0, n_elements(d.pname)-1 do begin
            t = d.pname(i)+'='+string(d.pval(i))
            err = execute(t)
          endfor
          low_in = round(low_in)
          low_out = round(low_out)
          high_in = round(high_in)
          high_out = round(high_out)
	  help,rev,low_in,low_out,high_in,high_out,exponent
	  return
	endif

	if name eq 'REV' then begin
	  widget_control, d.wid_rev, get_val=v
	  if v eq 'NO' then widget_control, d.wid_rev, set_val='YES'
	  if v eq 'YES' then widget_control, d.wid_rev, set_val='NO'
          xloglut_tv, d
          goto, update_str
        endif
 
        ;-------  Handle plot related items  ---------------
        if name eq 'PLT' then begin
          xloglut_tv, d
	  goto, update_str
        endif
 
        ;-------  Handle parameter related items  ----------
        if name eq 'PAR' then begin
          act = strmid(name0,3,3)       ; Parameter action code.
          i = strmid(name0,6,2) + 0     ; Parameter index.
 
          ;-------  Process action code  --------
          case act of
'SLD':    begin         ;*** Moved slider. ***
            widget_control, d.id_slid(i), get_val=p             ; New pos.
          end
'MIN':    begin         ;*** Entered new range min. ***
            widget_control, d.id_pmin(i), get_val=t             ; Get ran min.
            d.pmin(i) = t+0.                                    ; Store.
            p = xloglut_sv2p(d.pval(i), d.smax, d.pmin(i), d.pmax(i))   ; New pos.
            widget_control, d.id_slid(i), set_val=p             ; Update slider.
          end
'MAX':    begin         ;*** Entered new range max. ***
            widget_control, d.id_pmax(i), get_val=t             ; Get ran min.
            d.pmax(i) = t+0.                                    ; Store.
            p = xloglut_sv2p(d.pval(i), d.smax, d.pmin(i), d.pmax(i))   ; New pos.
            widget_control, d.id_slid(i), set_val=p             ; Update slider.
          end
'STN':    begin         ;*** Set current value as new range min. ***
            d.pmin(i) = d.pval(i)       ; Update and display new range min.
            widget_control, d.id_pmin(i), set_val=strtrim(d.pmin(i),2)
            p = 0
            widget_control, d.id_slid(i), set_val=p             ; Update slider.
          end
'STX':    begin         ;*** Set current value as new range max. ***
            d.pmax(i) = d.pval(i)       ; Update and display new range max.
            widget_control, d.id_pmax(i), set_val=strtrim(d.pmax(i),2)
            p = d.smax
            widget_control, d.id_slid(i), set_val=p             ; Update slider.
          end
'DEF':    begin         ;*** Set current value back to default  ***
            widget_control,d.id_pval(i),set_val=strtrim(d.pdef(i),2) ; Val 2 Def
            p = xloglut_sv2p(d.pdef(i), d.smax, d.pmin(i), d.pmax(i))
            widget_control, d.id_slid(i), set_val=p             ; Update slider.
          end
'VAL':    begin
            widget_control, d.id_pval(i), get_val=t             ; Get ran min.
            d.pval(i) = t+0.                                    ; Store.
            p = xloglut_sv2p(d.pval(i), d.smax, d.pmin(i), d.pmax(i))   ; New pos.
            widget_control, d.id_slid(i), set_val=p             ; Update slider.
            widget_control, ev.top, set_uval=d    ; Update parameter values.
            xloglut_tv, d                           ; Update plot.
	    goto, update_str
          end
'NAM':    begin
            widget_control, d.id_pnam(i), get_val=t             ; Get par name.
            d.pname(i) = t                                      ; Replace old.
            widget_control, ev.top, set_uval=d    ; Update parameter values.
            xloglut_tv, d                           ; Update plot.
	    goto, update_str
          end
          endcase
          ;-------  Always: compute new val, display it, store it.
          v = xloglut_sp2v(p,d.smax,d.pmin(i),d.pmax(i)) ; New val.
          widget_control,d.id_pval(i),set_val=strtrim(v,2)      ; Display.
          d.pval(i) = v                                         ; Store.
          widget_control, ev.top, set_uval=d      ; Update parameter values.
          xloglut_tv, d                             ; Update plot.
	  goto, update_str
        endif
 
	;-------  Help  ------------
	if name eq 'HLP' then begin
	  case name2 of
'1':	    xhelp,h_1
'2':	    xhelp,h_2
'3':	    xhelp,h_3
'4':	    xhelp,h_4
'5':	    xhelp,h_5
'6':	    xhelp,h_6
'7':	    xhelp,h_7
'8':	    xhelp,h_8
'9':	    xhelp,h_9
	  endcase
          return
        endif
 
 
	print,' Unkown command: ',name0
	return
 
update_str:
        widget_control, ev.top, set_uval=d      ; Save data structure.
	return
 
	end
 
 
;==============================================================
;	xloglut = Interactive Log Lookup table viewer.
;
;	Interactively adjust image scaling using logs
;==============================================================
 
	pro xloglut, img
 
	if keyword_set(hlp) then begin
help:	  print,' Interactively adjust image scaling using logs.'
	  print,' xloglut, img'
	  print,'   img = image array.   in'
	  return
	endif
 
	;------  No equation file given  ------------
	n = 5
	name = ['Low_in','Low_out','High_in','High_out','Exponent']
	amin = [  0.,  0., min(img)+1, 0, -15]
	amax = [max(img)-1,max(img)-1,max(img),topc(), 15]
	def =  [  0,  0, max(img), topc(), 1]

	par = {n:n,name:name,min:amin,max:amax,def:def}
 
	;--------  Set up widget  ------------
	smax = 800
	
	top = widget_base(/col)
 
	;--------  Sliders  ---------------
	id_pbase  = lonarr(par.n)   ; Base with all but slider itself.
        id_slid   = lonarr(par.n)   ; Parameter slider related wids.
        id_parnam = strarr(par.n)
        id_parval = lonarr(par.n)
        id_parmin = lonarr(par.n)
        id_parmax = lonarr(par.n)
        for i = 0, par.n-1 do begin         ; Loop through parameters.
	  if amin(i) eq amax(i) then goto, skip
          b2 = widget_base(top,/row)
	  id_pbase(i) = b2		; Remember slider base.
          id = widget_text(b2,val=par.name(i),xsize=10, /edit, $
            uval='PARNAM'+strtrim(i,2))
          id_parnam(i) = id
	  tmp = par.def(i)
          id = widget_text(b2,val=strtrim(tmp,2),xsize=15,/edit,$
            uval='PARVAL'+strtrim(i,2))
          id_parval(i) = id
          id = widget_label(b2,val='Range: ')
	  tmp = par.min(i)
          id = widget_text(b2,val=strtrim(tmp,2),/edit,$
            uval='PARMIN'+strtrim(i,2),xsize=15)
          id_parmin(i) = id
          id = widget_label(b2,val=' to ')
	  tmp = par.max(i)
          id = widget_text(b2,val=strtrim(tmp,2),/edit,$
            uval='PARMAX'+strtrim(i,2),xsize=15)
          id_parmax(i) = id
          id = widget_button(b2,val='Min',uval='PARSTN'+strtrim(i,2))
          id = widget_button(b2,val='Max',uval='PARSTX'+strtrim(i,2))
          id = widget_button(b2,val='Def',uval='PARDEF'+strtrim(i,2))
          s = widget_slider(top,uval='PARSLD'+strtrim(i,2),xsize=smax+1,$
            max=smax, /suppress,/drag)
          id_slid(i) = s
skip:
        endfor
 
        ;-------  Display widget and update plot  -------
        for i=0, par.n-1 do begin     ; Set parameter slider starting points.
	  if amin(i) ne amax(i) then $
          widget_control, id_slid(i),set_val=$
            xloglut_sv2p(par.def(i),smax,par.min(i),par.max(i))
        endfor
 
	;-------  Function buttons  ----------------
	b = widget_base(top,/row)
	;-------  Rev button  -----------------
	id = widget_label(b,val='Reverse? ')
	wid_rev = widget_button(b, value='NO', uval='REV')
	;-------  List button  -----------------
	id = widget_button(b, value='List', uval='LIS')
	;-------  Quit button  -----------------
	id = widget_button(b, value='Quit', uval='QUIT')
 
	;----  Set up info structure  -------
	info = {top:top,pname:[par.name], $
	  pdef:[par.def], pval:[par.def], pmin:[par.min], pmax:[par.max], $
	  id_pbase:[id_pbase], win:!d.window, $
	  id_slid:[id_slid], id_pval:[id_parval], id_pmin:[id_parmin], $
	  id_pmax:[id_parmax], id_pnam:[id_parnam], $
	  wid_rev:wid_rev, smax:smax, img:img }
	widget_control, top, set_uval=info
 
	;----  Do first plot here  --------
        xloglut_tv, info
	widget_control, top, set_uval=info
 
        ;-------  xmanager  -------
        widget_control, top, /real
        xmanager, 'xloglut', top, /no_block
 
	return
	end
