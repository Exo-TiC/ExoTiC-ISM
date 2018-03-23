;----------------------------------------------------------------------------
;  xpar.pro = Parameter exploration tool.  Easy parameter variation.
;  R. Sterner, 2006 Oct 17
;
;  Associated files:
;	xpar.pro = This file, main xpar routine.
;	xpar_parse.pro = Parse xpar input text.
;	xpar_load_help.pro = Load help text into info structure.
;	xpar_example_snap.pro = Example xpar user procedure.
;	xpar_example.txt = Example xpar input text file.
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;  NEXT STEPS:
;
;	Adding help.
;	Add a separate entry for user routines.  Give info structure
;	  in detail.
;
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
;
;
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
;	To pass in values and use in code:
;	  To pass in: In xpar call use p1=var1, p2=var2, ...
;	  To use in code: Refer to _s.p1, _s.p2, ... in the code to execute.
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
	;  Set parameters to their values
	;-------------------------------------------------------------
	if _s.n_par gt 0 then begin			; If any parameters...
	  _txt = ''					; String to build.
	  _fmt = '(G)'					; Format to use.
	  for _i=0, n_elements(_s.par_nam)-1 do begin	; Loop over pars.
	    _nam = _s.par_nam[_i]			; Par name.
	    _val = _s.par_cur[_i]			; Par val.
	    if _s.par_int[_i] eq 1 then begin		; Integer?
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
	  for _i=0, n_elements(_s.flag_nam)-1 do begin	; Loop over flags.
	    _nam = _s.flag_nam[_i]			; Flag name.
	    _val = strtrim(_s.flag_val[_i],2)		; Flag val.
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
	  for _i=0, _s.n_color-1 do begin		; Loop over colors.
	    _nam = _s.color_nam[_i]			; Color name.
	    _val = strtrim(_s.color_val[_i],2)		; Color val.
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
	  for _i=0, n_elements(_s.lst_nam)-1 do begin	; Loop over lists.
	    _nam = _s.lst_nam[_i]			; Flag name.
	    _val = strtrim(_s.lst_val[_i],2)		; Flag val.
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
	    '2. Press the OK button above.']
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
	  uv2 = string(ip,form=fmt)+string(is,form=fmt) ; Par indx, Sld indx.
	  ;---  Update age and par index  ----
	  age(is) = max(age) + 1	; Set age for new slider.
	  s.age_sld = age		; Save update age.
	  s.sld_parind(is) = ip		; Save which par this slider is.
	  ;---  Update slider values  ----
	  widget_control,s.id_slider(is),set_val='color='+string(s.par_clr(ip))
	  widget_control,s.id_slider(is),set_uval='SLDER '+uv2
	  widget_control,s.id_sldnam(is),set_val=s.par_nam(ip)
	  pval = s.par_cur(ip)				; Set val.
	  if s.par_int(ip) eq 1 then pval=fix(pval)	; Make integer if flag.
	  tmp = strtrim(pval,2)
	  uv = 'SLDVAL' + uv2
	  widget_control,s.id_sldval(is),set_val=tmp,set_uval=uv
	  pmin = s.par_min(ip)				; Set min.
	  if s.par_int(ip) eq 1 then pmin=fix(pmin)
	  tmp = strtrim(pmin,2)
	  uv = 'SLDMIN' + uv2
	  widget_control,s.id_sldmin(is),set_val=tmp,set_uval=uv
	  pmax = s.par_max(ip)				; Set max.
	  if s.par_int(ip) eq 1 then pmax=fix(pmax)
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
	;-------------------------------------------------------------
	if strmid(cmd,0,3) eq 'SLD' then begin
	  ip = getwrd(uval,1) + 0		; Parameter index.
	  is = getwrd(uval,2) + 0		; Slider index.
	  smax = s.smax				; Slider value range: 0 to smax.
	  pmin = s.par_min(ip)			; Parameter min.
	  pmax = s.par_max(ip)			; Parameter max.
	  int  = s.par_int(ip)			; Is parmeter an integer?

	  case cmd of
'SLDER':  begin			; SLIDER was moved.
	    p = ev.value			; Event value = slider value.
	    cur = xpar_sp2v(p, smax, pmin, pmax, int=int) ; Sld val to par val.
	    s.par_cur(ip) = cur			; Save current par val.
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
	    s.par_cur(ip) = cur			; Save current par val.
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
	      pmin = s.par_min(ip)		; Old Parameter min.
	      if int eq 1 then v=fix(pmin) else v=pmin	; Update pmin.
	      widget_control, ev.id, set_val=strtrim(v,2)
	      return
	    endif
	    s.par_min(ip) = pmin		; Save it.
	    cur = s.par_cur(ip)			; Get current par val.
	    vmin = pmin<pmax			; Allow for reversed range.
	    vmax = pmin>pmax
	    cur = cur>vmin<vmax			; Keep CUR in range.
	    s.par_cur(ip) = cur			; Save it.
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
	      pmax = s.par_max(ip)		; Old Parameter min.
	      if int eq 1 then v=fix(pmax) else v=pmax	; Update pmax.
	      widget_control, ev.id, set_val=strtrim(v,2)
	      return
	    endif
	    s.par_max(ip) = pmax		; Save it.
	    cur = s.par_cur(ip)			; Get current par val.
	    vmin = pmin<pmax			; Allow for reversed range.
	    vmax = pmin>pmax
	    cur = cur>vmin<vmax			; Keep CUR in range.
	    s.par_cur(ip) = cur			; Save it.
	    widget_control, s.id_slider(is), set_val= $ ; Update slider.
	        xpar_sv2p(cur, smax, pmin, pmax)
	    if int eq 1 then v=fix(pmax) else v=pmax	; Update pmin.
	    widget_control, ev.id, set_val=strtrim(v,2)
	    if int eq 1 then v=fix(cur) else v=cur	; Update cur.
	    widget_control, s.id_sldval(is), set_val=strtrim(v,2)	
	  end
'SLDSTN': begin			; NEW RANGE MIN set.
	    cur = s.par_cur(ip)			; Grab current value.
	    if cur eq pmax then begin		; Don't allow invalid entry.
	      bell				; Warning beep.
	      return
	    endif
	    pmin = cur				; Copy current to pmin.
	    if int eq 1 then pmin=fix(pmin) $   ; Fix pmin.
	      else pmin=pmin
	    s.par_min(ip) = pmin		; Save pmin in s.
	    widget_control, s.id_sldmin(is),$   ; Display new pmin.
	       set_val=strtrim(pmin,2)
	    widget_control, s.id_slider(is),$   ; Set slider position.
	        set_val=xpar_sv2p(cur,smax,pmin,pmax)
	  end
'SLDSTX': begin			; NEW RANGE MAX set.
	    cur = s.par_cur(ip)			; Grab current value.
	    if cur eq pmin then begin		; Don't allow invalid entry.
	      bell				; Warning beep.
	      return
	    endif
	    pmax = cur				; Copy current to pmax.
	    if int eq 1 then pmax=fix(pmax) $   ; Fix pmax.
	      else pmax=pmax
	    s.par_max(ip) = pmax		; Save pmax in s.
	    widget_control, s.id_sldmax(is),$   ; Display new pmax.
	       set_val=strtrim(pmax,2)
	    widget_control, s.id_slider(is),$   ; Set slider position.
	        set_val=xpar_sv2p(cur,smax,pmin,pmax)
	  end
'SLDDEF': begin			; DEFAULT VALUE set.
	    cur = s.par_def(ip)			; Get current par val.
	    vmin = pmin<pmax			; Allow for reversed range.
	    vmax = pmin>pmax
	    cur = cur>vmin<vmax			; Keep CUR in range.
	    s.par_cur(ip) = cur			; Save it.
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
	  in = getwrd(uval,1)
	  s.flag_val(in) = ev.select
	  widget_control, ev.top, set_uval=s
	  xpar_exe, s
	  return
	endif

	;-------------------------------------------------------------
	;  Color patch clicked
	;
	;  When a patch is clicked call color_pick.  Update the
	;  internal copy and execute the code.
	;-------------------------------------------------------------
	if cmd eq 'COLOR' then begin
	  if ev.press eq 1 then return		; Ignore press.
	  in = getwrd(uval,1)			; Array index of color.
	  old = s.color_val[in]			; Grab old value.
	  color_pick, new, old			; Get new with color wheel.
	  if new gt -1 then begin		; If not Canceled:
	    s.color_val[in] = new		;   Save new color.
	    win0 = !d.window			;   Get current window.
	    wset, s.color_win[in]		;   Set to color patch window.
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
	;-------------------------------------------------------------

	if cmd eq 'LIST' then begin
	  in = getwrd(uval,1)			   ; Which list?
	  val = getwrd(uval,2)			   ; Value of selected item.
	  widget_control,s.lst_wid[in],get_val=old ; Grab old value.
	  old = strmid(old,0,strlen(old)-4)	   ; Drop <-- from old.
	  widget_control,s.lst_wid[in],set_val=old ; Update old value.
	  s.lst_val[in] = val			   ; New current value.
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
	  parvals = {pname: s.par_nam,   pval:s.par_cur, $  ; par  and flag
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
	;-------------------------------------------------------------
	if cmd eq 'HLP' then begin
	  sect = getwrd(uval,1)			; Second word is the section.
	  case sect of
'OVER':	  xhelp,s.h_1,save='xpar_help_over.txt'
'WIDG':	  xhelp,s.h_2,save='xpar_help_widg.txt'
'FILE':	  xhelp,s.h_3,save='xpar_help_file.txt'
'EXAMP':  xhelp,s.h_4,save='xpar_help_examp.txt'
'TROUB':  xhelp,s.h_5,save='xpar_help_troub.txt'
	  endcase
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
	  return
	endif

	end


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
	pro xpar, txt0, debug=debug, wait=wait, parvals=parvals, $
	  exit_code=excode, check_info=check_info, $
	  p1=p1, p2=p2, p3=p3, p4=p4, p5=p5, help=hlp, $
	  top=top, group_leader=grp, xoffset=xoff, yoffset=yoff, $
	  demo=demo, dem2=dem2

	if ((n_params(0) lt 1) or keyword_set(hlp)) and $
	  (not keyword_set(demo)) and (not keyword_set(dem2)) then begin
	  print,' Execute IDL code using interactively varied parameters.'
	  print,' xpar, file'
	  print,'   file = xpar file or text array.   in'
	  print,' Keywords:'
	  print,'   P1=var1, P2=var2, ... P5=var5  Up to 5 variables.'
	  print,'     may be passed into the program using these keywords.'
	  print,'     To use in the code reference as _s.p1, _s.p2, ...'
	  print,'   /WAIT means wait until the routine is exited instead'
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
	  print,' '
	  print,' ------ Example XPAR text below this line  ------'
	  more,'   '+txt0,lines=100
	  print,' ------ Example XPAR text above this line  ------'
	  print,' '
	  print,' Blanks lines are ignored.'
	  print,' '
	endif

	;-------------------------------------------------------------
	;  Get help text.  Not all the returned values are defined.
	;-------------------------------------------------------------
	xpar_load_help, h_1, h_2, h_3, h_4, h_5, h_6, h_7, h_8, h_9

	;-------------------------------------------------------------
	;  Parse xpar layout text
	;-------------------------------------------------------------
	if n_elements(txt0) eq 1 then begin		; File name.
	  txt = getfile(txt0,err=err)			; Read text from file.
	  if err ne 0 then begin
	    print,' Error in xpar: Input file not opened: '+txt0
	    return
	  endif
	endif else begin				; Text array.
	  txt = txt0
	endelse
	txt = txtmercon(txt)				; Merge continued lines.
	
	xpar_parse,txt,s				; Parse xpar text.

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
	id_help_menu = widget_button(bar, $		; Help menu.
	  value='Help',/menu)
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
	;  Fill in Help menu
	;-------------------------------------------------------------
	id = widget_button(id_help_menu, $
	  val='XPAR overview',  uval='HLP OVER')
	id = widget_button(id_help_menu, $
	  val='XPAR widget layout',  uval='HLP WIDG')
	id = widget_button(id_help_menu, $
	  val='XPAR file format',  uval='HLP FILE')
	id = widget_button(id_help_menu, $
	  val='XPAR examples',  uval='HLP EXAMP')
	id = widget_button(id_help_menu, $
	  val='XPAR troubleshooting',  uval='HLP TROUB')

	;-------------------------------------------------------------
	;  Display code to execute
	;-------------------------------------------------------------
	widget_control, id_code, set_val=s.txt_cod

	;-------------------------------------------------------------
	;  Lay out parameter button bases
	;
	;  If there are any parameters then there will be at least
	;  1 button base.
	;-------------------------------------------------------------
	n_par_frm = s.n_par_frm				; # frames.
	n_par = s.n_par					; # parameters.
	par_nam = s.par_nam
	par_frm = s.par_frm
	par_min = s.par_min
	par_max = s.par_max
	par_def = s.par_def
	par_int = s.par_int
	par_clr = s.par_clr
	par_cur = par_def				; Current values.
	if n_par gt s.n_sld then begin			; If more pars than sld.
	  id_b_area = widget_base(top,/frame,/row)	; Buttons area.
	  id_b_b = lonarr(n_par_frm)			; Button base wids.
	  for i=0,n_par_frm-1 do begin			; Loop through bases.
	    nc = s.par_frm_col(i)
	    nr = s.par_frm_row(i)
	    id = widget_base(id_b_area,col=nc, $	; Create base.
	      row=nr,/frame)
	    id_b_b(i) = id				; Save base wid.
	  endfor
	  ;-------------------------------------------------------------
	  ;  Insert parameter buttons
	  ;-------------------------------------------------------------
	  for i=0,n_par-1 do begin
	    uv = 'PAR '+strtrim(i,2)
	    id = widget_button(id_b_b(par_frm(i)),val=par_nam(i),uval=uv)
	  endfor
	endif ; n_par

	;-------------------------------------------------------------
	;  Sliders
	;
	;  If there are any parameters then there will be at least 1
	;  slider.  But no more sliders than parameters.
	;
	;  The UVAL for each slider area, button, or slider itself is a
	;  keyword followed by the parameter index and slider index.
	;-------------------------------------------------------------
	n_sld = s.n_sld < n_par				; # sliders.
	smax = s.sld_len				; Slider length (pix).
	if n_par gt 0 then begin			; If any parameters ...
	  sldbase = widget_base(top,/col,y_scroll=s.y_scroll) ; Slider base..
	  id_sldnam = lonarr(n_sld)			; WID arrays.
	  id_sldval = lonarr(n_sld)
	  id_sldmin = lonarr(n_sld)
	  id_sldmax = lonarr(n_sld)
	  id_sldstn = lonarr(n_sld)
	  id_sldstx = lonarr(n_sld)
	  id_slddef = lonarr(n_sld)
	  id_slider = lonarr(n_sld)
	  rng_entry = s.rng_entry			; Show range entry area?
	  mmd_butt = s.mmd_butt				; Show min,max,def butt?
	  age_sld = lonarr(n_sld)			; Slider age in counts.
	  sld_parind = lonarr(n_sld)			; Par index of slider.
	  cnt = 0
	  fmt = '(I3.2)'
	  for i=0, n_sld-1 do begin			; Set up sliders.

	    pval = par_cur(i)				; Set slider curr VAL.
	    pmin = par_min(i)				; Set slider PAR MIN.
	    pmax = par_max(i)				; Set slider PAR MAX.

	    uv2 = string(i,form=fmt)+string(i,form=fmt) ; Par indx, Sld indx.
	    b = widget_base(sldbase,/row)		; Base for slider top.
	    age_sld(i) = cnt++				; Slider age.
	    sld_parind(i) = i				; Which par is slider?

	    id = widget_label(b,val=par_nam(i),/dynam)	; Set slider i to par i.
	    id_sldnam(i) = id

	    id = cw_dslider(b,uval='SLDER'+uv2,$	; Set up slider itself.
	      size=smax+1, max=smax, color=par_clr(i))
	    id_slider(i) = id				; Save slider WID.
	    widget_control, id, set_val= $		; Set slider position.
	      xpar_sv2p(pval, smax, pmin, pmax)

	    if par_int(i) eq 1 then pval=fix(pval)	; Make integer if flag.
	    tmp = strtrim(pval,2)			; Want string.
	    uv = 'SLDVAL' + uv2				; UVAL for this area.
	    id = widget_text(b,val=tmp,xsize=10,/edit,uval=uv) ; Text area.
	    id_sldval(i) = id				; Save WID.

	    if rng_entry eq 1 then begin		; Range entry area.
	      id = widget_label(b,val='Range:')		; Label.
	      if par_int(i) eq 1 then pmin=fix(pmin)	; Deal with INT values.
	      tmp = strtrim(pmin,2)			; Range min.
	      uv = 'SLDMIN' + uv2
	      id = widget_text(b,val=tmp,xsize=10,/edit,uval=uv)
	      id_sldmin(i) = id
	      id = widget_label(b,val='to')		; Label.
	      if par_int(i) eq 1 then pmax=fix(pmax)	; Deal with INT values.
	      tmp = strtrim(pmax,2)			; Range max.
	      uv = 'SLDMAX' + uv2
	      id = widget_text(b,val=tmp,xsize=10,/edit,uval=uv)
	      id_sldmax(i) = id
	    endif

	    if mmd_butt eq 1 then begin			; Min,Max,Def buttons.
	      id = widget_button(b,val='Min',uval='SLDSTN'+uv2)
	      id_sldstn(i) = id
	      id = widget_button(b,val='Max',uval='SLDSTX'+uv2)
	      id_sldstx(i) = id
	      id = widget_button(b,val='Def',uval='SLDDEF'+uv2)
	      id_slddef(i) = id
	    endif
	  endfor
	endif ; n_par

	;-------------------------------------------------------------
	;  Lay out the flag button bases
	;
	;  If there are any flags then there will be at least
	;  1 flag button base.
	;-------------------------------------------------------------
	n_flg_frm = s.n_flg_frm				; # flag_frames.

	n_flg = s.n_flg					; # flags.
	flg_nam = s.flg_nam
	flg_val = s.flg_val
	flg_frm = s.flg_frm

	if n_flg gt 0 then begin
	  id_f_area = widget_base(top,/row)		; Flag area.
	  id_f_b = lonarr(n_flg_frm)			; Flag base wids.
	  for i=0,n_flg_frm-1 do begin			; Loop through bases.
	    nc = s.flg_frm_col(i)
	    nr = s.flg_frm_row(i)
	    ex = s.flg_frm_exc(i)
	    id = widget_base(id_f_area,col=nc, $	; Create base.
	      row=nr,exclusive=ex, nonexclusive=1-ex,/frame)
	    id_f_b(i) = id				; Save base wid.
	  endfor
	  ;-------------------------------------------------------------
	  ;  Insert flag buttons
	  ;-------------------------------------------------------------
	  for i=0,n_flg-1 do begin
	    uv = 'FLAG '+strtrim(i,2)
	    id = widget_button(id_f_b(flg_frm(i)),val=flg_nam(i),uval=uv)
	    widget_control,id,set_button=flg_val(i)
	  endfor ; i
	endif ; n_flg

	;-------------------------------------------------------------
	;  Lay out the color patch bases
	;
	;  If there are any colors then there will be at least
	;  1 color patch base.
	;-------------------------------------------------------------
	n_clr_frm = s.n_clr_frm				; # color_frames.

	n_clr = s.n_clr					; # colors.
	clr_nam = s.clr_nam				; Color variable names.
	clr_val = s.clr_val				; 24-bit color values.
	clr_frm = s.clr_frm				; Patch frame index.
	clr_win = lonarr(n_clr>1)			; For patch windows.

	if n_clr gt 0 then begin
	  if n_elements(id_f_area) eq 0 then $		; Make sure defined.
	    id_f_area = widget_base(top,/row)		; Flags and colors area.
	  id_c_b = lonarr(n_clr_frm)			; Color base wids.
	  id_clr_wid = lonarr(n_clr)			; Patch wids.
	  for i=0,n_clr_frm-1 do begin			; Loop through bases.
	    nc = s.clr_frm_col(i)			; # columns.
	    nr = s.clr_frm_row(i)			; # rows.
	    id = widget_base(id_f_area,col=nc, $	; Create base.
	      row=nr,/frame)
	    id_c_b(i) = id				; Save base wid.
	  endfor
	  ;-------------------------------------------------------------
	  ;  Insert color patches
	  ;-------------------------------------------------------------
	  for i=0,n_clr-1 do begin			; Loop over colors.
	    uv = 'COLOR '+strtrim(i,2)			; User value.
	    b0 = id_c_b(clr_frm(i))			; Which color frame.
	    nam = clr_nam(i)				; Color variable name.
	    b1 = widget_base(b0,/row)			; Row = patch, name.
	    id = widget_draw(b1,xsize=10,ysize=10,/button,uval=uv) ; Draw widgt.
	    id_clr_wid[i] = id				; Save draw widget wid.
	    id = widget_label(b1,val=nam)		; Add color name.
	  endfor ; i
	endif ; n_clr

	;-------------------------------------------------------------
	;  Lay out the list bases
	;
	;  If there are any lists then there will be at least
	;  1 list base.
	;-------------------------------------------------------------
	n_lst_frm = s.n_lst_frm				; # list_frames.

	n_lst = s.n_lst					; # lists.
	lst_nam = s.lst_nam				; Name of list.
	lst_pck = s.lst_pck				; Packed list itself.
	lst_frm = s.lst_frm				; Frame list is in.
	lst_val = strarr(n_lst>1)			; Current value.
	lst_wid = lonarr(n_lst>1)			; WID of current value.

	if n_lst gt 0 then begin
	  if n_elements(id_f_area) eq 0 then $		; Make sure defined:
	    id_f_area = widget_base(top,/row)		; Flags,clrs,lists area.
	  id_f_b = lonarr(n_lst_frm)			; List base wids.
	  for i=0,n_lst_frm-1 do begin			; Loop through bases.
	    nc = s.lst_frm_col(i)
	    nr = s.lst_frm_row(i)
	    id = widget_base(id_f_area,col=nc, $	; Create base.
	      row=nr,/frame)
	    id_f_b(i) = id				; Save base wid.
	  endfor
	  ;-------------------------------------------------------------
	  ;  Insert lists
	  ;-------------------------------------------------------------
	  for i=0,n_lst-1 do begin			; Loop over all lists.
	    wordarray,lst_pck[i],val,del='/'		; Break packed list.
	    uv = 'LIST '+strtrim(i,2)+' '+val		; UVAL=List i val
	    bid = widget_button(id_f_b(lst_frm[i]), $	; List button.
	      val=lst_nam[i],/menu)
	    for j=0,n_elements(val)-1 do begin		; Loop over values.
	      v = val[j]				; Next list item.
	      if j eq 0 then begin			; First item in list.
	        lst_val[i] = v				; Set as current value.
	        v = v + ' <--'				; 1st is default.
	      endif
	      id = widget_button(bid,val=v, $		; Add item to list.
	        uval=uv[j],/dynamic)
	      if j eq 0 then lst_wid[i]=id		; Save WID for current.
	    endfor ; j
	  endfor ; i
	endif ; n_lst

	;-------------------------------------------------------------
	;  Activate widget
	;-------------------------------------------------------------
	widget_control, top, /real

	;-------------------------------------------------------------
	;  Fill any color patches
	;-------------------------------------------------------------
	if n_clr gt 0 then begin			; Any colors?
	  for i=0,n_clr-1 do begin			; Loop over colors.
	    widget_control, id_clr_wid[i], get_val=win	; Get the window index.
	    clr_win[i] = win				; Save it.
	    wset, win					; Set to it.
	    erase, clr_val[i]				; Fill with color.
	  endfor
	endif

	;-------------------------------------------------------------
	;  Build info structure and store
	;-------------------------------------------------------------
	res = widget_base()	   ; Return par vals in uval.
	ext = widget_base()        ; Return exit code in uval.
	info = {top:top,         $ ; Top level base (NOT USED FROM HERE?).

	  id_code:id_code,       $ ; WID of code area. Read and execute.

	  n_par:s.n_par,         $ ; Number of parameters.
	  par_nam:par_nam,       $ ; Parameter names.
	  par_frm:par_frm,       $ ; Frame index (group #) for each parameter.
	  par_min:par_min,       $ ; Parameter min value.
	  par_max:par_max,       $ ; Parameter max value.
	  par_def:par_def,       $ ; Parameter default value.
	  par_int:par_int,       $ ; Is parameter an integer? 0=no, 1=yes.
	  par_clr:par_clr,       $ ; Parameter slider bar color.
	  par_cur:par_cur,       $ ; Parameter current value.

	  n_flag:s.n_flg,        $ ; Number of flags.
	  flag_nam:flg_nam,      $ ; Flag names.
	  flag_val:flg_val,      $ ; Flag values (0 or 1).

	  n_color:n_clr,         $ ; Number of color patches.
	  color_nam:clr_nam,     $ ; Color variable name.
	  color_val:clr_val,     $ ; 24-bit color value.
	  color_win:clr_win,     $ ; Color patch window index.

	  n_lst:n_lst,           $ ; Number of lists.
	  lst_nam:lst_nam,       $ ; Name of each list.
	  lst_val:lst_val,       $ ; Current value of each list.
	  lst_wid:lst_wid,       $ ; WID of current value in each list.

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
	  dum:0 }
	;--- Add help text arrays where defined  ---
	if n_elements(h_1) gt 0 then info=create_struct(info,'h_1',h_1)
	if n_elements(h_2) gt 0 then info=create_struct(info,'h_2',h_2)
	if n_elements(h_3) gt 0 then info=create_struct(info,'h_3',h_3)
	if n_elements(h_4) gt 0 then info=create_struct(info,'h_4',h_4)
	if n_elements(h_5) gt 0 then info=create_struct(info,'h_5',h_5)
	if n_elements(h_6) gt 0 then info=create_struct(info,'h_6',h_6)
	if n_elements(h_7) gt 0 then info=create_struct(info,'h_7',h_7)
	if n_elements(h_8) gt 0 then info=create_struct(info,'h_8',h_8)
	if n_elements(h_9) gt 0 then info=create_struct(info,'h_9',h_9)
	;--- Add passed in values where defined  ---
	if n_elements(p1) gt 0 then info=create_struct(info,'p1',p1)
	if n_elements(p2) gt 0 then info=create_struct(info,'p2',p2)
	if n_elements(p3) gt 0 then info=create_struct(info,'p3',p3)
	if n_elements(p4) gt 0 then info=create_struct(info,'p4',p4)
	if n_elements(p5) gt 0 then info=create_struct(info,'p5',p5)
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
