;----------------------------------------------------------------------------
;  xpar_parse.pro = Parse xpar text.
;  R. Sterner, 2006 Oct 17
;  R. Sterner, 2006 Oct 24 --- Changed from flt to dbl for par values.
;  R. Sterner, 2006 Nov 02 --- Added input parameters and user routines.
;  R. Sterner, 2006 Nov 29 --- Added color patch frames and color patches.
;  R. Sterner, 2006 Dec 06 --- Added list frames and list variables.
;  R. Sterner, 2006 Dec 08 --- Forced par_nams to all same length.
;  R. Sterner, 2009 Jun 24 --- Cleaned up leftover TAB:/ENDTAB pairs.
;  R. Sterner, 2009 Jun 24 --- Commented out the above.
;
;  t = Input xpar text array.
;  s = Returned structure with parsed items.
;----------------------------------------------------------------------------
;  Tested and appears to work.
;  Use to parse code file or array.
;  Note the format is not quite like eqv3, need commas
;  even after par name.
;  Allowed items:
;	INIT: txt_ini is ready to execute.
;	EXIT: txt_exi is ready to return for execution on end.
;	TITLE: Ready to use.
;	USER: User routines.
;	PAR_FRAME: Parsed into parts.
;	PAR: Parsed into parts.
;	SLIDERS: # sliders.
;	SLIDER_LEN: Slider length.
;	FLAG_FRAME: Parsed into parts.
;	FLAGS: Parsed into parts.
;	COLOR_FRAME: Parsed into parts.
;	COLORS: Parsed into parts.
;	LIST_FRAME: Parsed into parts.
;	LISTS: Parsed into parts.
;	CODE: Read to use.
;	CODE_WIDTH: Code area width (char).
;	CODE_SCROLL: Code area scroll control.
;	WIN_REDIRECT: Graphics redirect.
;	Y_SCROLL: Slider bar Y scroll size (pixels).
; 	RANGE_ENTRY: 0 means no range entry areas (fixed range).
; 	MINMAXDEF: 0 means no Min, Max, Def buttons.
;----------------------------------------------------------------------------
;  TO BE ADDED:
;
;  TO BE FIXED:
;----------------------------------------------------------------------------

	pro xpar_parse, t0, s, error=err

	t = strtrim(t0,2)		; Make copy.  Drop any leading spaces.
	t = drop_comments(t)		; Drop comments and null lines.
	err = 0

	;=================================================================
	;  Start of Non-Tabbed items
	;=================================================================

	;----------------------------------------
	;  TITLE line
	;  Single title for the widget.
	;
	;  title: ...
	;----------------------------------------
	txt_ttl = ''					; Default = none.
	strfind,t,'title:',index=ind,count=n_ttl, $     ; Find TITLE line.
	  iindex=w, icount=n, /q			; and all the rest.
	if n_ttl gt 0 then txt_ttl=t(ind)		; Grab them.
	txt_ttl = strmid(txt_ttl,6)			; Drop tag.
	if n eq 0 then begin				; Any lines left?
	  err = 1
	  print,' Error in xpar: Incomplete parameter text.'
	  return
	endif
	if n gt 0 then t=t(w)				; Grab only them.

	;----------------------------------------
	;  INIT lines
	;  Lines of code executed at startup.
	;
	; init: ...
	; init: ...
	; ...
	;----------------------------------------
	txt_ini = ''					; Default = none.
	strfind,t,'init:',index=ind,count=n_ini, $      ; Find INIT lines.
	  iindex=w, icount=n, /q			; and all the rest.
	if n_ini gt 0 then txt_ini=t(ind)		; Grab them.
	txt_ini = strmid(txt_ini,5)			; Drop tag.
	if n eq 0 then begin				; Any lines left?
	  err = 1
	  print,' Error in xpar: Incomplete parameter text.'
	  return
	endif
	if n gt 0 then t=t(w)				; Grab only them.

	;----------------------------------------
	;  EXIT lines
	;  Lines of code executed at termination.
	;
	;  exit: ...
	;  exit: ...
	;  ...
	;----------------------------------------
	txt_exi = ''					; Default = none.
	strfind,t,'exit:',index=ind,count=n_exi, $      ; Find INIT lines.
	  iindex=w, icount=n, /q			; and all the rest.
	if n_exi gt 0 then txt_exi=t(ind)		; Grab them.
	txt_exi = strmid(txt_exi,5)			; Drop tag.
	if n eq 0 then begin				; Any lines left?
	  err = 1
	  print,' Error in xpar: Incomplete parameter text.'
	  return
	endif
	if n gt 0 then t=t(w)				; Grab only them.

	;----------------------------------------
	;  WIN_REDIRECT line
	;  Graphics redirect, only use for graphics applications.
	;
	;  win_redirect: 1
	;  Only need 1, 0 is default.
	;----------------------------------------
	winr = 0					; Default.
	strfind,t,'win_redirect:',index=ind,count=ns, $ ; Find line.
	  iindex=w, icount=n, /q			; and all the rest.
	if ns gt 0 then begin				; Grab them.
	  winr = t(ind)
	  winr = strmid(winr,13)+0			; Drop tag.
	endif
	if n eq 0 then begin				; Any lines left?
	  err = 1
	  print,' Error in xpar: Incomplete parameter text.'
	  return
	endif
	if n gt 0 then t=t(w)				; Grab only them.

	;----------------------------------------
	;  USER lines
	;  Specify user routines for User Menu buttons.
	;	
	;  user: ...
	;  user: ...
	;  ...
	;  user: pro=routine, label=button_text, [/info]
	;    routine = Name of user routine to call.
	;      Could be initialized elsewhere to give things
	;      like image windows.
	;    button_text = Text that appears in the menu.
	;    /INFO  If this flag is set then the info structure
	;      will be passed through the keyword INFO=s
	;      (which the routine must accept in that case).
	;----------------------------------------
	strfind,t,'user:',index=ind,count=n_usr, $     ; Find FRAME lines.
	  iindex=w, icount=n, /q			; and all the rest.
	if n_usr gt 0 then begin			; If frame lines then
	  txt_usr = t(ind)				; Grab them.
	  txt_usr = strmid(txt_usr,5)			; Drop tag.
	  usr_inf = intarr(n_usr)
	  usr_lab = strarr(n_usr)
	  usr_pro = strarr(n_usr)			; Set up arrays.
	  keyabb = ['in','lab','pro']			; Set up parse control.
	  keydef = ['0','','']
	  keyful = ['info','label','pro']
	  for i=0,n_usr-1 do begin			; Parse lines.
	    arg_parse,txt_usr(i),out,keyabb=keyabb,keydef=keydef,keyful=keyful
	    usr_inf(i) = out.keyval(0) + 0
	    usr_lab(i) = out.keyval(1)
	    usr_pro(i) = out.keyval(2)
	  endfor
	endif else begin				; Default is none.
	  n_usr = 0
	  usr_inf = 0
	  usr_lab = ''
	  usr_pro = ''
	endelse
	if n eq 0 then begin				; Any lines left?
	  err = 1
	  print,' Error in xpar: Incomplete parameter text.'
	  return
	endif
	if n gt 0 then t=t(w)				; Grab only them.

	;----------------------------------------
	;  CODE_WIDTH line
	;  Code area width (char).
	;
	;  code_width: 86
	;----------------------------------------
	cwid = 86					; Default.
	strfind,t,'code_width:',index=ind,count=ns, $ ; Find line.
	  iindex=w, icount=n, /q			; and all the rest.
	if ns gt 0 then begin				; Grab them.
	  cwid = t(ind)
	  cwid = strmid(cwid,11)+0			; Drop tag.
	endif
	if n eq 0 then begin				; Any lines left?
	  err = 1
	  print,' Error in xpar: Incomplete parameter text.'
	  return
	endif
	if n gt 0 then t=t(w)				; Grab only them.

	;----------------------------------------
	;  CODE_SCROLL line
	;  Code area scroll control: 0=no scroll,
	;    1=force scroll, Blank means auto (def).
	;
	;  code_scroll: 1
	;----------------------------------------
	cscr = ''					; Default.
	strfind,t,'code_scroll:',index=ind,count=ns, $ ; Find line.
	  iindex=w, icount=n, /q			; and all the rest.
	if ns gt 0 then begin				; Grab them.
	  cscr = (t(ind))(0)
	  cscr = strmid(cscr,12)			; Drop tag.
	endif
	if n eq 0 then begin				; Any lines left?
	  err = 1
	  print,' Error in xpar: Incomplete parameter text.'
	  return
	endif
	if n gt 0 then t=t(w)				; Grab only them.

	;----------------------------------------
	;  Y_SCROLL line
	;  Slider bar Y scroll size (pixels).
	;
	;  y_scroll: 200
	;----------------------------------------
	yscr = 0					; Default (no scr bar).
	strfind,t,'y_scroll:',index=ind,count=ns, $ 	; Find line.
	  iindex=w, icount=n, /q			; and all the rest.
	if ns gt 0 then begin				; Grab them.
	  yscr = (t(ind))(0)
	  yscr = strmid(yscr,9)+0			; Drop tag.
	endif
	if n eq 0 then begin				; Any lines left?
	  err = 1
	  print,' Error in xpar: Incomplete parameter text.'
	  return
	endif
	if n gt 0 then t=t(w)				; Grab only them.

	;----------------------------------------
	;  SLIDERS line
	;  How many sliders to use?
	;
	;  sliders: n
	;----------------------------------------
	strfind,t,'sliders:',index=ind,count=n_sld0, $  ; Find SLIDERS line.
	  iindex=w, icount=n, /q			; and all the rest.
	if n_sld0 gt 0 then begin			; If flag line then
	  tmp = t(ind(0))				; Use 1st found.
	  n_sld = getwrd(tmp,1,del=':') + 0		; # sliders.
	endif else begin
	  n_sld = 1					; Def = 1 slider.
	endelse
;	n_sld = n_sld < n_par				; Limit to n_par sldrs.
	if n eq 0 then begin				; Any lines left?
	  err = 1
	  print,' Error in xpar: Incomplete parameter text.'
	  return
	endif
	if n gt 0 then t=t(w)

	;----------------------------------------
	;  SLIDER_LEN line
	;  Slider length.
	;
	;  slider_len: n_pix
	;----------------------------------------
	strfind,t,'slider_len:',index=ind,count=n_sld0,$ ; Find SLIDER_LEN line.
	  iindex=w, icount=n, /q			; and all the rest.
	if n_sld0 gt 0 then begin			; If flag line then
	  tmp = t(ind(0))				; Use 1st found.
	  sld_len = getwrd(tmp,1,del=':') + 0		; Slider length.
	endif else begin
	  sld_len = 300					; Def = 300 pixels.
	endelse
	if n eq 0 then begin				; Any lines left?
	  err = 1
	  print,' Error in xpar: Incomplete parameter text.'
	  return
	endif
	if n gt 0 then t=t(w)

	;----------------------------------------
	;  RANGE_ENTRY line
	;  Do not display range entry area.
	;  So range is fixed (and not listed).
	;
	;  no_range: 0
	;  Only need 0, 1 is default.
	;----------------------------------------
	rng_entry = 1					; Default.
	strfind,t,'range_entry:',index=ind,count=ns, $ 	; Find line.
	  iindex=w, icount=n, /q			; and all the rest.
	if ns gt 0 then begin				; Grab them.
	  rng_entry = t(ind)
	  rng_entry = strmid(rng_entry[0],12)+0		; Drop tag.
	endif
	if n eq 0 then begin				; Any lines left?
	  err = 1
	  print,' Error in xpar: Incomplete parameter text.'
	  return
	endif
	if n gt 0 then t=t(w)				; Grab only them.

;	;----------------------------------------
;	;  NO_RANGE line
;	;  Do not display range entry area.
;	;  So range is fixed (and not listed).
;	;
;	;  no_range: 0
;	;  Only need 0, 1 is default.
;	;----------------------------------------
;	rng_area = 1					; Default.
;	strfind,t,'no_range:',index=ind,count=ns, $ 	; Find line.
;	  iindex=w, icount=n, /q			; and all the rest.
;	if ns gt 0 then begin				; Grab them.
;	  rng_area = t(ind)
;	  rng_area = strmid(rng_area,9)+0		; Drop tag.
;	endif
;	if n eq 0 then begin				; Any lines left?
;	  err = 1
;	  print,' Error in xpar: Incomplete parameter text.'
;	  return
;	endif
;	if n gt 0 then t=t(w)				; Grab only them.

	;----------------------------------------
	;  MINMAXDEF line
	;  Do not display Min, Max, Def buttons.
	;
	;  mmd_butt: 0
	;  Only need 0, 1 is default.
	;----------------------------------------
	mmd_butt = 1					; Default.
	strfind,t,'minmaxdef:',index=ind,count=ns,$	; Find line.
	  iindex=w, icount=n, /q			; and all the rest.
	if ns gt 0 then begin				; Grab them.
	  mmd_butt = t(ind)
	  mmd_butt = strmid(mmd_butt[0],10)+0		; Drop tag.
	endif
	if n eq 0 then begin				; Any lines left?
	  err = 1
	  print,' Error in xpar: Incomplete parameter text.'
	  return
	endif
	if n gt 0 then t=t(w)				; Grab only them.

	;=================================================================
	;  End of Non-Tabbed items
	;=================================================================

	;=================================================================
	;  Start of Tabbed items
	;=================================================================

	;----------------------------------------
	;  PAR_FRAME lines
	;  Set up frames for parameters to allow grouping.
	;	
	;  par_frame: ...
	;  par_frame: ...
	;  ...
	;  par_frame: Num, [ROW=nr], [COL=nc]
	;  Num = Frame number, ROW is row spec, COL is column
	;  spec.
	;
	;  par_frame: 0, row=2
	;  par_frame: 1, /col
	;  par_frame: 2, col=3
	;  Parsed to n_par_frm, par_frm_num, par_frm_col,
	;  par_frm_row.  All but n_par_frm are arrays.
	;  Sort on par_frm_num, must not have any gaps
	;  in par_frm_num.
	;----------------------------------------
;########
	strfind,t,'par_frame:',index=ind,count=n_par_frm, $ ; Find FRAME lines.
	  iindex=w, icount=n, /q			; and all the rest.
	if n_par_frm gt 0 then begin			; If frame lines then
	  txt_par_frm = t(ind)				; Grab them.
	  txt_par_frm = strmid(txt_par_frm,10)		; Drop tag.
	  par_frm_num = intarr(n_par_frm)			; Set up arrays.
	  par_frm_row = intarr(n_par_frm)
	  par_frm_col = intarr(n_par_frm)
	  keyabb = ['c','r']				; Set up parse control.
	  keydef = ['0','0']
	  keyful = ['col','row']
;help,n_par_frm
	  for i=0,n_par_frm-1 do begin			; Parse lines.
	    arg_parse,txt_par_frm(i),out,keyabb=keyabb, $
	      keydef=keydef,keyful=keyful
;stop
	    par_frm_num(i) = out.pos(0) + 0		; Save all values.
	    par_frm_col(i) = out.keyval(0) + 0
	    par_frm_row(i) = out.keyval(1) + 0
	    if (par_frm_col(i) eq 0) and (par_frm_row(i) eq 0)$ ; Row=def.
	      then par_frm_row(i)=1
	    if (par_frm_col(i) gt 0) and (par_frm_row(i) gt 0)$ ; Not both.
	      then begin
	      print,' Warning in xpar_parse: A frame must be row or column'
	      print,'   but not both.  Row taking precedence.'
	      par_frm_col(i) = 0
	    endif
	  endfor
	  is = sort(par_frm_num)			; Sort on par_frm_num.
	  par_frm_num = par_frm_num(is)
	  par_frm_col = par_frm_col(is)
	  par_frm_row = par_frm_row(is)
	endif else begin				; Default frame.
	  n_par_frm = 1
	  par_frm_num = 0				; Is frame # 0.
	  par_frm_col = 0
	  par_frm_row = 1				; 1 row.
	endelse
	if n eq 0 then begin				; Any lines left?
	  err = 1
	  print,' Error in xpar: Incomplete parameter text.'
	  return
	endif
	if n gt 0 then t=t(w)				; Grab only them.
;########

	;----------------------------------------
	;  PAR lines
	;  Lines defining the parameter.
	;
	;  par: ...
	;  par: ...
	;  ...
	;
	;  par: Name, Min, Max, Def, [/INT], [FRAME=fr], [COLOR=clr]
	;  Name = Parameter name, Min and Max = Range of values,
	;  Def = Default value, /INT values are integers,
	;  FRAME gives frame button is placed in, allows grouping,
	;  COLOR gives slider bar color.  Example:
	;  par: sm,1,11,1,/int,frame=2,col=255
	;  Parsed to n_par, par_min, par_max,
	;  par_def, par_int, par_frm, par_clr.
	;  All but n_par are arrays.
	;----------------------------------------
	txt_par = ''					; Default = none.
	strfind,t,'par:',index=ind,count=n_par, $       ; Find PAR lines.
	  iindex=w, icount=n, /q			; and all the rest.
	n_sld = n_sld < n_par				; # sliders LE # pars.
	if n_par gt 0 then begin			; If par lines then
	  txt_par = t(ind)				; Grab them.
	  txt_par = strmid(txt_par,4)			; Drop tag.
	  par_nam = strarr(n_par)			; Set up arrays.
	  par_min = dblarr(n_par)
	  par_max = dblarr(n_par)
	  par_def = dblarr(n_par)
	  par_clr = lonarr(n_par)
	  par_frm = intarr(n_par)
	  par_int = bytarr(n_par)
	  keyabb = ['in','fr','col']			; Set up parse control.
	  keydef = ['0','0','16777215']
	  keyful = ['int','frame','color']
	  for i=0,n_par-1 do begin			; Parse lines.
	    arg_parse,txt_par(i),out,keyabb=keyabb,keydef=keydef, $
	      keyful=keyful, nparams=4, error=err
	    if err ne 0 then begin
	      print,' The input line with the problem is:'
	      print,txt_par(i)
	      print,' Correct the problem and try again.'
	      stop
	    endif
	    par_nam(i) = out.pos(0)			; Save all values.
	    par_min(i) = out.pos(1) + 0.
	    par_max(i) = out.pos(2) + 0.
	    par_def(i) = out.pos(3) + 0.
	    par_clr(i) = out.keyval(0) + 0L		; Index is known since
	    par_frm(i) = out.keyval(1) + 0		; names are sorted.
	    par_int(i) = out.keyval(2) + 0B
	  endfor
	endif else begin				; No parameters.
	  par_nam='' & par_min=0. & par_max=0. & par_def=0.
	  par_clr=0 & par_frm=0 & par_int=0B
	endelse
	par_nam = string(par_nam,form='(A'+ $		; Force same name len.
	  strtrim(max(strlen(par_nam)),2)+')')
	if n eq 0 then begin				; Any lines left?
	  err = 1
	  print,' Error in xpar: Incomplete parameter text.'
	  return
	endif
	if n gt 0 then t=t(w)				; Grab only them.

	;----------------------------------------
	;  FLAG_FRAME lines
	;  Set up frames for flags to allow grouping.
	;	
	;  flag_frame: ...
	;  flag_frame: ...
	;  ...
	;  flag_frame: Num, [ROW=nr], [COL=nc], [/EXCLUSIVE]
	;  Num = Frame number, ROW is row spec, COL is column
	;  spec, /EXCLUSIVE means exclusive button base.
	;----------------------------------------
	strfind,t,'flag_frame:',index=ind,$		; Find FLAG_FRAME lines.
	  count=n_flg_frm, iindex=w, icount=n, /q	; and all the rest.
	if n_flg_frm gt 0 then begin			; If frame lines then
	  txt_flg_frm = t(ind)				; Grab them.
	  txt_flg_frm = strmid(txt_flg_frm,11)		; Drop tag.
	  flg_frm_num = intarr(n_flg_frm)		; Set up arrays.
	  flg_frm_row = intarr(n_flg_frm)
	  flg_frm_col = intarr(n_flg_frm)
	  flg_frm_exc = intarr(n_flg_frm)
	  keyabb = ['c','r','ex']			; Set up parse control.
	  keydef = ['0','0','0']
	  keyful = ['col','row','exclusive']
	  for i=0,n_flg_frm-1 do begin			; Parse lines.
	    arg_parse,txt_flg_frm(i),out, $
	      keyabb=keyabb,keydef=keydef,keyful=keyful
	    flg_frm_num(i) = out.pos(0) + 0		; Save all values.
	    flg_frm_col(i) = out.keyval(0) + 0		; Flag names were
	    flg_frm_exc(i) = out.keyval(1) + 0		; sorted, so indices
	    flg_frm_row(i) = out.keyval(2) + 0		; are known.
	    if (flg_frm_col(i) eq 0) and $		; Must have something.
	       (flg_frm_row(i) eq 0) then flg_frm_row(i)=1
	    if (flg_frm_col(i) gt 0) and $		; One or the other.
	      (flg_frm_row(i) gt 0) then begin
	      print,' Warning in xpar_parse: A frame must be row or column'
	      print,'   but not both.  Row taking precedence.'
	      flg_frm_col(i) = 0
	    endif
	  endfor
	  is = sort(flg_frm_num)			; Sort on frm_num.
	  flg_frm_num = flg_frm_num(is)
	  flg_frm_col = flg_frm_col(is)
	  flg_frm_row = flg_frm_row(is)
	  flg_frm_exc = flg_frm_exc(is)
	endif else begin				; Default frame.
	  n_flg_frm = 1
	  flg_frm_num = 0				; Is frame # 0.
	  flg_frm_col = 0
	  flg_frm_row = 1				; 1 row.
	  flg_frm_exc = 0				; 1 row.
	endelse
	if n eq 0 then begin				; Any lines left?
	  err = 1
	  print,' Error in xpar: Incomplete parameter text.'
	  return
	endif
	if n gt 0 then t=t(w)		

	;----------------------------------------
	;  FLAGS lines
	;  Flag buttons.
	;
	;  flags: ...
	;  flags: ...
	;  ...
	;  flags: Name1=Val1, Name2=Val2, ..., [FRAME=fr]
	;  Name1 = flag 1 name, Val1 = flag 1 setting (0 or 1),
	;  FRAME gives frame button is placed in, allows grouping.
	;----------------------------------------
	strfind,t,'flags:',index=ind,count=n_flg0, $ ; Find FLAGS line.
	  iindex=w, icount=n, /q		; and all the rest.
	
	if n_flg0 gt 0 then begin		; If flag lines then ...
	  txt_flg = t(ind)			; Extract them.
	  txt_flg = strmid(txt_flg,6)		; Trim off 'flags:'.

	  flg_frm = [0]				; Start flag arrays.
	  flg_nam = ['']
	  flg_val = [0]

	  keyabb = ['fr']			; Force keyword FRAME to be
	  keydef = ['0']			; there and to be the full
	  keyful = ['frame']			; word and default to 0.

	  for i=0, n_flg0-1 do begin		; Loop through flag lines.
	    arg_parse,txt_flg[i],out, $		; Parse the i'th line.
	      keyabb=keyabb,keydef=keydef,keyful=keyful
	    wf = where(out.keytag eq 'FRAME', cnt, comp=wc, ncomp=ncnt)
	    frame_ind = out.keyval[wf[0]]	; Frame # for these flags.
	    flg_nam0 = out.keytag[wc]		; Flag names.
	    flg_val0 = out.keyval[wc]+0		; Flag settings (0 or 1).
	    flg_frm0 = flg_val0*0 + frame_ind	; Frame for each flag on line.
	    flg_frm = [flg_frm,flg_frm0]	; Add to full flag list.
	    flg_nam = [flg_nam,flg_nam0]
	    flg_val = [flg_val,flg_val0]
	  endfor ; i
	  flg_frm = flg_frm[1:*]		; Drop seed value.
	  flg_nam = flg_nam[1:*]
	  flg_val = flg_val[1:*]
	  n_flg = n_elements(flg_nam)		; Total flags.

	endif else begin
	  n_flg = 0				; Force defined
	  flg_frm = 0				; Even though not used.
	  flg_nam = ''
	  flg_val = 0
	endelse

	if n eq 0 then begin				; Any lines left?
	  err = 1
	  print,' Error in xpar: Incomplete parameter text.'
	  return
	endif
	if n gt 0 then t=t(w)				; Grab only them.

	;----------------------------------------
	;  COLOR_FRAME lines
	;  Set up frames for colors to allow grouping.
	;	
	;  color_frame: ...
	;  color_frame: ...
	;  ...
	;  color_frame: Num, [ROW=nr], [COL=nc]
	;  Num = Frame number, ROW is row spec, COL is column spec.
	;----------------------------------------
	strfind,t,'color_frame:',index=ind,$	      ; Find COLOR_FRAME lines.
	  count=n_clr_frm, iindex=w, icount=n, /q	; and all the rest.
	if n_clr_frm gt 0 then begin			; If frame lines then
	  txt_clr_frm = t(ind)				; Grab them.
	  txt_clr_frm = strmid(txt_clr_frm,12)		; Drop tag.
	  clr_frm_num = intarr(n_clr_frm)		; Set up arrays.
	  clr_frm_row = intarr(n_clr_frm)
	  clr_frm_col = intarr(n_clr_frm)
	  keyabb = ['c','r']				; Set up parse control.
;	  keydef = ['16777215','16777215']		; White.
	  keydef = ['0','0']
	  keyful = ['col','row']
	  for i=0,n_clr_frm-1 do begin			; Parse lines.
	    arg_parse,txt_clr_frm(i),out, $
	      keyabb=keyabb,keydef=keydef,keyful=keyful
	    clr_frm_num(i) = out.pos(0) + 0		; Save all values.
	    clr_frm_col(i) = out.keyval(0) + 0		; Color names were
	    clr_frm_row(i) = out.keyval(1) + 0		; sorted.
	    if (clr_frm_col(i) eq 0) and $		; Must have something.
	       (clr_frm_row(i) eq 0) then clr_frm_row(i)=1
	    if (clr_frm_col(i) gt 0) and $		; One or the other.
	      (clr_frm_row(i) gt 0) then begin
	      print,' Warning in xpar_parse: A frame must be row or column'
	      print,'   but not both.  Row taking precedence.'
	      clr_frm_col(i) = 0
	    endif
	  endfor
	  is = sort(clr_frm_num)			; Sort on frm_num.
	  clr_frm_num = clr_frm_num(is)
	  clr_frm_col = clr_frm_col(is)
	  clr_frm_row = clr_frm_row(is)
	endif else begin				; Default frame.
	  n_clr_frm = 1
	  clr_frm_num = 0				; Is frame # 0.
	  clr_frm_col = 0
	  clr_frm_row = 1				; 1 row.
	endelse
	if n eq 0 then begin				; Any lines left?
	  err = 1
	  print,' Error in xpar: Incomplete parameter text.'
	  return
	endif
	if n gt 0 then t=t(w)		

	;----------------------------------------
	;  COLORS lines
	;  Color patches.
	;
	;  colors: ...
	;  colors: ...
	;  ...
	;  colors: Name1=Val1, Name2=Val2, ..., [FRAME=fr]
	;  Name1 = color 1 name, Val1 = color 1 setting (24-bit color value),
	;  FRAME gives frame patch is placed in, allows grouping.
	;----------------------------------------
	strfind,t,'colors:',index=ind,count=n_clr0, $ ; Find COLORS line.
	  iindex=w, icount=n, /q		; and all the rest.
	
	if n_clr0 gt 0 then begin		; If color lines then ...
	  txt_clr = t(ind)			; Extract them.
	  txt_clr = strmid(txt_clr,7)		; Trim off 'colors:'.

	  clr_frm = [0]				; Start color arrays.
	  clr_nam = ['']
	  clr_val = [0L]

	  keyabb = ['fr']			; Force keyword FRAME to be
	  keydef = ['0']			; there and to be the full
	  keyful = ['frame']			; word and default to 0.

	  for i=0, n_clr0-1 do begin		; Loop through color lines.
	    arg_parse,txt_clr[i],out, $		; Parse the i'th line.
	      keyabb=keyabb,keydef=keydef,keyful=keyful
	    wf = where(out.keytag eq 'FRAME', cnt, comp=wc, ncomp=ncnt)
	    frame_ind = out.keyval[wf[0]]	; Frame # for these colors.
	    clr_nam0 = out.keytag[wc]		; Color names.
	    clr_val0 = out.keyval[wc]+0L	; 24-bit color values.
	    clr_frm0 = clr_val0*0 + frame_ind	; Frame for each color on line.
	    clr_frm = [clr_frm,clr_frm0]	; Add to full color list.
	    clr_nam = [clr_nam,clr_nam0]
	    clr_val = [clr_val,clr_val0]
	  endfor ; i
	  clr_frm = clr_frm[1:*]		; Drop seed value.
	  clr_nam = clr_nam[1:*]
	  clr_val = clr_val[1:*]
	  n_clr = n_elements(clr_nam)		; Total colors.

	endif else begin
	  n_clr = 0				; Force defined
	  clr_frm = 0				; Even though not used.
	  clr_nam = ''
	  clr_val = 0L
	endelse

	if n eq 0 then begin				; Any lines left?
	  err = 1
	  print,' Error in xpar: Incomplete parameter text.'
	  return
	endif
	if n gt 0 then t=t(w)				; Grab only them.

	;----------------------------------------
	;  LIST_FRAME lines
	;  Set up frames for lists to allow grouping.
	;	
	;  list_frame: ...
	;  list_frame: ...
	;  ...
	;  list_frame: Num, [ROW=nr], [COL=nc]
	;  Num = Frame number, ROW is row spec, COL is column spec.
	;----------------------------------------
	strfind,t,'list_frame:',index=ind,$	      ; Find LIST_FRAME lines.
	  count=n_lst_frm, iindex=w, icount=n, /q	; and all the rest.
	if n_lst_frm gt 0 then begin			; If frame lines then
	  txt_lst_frm = t(ind)				; Grab them.
	  txt_lst_frm = strmid(txt_lst_frm,11)		; Drop tag.
	  lst_frm_num = intarr(n_lst_frm)		; Set up arrays.
	  lst_frm_row = intarr(n_lst_frm)
	  lst_frm_col = intarr(n_lst_frm)
	  keyabb = ['c','r']				; Set up parse control.
	  keydef = ['0','0']
	  keyful = ['col','row']
	  for i=0,n_lst_frm-1 do begin			; Parse lines.
	    arg_parse,txt_lst_frm(i),out, $
	      keyabb=keyabb,keydef=keydef,keyful=keyful
	    lst_frm_num(i) = out.pos(0) + 0		; Save all values.
	    lst_frm_col(i) = out.keyval(0) + 0		; List names were
	    lst_frm_row(i) = out.keyval(1) + 0		; sorted.
	    if (lst_frm_col(i) eq 0) and $		; Must have something.
	       (lst_frm_row(i) eq 0) then lst_frm_row(i)=1
	    if (lst_frm_col(i) gt 0) and $		; One or the other.
	      (lst_frm_row(i) gt 0) then begin
	      print,' Warning in xpar_parse: A frame must be row or column'
	      print,'   but not both.  Row taking precedence.'
	      lst_frm_col(i) = 0
	    endif
	  endfor
	  is = sort(lst_frm_num)			; Sort on frm_num.
	  lst_frm_num = lst_frm_num(is)
	  lst_frm_col = lst_frm_col(is)
	  lst_frm_row = lst_frm_row(is)
	endif else begin				; Default frame
	  n_lst_frm = 1
	  lst_frm_num = 0				;   is frame # 0.
	  lst_frm_col = 0
	  lst_frm_row = 1				; 1 row.
	endelse
	if n eq 0 then begin				; Any lines left?
	  err = 1
	  print,' Error in xpar: Incomplete parameter text.'
	  return
	endif
	if n gt 0 then t=t(w)		

	;----------------------------------------
	;  LISTS lines
	;  List patches.
	;
	;  lists: ...
	;  lists: ...
	;  ...
	;  lists: Name1=Val1, Name2=Val2, ..., [FRAME=fr]
	;  Name1 = list 1 name, Val1 = list 1 (like v1/v2/v3/...),
	;  FRAME gives frame patch is placed in, allows grouping.
	;----------------------------------------
	strfind,t,'lists:',index=ind,count=n_lst0, $ ; Find LISTS line.
	  iindex=w, icount=n, /q		; and all the rest.
	
	if n_lst0 gt 0 then begin		; If list lines then ...
	  txt_lst = t(ind)			; Extract them.
	  txt_lst = strmid(txt_lst,6)		; Trim off 'lists:'.

	  lst_frm = [0]				; Start list arrays.
	  lst_nam = ['']
	  lst_pck = ['']			; Packed values for list.

	  keyabb = ['fr']			; Force keyword FRAME to be
	  keydef = ['0']			; there and to be the full
	  keyful = ['frame']			; word and default to 0.

	  for i=0, n_lst0-1 do begin		; Loop through list lines.
	    arg_parse,txt_lst[i],out, $		; Parse the i'th line.
	      keyabb=keyabb,keydef=keydef,keyful=keyful,/keymerge
	    wf = where(out.keytag eq 'FRAME', cnt, comp=wc, ncomp=ncnt)
	    frame_ind = out.keyval[wf[0]]	; Frame # for these lists.
	    lst_nam0 = out.keytag[wc]		; All list names in line.
	    lst_pck0 = out.keyval[wc]		; All list values (/v1/v2/...).
	    lst_frm0 = intarr(ncnt) + frame_ind	; Frame # for each list in line.
	    lst_frm = [lst_frm,lst_frm0]	; Add to full array of lists.
	    lst_nam = [lst_nam,lst_nam0]	; Names of added lists.
	    lst_pck = [lst_pck,lst_pck0]	; Packed values of added lists.
	  endfor ; i
	  lst_frm = lst_frm[1:*]		; Drop seed value.
	  lst_nam = lst_nam[1:*]
	  lst_pck = lst_pck[1:*]
	  n_lst = n_elements(lst_nam)		; Total lists.

	endif else begin
	  n_lst = 0				; Force defined
	  lst_frm = 0				; Even though not used.
	  lst_nam = ''
	  lst_pck = ''
	endelse

	if n eq 0 then begin				; Any lines left?
	  err = 1
	  print,' Error in xpar: Incomplete parameter text.'
	  return
	endif
	if n gt 0 then t=t(w)				; Grab only them.

	;----------------------------------------
	;  Now have code plus left over
	;  TAB: ... / ENDTAB pairs which must
	;  be cleaned out.
	;----------------------------------------
;	strfind,t,'tab:', $ 			; Find TAB: lines 
;	  iindex=w, icount=n, /q		; and all the rest.
;	if n gt 0 then t=t(w)
;	strfind,t,'endtab', $ 			; Find ENDTAB lines 
;	  iindex=w, icount=n, /q		; and all the rest.
;	if n gt 0 then t=t(w)

	;=================================================================
	;  End of Tabbed items
	;=================================================================

	;=================================================================
	;  Start of IDL code
	;=================================================================

	;----------------------------------------
	;  MUST BE PARSED LAST.
	;  CODE lines
	;  IDL code to be executed.  Multiple lines allowed.
	;
	;  code: ...
	;  code: ...
	;  ...
	;
	;  At this point in parsing there are n
	;  lines left, better all be
	;  code lines.  Trim leading CODE: from
	;  first, and trailing $ from any others
	;  and concatenate into 1 line.
	;  Any spaces on the ends of the lines
	;  are trimmed.
	;----------------------------------------
	strfind,t,'code:',index=ind,/q,count=n_cod	; Find CODE lines.
	if n_cod eq 0 then begin			; Any lines left?
	  err = 1
	  print,' Error in xpar: No code line(s) found.'
	  return
	endif
	if n_cod ne 1 then begin			; Any lines left?
	  err = 1
	  print,' Error in xpar: Must be only one tag CODE:.'
	  print,'   Use &$ to terminate continued lines.'
	  return
	endif
	txt_cod = strmid(t(0),5)			; 1st line, drop code:.
	p = strpos(txt_cod,'$')
	if p gt 1 then txt_cod=strmid(txt_cod,0,p)
	for j=1,n-1 do begin				; Loop over any others.
	  p = strpos(t(j),'$')
	  if p lt 1 then begin
	     txt_cod = txt_cod + strtrim(t(j),2)
	     break
	  endif
	  txt_cod = txt_cod + strtrim(strmid(t(j),0,p),2)
	endfor
	txt_cod = strcompress(txt_cod)		; Squeeze out extra space.
	;=================================================================
	;  End of IDL code
	;=================================================================

	;----------------------------------------
	;  Pack into structure
	;----------------------------------------
	s = {n_ini:n_ini,             $  ; # INIT lines.
	     txt_ini:txt_ini,         $  ; INIT lines.

	     n_exi:n_exi,             $  ; # EXIT lines.
	     txt_exi:txt_exi,         $  ; EXIT lines.

	     txt_ttl:txt_ttl,         $  ; Title.
	     win_redirect:winr,       $  ; Window redirect.
	     n_usr:n_usr,             $  ; # user routines.
	     usr_inf:usr_inf,         $  ; Was /INFO set? 0=no, 1=yes.
	     usr_lab:usr_lab,         $  ; User button labels.
	     usr_pro:usr_pro,         $  ; User procedures names.
	     code_scroll:cscr,        $  ; Code area scroll control.
	     code_width:cwid,         $  ; Code area width (chr).
	     y_scroll:yscr,           $  ; Y_scroll size (pix).
	     n_sld:n_sld,             $  ; # sliders (1 minimum).
	     sld_len:sld_len,         $  ; Slider length.
	     rng_entry:rng_entry,     $  ; Display range entry area?
	     mmd_butt:mmd_butt,       $  ; Display Min, Max, Def buttons?

	     txt_cod:txt_cod,         $  ; Code to execute.

	     n_par_frm:n_par_frm,     $  ; # par_frames (1 minimum).
	     par_frm_num:par_frm_num, $  ; Par_frame indices (0=first).
	     par_frm_col:par_frm_col, $  ; # columns.
	     par_frm_row:par_frm_row, $  ; # rows.

	     n_par:n_par,             $  ; # par lines.
	     par_nam:par_nam,         $  ; Par values.
             par_min:par_min,         $
	     par_max:par_max,         $
	     par_def:par_def,         $
	     par_clr:par_clr,         $
	     par_frm:par_frm,         $
	     par_int:par_int,         $

	     n_flg_frm:n_flg_frm,     $  ; # flag frames (1 minimum).
	     flg_frm_num:flg_frm_num, $  ; Flag_frame indices of flag.
	     flg_frm_col:flg_frm_col, $  ; # columns.
	     flg_frm_row:flg_frm_row, $  ; # rows.
	     flg_frm_exc:flg_frm_exc, $  ; Exclusive base? 0=no, 1=yes.

	     n_flg:n_flg,             $  ; # flags.
	     flg_nam:flg_nam,         $  ; Flag names.
	     flg_val:flg_val,         $  ; Flag initial value (0 or 1).
	     flg_frm:flg_frm,         $  ; Which flag_frame is this flag in?

	     n_clr_frm:n_clr_frm,     $  ; # color frames (1 minimum).
	     clr_frm_num:clr_frm_num, $  ; Color_frame indices of color.
	     clr_frm_col:clr_frm_col, $  ; # columns.
	     clr_frm_row:clr_frm_row, $  ; # rows.

	     n_clr:n_clr,             $  ; # colors.
	     clr_nam:clr_nam,         $  ; Color names.
	     clr_val:clr_val,         $  ; 24-bit color values.
	     clr_frm:clr_frm,         $  ; Which color_frame is this color in?

	     n_lst_frm:n_lst_frm,     $  ; # list frames (1 minimum).
	     lst_frm_num:lst_frm_num, $  ; List frame indices.
	     lst_frm_col:lst_frm_col, $  ; # columns.
	     lst_frm_row:lst_frm_row, $  ; # rows.
	
	     n_lst:n_lst,             $  ; # lists.
	     lst_frm:lst_frm,         $  ; Which list_frame is this list in?
	     lst_nam:lst_nam,         $  ; List names.
	     lst_pck:lst_pck,         $  ; List packed values.

	     dum:0 }

	end
