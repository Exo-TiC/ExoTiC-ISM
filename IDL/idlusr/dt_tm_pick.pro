;-------------------------------------------------------------
;+
; NAME:
;       DT_TM_PICK
; PURPOSE:
;       Pick a date and time using a widget.
; CATEGORY:
; CALLING SEQUENCE:
;       dt_tm_pick
; INPUTS:
; KEYWORD PARAMETERS:
;       Keywords:
;         OUT=s  Returned structure with date/time string and
;           same time as Julian Seconds.
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 2008 Aug 07
;
; Copyright (C) 2008, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	function dt_tm_pick_tojs, s
	date = ymd2date(s.ynow,s.mnow,s.dnow,form='Y$ n$ 0d$')
	time = ' '+s.hhnow+':'+s.mmnow
	return, dt_tm_tojs(date+time)
	end
 
	;==============================================================
	;  S from JS
	;==============================================================
	pro dt_tm_pick_fromjs, js, s
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
	pro dt_tm_pick_date_update, s
 
	js = dt_tm_pick_tojs(s)
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
	pro dt_tm_pick_event, ev
 
	widget_control, ev.top, get_uval=s
	widget_control, ev.id, get_uval=cmd
 
	if cmd eq 'YR' then begin
	  widget_control, ev.id, get_val=val
	  s.ynow = val+0
	  dt_tm_pick_date_update, s
	  return
	endif
 
	if (cmd eq 'Y-') or (cmd eq 'Y+') then begin
	  if cmd eq 'Y-' then s.ynow-=1 else s.ynow+=1
	  dt_tm_pick_date_update, s
	endif
 
	if cmd eq 'MN' then begin
	  widget_control, ev.id, get_val=val
	  s.mnow = val+0
	  dt_tm_pick_date_update, s
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
	  dt_tm_pick_date_update, s
	  return
	endif
 
	if cmd eq 'HH' then begin
	  widget_control, ev.id, get_val=val
	  s.hhnow = strtrim(val,2)
	  dt_tm_pick_date_update, s
	  return
	endif
 
	if (cmd eq 'HH-') or (cmd eq 'HH+') then begin
	  js = dt_tm_pick_tojs(s)
	  if cmd eq 'HH-' then js-=3600 else js+=3600
	  dt_tm_pick_fromjs, js, s
	  dt_tm_pick_date_update, s
	  return
	endif
 
	if cmd eq 'MM' then begin
	  widget_control, ev.id, get_val=val
	  s.mmnow = strtrim(val,2)
	  dt_tm_pick_date_update, s
	  return
	endif
 
	if (cmd eq 'MM-') or (cmd eq 'MM+') then begin
	  js = dt_tm_pick_tojs(s)
	  if cmd eq 'MM-' then js-=60 else js+=60
	  dt_tm_pick_fromjs, js, s
	  dt_tm_pick_date_update, s
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
	  dt_tm_pick_date_update, s
	  return
	endif
 
	if cmd eq 'DATE' then begin
	  widget_control, s.ddid, get_val=t
	  js = dt_tm_tojs(t)
	  dt_tm_pick_fromjs, js, s
	  dt_tm_pick_date_update, s
	  return
	endif
 
	if cmd eq 'OK' then begin
	  widget_control, s.ddid, get_val=t
	  t = t[0]
	  js = dt_tm_tojs(t)
	  out = {t:t, js:js}
	  widget_control, s.res, set_uval=out
	  widget_control, ev.top, /destroy
	  return
	endif
 
	if cmd eq 'CAN' then begin
	  out = {t:'', js:0}
	  widget_control, s.res, set_uval=out
	  widget_control, ev.top, /destroy
	  return
	endif
 
	if cmd eq 'HELP' then begin
	  text_block, /widget
; A date and time may be entered or updated in the
; date/time display area.  Use the Enter key to update
; the calendar.  The calendar area may be used to select
; a month day.  The Year, Month, Hour, Minute buttons give
; drop-down menus that allow those values to be selected.
; The - and + buttons will adjust those values by one down
; or up.
 
	  return
	endif
 
	end
 
 
	;==============================================================
	;  Main routine
	;==============================================================
	pro dt_tm_pick, out=dt_tm, help=hlp
 
	if keyword_set(hlp) then begin
	  print,' Pick a date and time using a widget.'
	  print,' dt_tm_pick'
	  print,'   All args are keywords.'
	  print,' Keywords:'
	  print,'   OUT=s  Returned structure with date/time string and'
	  print,'     same time as Julian Seconds.'
	  return
	endif
 
	;--------------------------------------------------------------
	;  Initialize
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
 
	;--------------------------------------------------------------
	;  Widget setup
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
	
	;---  Control buttons  ---
	b = widget_base(top,/row)
	id = widget_button(b,val='OK',uval='OK')
	id = widget_button(b,val='Cancel',uval='CAN')
	id = widget_button(b,val='Help',uval='HELP')
 
 
 
	;--------------------------------------------------------------
	;  Activate widget
	;--------------------------------------------------------------
	res = widget_base()
	s = {top:top, res:res, wdn1:wdn1, ndays:ndays, $
	  tid:tid, ddid:ddid, $
	  ynow:ynow, mnow:mnow, dnow:dnow, hhnow:hhnow, mmnow:mmnow}
	widget_control, top, /real, set_uval=s
	dt_tm_pick_date_update, s
	xmanager, 'dt_tm_pick', top
 
	;--------------------------------------------------------------
	;  Get returned value
	;--------------------------------------------------------------
	widget_control, res, get_uval=out
	dt_tm = out
 
 
	end
