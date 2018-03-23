;-------------------------------------------------------------
;+
; NAME:
;       XPAR2
; PURPOSE:
;       Execute IDL code using interactively varied parameters.
; CATEGORY:
; CALLING SEQUENCE:
;       xpar, file
; INPUTS:
;       file = xpar file or text array.   in
; KEYWORD PARAMETERS:
;       Keywords:
;         P1=var1, P2=var2, ... P5=var5  Up to 5 variables.
;           may be passed into the program using these keywords.
;           To use in the code reference as _s.p1, _s.p2, ...
;         /WAIT means wait until the routine is exited instead
;            returning right after startup.
;         PARVALS=pv Structure with parameter names and values.
;            Must be used with /WAIT or pv will be undefined.
;         EXITCODE=excd 0=normal, 1=cancel.  Must use with /WAIT.
;         /DEMO runs a default demo, an interactive globe.
;         /DEM2 runs a non-graphical demo, prime factors.
;         TOP=top    Returns widget ID of top level base.
;           Use widget_control to retrieve or store info structure.
;         OK=wid  ID of widget to notify when OK button pressed.
;           If not given no OK button is displayed.
;           Useful to allow a higher level widget routine to call
;           EQV3.  The OK button then sends an event to the higher
;           level widget which can then destroy the eqv3 widget.
;         WID_OK=wid  Returned widget ID of the OK button.
;           Can use to set /input_focus.
;         GROUP_LEADER=grp  Set group leader.
;         XOFFSET=xoff, YOFFSET=yoff Widget position.
;       
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
;       Notes: This routine will not work in an IDL Virtual Machine.
;       Use the Help button for more details.
;       Xpar file format: This text file defines the IDL code,
;       and range of each adjustable parameter.
;       Null and comment lines (* or ; in first column) are allowed.
;       The tags are shown by a simple example:
;          init: window,/free
;          title: Parabola
;          code: x=maken(-10,10,100) & plot,x,a + b*x + $
;            c*x^2,xr=[-10,10],yr=[-100,100]
;          sliders: 3
;          par:  a, -50, 50, 0
;          par:  b, -50, 50, 0
;          par:  c, -10, 10, 1
;       
;       The parameter tags are followed by 4 items:
;         Parameter name (as in the equation),
;         min value, max value, initial value.  Optional items are
;         /INT to force an integer value, COLOR=clr for slider
;         color, FRAME=fr for button frame.
;       
;       Use the Help button menu for more complete details.
; MODIFICATION HISTORY:
;       R. Sterner, 2006 Oct 17
;       R. Sterner, 2008 Oct 07 --- Added list input source under file menu.
;       R. Sterner, 2008 Oct 09 --- Drop-down lists should be working.
;       R. Sterner, 2008 Oct 16 --- Color patches should be working.
;       R. Sterner, 2008 Oct 22 --- Converted xpar help to add_helpmenu form.
;       R. Sterner, 2008 Oct 22 --- No longer drops through on error.
;       R. Sterner, 2008 Oct 23 --- Changed variable input to INPUT=struct.
;
; Copyright (C) 2006, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------


	;====================================================================
	;====================================================================
	;  xpar_exe = Execute xpar code
	;
	;  Internal variables are named with a leading _.
	;====================================================================
	;====================================================================

	pro xpar_exe, _s
 
	;-------------------------------------------------------------
	;  Read code
	;-------------------------------------------------------------
	widget_control, _s.id_code, get_val=_code
	_code = _code[0]
 
	;-------------------------------------------------------------
	;  Deal with passed in variables
	;-------------------------------------------------------------
	if _s.n_in gt 0 then begin			; INPUT keyword used.
	  for _i=0,_s.n_in-1 do begin
	    _txt = _s.input_name[_i]+ $			; Get vars in INPUT.
	      '=_s.input.('+string(_i)+')'
	    _err = execute(_txt)			; Execute string.
	  endfor
	endif

	;-------------------------------------------------------------
	;  Set parameters to their values
	;-------------------------------------------------------------
	if _s.n_par gt 0 then begin			; If any parameters...
	  _txt = ''					; String to build.
	  _fmt = '(G)'					; Format to use.
	  _par_nam = _s.par_nam0[_s.par_uin]		; Use only the unique.
	  _par_cur = _s.par_cur0[_s.par_uin]
	  _par_int = _s.par_int0[_s.par_uin]
	  for _i=0, n_elements(_s.par_uin)-1 do begin	; Loop over pars.
	    _nam = _par_nam[_i]				; Par name.
	    _val = _par_cur[_i]				; Par val.
	    if _par_int[_i] eq 1 then begin		; Integer?
	      _val = strtrim(fix(_val),2)		; Yes, fix.
	    endif else begin
	      _val0 = strtrim(string(_val,form=_fmt),2)	; No, convert to string.
	      _val = repchr(_val0,'E','D')		; Force double.
	      if _val eq _val0 then _val=_val+'D0'	; Add D0 if no D.
	    endelse
	    _txt = _txt + _nam + '=' + _val + ' & '	; Add var to string.
	  endfor
	  if _s.debug then print,_txt			; Debug print.
	  _err = execute(_txt)				; Execute string.
	endif
 
	;-------------------------------------------------------------
	;  Set flags to their values
	;-------------------------------------------------------------
	if _s.n_flag gt 0 then begin			; If any parameters...
	  _txt = ''					; String to build.
	  _flag_nam = _s.flag_nam[_s.flag_uin]		; Use only the unique.
	  _flag_val = _s.flag_val[_s.flag_uin]
	  for _i=0, n_elements(_flag_nam)-1 do begin	; Loop over flags.
	    _nam = _flag_nam[_i]			; Flag name.
	    _val = strtrim(_flag_val[_i],2)		; Flag val.
	    _txt = _txt + _nam + '=' + _val + ' & '	; Add var to string.
	  endfor
	  if _s.debug then print,_txt			; Debug print.
	  _err = execute(_txt)				; Execute string.
	endif
 
	;-------------------------------------------------------------
	;  Set color variables to their values
	;-------------------------------------------------------------
	if _s.n_color gt 0 then begin			; If any colors...
	  _txt = ''					; String to build.
	  _color_nam = _s.color_nam[_s.color_uin]	; Use only the unique.
	  _color_val = _s.color_val[_s.color_uin]
	  for _i=0, n_elements(_color_nam)-1 do begin	; Loop over colors.
	    _nam = _color_nam[_i]			; Color name.
	    _val = strtrim(_color_val[_i],2)		; Color val.
	    _txt = _txt + _nam + '=' + _val + ' & '	; Add var to string.
	  endfor
	  if _s.debug then print,_txt			; Debug print.
	  _err = execute(_txt)				; Execute string.
	endif
 
	;-------------------------------------------------------------
	;  Set lists to their values
	;-------------------------------------------------------------
	if _s.n_lst gt 0 then begin			; If any parameters...
	  _txt = ''					; String to build.
	  _lst_nam = _s.lst_nam[_s.lst_uin]		; Use only the unique.
	  _lst_val = _s.lst_val[_s.lst_uin]
	  for _i=0, n_elements(_lst_nam)-1 do begin	; Loop over lists.
	    _nam = _lst_nam[_i]				; List name.
	    _val = strtrim(_lst_val[_i],2)		; List val.
	    _txt = _txt + _nam + "='" + _val + "' & "	; Add var to string.
	  endfor
	  if _s.debug then print,_txt			; Debug print.
	  _err = execute(_txt)				; Execute string.
	endif
 
	;-------------------------------------------------------------
	;  Execute code
	;-------------------------------------------------------------
	if _s.win_re eq 1 then win_redirect
	if _s.debug then print,_code			; Debug print.
	_err = execute(_code)				; Execute string.
	if _s.win_re eq 1 then win_copy
	if _err ne 1 then begin
	  xhelp,exit='OK',['Error executing: ',_code,!err_string, $
	    ' ','Do the following to recover:', $
	    '1. Correct any errors in the executable text.', $
	    '2. Press the OK button above.'],/wait
	  return
	endif
 
	end
 
	;====================================================================
	;====================================================================
	;  xpar_sp2v = Slider: Convert slider position to parameter value.
	;====================================================================
	;====================================================================
	function xpar_sp2v, p, smax, pmin, pmax, int=int
	if keyword_set(int) then begin
          return, fix((p/float(smax))*(pmax-pmin) + pmin)
	endif else begin
          return, (p/float(smax))*(pmax-pmin) + pmin
	endelse
        end
 
	;====================================================================
	;====================================================================
	;  xpar_sv2p = Slider: Convert parameter value to slider position.
	;====================================================================
	;====================================================================
	function xpar_sv2p, v, smax, pmin, pmax
	p = fix(.5+float(smax)*(v-pmin)/(pmax-pmin))
        return, p>0<smax
        end
 
	;====================================================================
	;====================================================================
	;  xpar_event = Event handler
	;====================================================================
	;====================================================================
	pro xpar_event, ev
 
	widget_control, ev.top, get_uval=s	; Grab info structure.
	widget_control, ev.id, get_uval=uval	; Get event UVAL.
 
	if s.debug then begin
	  help,uval
	  help,ev,/st
	endif
 
	cmd = getwrd(uval,0)			; First word is the command.
 
	;-------------------------------------------------------------
	;  Parameter Button clicked
	;
	;  When a parameter button is clicked, first check if it is
	;  already tied to a slider.  if so just beep and ignore.
	;  If not, find the oldest slider and update it with the
	;  values for the new parameter.
	;-------------------------------------------------------------
	if cmd eq 'PAR' then begin
	  ip = getwrd(uval,1)		; Parameter index from uval.
	  ;---  Check if this parameter is already a slider  ----
	  w = where(ip eq s.sld_parind,cnt)  ; Already a slider?
	  if cnt gt 0 then begin	; If yes,
	    bell			;   just beep and return.
	    return
	  endif
	  ;---  Find oldest slider and update it  ----
	  age = s.age_sld		; Slider age array.
	  w = where(age eq min(age))	; Find oldest slider.
	  is = w(0)			; Index of oldest slider.
	  id_sl = s.id_slider(is)	; WID of oldest slider.
	  ;---  Make a new uval  ----
	  fmt = '(I3.2)'
	  ip = string(ip,form=fmt)			; Par index.
	  is = string(is,form=fmt)			; Slider index.
	  iu = string(s.par_uin[ip+0],form=fmt)		; Unique index.
	  uv2 = ip + is + iu				; Indices in uval.
	  ;---  Update age and par index  ----
	  age(is) = max(age) + 1	; Set age for new slider.
	  s.age_sld = age		; Save update age.
	  s.sld_parind(is) = ip		; Save which par this slider is.
	  ;---  Update slider values  ----
	  widget_control,s.id_slider(is),set_val='color='+string(s.par_clr0(ip))
	  widget_control,s.id_slider(is),set_uval='SLDER '+uv2
	  widget_control,s.id_sldnam(is),set_val=s.par_nam0(ip)
	  pval = s.par_cur0(ip)				; Set val.
	  if s.par_int0(ip) eq 1 then pval=fix(pval)	; Make integer if flag.
	  tmp = strtrim(pval,2)
	  uv = 'SLDVAL' + uv2
	  widget_control,s.id_sldval(is),set_val=tmp,set_uval=uv
	  pmin = s.par_min0(ip)				; Set min.
	  if s.par_int0(ip) eq 1 then pmin=fix(pmin)
	  tmp = strtrim(pmin,2)
	  uv = 'SLDMIN' + uv2
	  widget_control,s.id_sldmin(is),set_val=tmp,set_uval=uv
	  pmax = s.par_max0(ip)				; Set max.
	  if s.par_int0(ip) eq 1 then pmax=fix(pmax)
	  tmp = strtrim(pmax,2)
	  uv = 'SLDMAX' + uv2
	  widget_control,s.id_sldmax(is),set_val=tmp,set_uval=uv
	  widget_control, s.id_slider(is), set_val= $   ; Set slider position.
	      xpar_sv2p(pval, s.smax, pmin, pmax)
	  uv = 'SLDSTN' + uv2				; Set Min button uval.
	  widget_control,s.id_sldstn(is),set_uval=uv
	  uv = 'SLDSTX' + uv2				; Set Max button uval.
	  widget_control,s.id_sldstx(is),set_uval=uv
	  uv = 'SLDDEF' + uv2				; Set Def button uval.
	  widget_control,s.id_slddef(is),set_uval=uv
	  ;---  Save updated info structure  ----
	  widget_control, ev.top, set_uval=s
	  return
	endif
 
	;-------------------------------------------------------------
	;  Slider item
	;
	;  When a slider is moved, or any of the values changed,
	;  then update the widget and internal values and
	;  execute the code.  Invalid entries are ignored.
	;  Also update unique index.
	;-------------------------------------------------------------
	if strmid(cmd,0,3) eq 'SLD' then begin
	  ip = getwrd(uval,1) + 0		; Parameter index (full list).
	  is = getwrd(uval,2) + 0		; Slider index.
	  iu = getwrd(uval,3) + 0		; Unique index.
	  smax = s.smax				; Slider value range: 0 to smax.
	  pmin = s.par_min0(ip)			; Parameter min.
	  pmax = s.par_max0(ip)			; Parameter max.
	  int  = s.par_int0(ip)			; Is parmeter an integer?
 
	  case cmd of
'SLDER':  begin			; SLIDER was moved.
	    p = ev.value			; Event value = slider value.
	    cur = xpar_sp2v(p, smax, pmin, pmax, int=int) ; Sld val to par val.
	    s.par_cur0(ip) = cur		; Save current par val.
	    s.par_cur0(iu) = cur		; Save current par val.
	    vmin = pmin<pmax			; Allow for reversed range.
	    vmax = pmin>pmax
	    v = cur>vmin<vmax
	    if int eq 1 then v=fix(v)
	    widget_control, s.id_sldval(is), set_val=strtrim(v,2)
	  end
'SLDVAL': begin			; NEW VALUE entered.
	    widget_control, ev.id, get_val=cur	; Grab new current par val.
	    cur = cur + 0D0			; Force dbl.
	    widget_control, s.id_slider(is), set_val= $ ; Set slider position.
	        xpar_sv2p(cur, smax, pmin, pmax)
	    s.par_cur0(ip) = cur		; Save current par val.
	    s.par_cur0(iu) = cur		; Save current par val.
	    vmin = pmin<pmax			; Allow for reversed range.
	    vmax = pmin>pmax
	    v = cur>vmin<vmax
	    if int eq 1 then v=fix(v)
	    widget_control, ev.id, set_val=strtrim(v,2)
	  end
'SLDMIN': begin			; NEW MIN VALUE entered.
	    widget_control, ev.id, get_val=pmin	; Grab new par min.
	    pmin = pmin + 0D0			; Force dbl.
	    if pmin eq pmax then begin		; Repair invalid entry.
	      bell				; Warning beep.
	      pmin = s.par_min0(ip)		; Old Parameter min.
	      if int eq 1 then v=fix(pmin) else v=pmin	; Update pmin.
	      widget_control, ev.id, set_val=strtrim(v,2)
	      return
	    endif
	    s.par_min0(ip) = pmin		; Save it.
	    s.par_min0(iu) = pmin		; Save it.
	    cur = s.par_cur0(ip)		; Get current par val.
	    vmin = pmin<pmax			; Allow for reversed range.
	    vmax = pmin>pmax
	    cur = cur>vmin<vmax			; Keep CUR in range.
	    s.par_cur0(ip) = cur		; Save it.
	    s.par_cur0(iu) = cur		; Save it.
	    widget_control, s.id_slider(is), set_val= $ ; Update slider.
	        xpar_sv2p(cur, smax, pmin, pmax)
	    if int eq 1 then v=fix(pmin) else v=pmin	; Update pmin.
	    widget_control, ev.id, set_val=strtrim(v,2)
	    if int eq 1 then v=fix(cur) else v=cur	; Update cur.
	    widget_control, s.id_sldval(is), set_val=strtrim(v,2)	
	  end
'SLDMAX': begin			; NEW MAX VALUE entered.
	    widget_control, ev.id, get_val=pmax	; Grab new par max.
	    pmax = pmax + 0D0			; Force dbl.
	    if pmax eq pmin then begin		; Repair invalid entry.
	      bell				; Warning beep.
	      pmax = s.par_max0(ip)		; Old Parameter min.
	      if int eq 1 then v=fix(pmax) else v=pmax	; Update pmax.
	      widget_control, ev.id, set_val=strtrim(v,2)
	      return
	    endif
	    s.par_max0(ip) = pmax		; Save it.
	    s.par_max0(iu) = pmax		; Save it.
	    cur = s.par_cur0(ip)		; Get current par val.
	    vmin = pmin<pmax			; Allow for reversed range.
	    vmax = pmin>pmax
	    cur = cur>vmin<vmax			; Keep CUR in range.
	    s.par_cur0(ip) = cur		; Save it.
	    s.par_cur0(iu) = cur		; Save it.
	    widget_control, s.id_slider(is), set_val= $ ; Update slider.
	        xpar_sv2p(cur, smax, pmin, pmax)
	    if int eq 1 then v=fix(pmax) else v=pmax	; Update pmin.
	    widget_control, ev.id, set_val=strtrim(v,2)
	    if int eq 1 then v=fix(cur) else v=cur	; Update cur.
	    widget_control, s.id_sldval(is), set_val=strtrim(v,2)	
	  end
'SLDSTN': begin			; NEW RANGE MIN set.
	    cur = s.par_cur0(ip)		; Grab current value.
	    if cur eq pmax then begin		; Don't allow invalid entry.
	      bell				; Warning beep.
	      return
	    endif
	    pmin = cur				; Copy current to pmin.
	    if int eq 1 then pmin=fix(pmin) $   ; Fix pmin.
	      else pmin=pmin
	    s.par_min0(ip) = pmin		; Save pmin in s.
	    s.par_min0(iu) = pmin		; Save pmin in s.
	    widget_control, s.id_sldmin(is),$   ; Display new pmin.
	       set_val=strtrim(pmin,2)
	    widget_control, s.id_slider(is),$   ; Set slider position.
	        set_val=xpar_sv2p(cur,smax,pmin,pmax)
	  end
'SLDSTX': begin			; NEW RANGE MAX set.
	    cur = s.par_cur0(ip)		; Grab current value.
	    if cur eq pmin then begin		; Don't allow invalid entry.
	      bell				; Warning beep.
	      return
	    endif
	    pmax = cur				; Copy current to pmax.
	    if int eq 1 then pmax=fix(pmax) $   ; Fix pmax.
	      else pmax=pmax
	    s.par_max0(ip) = pmax		; Save pmax in s.
	    s.par_max0(iu) = pmax		; Save pmax in s.
	    widget_control, s.id_sldmax(is),$  ; Display new pmax.
	       set_val=strtrim(pmax,2)
	    widget_control, s.id_slider(is),$   ; Set slider position.
	        set_val=xpar_sv2p(cur,smax,pmin,pmax)
	  end
'SLDDEF': begin			; DEFAULT VALUE set.
	    cur = s.par_def0(ip)		; Get current par val.
	    vmin = pmin<pmax			; Allow for reversed range.
	    vmax = pmin>pmax
	    cur = cur>vmin<vmax			; Keep CUR in range.
	    s.par_cur0(ip) = cur		; Save it.
	    s.par_cur0(iu) = cur		; Save it.
	    widget_control, s.id_slider(is), set_val= $ ; Update slider.
	        xpar_sv2p(cur, smax, pmin, pmax)
	    if int eq 1 then v=fix(cur) else v=cur	; Update cur.
	    widget_control, s.id_sldval(is), set_val=strtrim(v,2)	
	  end
	  endcase
 
	  widget_control, ev.top, set_uval=s	; Save updated info structure.
	  xpar_exe, s
	  return
	endif
 
	;-------------------------------------------------------------
	;  Flag clicked
	;
	;  When a flag is clicked its value is toggled.  Update the
	;  internal copy and execute the code.
	;-------------------------------------------------------------
	if cmd eq 'FLAG' then begin
	  in = getwrd(uval,1)		; Actual flag index.
	  iu = getwrd(uval,2)		; Unique flag index.
	  s.flag_val(in) = ev.select	; Set actual flag.
	  s.flag_val(iu) = ev.select	; Set unique flag too.
	  widget_control, ev.top, set_uval=s
	  xpar_exe, s
	  return
	endif
 
	;-------------------------------------------------------------
	;  Color patch clicked
	;
	;  When a patch is clicked call color_pick.  Update the
	;  color patch clicked and the unique color (color actually used)
	;  and execute the code.
	;-------------------------------------------------------------
	if cmd eq 'COLOR' then begin
	  if ev.press eq 1 then return		; Ignore press.
	  in = getwrd(uval,1)			; Array index of color.
	  iu = getwrd(uval,2)			; Index of unique color.
	  old = s.color_val[in]			; Grab old value.
	  color_pick, new, old			; Get new with color wheel.
	  if new gt -1 then begin		; If not Canceled:
	    s.color_val[in] = new		;   Save new clr for ptch clckd.
	    s.color_val[iu] = new		;   and for patch actually used.
	    win0 = !d.window			;   Get current window.
	    wset, s.color_win[in]		;   Set to clckd clr patch win.
	    erase, new				;   Fill with new color.
	    wset, s.color_win[iu]		;   Set to used clr patch win.
	    erase, new				;   Fill with new color.
	    wset, win0				;   Set back to original window.
	    widget_control, ev.top, set_uval=s	;   Save updated values.
	    xpar_exe, s				;   Execute code with new vals.
	  endif
	  return
	endif
 
	;-------------------------------------------------------------
	;  List clicked
	;
	;  When a list is clicked: Update last item (drop <--),
	;    pick off new curr value from uval, update curr item
	;    with <---, save curr item, save curr wid, execute code.
	;
	;  Get items from uval: in iu il val
	;    in = Index into complete array of lists.
	;    iu = Index actually used in execute code.
	;    il = Index in list of item (not used here).
	;    val = Value to use.
	;  Erase arrow (<--) in current list.
	;  Update values array for current list and unique list.
	;  Update current list pointer to new list element (wid).
	;    This will be used to erase arrow when it changes.
	;-------------------------------------------------------------
	if cmd eq 'LIST' then begin
	  in = getwrd(uval,1)			   ; Actual list index.
	  iu = getwrd(uval,2)			   ; Unique list index.
	  val = getwrd(uval,4)			   ; Value of selected item.
	  widget_control,s.lst_wid[in],get_val=old ; Grab old value, has <--.
	  old = strmid(old,0,strlen(old)-4)	   ; Drop <-- from old.
	  widget_control,s.lst_wid[in],set_val=old ; Update old value.
	  s.lst_val[in] = val			   ; New current value.
	  s.lst_val[iu] = val			   ; Update unique too.
	  s.lst_wid[in] = ev.id			   ; New curr WID.
	  val = val + ' <--'			   ; Add <--- to new.
	  widget_control,ev.id,set_val=val	   ; Update new.
	  widget_control, ev.top, set_uval=s	   ; Save new values.
	  xpar_exe, s				   ; Execute code.
	  return
	endif
 
	;-------------------------------------------------------------
	;  File menu item selected
	;-------------------------------------------------------------
	;-------------------------------------------------------------
	;  QUIT
	;-------------------------------------------------------------
	if cmd eq 'FMEN_QUIT' then begin
	  parvals = {pname: s.par_nam0,   pval:s.par_cur0, $  ; par  and flag
	            fname: s.flag_nam,   fval: s.flag_val } ; values in struct.
	  widget_control,s.res,set_uval=parvals ; Store in base.
	  widget_control, s.ext, set_uval=1	; 1 = Normal exit.
	  for i=0,s.n_exi-1 do begin		; Execute EXIT code.
	    code = s.txt_exi(i)
	    if s.debug then print,code
	    err=execute(code)
	  endfor
	  widget_control, ev.top, /destroy	; Destroy widget.
	  return
	endif
	;-------------------------------------------------------------
	;  CANCEL
	;-------------------------------------------------------------
	if cmd eq 'FMEN_CANCEL' then begin
	  widget_control, s.res, set_uval=''	; Values not returned.
	  widget_control, s.ext, set_uval=0	; 0 = Canceled exit.
	  for i=0,s.n_exi-1 do begin		; Execute EXIT code.
	    code = s.txt_exi(i)
	    print,code
	    err=execute(code)
	  endfor
	  widget_control, ev.top, /destroy	; Destroy widget.
	  return
	endif
	;-------------------------------------------------------------
	;  SNAPSHOT
	;-------------------------------------------------------------
	if cmd eq 'FMEN_SNAP' then begin
	  ;---  Make code text  -----
	  widget_control, s.id_code,get_val=txt	; Code code line.
	  wordarray,txt,del='&',out		; Break into lines.
	  code = ['']				; Output code array.
	  lst = n_elements(out)-1
	  for i=0,lst do begin			; Process lines.
	    if i lt lst then post=' &$' $       ; Add &$ at end of each line.
	      else post=''
	    t1 = out[i]				; Line i.
	    wordarray,t1,del=',',out2		; Split up line i.
	    n2 = n_elements(out2)
	    out2[0:n2-2] = out2[0:n2-2]+','
	    c = cumulate(strlen(out2))
	    if max(c) lt 70 then begin		; Line short enough.
	      t2 = ''				; Start output line.
	      for j=0,n2-1 do t2=t2+out2[j]	; Build output line.
	      code = [code,t2+post]		; Add to output.
	    endif else begin			; Line too long.
	      t2 = ''				; Start output line.
	      w = where(c ge 60,cnt)		; Find good length.
	      hi = w[0]<(n2-3)			; Keep some at end.
	      for j=0,hi do t2=t2+out2[j]	; Build output line.
	      code = [code,t2+' $']		; Add to output.
	      t2 = '  '				; Start rest of line.
	      for j=hi+1,n2-1 do t2=t2+out2[j]	; Build output line.
	      code = [code,t2+post]		; Add to output.
	    endelse
	  endfor
	  code = code[1:*]			; Trim start null.
	  code[0] = strtrim(code[0],2)
	  ;---  Parameters  ------
	  vals = strarr(s.n_par)		; Values array.
	  fmt = '(G)'				; Format to use.
	  for i=0,s.n_par-1 do begin		; Loop over pars.
	    val = s.par_cur[i]			; Par val.
	    if s.par_int[i] eq 1 then begin	; Integer?
	      val = strtrim(fix(val),2)		; Yes, fix.
	    endif else begin
	      val0 = strtrim(string(val,form=fmt),2) ; No, convert to string.
	      val = repchr(val0,'E','D')	; Force double.
	      if val eq val0 then val=val+'D0'	; Add D0 if no D.
	    endelse
	    vals[i] = val
	  endfor
	  par = s.par_nam + ' = ' + vals
	  ;---  Flags  ---------
	  flags = s.flag_nam+' = '+strtrim(s.flag_val,2)
	  ;---  Output  --------
	  txt = [';--- Code  ---',code,' ', $
	    ';--- Parameters ---',par,' ',';--- Flags ---',flags]
	  js = dt_tm_tojs(systime())
	  ttag = dt_tm_fromjs(js,form='y$n$0d$_h$m$s$')
	  out = 'snapshot_'+ttag+'.txt'
	  putfile, out,txt
	  print,' Snapshot saved in text file '+out
	  return
	endif
	;-------------------------------------------------------------
	;  DEBUG
	;-------------------------------------------------------------
	if cmd eq 'FMEN_DEBUG' then begin
	  print,' '
	  print,' Info structure is s.  Event structure is ev.'
	  stop,' Debug STOP.  Do .con to continue.'
	  return
	endif
	;-------------------------------------------------------------
	;  DISPLAY INPUT SOURCE
	;-------------------------------------------------------------
	if cmd eq 'FMEN_SRC' then begin
	  xmess,['Input source:',s.txtsrc]
	  return
	endif
 
	;-------------------------------------------------------------
	;  Options menu item selected
	;-------------------------------------------------------------
	;-------------------------------------------------------------
	;  WIN_REDIRECT	= Toggle win_redirect on or off.
	;-------------------------------------------------------------
	if cmd eq 'OPTN_WINR' then begin
	  s.win_re = 1-s.win_re
	  tmp = (s.win_re eq 0)?'Turn Win_redirect On':'Turn Win_redirect Off'
	  widget_control, s.id_winr, set_val=tmp
	  widget_control, ev.top, set_uval=s
	  return
	endif
	;-------------------------------------------------------------
	;  WIN_SHOW = Show current window.
	;-------------------------------------------------------------
	if cmd eq 'OPTN_WSHOW' then begin
	  wshow
	  return
	endif
	;-------------------------------------------------------------
	;  DEBUG = Toggle debug on or off.
	;-------------------------------------------------------------
	if cmd eq 'OPTN_DBG' then begin
	  s.debug = 1-s.debug
	  tmp = (s.debug eq 0)?'Turn Debug On':'Turn Debug Off'
	  widget_control, s.id_debug, set_val=tmp
	  widget_control, ev.top, set_uval=s
	  return
	endif
 
	;-------------------------------------------------------------
	;  User menu item selected
	;-------------------------------------------------------------
	if cmd eq 'USER' then begin
	  rout = getwrd(uval,1)			; Second word is the routine.
	  flag = getwrd(uval,2) + 0		; Third is flag.
	  if flag eq 1 then begin
	    call_procedure, rout, info=s	; Call procedure with INFO=s.
	  endif else begin
	    call_procedure, rout		; Call just the procedure.
	  endelse
	  return
	endif
 
	;-------------------------------------------------------------
	;  Help menu item selected
	;
	;  UVAL = "HELP tag"
	;  Tag is a pointer to a section of text in s.txt_help.
	;-------------------------------------------------------------
	if cmd eq 'HELP' then begin
	  txt = s.txt_help			; Grab XPAR help text.
	  tag = getwrd(uval,1)			; Second word is the section.
	  atag = '<'+tag+'>'			; Construct the help text
	  btag = '</'+tag+'>'			; delimiters.
	  txt_keysection,txt,after=atag,before=btag, $ ; Grab the help text.
	    /quiet, err=err
	  if err ne 0 then begin			; Deal with an error.
	    xmess,['Error in menu layout text: Could not find matching',$
		   'delimiting tags.  Was looking for', $
		   atag+ ' and '+btag+' in ', $
		   src] 
	    return
	  endif
	  xhelp,txt,/bottom			; Display the help text.
	  return
	endif
 
	;-------------------------------------------------------------
	;  CODE area
	;-------------------------------------------------------------
	if cmd eq 'CODE' then begin
	  widget_control, ev.id, get_val=txt
	  t = ''
	  for i=0,n_elements(txt)-1 do t=t+txt[i]
	  widget_control, ev.id, set_val=t
	  xpar_exe, s
	  return
	endif
 
	;-------------------------------------------------------------
	;  TAB
	;
	;  On tab change update:
	;    Parameters, Flags, Color patches, Lists.
	;
	;  Find all items on current tab and check all other
	;  tabs for same name to find matches.  For each match
	;  copy values from current tab to other tab.
	;  wl = Indices of last tab parameters,
	;  wr = indices of all the rest of the parameters.
	;
	;  s.???_tab0 is a list of the tab index of each item of type
	;  ???.  s.tab_last is the tab index of the tab just before
	;  it is changed to another tab.  So find where s.???_tab0
	;  equals s.tab_last to find all items of typ ??? that need
	;  to be synched on other tabs.
	;
	;  wl below is the array of indices into the complete list of items
	;  of typ ??? that are on the old tab.
	;  wm below is the array of indices into the complete list of items
	;  of typ ??? on all tabs that have the same name as one
	;  of the items on the old tab.
	;-------------------------------------------------------------
	if cmd eq 'TAB' then begin
	  ;--- Update parameters  ---
	  wl = where(s.par_tab0 eq s.tab_last,$	; Par indices on last tab
	    nl, comp=wr, ncomp=nr)		; and on all the other tabs.
	  if nr gt 0 then begin			; Any other tabs with pars?
	    smax = s.smax			; Slider length in pixels.
	    for i=0,nl-1 do begin		; Loop over last pars.
	      ip = wl[i]			; Complete list index.
	      nam = s.par_nam0[ip]		; Parameter name.
	      wm = where(nam eq s.par_nam0,cnt)	; Find all matches.
	      if cnt gt 1 then begin		; If more than 1 update all.
	  	pmin = s.par_min0[ip]		; Parameter min.
	  	pmax = s.par_max0[ip]		; Parameter max.
	  	int = s.par_int0[ip]		; Is integer?
	        s.par_min0[wm] = pmin		; Copy min and max to matches.
	        s.par_max0[wm] = pmax
		cur = s.par_cur0[ip]		; Current value.
	        s.par_cur0[wm] = cur		; Copy to matches.
		for j=0,cnt-1 do begin		; Move matching sliders to cur.
		  is = wm[j]			; Complete list index.
	    	  widget_control,s.id_slider[is],$  ; Set slider position.
		    set_val=xpar_sv2p(cur, smax, pmin, pmax)
	    	  v = cur>pmin<pmax
	    	  if int eq 1 then v=fix(v)
	    	  widget_control, s.id_sldval(is), set_val=strtrim(v,2)
		endfor ; j
	      endif ; cnt
	    endfor ; i
	  endif ; nr
	  ;---  Update flags  ---
	  wl = where(s.flag_tab eq s.tab_last,$	; Flg indices on last tab
	    nl, comp=wr, ncomp=nr)		; and on all the other tabs.
	  if nr gt 0 then begin			; Any other tabs with flgs?
	    for i=0,nl-1 do begin		; Loop over last flgs.
	      in = wl[i]			; Complete list index.
	      nam = s.flag_nam[in]		; Flag name.
	      wm = where(nam eq s.flag_nam,cnt)	; Find all matches.
	      if cnt gt 1 then begin		; If more than 1 update all.
	        val = s.flag_val[in]		; Value of flag in.
		for j=0,cnt-1 do begin		; Set matching flags to val.
		  is = wm[j]			; Complete list index.
		  widget_control,s.id_flg[is], $
		    set_button=val
	          s.flag_val[is] = val		; Update flag value.
		endfor ; j
	      endif ; cnt
	    endfor ; i = flags on last tab.
	  endif ; nr
	  ;-----------------------------------------------------------
	  ;  Update color patches
	  ;
	  ;  Find which (if any) colors were on previous tab.
	  ;  If any old colors then 
	  ;    Remember incoming window index.
	  ;    Loop (I) over colors from previous tab:
	  ;      Get index (IN) of old color I.
	  ;      Get name of old color I (s.color_nam[IN]).
	  ;      Find all (if any) colors that match in name.
	  ;      If any matching colors then
	  ;        Grab old color value.
	  ;        loop over matching colors:
	  ;          Get index (IS) of matching color J.
	  ;          Set color patch is window as current.
	  ;          Erase to old tab color.
	  ;        End loop matching colors.
	  ;      Endif any matching colors
	  ;    End loop old colors (I).
	  ;    Restore incoming window as current
	  ;  Endif any old colors
	  ;
	  ;  WL = array of indices of colors on previous tab, NL of them.
	  ;  NR = number of colors on all the other tabs.
	  ;  I = loop over those old tab colors.
	  ;  IN = index of ith old tab color.
	  ;  WM = array of all colors with same name, CNT of them.
	  ;  VAL = value of old tab color IN.
	  ;  J = loop over those colors with matching names.
	  ;  IS = index of Jth matching name color.
	  ;-----------------------------------------------------------
	  wl = where(s.color_tab eq s.tab_last,$  ; Color indices on last tab.
	    nl, comp=wr, ncomp=nr)		; and on all the other tabs.
	  if nr gt 0 then begin			; Any other tabs with colors?
	    win0 = !d.window			; Remember incoming window.
	    for i=0,nl-1 do begin		; Loop over previous tab colors.
	      in = wl[i]			; Previous tab clr patch index.
	      nam = s.color_nam[in]		; Color name.
	      wm = where(nam eq s.color_nam,cnt); Find all matches.
	      if cnt gt 1 then begin		; If more than 1 update all.
	        val = s.color_val[in]		; Value of color in on old tab.
		for j=0,cnt-1 do begin		; Set matching colors to val.
		  is = wm[j]			; Matching color patch index.
		  wset, s.color_win[is]		; Set to matching color window.
		  erase, val			; Fill with color from old tab.
	          s.color_val[is] = val		; Update color value.
		endfor ; j
	      endif ; cnt
	    endfor ; i = colors on last tab.
	    wset, win0				; Restore to incoming window.
	  endif ; nr
	  ;-----------------------------------------------------------
	  ;  Update lists
	  ;
	  ;  Find which (if any) lists were on previous tab.
	  ;  If any then loop over lists from previous tab:
	  ;    Get index (in) of old list i.
	  ;    Get name of old list i (s.lst_nam[in]).
	  ;    Find all (if any) lists that match in name.
	  ;    If any then
	  ;      Find current item on old list i and item # (il).
	  ;      loop over matching lists:
	  ;        Get index (is) of matching list j.
	  ;        Get old item on list j (lst_wid[is]) and drop arrow.
	  ;        Get new item on list j from lst_iwd item # il,
	  ;          add arrow, and save wid in lst_wid[is].
	  ;      End loop matching lists.
	  ;    If any
	  ;  End loop old lists.
	  ;
	  ;  WL = array of indices of lists on previous tab, NL of them.
	  ;  I = loop over those old tab lists.
	  ;  IN = index of ith old tab list.
	  ;  WM = array of all lists with same name, CNT of them.
	  ;  VAL = selected Item on old tab list IN.
	  ;  J = loop over those matching name lists.
	  ;  IS = index of Jth matching name list.
	  ;-----------------------------------------------------------
	  ;---  Find all lists on previous tab  ---
	  wl = where(s.lst_tab eq s.tab_last,$	; List indices on last tab
	    nl, comp=wr, ncomp=nr)		; and on all the other tabs.
	  ;---  If any other tabs have lists synch them  ---
	  if nr gt 0 then begin			; Any other tabs with lists?
	    ;---  Loop over each list on previous tab  ---
	    for i=0,nl-1 do begin		; Loop over last tab lists.
	      in = wl[i]			; Complete list index.
	      nam = s.lst_nam[in]		; List name.
	      ;---  Find any lists with the same name  ---
	      wm = where(nam eq s.lst_nam,cnt)	; Find all matches.
	      ;---  If any then synch them  ---
	      if cnt gt 1 then begin		; If more than 1 update all.
		;---  Target value and # in list  ---
	        val = s.lst_val[in]		; Value of list in.
	        widget_control,s.lst_wid[in],get_uval=uv ; And uval.
	        il = getwrd(uv,3)+0		; Item index in that list.
		;---  Loop over matching lists  ---
		for j=0,cnt-1 do begin		; Set matching lists to val.
		  is = wm[j]			; Complete list index.
	          ;---  Drop arrow from old list item  ---
		  widget_control, s.lst_wid[is],get_val=old  ; Old list item.
	          old = strmid(old,0,strlen(old)-4)        ; Drop <--.
	          widget_control,s.lst_wid[is],set_val=old ; Replace w/o arrow.
		  ;---  Add arrow to new list item  ---
		  id = getwrd(s.lst_iwd(is),il,del='/')+0L ; New item WID.
	  	  val2 = val + ' <--'			   ; Add <--- to new.
	  	  widget_control,id,set_val=val2	   ; Update new.
		  ;---  Update matching list WID and value  ---
		  s.lst_wid[is] = id		; Update list current item wid.
	          s.lst_val[is] = val		; Update list value.
		endfor ; j = A list that has same name as list i.
	      endif ; cnt: Any matching lists?
	    endfor ; i = A list on last tab.
	  endif ; nr: Any lists on other tabs?
 
	  ;---  Finish up  ---
	  s.tab_last = ev.tab			; Current tab becomes last tab.
	  widget_control, ev.top, set_uval=s	; Save updated values.
	  return
	endif
 
	end
 
;############################################################################
;############################################################################
;=============================================================
;  Internal comment block
;=============================================================
;----------------------------------------------------------------------------
;  XPAR Associated files:
;	xpar.pro = This file, main xpar routine.
;	xpar_parse.pro = Parse xpar input text.
;	xpar_load_help.pro = Load help text into info structure.
;	xpar_example_snap.pro = Example xpar user procedure.
;	xpar_example.txt = Example xpar input text file.
;
;  How the program operates:
;	The text or text file is parsed into a structure which is used to
;	set up the widget interface.  There are several types of items:
;	PARS = Parameters: sliders.
;	       These are for continuous variables but may optionally
;	       be forced to integers.
;	FLGS = Flags: Check boxes.
;	       These are for two state parameters.
;	CLRS = Colors: Color patches.
;	       These are for colors and allow any color to be selected.
;	LSTS = Lists: Drop down menus.
;	       These are for a small number of items, string or numeric.
;	Items may be grouped on TABS, items may appear on more than one tab.
;	Each item is set up and handled independently, even repeated items,
;	with two exceptions.  The first exception is when the code is
;	executed only the unique items are used (to save time).  The second
;	exception is that when a TAB is changed all repeated items are
;	synchronized with the items on the tab that was just active (no
;	need for great speed here).  So the complete list of each type item
;	from the parse structure is used for widget setup.
;
;----------------------------------------------------------------------------
;  Status at end of 2008 Oct 23:
;    New input method now working: INPUT=in_struct
;      {vnam1:val1, vnam2:val2, ...}
;      Was using xpar file xpar_example_alignimgs.txt.
;      xpar2,'xpar_example_alignimgs.txt',input={z:z,z2:z2}
;      where z and z2 are images to align.
;
;  Status at end of 2008 Oct 22:
;    Converted XPAR Help in the menu bar to use add_helpmenu.
;    Cleaned up code.
;    Added /wait to code error xhelp message to avoid stacks of err messages.
;
;  Status at end of 2008 Oct 16:
;    Color patches are working.
;
;  Status at end of 2008 Oct 15:
;    Lists are now working for repeated lists on multiple tabs.
;    The last item to bring up to full working is color patches.
;
;  Status at end of 2007 Jun 11:
;    Working for current xpar_parse2.pro.
;    Needs lots of testing and will probably have problems when
;    multiple banks of flags, colors, and lists are added on a tab.
;    Not using some of the parsed values like ???_frm_num,
;    ??? = par, flg, clr, lst.  Maybe they are not needed, if
;    not then drop from the parsing.
;
;    Added circle plot and circle color.
;    Had problems but got working ok so far.
;    Maybe thickness as a list item.  Add a flag for circle on/off.
;
;    Try multiple banks of par buttons, flgs, clrs, lsts.
;
;  FIX:
;
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;  NEXT STEPS: See xpar_notes.txt in
;	  /homes/sterner/idl/libs/idlusr.
;
;	[X] Try new input method.  New keyword: INPUT=instruct
;	    instruct is a structure; {name1:val1, name2:val2, ...}
;	    Add input:instruct, n_in:n_in to info structure.
;	    n_in = # items in INPUT structure (0 if none).
;	    In execute code define values: execute name1=val1, ...
;	[ ] Add user/application help.
;	[ ] Make xpar help optional.
;	[ ] Rename back to xpar.pro.
;	[ ] Put some of the details found in this header area in built in
;	    help and documentation.
;	[ ] Consider a multiline code area.  Would have to use &$ at each
;           line end.  execute can only do scalar strings so would have to
;           merge to one line, or execute each line (like the init lines).
;	[X] On tab change update color patches.
;	[X] On tab change update lists.
;
;	DONE:
;	Consider adding Tabs to group related items.  These could be
;	used instead of parameter buttons (although still allow parameter
;	buttons).  Set up to use the following tags in the xpar text:
;	tab: tab1_name
;	...
;	tabend
;	tab: tab2_name
;	...
;	tabend
;	where ... is all the same stuff as before except for what is not
;	on a tab.  A tab will then be a group of variables, sliders, flags,
;	color patches, drop-down lists.  It could even have parameter
;	buttons as before, but if none are used then the space where the
;	buttons would have been will be the tabs area.  Then make the
;	parser return the contents of each tab as an array of structures,
;	with the non-tab items (overall title, init code, exit code, idl code)
;	in a separate sub-structure, not in the tab array of structures.
;	Set up tabnum, a numeric array with as many elements as lines in the
;	xpar text.  Start all at -1.  Then locate all the tab:/tabend pairs
;	and use to fill the tabnum array with the correct tab number for
;	each line of text.  Then parse as now but keep track of tab numbers
;	and divide into tab arrays.  Each tab will then be set up as now
;	in xpar.  Everything below the IDL code area will be in a tab
;	(if more than 1).  If no tabs are specified than process as now.
;
;
;	Add color patches to Snapshot file.
;
;	DONE: Fix code area to correct broken lines from Enter keys.
;
;	DONE:
;	Add NOMINMAXDEF option to xpar file.  Drops Min, Max, Def buttons.
;	Add NORANGE option to xpar file.  Drops range entry windows.
;	Allows more compact form.
;
;	DONE: Added list variales.
;
;	DONE. Add second demo, /dem2. So /demo or /dem2
;
;	DONE:
;	Made the function txtmercon.pro to merge continued lines in
;	a given text array.  Now can allow continued lines in an
;	xpar text file.  Also modified arg_parse.pro to deal with
;	repeated keywords, they may now be merged together by concatenating
;	their values (if /keymerge is used).  This now makes it reasonable
;	to have keywords with long values, such as a list of map projections.
;	Just break up the line into continued lines and use repeated keywords
;	to build the list.  Make sure to deal with the delimited for the list.
;	For example:
;	  list: proj=p1/p2/p3/p4, $
;	    proj=/p5/p6/p7, $
;	    pro=/p8/p9/p10
;	arg_parse can deal with pro and proj and force the same.  But these
;	multiple lines must be merged first (by running the xpar file through
;	txtmercon).  Note the list delimiter above is /.  Be careful to use
;	leading and trailing delimiters as needed.  Aslo must use the commas
;	even for repeated keywords, they are just ordinary keywords to
;	arg_parse until merged.
;
;----------------------------------------------------------------------------
;  OTHER IDEAS:
;
;	A routine could be written to use for the executable code
;	that grabs variables from 1 level up instead of having them
;	passed in.  That would make the code very simple at the top
;	level (but it couldn't be edited).  Here is an example:
;--------------------------------------------------------------
;	pro example
;
;	;---  Variable list  ---
;	list = ['x1','y1','z1']
;	n = n_elements(list)
;
;	;---  Grab these variables from 1 level up  ---
;	for i=0,n-1 do begin
;	  cmd = list[i] + ' = scope_varfetch(list[i],level=-1,/enter)'
;	  err = execute(cmd)
;	endfor
;
;	;---  Use these variables in an expression  ---
;	help, x1, y1, z1
;
;	end
;--------------------------------------------------------------
;	LATER:
;	Use /no_copy:
;	widget_control, ev.top, get_uval=s,/no_copy
;	...
;	widget_control, ev.top, set_uval=s,/no_copy
;	MUST SET AFTER EVERY GET or s will be lost.
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;  Notes:
;	On startup the current graphics window is the last slider or
;	last color patch.
;	Must avoid clobbering it.  Do wset,0 to make a new window for example.
;	Could do that in the init code.
;
;	Must define at least frame 0 for each type of item (par, flg, clr, lst)
;	on a tab.  Perhaps at some point make the parser default to frame 0
;	if none defined.  DONE (not well tested yet).
;
;	To pass in values and use in code:
;	  To pass in: In xpar call use INPUT={vnam1:val1, vnam2:val2, ...}
;	  To use in code: Refer to vnam1, vnam2, ... in the code to execute.
;	    In init statements use input.vnam1, input.vnam2, ...
;	    Same for exit statements.  Init and exit statements are executed
;	    directly so variables are not predefined.
;
;	Dislpaying images:
;	  Images dislpayed in the init code seem to be lost or something
;	  by the execute code.  Tried putting one image in chan=1 in init
;	  and another in chan=2 in the code but it didn't work right.
;	  Had to do both in the code.  Not sure why yet.
;
;	May call a routine in the executed code that takes the info
;	structure as an argument and uses it to do something.  Must
;	know the details of the structure.  This might be useful if the
;	sliders control elements of an array, like a convolution kernal
;	for example.  Then pick out the values from the par_cur array in the
;	info structure and use.
;
;	If win_redirect gets out of synch odd things may happen like putting
;	the graphics in a slider bar.  Just do win_redirect,/cleanup
;	to fix.
;----------------------------------------------------------------------------
;############################################################################
;############################################################################
 
	;====================================================================
	;====================================================================
	;  xpar = Main routine
	;
	;  txt0 = File name or input text array.
	;  /debug List values and events.
	;  /WAIT  Do not drop through to command line.
	;  PARVALS=pv  Returned parameter values in a structure.
	;  EXIT_CODE=ex Exit code 1=quite, 0=cancel.
	;  /CHECK_INFO Stop to allow info structure check.
	;  P1=p1, ... Passed in parameters.  Reference as s.p1 in code.
	;====================================================================
	;====================================================================
	pro xpar2, txt0, debug=debug, wait=wait, parvals=parvals, $
	  exit_code=excode, check_info=check_info, $
	  input=input, help=hlp, $
	  top=top, group_leader=grp, xoffset=xoff, yoffset=yoff, $
	  demo=demo, dem2=dem2
 
	if ((n_params(0) lt 1) or keyword_set(hlp)) and $
	  (not keyword_set(demo)) and (not keyword_set(dem2)) then begin
	  print,' Execute IDL code using interactively varied parameters.'
	  print,' xpar, file'
	  print,'   file = xpar file or text array.   in'
	  print,' Keywords:'
	  print,'   INPUT=input  Variables may be passed into xpar in a' 
	  print,'     structure with this keyword.  The tag must match the'
	  print,'     variable name used in the code to execute.  The values'
	  print,'     will be the variable values.  For example, if s1 and s2'
	  print,'     are slider values and the code is tv,s1*a+s2*b, then a'
	  print,'     and b could be passed in by INPUT={a:arr_a, b:arr_b}.'
	  print,'   /WAIT means wait until the routine is exited instead of'
	  print,'      returning right after startup.'
	  print,'   PARVALS=pv Structure with parameter names and values.'
	  print,'      Must be used with /WAIT or pv will be undefined.'
	  print,'   EXITCODE=excd 0=normal, 1=cancel.  Must use with /WAIT.'
	  print,'   /DEMO runs a default demo, an interactive globe.'
	  print,'   /DEM2 runs a non-graphical demo, prime factors.'
	  print,'   TOP=top    Returns widget ID of top level base.'
	  print,'     Use widget_control to retrieve or store info structure.'
;	  print,'   OK=wid  ID of widget to notify when OK button pressed.'
;	  print,'     If not given no OK button is displayed.'
;	  print,'     Useful to allow a higher level widget routine to call'
;	  print,'     EQV3.  The OK button then sends an event to the higher'
;	  print,'     level widget which can then destroy the eqv3 widget.'
;	  print,'   WID_OK=wid  Returned widget ID of the OK button.'
;	  print,'     Can use to set /input_focus.'
	  print,'   GROUP_LEADER=grp  Set group leader.'
	  print,'   XOFFSET=xoff, YOFFSET=yoff Widget position.'
	  print,' '
	  print,' Notes: This routine will not work in an IDL Virtual Machine.'
	  print,' Use the Help button for more details.'
	  print,' Xpar file format: This text file defines the IDL code,'
	  print,' and range of each adjustable parameter.'
	  print,' Null and comment lines (* or ; in first column) are allowed.'
	  print,' The tags are shown by a simple example:'
	  print,'    init: window,/free'
	  print,'    title: Parabola'
	  print,'    code: x=maken(-10,10,100) & plot,x,a + b*x + $'
	  print,'      c*x^2,xr=[-10,10],yr=[-100,100]'
	  print,'    sliders: 3'
	  print,'    par:  a, -50, 50, 0'
	  print,'    par:  b, -50, 50, 0'
	  print,'    par:  c, -10, 10, 1'
	  print,' '
	  print,' The parameter tags are followed by 4 items:'
	  print,'   Parameter name (as in the equation),'
	  print,'   min value, max value, initial value.  Optional items are'
	  print,'   /INT to force an integer value, COLOR=clr for slider'
	  print,'   color, FRAME=fr for button frame.'
	  print,' '
	  print,' Use the Help button menu for more complete details.'
	  return
	endif
 
	;-------------------------------------------------------------
	;  Set up demo text
	;-------------------------------------------------------------
	if keyword_set(demo) then begin
	  txt0 = ['init: print,"Hello"', 'init: window,/free', $
        	'init: erase,128', ' ','title: Interactive Globe',' ', $
        	'win_redirect: 1', 'code_scroll: ', 'code_width: 120', $
        	' ','code: map_set,lat,lon,ang,cont=cont,usa=usa,$', $
        	'  iso=iso,hor=hor, /nobord,  $', $
        	'  ortho=ortho,merc=merc,goode=goode,cyl=cyl &$', $
        	'  rb2ll,lonc,latc,radc,/deg,maken(0,360,100),x,y &$', $
        	'  plots,x,y,col=12582847', $
        	' ','par_frame: 0, /row', 'par_frame: 1, /row',' ', $
        	'par: lat, -90, 90, 0, col=13421823', $
        	'par: lon, 180, -180, 0, col=13421823', $
        	'par: ang, -180, 180, 0, col=13421823',' ', $
        	'par: latc, -90, 90, 0, col=12582847, fr=1', $
        	'par: lonc, -180, 180, 0, col=12582847, fr=1', $
        	'par: radc, 0, 90, 10, col=12582847, fr=1', $
        	' ','sliders: 3', 'slider_len: 300', $
        	'y_scroll: 0', ' ','flag_frame: 0, /row', $
        	'flag_frame: 1, /row, /exclusive', $
        	' ','flags: cont=1, usa=1, iso=1, hor=1', $
        	'flags: ortho=1, merc=0, goode=0, cyl=0, frame=1',' ', $
        	'user: pro=xpar_example_snap, lab=Window snapshot, /info', $
        	'user: pro=list_doy, lab=List day number in year', $
        	' ','exit: wdelete', 'exit: print,"Good-bye"']
	  txtsrc = 'Keyword: /DEMO'
	  print,' '
	  print,' ------ Example XPAR text below this line  ------'
	  more,'   '+txt0,lines=100
	  print,' ------ Example XPAR text above this line  ------'
	  print,' '
	  print,' Blanks lines are ignored.'
	  print,' '
	endif else if keyword_set(dem2) then begin
	  txt0 = ['code: factor, i, p, n, /quiet & print_fact, p, n',$
		  'par: i, 1, 200, 1, /int','title: Demo: Prime Factors']
	  txtsrc = 'Keyword: /DEM2'
	  print,' '
	  print,' ------ Example XPAR text below this line  ------'
	  more,'   '+txt0,lines=100
	  print,' ------ Example XPAR text above this line  ------'
	  print,' '
	  print,' Blanks lines are ignored.'
	  print,' '
	endif
 
	;-------------------------------------------------------------
	;  Parse xpar layout text
	;-------------------------------------------------------------
	if n_elements(txt0) eq 1 then begin		; File name.
	  txt = getfile(txt0,err=err)			; Read text from file.
	  if err ne 0 then begin
	    print,' Error in xpar: Input file not opened: '+txt0
	    return
	  endif
	  txtsrc = 'Input file: '+txt0[0]
	endif else begin				; Text array.
	  txt = txt0
	  if n_elements(txtsrc) eq 0 then txtsrc='Input text array'
	endelse
	txt = txtmercon(txt)				; Merge continued lines.
	
	xpar_parse2,txt,s				; Parse xpar text.
 
	;-------------------------------------------------------------
	;  Get indices of unique items of each type.
	; 
	;  When adding widget UVALS use as the index to the variable
	;  the index from the unique indices array, *_uin.
	;  This way only the unique variables are updated in the full arrays.
	;  When running the execute routine only use the unique variables to
	;  avoid defining variables multiple times.
	;  When TABS are changed, make sure to update values (and range
	;  min, max for sliders) from last TAB to current tab, using the unique
	;  indices.
	;-------------------------------------------------------------
	uniq_tagval,s.par_nam,par_unam,index=par_uin,/first
	uniq_tagval,s.flg_nam,flg_unam,index=flg_uin,/first
	uniq_tagval,s.clr_nam,clr_unam,index=clr_uin,/first
	uniq_tagval,s.lst_nam,lst_unam,index=lst_uin,/first
 
	;-------------------------------------------------------------
	;  Initialize
	;-------------------------------------------------------------
	code = s.txt_cod				; Grab code to execute.
	len = strlen(code)				; Check length.
	xsz = s.code_width				; Set def code area len.
	scroll = s.code_scroll				; From control file.
	if s.code_scroll eq '' then begin		; Set scroll keyword.
	  if len le xsz then scroll=0 else scroll=1	; Only if needed,
	endif						;   unless forced.
	if n_elements(debug) eq 0 then debug=0		; Force defined.
	window,/free,/pix,xs=50,ys=50			; Initialize windows.
	erase
	wdelete
 
	;-------------------------------------------------------------
	;  Main widget layout
	;-------------------------------------------------------------
	top = widget_base(/col,mbar=bar, $		; Top base.
	  title=s.txt_ttl, group_leader=grp, $
	  xoff=xoff,yoff=yoff)
	id_file_menu = widget_button(bar, $		; File menu.
	  value='File',/menu)
	id_optn_menu = widget_button(bar, $		; Options menu.
	  value='Options',/menu)
	id_user_menu = widget_button(bar, $		; User menu.
	  value='User',/menu)
	xpar_load_help, bar, txt_hlp			; Make Help menu.
	b = widget_base(top,/row,ypad=0)		; For code window.
	id_code = widget_text(b,xsize=xsz, $		; Code window.
	  /editable,uval='CODE',scroll=scroll)
 
	;-------------------------------------------------------------
	;  Fill in File menu
	;-------------------------------------------------------------
	id = widget_button(id_file_menu,val='Quit',  uval='FMEN_QUIT')
	id = widget_button(id_file_menu,val='Cancel',uval='FMEN_CANCEL')
	id = widget_button(id_file_menu,val='Snapshot',uval='FMEN_SNAP')
	id = widget_button(id_file_menu,val='Debug', uval='FMEN_DEBUG')
	id = widget_button(id_file_menu,val='List input source',uval='FMEN_SRC')
 
	;-------------------------------------------------------------
	;  Fill in Options menu
	;-------------------------------------------------------------
	win_re = s.win_redirect
	tmp = (win_re eq 0)?'Turn Win_redirect On':'Turn Win_redirect Off'
	id_winr = widget_button(id_optn_menu,val=tmp,uval='OPTN_WINR',/dynamic)
	id = widget_button(id_optn_menu,val='WSHOW', uval='OPTN_WSHOW')
	tmp = (debug eq 0)?'Turn Debug On':'Turn Debug Off'
	id_debug = widget_button(id_optn_menu,val=tmp,uval='OPTN_DBG',/dynamic)
 
	;-------------------------------------------------------------
	;  Fill in User menu
	;    Button event user value is: USER rout flag
	;      where rout is the name of the user routine to call,
	;      flag mean send info struct as INFO=s? 0=no, 1=yes.
	;-------------------------------------------------------------
	for i=0,s.n_usr-1 do begin
	  uv = 'USER '+s.usr_pro[i] + string(s.usr_inf[i],form='(I2)')
	  lab = s.usr_lab[i]
	  id = widget_button(id_user_menu, val=lab, uval=uv)
	endfor
 
	;-------------------------------------------------------------
	;  Display code to execute
	;-------------------------------------------------------------
	widget_control, id_code, set_val=s.txt_cod
 
	;-------------------------------------------------------------
	;  Grab complete arrays
	;  These arrays include all parameters, even ones repeated
	;  on multiple tabs.  Will only update values for current
	;  tab.
	;  TO BE ADDED: Similar values for flags, colors, lists.
	;-------------------------------------------------------------
	;--- par ---
	par_nam0 = s.par_nam		; Complete arrays for all parameters,
	par_frm0 = s.par_frm		; even repeated ones.
	par_min0 = s.par_min		; Keep these in the info structure.
	par_max0 = s.par_max
	par_def0 = s.par_def
	par_int0 = s.par_int
	par_clr0 = s.par_clr
	par_cur0 = s.par_def
	par_usd0 = s.par_usd
	n = s.n_sld			; Max # sliders on one tab.
	;---  Set up slider arrays  ---
	h = histogram(s.par_tab)	; # pars on each tab.
	n_all_sld = fix(total(h<s.n_sld)) ; Total number of all sliders.
	id_sldnam = lonarr(n_all_sld)	; WID arrays for all sliders.
	id_slider = lonarr(n_all_sld)	; Keep these in the info structure.
	id_sldval = lonarr(n_all_sld)
	id_sldmin = lonarr(n_all_sld)
	id_sldmax = lonarr(n_all_sld)
	id_sldstn = lonarr(n_all_sld)
	id_sldstx = lonarr(n_all_sld)
	id_slddef = lonarr(n_all_sld)
	age_sld   = lonarr(n_all_sld)	; Slider age in counts.
	sld_parind= lonarr(n_all_sld)	; Par index of slider.
	;---  Offsets into total slider arrays for each tab  ----
	h = histogram(s.par_tab)<s.n_sld	; Hist limited to max sld/tab.
	off = cumulate(h)			; Cumulative for each tab.
	ntab = max(s.par_tab) + 1		; # tabs.
	sld_off = [0,off]			; Tab 0 has 0 offset.
 
	;--- flg ---
	flg_usd = s.flg_usd			; Indices of flgs actually used.
	n = n_elements(s.flg_nam)		; # flags.
	id_flg = lonarr(n)			; Complete list of all flg WIDs.
 
	;--- clr ---
	n_all_clr = s.n_clr			; Total # colors.
	if n_all_clr gt 0 then begin
	  id_clr_wid = lonarr(n_all_clr)	; Patch wids.
	  clr_win    = lonarr(n_all_clr)	; Color patch window index.
	  clr_vals   = lonarr(n_all_clr)	; All color patch color values.
	endif else begin
	  id_clr_wid = 0
	  clr_win    = 0
	  clr_vals   = 0
	endelse
	clr_usd = s.clr_usd			; Indices of clrs actually used.
 
	;--- lst ---
	n_all_lst = n_elements(s.lst_nam)	; Total # lists.
	lst_val = strarr(n_all_lst>1)		; Current value.
	lst_wid = lonarr(n_all_lst>1)		; WID of current value.
	lst_iwd = strarr(n_all_lst>1)		; WIDs of items on each list.
	lst_usd = s.lst_usd			; Indices of lsts actually used.
 
	;=============================================================
	;  Start TABs loop
	;=============================================================
 
	wtab = widget_tab(top, uval='TAB')
 
	for itab = 0, (s.n_tabs-1)>0 do begin
 
	tab = widget_base(wtab, title=s.tab_nam[itab], /col)
 
	;-------------------------------------------------------------
	;  Lay out parameter button bases
	;
	;  If there are more parameters then allowed sliders
	;  then there will be at least 1 button base.
	;-------------------------------------------------------------
	w = where(s.par_tab eq itab, n_par)		; Pars on this tab.
	if n_par gt 0 then begin
	  par_nam = s.par_nam[w]  ; Pull out only the parameters on this tab.
	  par_frm = s.par_frm[w]
	  par_min = s.par_min[w]
	  par_max = s.par_max[w]
	  par_def = s.par_def[w]
	  par_int = s.par_int[w]
	  par_clr = s.par_clr[w]
	  par_cur = par_def[w]		; ??? Needed ???  Maybe.
	endif
	if n_par gt s.n_sld then begin			; If more pars than sld.
	  id_b_area = widget_base(tab,/frame,/row)	; Buttons area.
	  wt = where(s.par_frm_tab eq itab, n_par_frm)	; Frames on this tab.
	  if n_par_frm gt 0 then begin			; If any grab layout.
	    par_frm_col = s.par_frm_col[wt]
	    par_frm_row = s.par_frm_row[wt]
	  endif
	  if min(s.par_frm_num) gt 0 then begin		; Frame 0 implied.
	    par_frm_col = [0,par_frm_col]
	    par_frm_row = [1,par_frm_row]		; Row base.
	    n_par_frm = n_par_frm + 1			; Count it.
	  endif
	  id_b_b = lonarr(n_par_frm)			; Button base wids.
	  for i=0,n_par_frm-1 do begin			; Loop through bases.
	    nc = par_frm_col[i]				; Get layout.
	    nr = par_frm_row[i]
	    id = widget_base(id_b_area,col=nc, $	; Create base.
	      row=nr,/frame)
	    id_b_b[i] = id				; Save base wid.
	  endfor
	  ;-------------------------------------------------------------
	  ;  Insert parameter buttons
	  ;
	  ;  UVAL = PAR ip
	  ;   where ip = index of button in par frame (0 to npar-1)
	  ;   where npar is the number of parameters on this tab.
	  ;-------------------------------------------------------------
	  for i=0,n_par-1 do begin
	    uv = 'PAR '+strtrim(i,2)
	    id = widget_button(id_b_b[par_frm[i]],val=par_nam[i],uval=uv)
	  endfor
	endif ; n_par
 
	;-------------------------------------------------------------
	;  Sliders
	;
	;  If there are any parameters then there will be at least 1
	;  slider.  But no more sliders than parameters.
	;
	;  UVAL = SLDER ip is iu
	;    where
	;      ip = index of slider in complete list (?),
	;      is = index of slider on tab (0 to #_sliders-1 on tab).
	;      iu = index of unique item (item actually used).
	;  >>>===> is should be index of slider in complete slider list.
	;
	;  In code below, i=slider index on tab, j=complete list index.
	;  itab = is the current tab index.
	;  n_par = # parameters on this tab.
	;-------------------------------------------------------------
	n_sld = s.n_sld < n_par				; # sliders.
	smax = s.sld_len				; Slider length (pix).
	if n_par gt 0 then begin			; If any parameters ...
	  sldbase = widget_base(tab,/col,y_scroll=s.y_scroll) ; Slider base..
	  cnt = 0
	  fmt = '(I3.2)'
	  off = sld_off[itab]				; Offset into sld list.
	  for i=0, n_sld-1 do begin			; Set up sliders.
 
	    ii = i + off				; Complete slider index.
	    j = w[i]					; Index into complete.
	    pval = par_cur0(j)				; Set slider curr VAL.
	    pmin = par_min0(j)				; Set slider PAR MIN.
	    pmax = par_max0(j)				; Set slider PAR MAX.
	    pusd = par_usd0[j]
 
	    ip = string(j,form=fmt)
	    is = string(ii,form=fmt)
	    iu = string(pusd,form=fmt)
	    uv2 = ip + is + iu				; Indices in uval.
	    b = widget_base(sldbase,/row)		; Base for slider top.
	    age_sld(ii) = cnt++				; Slider age.
	    sld_parind(ii) = j				; Which par is slider?
 
	    id = widget_label(b,val=par_nam0(j),/dynam)	; Set slider i to par j.
	    id_sldnam(ii) = id
 
	    id = cw_dslider(b,uval='SLDER'+uv2,$	; Set up slider itself.
	      size=smax+1, max=smax, color=par_clr0(j))
	    id_slider(ii) = id				; Save slider WID.
	    widget_control, id, set_val= $		; Set slider position.
	      xpar_sv2p(pval, smax, pmin, pmax)
 
	    if par_int0(j) eq 1 then pval=fix(pval)	; Make integer if flag.
	    tmp = strtrim(pval,2)			; Want string.
	    uv = 'SLDVAL' + uv2				; UVAL for this area.
	    id = widget_text(b,val=tmp,xsize=10,/edit,uval=uv) ; Text area.
	    id_sldval(ii) = id				; Save WID.
 
	    if s.rng_entry eq 1 then begin		; Range entry area.
	      id = widget_label(b,val='Range:')		; Label.
	      if par_int0(j) eq 1 then pmin=fix(pmin)	; Deal with INT values.
	      tmp = strtrim(pmin,2)			; Range min.
	      uv = 'SLDMIN' + uv2
	      id = widget_text(b,val=tmp,xsize=10,/edit,uval=uv)
	      id_sldmin(ii) = id
	      id = widget_label(b,val='to')		; Label.
	      if par_int0(j) eq 1 then pmax=fix(pmax)	; Deal with INT values.
	      tmp = strtrim(pmax,2)			; Range max.
	      uv = 'SLDMAX' + uv2
	      id = widget_text(b,val=tmp,xsize=10,/edit,uval=uv)
	      id_sldmax(ii) = id
	    endif
 
	    if s.mmd_butt eq 1 then begin		; Min,Max,Def buttons.
	      id = widget_button(b,val='Min',uval='SLDSTN'+uv2)
	      id_sldstn(ii) = id
	      id = widget_button(b,val='Max',uval='SLDSTX'+uv2)
	      id_sldstx(ii) = id
	      id = widget_button(b,val='Def',uval='SLDDEF'+uv2)
	      id_slddef(ii) = id
	    endif
	  endfor
	endif ; n_par
 
	;-------------------------------------------------------------
	;  Lay out the flag button bases
	;
	;  If there are any flags then there will be at least
	;  1 flag button base.
	;
	;  Note: The same parent frame is used for flgs, clrs, lsts:
	;    id_f_area
	;    Must set to 0 (means undefined) each tab loop.
	;    If undefined for an item (flg, clr, or lst) then
	;    define it.  May always define it for flg since that is
	;    the first item needing it.
	;-------------------------------------------------------------
	id_f_area = 0					; Set to undefined.
	w = where(s.flg_tab eq itab, n_flg)		; Flags on this tab.
	if n_flg gt 0 then begin
	  flg_nam = s.flg_nam[w]
	  flg_frm = s.flg_frm[w]
	  flg_val = s.flg_val[w]
	endif
	if n_flg gt 0 then begin
	  id_f_area = widget_base(tab,/row)		; Flag area.
	  wt = where(s.flg_frm_tab eq itab, n_flg_frm)	; Frames on this tab.
	  if n_flg_frm gt 0 then begin			; If any grab layout.
	    flg_frm_col = s.flg_frm_col[wt]
	    flg_frm_row = s.flg_frm_row[wt]
	    flg_frm_exc = s.flg_frm_exc[wt]
	  endif
	  if min(s.flg_frm_num) gt 0 then begin		; Frame 0 implied.
	    flg_frm_col = [0,flg_frm_col]
	    flg_frm_row = [1,flg_frm_row]		; Row base.
	    flg_frm_exc = [0,flg_frm_exc]
	    n_flg_frm = n_flg_frm + 1			; Count it.
	  endif
	  id_f_b = lonarr(n_flg_frm)			; Flag base wids.
	  for i=0,n_flg_frm-1 do begin			; Loop through bases.
	    nc = flg_frm_col[i]
	    nr = flg_frm_row[i]
	    ex = flg_frm_exc[i]
	    id = widget_base(id_f_area,col=nc, $	; Create base.
	      row=nr,exclusive=ex, nonexclusive=1-ex,/frame)
	    id_f_b[i] = id				; Save base wid.
	  endfor
	  ;-------------------------------------------------------------
	  ;  Insert flag buttons
	  ;-------------------------------------------------------------
	  for i=0,n_flg-1 do begin
	    uv = 'FLAG '+strtrim(w[i],2)+' '+strtrim(flg_usd[w[i]],2)
	    id = widget_button(id_f_b[flg_frm[i]],val=flg_nam[i],uval=uv)
	    widget_control,id,set_button=flg_val[i]
	    id_flg[w[i]] = id				; Save flag WID.
	  endfor ; i
	endif ; n_flg
 
	;-------------------------------------------------------------
	;  Lay out the color patch bases
	;
	;  If there are any colors then there will be at least
	;  1 color patch base.
	;-------------------------------------------------------------
	w = where(s.clr_tab eq itab, n_clr)		; Colors on this tab.
	if n_clr gt 0 then begin
	  clr_nam = s.clr_nam[w]			; Color variable names.
	  clr_val = s.clr_val[w]			; 24-bit color values.
	  clr_frm = s.clr_frm[w]			; Patch frame index.
	endif
	if n_clr gt 0 then begin
	  if id_f_area eq 0 then $			; Make sure defined.
	    id_f_area = widget_base(tab,/row)		; Flags and colors area.
	  wt = where(s.clr_frm_tab eq itab, n_clr_frm)	; Frames on this tab.
	  id_c_b = lonarr(n_clr_frm)			; Color base wids.
	  if n_clr_frm gt 0 then begin			; If any grab layout.
	    clr_frm_col = s.clr_frm_col[wt]
	    clr_frm_row = s.clr_frm_row[wt]
	  endif
	  for i=0,n_clr_frm-1 do begin			; Loop through bases.
	    nc = clr_frm_col[i]				; # columns.
	    nr = clr_frm_row[i]				; # rows.
	    id = widget_base(id_f_area,col=nc, $	; Create base.
	      row=nr,/frame)
	    id_c_b[i] = id				; Save base wid.
	  endfor
	  ;-------------------------------------------------------------
	  ;  Insert color patches
	  ;    The uval for each color patch is:
	  ;    uval = COLOR in iu
	  ;      in = index into complete array of color patches.
	  ;      iu = index to element actually used (in execute code).
	  ;-------------------------------------------------------------
	  for i=0,n_clr-1 do begin			; Loop over colors.
	    uv = 'COLOR '+strtrim(w[i],2)+' '+ $	; UVAL=COLOR in iu.
		strtrim(clr_usd[w[i]],2)
	    b0 = id_c_b(clr_frm[i])			; Which color frame.
	    nam = clr_nam[i]				; Color variable name.
	    b1 = widget_base(b0,/row)			; Row = patch, name.
	    id = widget_draw(b1,xsize=10,ysize=10,/button,uval=uv) ; Draw widgt.
	    id_clr_wid[w[i]] = id			; Save draw widget wid.
	    clr_vals[w[i]] = clr_val[i]			; Copy color value.
	    id = widget_label(b1,val=nam)		; Add color name.
	  endfor ; i
	endif ; n_clr
 
	;-------------------------------------------------------------
	;  Lay out the list bases
	;
	;  If there are any lists then there will be at least
	;  1 list base.
	;-------------------------------------------------------------
	w = where(s.lst_tab eq itab, n_lst)		; Lists on this tab.
	if n_lst gt 0 then begin
	  lst_nam = s.lst_nam[w]			; Name of list.
	  lst_pck = s.lst_pck[w]			; Packed list itself.
	  lst_frm = s.lst_frm[w]			; Frame list is in.
	endif
	if n_lst gt 0 then begin
	  if id_f_area eq 0 then $			; Make sure defined:
	    id_f_area = widget_base(tab,/row)		; Flags,clrs,lists area.
	  wt = where(s.lst_frm_tab eq itab, n_lst_frm)	; Frames on this tab.
	  id_f_b = lonarr(n_lst_frm)			; List base wids.
	  if n_lst gt 0 then begin			; If any grab layout.
	    lst_frm_col = s.lst_frm_col[wt]
	    lst_frm_row = s.lst_frm_row[wt]
	  endif
	  for i=0,n_lst_frm-1 do begin			; Loop through bases.
	    nc = lst_frm_col[i]
	    nr = lst_frm_row[i]
	    id = widget_base(id_f_area,col=nc, $	; Create base.
	      row=nr,/frame)
	    id_f_b[i] = id				; Save base wid.
	  endfor
	  ;-------------------------------------------------------------
	  ;  Insert lists
	  ;    The uval for each item in the list is:
	  ;    uval = LIST in iu il val
	  ;      in = index into complete array of lists.
	  ;      iu = index to element actually used (in execute code).
	  ;      il = Index in list (from 0 as first).
	  ;      val = Value of that list item.
	  ;-------------------------------------------------------------
	  for i=0,n_lst-1 do begin			; Loop over all lists.
	    txtwid = ''					; Delimited wid str.
	    wordarray,lst_pck[i],val,del='/'		; Break packed list.
	    il = strtrim(indgen(n_elements(val)),2)	; Index into list item.
	    uv = 'LIST '+strtrim(w[i],2)+' '+ $		; UVAL=List in iu val
		strtrim(lst_usd[w[i]],2)+' '+il+' '+val
	    bid = widget_button(id_f_b(lst_frm[i]), $	; List button.
	      val=lst_nam[i],/menu)
	    for j=0,n_elements(val)-1 do begin		; Loop over values.
	      v = val[j]				; Next list item.
	      if j eq 0 then begin			; First item in list.
	        lst_val[w[i]] = v			; Set as current value.
	        v = v + ' <--'				; 1st is default.
	      endif
	      id = widget_button(bid,val=v, $		; Add item to list.
	        uval=uv[j],/dynamic)
	      txtwid = txtwid+strtrim(id,2)+'/'		; Add item wid to str.
	      if j eq 0 then lst_wid[w[i]]=id		; Save WID for current.
	    endfor ; j List i item j.
	    lst_iwd[w[i]] = txtwid			; Save wids for items.
	  endfor ; i List i.
	endif ; n_lst
 
	endfor ; itab
	;=============================================================
	;  End TABs loop
	;=============================================================
 
	;-------------------------------------------------------------
	;  Activate widget
	;-------------------------------------------------------------
	widget_control, top, /real
	widget_control,wtab,set_tab_curr=0		; Set to first tab.
 
	;-------------------------------------------------------------
	;  Fill any color patches
	;-------------------------------------------------------------
	if n_all_clr gt 0 then begin			; Any colors?
	  for i=0,n_all_clr-1 do begin			; Loop over all colors.
	    widget_control, id_clr_wid[i], get_val=win	; Get the window index.
	    clr_win[i] = win				; Save it.
	    wset, win					; Set to it.
	    erase, clr_vals[i]				; Fill with color.
	  endfor
	endif
 
	;-------------------------------------------------------------
	;  Build info structure and store
	;-------------------------------------------------------------
	res = widget_base()	   ; Return par vals in uval.
	ext = widget_base()        ; Return exit code in uval.
	info = {top:top,         $ ; Top level base (NOT USED FROM HERE?).
 
	  txt_help:txt_hlp,      $ ; Text for XPAR help.
 
	  id_code:id_code,       $ ; WID of code area. Read and execute.
 
	  tab_last:0,            $ ; Last tab number.
	  n_par:s.n_par,         $ ; Number of parameters.
	  par_nam0:s.par_nam,    $ ; Parameter names.
	  par_min0:s.par_min,    $ ; Parameter min value.
	  par_max0:s.par_max,    $ ; Parameter max value.
	  par_def0:s.par_def,    $ ; Parameter default value.
	  par_int0:s.par_int,    $ ; Is parameter an integer? 0=no, 1=yes.
	  par_clr0:s.par_clr,    $ ; Parameter slider bar color.
	  par_cur0:s.par_def,    $ ; Parameter current value, start at default.
	  par_tab0:s.par_tab,    $ ; Parameter tab index.
	  par_uin:par_uin,       $ ; Indices of unique pars.
 
	  n_flag:s.n_flg,        $ ; Number of flags.
	  flag_nam:s.flg_nam,    $ ; Flag names.
	  flag_val:s.flg_val,    $ ; Flag values (0 or 1).
	  flag_tab:s.flg_tab,    $ ; Flag tab index.
	  flag_uin:flg_uin,      $ ; Indices of unique flgs.
 
	  n_color:s.n_clr,       $ ; Number of color patches.
	  color_nam:s.clr_nam,   $ ; Color variable name.
	  color_val:s.clr_val,   $ ; 24-bit color value.
	  color_tab:s.clr_tab,   $ ; Color tab index.
	  color_uin:clr_uin,     $ ; Indices of unique clrs.
	  color_win:clr_win,     $ ; Color patch window index.
 
	  n_lst:s.n_lst,         $ ; Number of lists.
	  lst_nam:s.lst_nam,     $ ; Name of each list.
	  lst_val:lst_val,       $ ; Current value of each list.
	  lst_tab:s.lst_tab,     $ ; List tab index.
	  lst_uin:lst_uin,       $ ; Indices of unique lsts.
	  lst_wid:lst_wid,       $ ; WID of current value in each list.
	  lst_iwd:lst_iwd,       $ ; Item WIDs for each list.
 
	  smax:smax,             $ ; Slider max value (0 to smax).  Also length.
	  age_sld:age_sld,       $ ; Slider age in counts.
	  sld_parind:sld_parind, $ ; Parameter number for each slider.
	  id_slider:id_slider,   $ ; WID of each slider.
	  id_sldnam:id_sldnam,   $ ; WID of parameter name for each slider.
	  id_sldval:id_sldval,   $ ; WID of par current value for each slider.
	  id_sldmin:id_sldmin,   $ ; WID of parameter min value for each slider.
	  id_sldmax:id_sldmax,   $ ; WID of parameter max value for each slider.
	  id_sldstn:id_sldstn,   $ ; WID of slider set new min button.
	  id_sldstx:id_sldstx,   $ ; WID of slider set new max button.
	  id_slddef:id_slddef,   $ ; WID of slider set default button.
 
	  id_flg:id_flg,         $ ; WID of each flag.
 
	  n_ini:s.n_ini,         $ ; Number of init code lines.
	  txt_ini:s.txt_ini,     $ ; Array of init code.
 
	  n_exi:s.n_exi,         $ ; Number of exit code lines.
	  txt_exi:s.txt_exi,     $ ; Array of exit code.
 
	  win_re:win_re,         $ ; Wind-redirect flag (0=off, 1=on).
	  id_winr:id_winr,       $ ; WID of win_redirect button (to update).
	  id_debug:id_debug,     $ ; WID of Debug button (to update).
	  res:res,               $ ; Unused base.  Parvals returned in uval.
	  ext:ext,               $ ; Unused base.  Exit code returned in uval.
	  debug:debug,           $ ; Debug flag.  If set list some values.
	  txtsrc:txtsrc,         $ ; Input source.
	  dum:0 }
	;---  Deal with passed in variables  ---
	if n_elements(input) eq 0 then begin
	  info=create_struct(info,'n_in',0)
	endif else begin
	  itags = tag_names(input)
	  info=create_struct(info,'n_in',n_tags(input), $
	    'input_name',itags,'input',input)
	endelse
;	;--- Add passed in values where defined  ---
;	if n_elements(p1) gt 0 then info=create_struct(info,'p1',p1)
;	if n_elements(p2) gt 0 then info=create_struct(info,'p2',p2)
;	if n_elements(p3) gt 0 then info=create_struct(info,'p3',p3)
;	if n_elements(p4) gt 0 then info=create_struct(info,'p4',p4)
;;	if n_elements(p5) gt 0 then info=create_struct(info,'p5',p5)
	;-------------------------------------------------------------
	;  Where items in info structure are used:
	;  id_sldnam, id_sldval, id_sldmin, id_sldmax:
	;    used when parameter button clicked to update slider.
	;  age_sld: to connect a parameter to a slider.
	;-------------------------------------------------------------
	widget_control, top, set_uval=info
 
	;-------------------------------------------------------------
	;  Execute INIT code
	;-------------------------------------------------------------
	for i=0,s.n_ini-1 do begin
	  code = s.txt_ini(i)
	  if debug then print,code
	  err=execute(code)
	endfor
 
	;-------------------------------------------------------------
	;  Execute main code
	;-------------------------------------------------------------
	xpar_exe, info
 
	if keyword_set(check_info) then begin
	  print,' '
	  print,' Parse structure = s.'
	  print,' Info structure = info.'
	  stop,' STOP in xpar.  Do .con to continue.'
	endif
 
	;-------------------------------------------------------------
	;  Manage the widget
	;-------------------------------------------------------------
	if keyword_set(wait) then no_block=0 else no_block=1
	xmanager, 'xpar', top, no_block=no_block
 
	;-------------------------------------------------------------
	;  Return parameter values
	;-------------------------------------------------------------
	if keyword_set(wait) then begin
	  widget_control, res, get_uval=parvals,/destroy
	  widget_control, ext, get_uval=excode, /destroy
	endif
 
	end
