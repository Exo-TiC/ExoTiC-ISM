;-------------------------------------------------------------
;+
; NAME:
;       DT_TM_PICK_INT
; PURPOSE:
;       Pick a date and time using a widget.
; CATEGORY:
; CALLING SEQUENCE:
;       dt_tm_pick_int
; INPUTS:
; KEYWORD PARAMETERS:
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
;       Notes: The list of time intervals may be saved in an
;         output file and read into a structure using
;         s = txtdb_rd(filename,/execute)
; MODIFICATION HISTORY:
;       R. Sterner, 2008 Aug 07
;       R. Sterner, 2009 Jul 24 --- Added a bit to the help text.
;
; Copyright (C) 2008, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	function dt_tm_pick_int_tojs, s
	date = ymd2date(s.ynow,s.mnow,s.dnow,form='Y$ n$ 0d$')
	time = ' '+s.hhnow+':'+s.mmnow
	return, dt_tm_tojs(date+time)
	end
 
	;==============================================================
	;  S from JS
	;==============================================================
	pro dt_tm_pick_int_fromjs, js, s
	  t = dt_tm_fromjs(js,form='Y$ 0n$ d$ h$ m$')
	  s.ynow = getwrd(t,0) + 0
	  s.mnow = getwrd('',1) + 0
	  s.dnow = getwrd('',2) + 0
	  s.hhnow = getwrd('',3)
	  s.mmnow = getwrd('',4)
	end
 
	;==============================================================
	;  Date update
	;==============================================================
	pro dt_tm_pick_int_date_update, s
 
	js = dt_tm_pick_int_tojs(s)
	dt_tm = dt_tm_fromjs(js,form='Y$ n$ 0d$ h$:m$ w$')
	widget_control, s.ddid, set_val=dt_tm
	txt = caltxt(s.ynow, s.mnow, wdn1=wdn1,days=ndays)
	s.wdn1 = wdn1
	s.ndays = ndays
	widget_control, s.top, set_uval=s
	widget_control, s.tid, set_val=txt
	day = s.dnow
	n = (day+wdn1-2) mod 7	; Day of week.
	iy = fix(((wdn1-1)+(day-1))/7) + 2
	start = iy*29 + n*4		; Highlight start char.
	widget_control, s.tid, set_text_select=[start,4] ; Highlight.
	
	end
 
	;==============================================================
	;  Event Handler
	;==============================================================
	pro dt_tm_pick_int_event, ev
 
	widget_control, ev.top, get_uval=s
	widget_control, ev.id, get_uval=cmd
 
	if cmd eq 'YR' then begin
	  widget_control, ev.id, get_val=val
	  s.ynow = val+0
	  dt_tm_pick_int_date_update, s
	  return
	endif
 
	if (cmd eq 'Y-') or (cmd eq 'Y+') then begin
	  if cmd eq 'Y-' then s.ynow-=1 else s.ynow+=1
	  dt_tm_pick_int_date_update, s
	endif
 
	if cmd eq 'MN' then begin
	  widget_control, ev.id, get_val=val
	  s.mnow = val+0
	  dt_tm_pick_int_date_update, s
	  return
	endif
 
	if (cmd eq 'M-') or (cmd eq 'M+') then begin
	  m = s.mnow - 1
	  if cmd eq 'M-' then m-=1 else m+=1
	  if m lt 0 then begin
	    m = 11
	    s.ynow -= 1
	  endif
	  if m gt 11 then begin
	    m = 0
	    s.ynow += 1
	  endif
	  s.mnow = m + 1
	  dt_tm_pick_int_date_update, s
	  return
	endif
 
	if cmd eq 'HH' then begin
	  widget_control, ev.id, get_val=val
	  s.hhnow = strtrim(val,2)
	  dt_tm_pick_int_date_update, s
	  return
	endif
 
	if (cmd eq 'HH-') or (cmd eq 'HH+') then begin
	  js = dt_tm_pick_int_tojs(s)
	  if cmd eq 'HH-' then js-=3600 else js+=3600
	  dt_tm_pick_int_fromjs, js, s
	  dt_tm_pick_int_date_update, s
	  return
	endif
 
	if cmd eq 'MM' then begin
	  widget_control, ev.id, get_val=val
	  s.mmnow = strtrim(val,2)
	  dt_tm_pick_int_date_update, s
	  return
	endif
 
	if (cmd eq 'MM-') or (cmd eq 'MM+') then begin
	  js = dt_tm_pick_int_tojs(s)
	  if cmd eq 'MM-' then js-=60 else js+=60
	  dt_tm_pick_int_fromjs, js, s
	  dt_tm_pick_int_date_update, s
	  return
	endif
 
	if cmd eq 'TEXT' then begin
	  wdn1 = s.wdn1
	  ndays = s.ndays
	  off = ev.offset
	  iy = fix(off/29)		; Row.
	  ix = off - 29*iy		; Column.
	  ix4 = fix(((ix>1<28)-1)/4)	; Day of week.
	  day = ((iy-2)*7 + ix4 - wdn1 + 2)>1<ndays  ; Day of month.
	  s.dnow = day
	  dt_tm_pick_int_date_update, s
	  return
	endif
 
	if cmd eq 'DATE' then begin
	  widget_control, s.ddid, get_val=t
	  js = dt_tm_tojs(t)
	  dt_tm_pick_int_fromjs, js, s
	  dt_tm_pick_int_date_update, s
	  return
	endif
 
	;----------------------------------------------------
	;  Set interval Start and End
	;    The variable mode controls which part of the
	;    time interval is set.  When mode eq 0 the time
	;    displayed can be set as the start time.  When
	;    mode eq 1 the time can be set as end time (or
	;    used to replace start time).
	;----------------------------------------------------
	if cmd eq 'START' then begin		; Add a start time.
	  widget_control, s.ddid, get_val=val	; Get current time value.
	  val = strtrim(val[0],2)		; Clean it up.
	  if s.mode eq 0 then begin		; Start time mode.
	    s.nlast = s.nlist			; Save last count.
	    s.nlist += 1			; New interval.
	    s.list1[s.nlist] = val		; Add new start time.
	    s.mode = (s.mode+1) mod 2		; End time mode.
	    widget_control, s.id2, sensitive=1	; Ungray end time button.
	  endif else begin			; Was in end time mode.
	    s.list1[s.nlist] = val		; Replace current start time.
	  endelse
	  widget_control, s.top, set_uval=s	; Save updated time intervals.
	  txt = strarr(s.nlist)			; Make output list.
	  for i=1,s.nlist do begin		; Loop over intervals.
	    txt[i-1] = s.list1[i]+'  '+s.list2[i] ; Add next interval to list.
	  endfor
	  widget_control, s.idlist, set_val=txt	; Display interval list.
	  if s.mode eq 1 then widget_control, s.idrep, sensitive=0
	  return
	endif
 
	if cmd eq 'END' then begin		; Add a new end time.
	  widget_control, s.ddid, get_val=val	; Get current time value.
	  val = strtrim(val[0],2)		; Clean it up.
	  s.list2[s.nlist] = val		; Add new end time.
	  s.mode = (s.mode+1) mod 2		; Back to start time mode.
	  widget_control, s.id2, sensitive=0	; Gray end time button.
	  widget_control, s.top, set_uval=s	; Save updated time intervals.
	  txt = strarr(s.nlist)			; Make output list.
	  for i=1,s.nlist do begin		; Loop over intervals.
	    txt[i-1] = s.list1[i]+'  '+s.list2[i] ; Add next interval to list.
	  endfor
	  widget_control, s.idlist, set_val=txt	; Display interval list.
	  widget_control, s.idrep, sensitive=1
	  return
	endif
 
	if cmd eq 'DROP' then begin
	  if s.nlist gt 0 then begin		; Have one or more intervals.
print,' nlist, nlast: ',s.nlist, s.nlast
;	    s.list2[s.nlist] = ''		; Blank out end time.
;	    s.nlist-= 1				; Back off last interval.
	    n = s.nlist - s.nlast		; # dropped.
	    s.nlist = s.nlast
	    s.nlast = s.nlist-1			; Now delete back 1 at a time.
	    lo = s.nlist+1
	    hi = lo + n - 1
	    s.list2[lo:hi] = strarr(n)		; Blank dropped values.
	  endif
	  if s.nlist gt 0 then begin
	    txt = strarr(s.nlist)		; Make output list.
	    for i=1,s.nlist do begin		; Loop over intervals.
	      txt[i-1] = s.list1[i]+'  '+s.list2[i] ; Add next interval to list.
	    endfor
	    widget_control, s.idlist, set_val=txt   ; Display interval list.
	  endif else begin
	    widget_control, s.idlist, set_val='No time intervals'
	    ;---  No intervals (so no repeated intervals allowed)  ---
	    widget_control, s.idrep, sensitive=0  ; Gray out checkbox.
	    widget_control, s.idrep, set_button=0 ; Unset checkbox.
	    widget_control, s.brep, sensitive=0   ; Gray out entry areas.
	  endelse
	  s.mode = 0
	  widget_control, s.top, set_uval=s	; Save updated time intervals.
	  widget_control, s.id1, sensitive=1	; Make sure "Set Start" active.
	  return
	endif
 
	if cmd eq 'REPFLAG' then begin
	  if ev.select eq 1 then begin		 ; Repeats requested.
	    widget_control, s.id1, sensitive=0
	    widget_control, s.brep, sensitive=1
	  endif else begin			 ; No repeats.
	    widget_control, s.id1, sensitive=1
	    widget_control, s.brep, sensitive=0
	  endelse
	endif
 
	if cmd eq 'ADDREP' then begin
	  ;---  Grab step and number  ---
	  widget_control, s.idistep, get_val=step
	  widget_control, s.idinum, get_val=num & num=num[0]
	  ;---  Try to convert step to seconds  ---
	  sec = secstr(step,err=err)
	  ;---  If not valid give message  ---
	  if err ne 0 then begin
	    xmess,/left,['The step between intervals was not understood.',$
	           'The value given was '+step,$
		   'The expected format is ([ ] means optional):',$
		   '[ddd/]hh:mm[:ss] where ddd is an integer #',$
		   'of days (followed by a slash), hh is hours,',$
		   'mm is minutes, and ss is optional seconds.',$
		   'May also use the format hhmm[ss] (no colons).',$
		   ' ','Correct and try again.']
	    return
	  endif
	  ;---  Check if number valid  ---
	  if isnumber(num) eq 0 then begin
	    xmess,/left,['The number of repeated intervals was not',$
		   'understood.  It should be an integer value.',$
		   ' ','Correct and try again.']
	    return
	  endif
	  ;---  Check if space for request  ---
	  if (num+s.nlist) gt s.nmax-1 then begin
	    xmess,/left,['Not enough space available for that many',$
		   'intervals.  Total intervals allowed is '+ $
	           strtrim(s.nmax,2)+'.',$
		   'This would give '+strtrim(s.nlist+num,2)+ $
	           ' intervals.',$
		   'Reduce the number of intervals or change nmax',$
		   'in the code to allow more.']
	    return
	  endif
	  ;---  Find new intervals  ---
	  js10 = dt_tm_tojs(s.list1[s.nlist])	; Last start time.
	  js20 = dt_tm_tojs(s.list2[s.nlist])	; Last end time.
	  dsec = lindgen(num+1)*sec		; Offsets to new intervals.
	  js1 = js10 + dsec			; New start times.
	  js2 = js20 + dsec			; New end times.
	  lst1 = dt_tm_fromjs(js1,form='Y$ n$ 0d$ h$:m$ w$') ; Convert times
	  lst2 = dt_tm_fromjs(js2,form='Y$ n$ 0d$ h$:m$ w$') ; to text.
	  lo = s.nlist				; Must use a range for
	  hi = lo + num				; arrays in structures.
	  s.list1[lo:hi] = lst1			; Insert new times.
	  s.list2[lo:hi] = lst2
	  s.nlast = s.nlist			; Save last count.
	  s.nlist = s.nlist + num		; Update count.
	  widget_control, s.top, set_uval=s	; Save updated time intervals.
	  txt = strarr(s.nlist)			; Make output list.
	  for i=1,s.nlist do begin		; Loop over intervals.
	    txt[i-1] = s.list1[i]+'  '+s.list2[i] ; Add next interval to list.
	  endfor
	  widget_control, s.idlist, set_val=txt ; Display interval list.
	endif
 
	if cmd eq 'SAVE' then begin
	  n = s.nlist
	  if n eq 0 then begin
	    xmess,'No time intervals to save'
	    return
	  endif
	  list1 = s.list1[1:n]
	  list2 = s.list2[1:n]
	  out = {t_start:list1, t_end:list2}
	  tr = ['execute js1=dt_tm_tojs(s.t_start)',$
	        'execute js2=dt_tm_tojs(s.t_end)']
	  xtxtin,title='Name of output file:',def='time_intervals.txt',nam
	  if nam eq '' then begin
	    print,' No save'
	    return
	  endif
	  txtdb_wr,nam,out,trail=tr
	  print,' Time intervals saved in '+nam+'.'
	  print," To read data do: s=txtdb_rd('"+nam+"',/execute)"
	  print,' Will return a structure with start and end times'
	  print,' in both text arrays and Julian Secods arrays.'
	  return
	endif
 
	if cmd eq 'QUIT' then begin
	  out = {t:'', js:0}
	  widget_control, s.res, set_uval=out
	  widget_control, ev.top, /destroy
	  return
	endif
 
	if cmd eq 'DEBUG' then begin
	  stop
	  return
	endif
 
	if cmd eq 'HELP' then begin
	  text_block, /widget, group=s.top
; A date and time may be entered or updated in the
; date/time display area at the top.  Use the Enter key
; to update the displayed calendar.  The calendar area may
; be used to select a month day.  The Year, Month, Hour,
; and Minute buttons give drop-down menus that allow those
; values to be selected.  The - and + buttons will adjust
; those values by one down or up.
; The "Set Start" button will add the displayed time to
; the list as a new start time or update it if no end time
; yet selected.  The "Set End" button will add the displayed
; time as the end time for the interval and then get ready
; for a new start time.  The end time can only be changed
; by dropping the interval and entering it again.
; 
; The displayed date and time may be used as an interval
; start or end time using the "Set Start" and "Set End"
; buttons. The "Drop last" button drops the last interval
; in the list, or the last group added (it only drops the
; group just added as a group, after that it drops single
; intervals at a time).  A group of time intervals may be
; entered by entering one using the above buttons and then
; selecting "Repeat last interval?".  This allows input of
; a step between intervals and how many to make.  Use the
; "Add repeats" button to add them to the list.
; The expected format is ([ ] means optional):
; [ddd/]hh:mm[:ss] where ddd is an integer #
; of days (followed by a slash), hh is hours,
; mm is minutes, and ss is optional seconds.
; May also use the format hhmm[ss] (no colons).
; 
; The time interval list may be saved in a file with the
; "Save" button.  The intervals may be read from this file
; into a structure: s = txtdb_rd(file,/execute)
; The structure will contain t_start, t_end and the
; corresponding times in JS as js1 and js2.
 
	  return
	endif
 
	end
 
 
	;==============================================================
	;  Main routine
	;==============================================================
	pro dt_tm_pick_int, help=hlp
 
	if keyword_set(hlp) then begin
	  print,' Pick a date and time using a widget.'
	  print,' dt_tm_pick_int'
	  print,'   All args are keywords.'
	  print,' Notes: The list of time intervals may be saved in an'
	  print,'   output file and read into a structure using'
	  print,'   s = txtdb_rd(filename,/execute)'
	  return
	endif
 
	;--------------------------------------------------------------
	;  Initialize
	;  nlist = Current # intervals,
	;  nlast = Previous # intervals (used for DROP).
	;--------------------------------------------------------------
	now = systime()
	jsnow = dt_tm_tojs(now)
	ynow = getwrd(/last,now) + 0
	mnow = monthnum(getwrd(now,1))
	dnow = getwrd(now,2) + 0
	ylist = strtrim(makei(ynow-5,ynow+5,1),2)
	mlist = makes(0,12,1,dig=2)+' '+monthnames()
	txt = caltxt(ynow,mnow,wdn1=wdn1,days=ndays)
	date = dt_tm_fromjs(jsnow,form='Y$ n$ 0d$')
	hhnow = dt_tm_fromjs(jsnow,form='h$')
	mmnow = dt_tm_fromjs(jsnow,form='m$')
	nlist = 0		; Intervals in list.
	nlast = 0		; Previous # intervals in list.
	nmax = 100		; Max list size.
	list1 = strarr(nmax)
	list2 = strarr(nmax)
	mode = 0		; 0: set start, 1: set end.
 
	;--------------------------------------------------------------
	;  Date/time pick Widget setup
	;--------------------------------------------------------------
	top = widget_base(title='Pick Date/Time',/col)
 
	;---  Date display area  ---
	ddid = widget_text(top,val=date, xsize=24,ysize=1,/edit,uval='DATE')
 
	;---  Calendar area  ---
	tid = widget_text(top,value=txt,xsize=29,ysize=8, $
	    /all_events,uval='TEXT')
 
	;----  Year and Month  ---
	b = widget_base(top,/row,/align_center)
	;---  Year  ---
	ba = widget_base(b,/row,frame=1,space=0)
	bid = widget_button(ba,val='Year',/menu)
	  for i=0,n_elements(ylist)-1 do begin
	    id = widget_button(bid,val='  '+ylist[i]+'  ',uval='YR')
	  endfor
	id = widget_button(ba,val='-',uval='Y-')
	id = widget_button(ba,val='+',uval='Y+')
	;---  Month  ---
	bb = widget_base(b,/row,frame=1,space=0)
	bid = widget_button(bb,val='Month',/menu)
	  for i=1,12 do begin
	    id = widget_button(bid,val=mlist[i],uval='MN')
	  endfor
	id = widget_button(bb,val='-',uval='M-')
	id = widget_button(bb,val='+',uval='M+')
 
	;---  Hour and Minute  ---
	b = widget_base(top,/row,/align_center)
	;---  Hour  ---
	ba = widget_base(b,/row,/frame,space=0)
	bid = widget_button(ba,val='Hour',/menu)
	  for i=0,23 do begin
	    id = widget_button(bid,val='  '+ $
	      string(i,form='(i2.2)')+'  ',uval='HH')
	  endfor
	id = widget_button(ba,val='-',uval='HH-')
	id = widget_button(ba,val='+',uval='HH+')
	;---  Minute  ---
	ba = widget_base(b,/row,/frame,space=0)
	bid = widget_button(ba,val='Minute',/menu)
	  b00 = widget_button(bid,val='00',/menu)
	  b10 = widget_button(bid,val='10',/menu)
	  b20 = widget_button(bid,val='20',/menu)
	  b30 = widget_button(bid,val='30',/menu)
	  b40 = widget_button(bid,val='40',/menu)
	  b50 = widget_button(bid,val='50',/menu)
	  for i=0,9 do begin
	    id = widget_button(b00,val='  '+ $
	      string(i,form='(i2.2)')+'  ',uval='MM')
	  endfor
	  for i=10,19 do begin
	    id = widget_button(b10,val='  '+ $
	      string(i,form='(i2.2)')+'  ',uval='MM')
	  endfor
	  for i=20,29 do begin
	    id = widget_button(b20,val='  '+ $
	      string(i,form='(i2.2)')+'  ',uval='MM')
	  endfor
	  for i=30,39 do begin
	    id = widget_button(b30,val='  '+ $
	      string(i,form='(i2.2)')+'  ',uval='MM')
	  endfor
	  for i=40,49 do begin
	    id = widget_button(b40,val='  '+ $
	      string(i,form='(i2.2)')+'  ',uval='MM')
	  endfor
	  for i=50,59 do begin
	    id = widget_button(b50,val='  '+ $
	      string(i,form='(i2.2)')+'  ',uval='MM')
	  endfor
	id = widget_button(ba,val='-',uval='MM-')
	id = widget_button(ba,val='+',uval='MM+')
	
	;---  Interval buttons  ---
	b = widget_base(top,/row)
	id1 = widget_button(b,val='Set Start',uval='START')
	id2 = widget_button(b,val='Set End',uval='END')
	widget_control, id2, sensitive=0
	id = widget_button(b,val='Drop last',uval='DROP')
 
	;---  Interval repeated area  ---
	topr = widget_base(top,/col,frame=1,space=0)
	b = widget_base(topr,/row,/nonexclusive)
	idrep = widget_button(b,val='Repeat last interval?',uval='REPFLAG')
	widget_control, idrep, sensitive=0
	brep = widget_base(topr,/col,ypad=0,space=0)
	b = widget_base(brep,/row)
	id = widget_label(b,val='Step between intervals:')
	idistep = widget_text(b,xsize=10,/edit,uval='')
	b = widget_base(brep,/row)
	id = widget_label(b,val='Number of repeated intervals:')
	idinum = widget_text(b,xsize=5,/edit,uval='')
	b = widget_base(brep,/row)
	id = widget_button(b,val='Add repeats',uval='ADDREP')
	widget_control, brep, sensitive=0
 
	;---  Control buttons  ---
	b = widget_base(top,/row)
	id = widget_button(b,val='SAVE',uval='SAVE')
	id = widget_button(b,val='QUIT',uval='QUIT')
	id = widget_button(b,val='DEBUG',uval='DEBUG')
	id = widget_button(b,val='Help',uval='HELP')
 
	;--------------------------------------------------------------
	;  List widget set up
	;--------------------------------------------------------------
	topl = widget_base(/col, group_leader=top, $
	  title='Time interval list window')
	text_block, txt_init, /quiet
; 
; Enter times with the date/time picker.
; Time intervals will be listed in this window.
; 
; Pick a date and time using the Pick Date/Time
; widget and then set a time interval start or
; end using the "Set Start" or "Set End" buttons.
; May delete intervals from the last backwards
; using the "Drop last" button.
;
; Use the "Help" button for more details.
 
	idlist = widget_text(topl,val=txt_init,xsize=52,ysize=30,/scroll)
 
	widget_control, topl, /real
 
 
	;--------------------------------------------------------------
	;  Activate widget
	;--------------------------------------------------------------
	res = widget_base()
	s = {top:top, res:res, wdn1:wdn1, ndays:ndays, $
	  tid:tid, ddid:ddid, $
	  ynow:ynow, mnow:mnow, dnow:dnow, hhnow:hhnow, mmnow:mmnow, $
	  topl:topl, idlist:idlist, list1:list1, list2:list2, $
	  nmax:nmax, nlist:nlist, nlast:nlast, mode:mode, id1:id1, id2:id2, $
	  idrep:idrep, brep:brep, idistep:idistep, idinum:idinum}
	widget_control, top, /real, set_uval=s
	dt_tm_pick_int_date_update, s
	xmanager, 'dt_tm_pick_int', top
 
	end
