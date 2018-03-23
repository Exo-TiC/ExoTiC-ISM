	;===========================================================
	;  timer__define.pro = Timer object
	;  Return or list time from start time.
	;  R. Sterner, 2002 Jan 14
	;  R. Sterner, 2008 Oct 29 --- Added OUT=out and /QUIET to .time.
	;  R. Sterner, 2014 Jan 20 --- Added /fraction to .time.
	;
	;  Object quick start:
	;	t = obj_new('timer')
	;	t.help
	;===========================================================
 
	;===========================================================
	;  HELP = List some help for this object.
	;===========================================================
 
	pro timer::help
 
	print,' Timer object.  Multiple timers may be used to time'
	print,'   multiple events.'
	print,' To create a timer object:'
	print,"   t = obj_new('timer')"
	print,'   An optional keyword here is TEXT=txt, txt is used when'
	print,'     elapsed time is listed.'
	print,' To list the elapsed time: t.time'
	print,'   Keywords:'
	print,'      TEXT=txt Give text to list in message.'
	print,'      OUT=out Returned message.'
        print,'      /FRACTION show fraction of second in start and stop times.'
	print,'      /QUIET  Useful with OUT=out to not display message.'
	print,' To get the elapsed time in seconds: t.get, sec'
	print,' To reset the timer: t.reset'
 
	end
 
	;===========================================================
	;  TIME = List elapsed time.
	;===========================================================
 
	pro timer::time, text=txt, out=out, fraction=frac, quiet=quiet
 
	if n_elements(txt) eq 0 then txt=self.text ; Use text given at init.
 
	js_start = self.start + self.offset	; Convert start and end times
	js_now = systime(1) + self.offset	; to Julian Seconds.
	dt = js_now - js_start			; Time difference (seconds).
 
	tprint,/init
	;------  No text given, default is verbose  ----------
	if txt eq '' then begin
	  tprint,' Timer started: '+dt_tm_fromjs(js_start,frac=frac)
	  tprint,' Timer stopped: '+dt_tm_fromjs(js_now,  frac=frac)
	  tprint,' Elapsed time: ',strsec(dt)+' ('+$
	      strtrim(dt,2)+' sec)'
	;------  Use given text  -------------------------------
	endif else begin
	  tprint,' '+txt+' elapsed time: ',strsec(dt)+' ('+$
              strtrim(dt,2)+' sec)'
	endelse
	
	tprint,print=1-keyword_set(quiet),out=out
 
	end
 
	;===========================================================
	;  RESET = Restart timer.
	;===========================================================
 
	pro timer::reset
 
	self.start = systime(1)		; Timer start time.
 
	end
 
 
	;===========================================================
	;  GET = Get time since timer start or reset.
	;===========================================================
 
	pro timer::get, diff
 
	now = systime(1)	; Current time.
	diff = now - self.start	; Return time difference in seconds.
 
	end
 
 
	;===========================================================
	;  INIT = set up initial values and start timer.
	;===========================================================
 
	function timer::init, text=txt
 
	if n_elements(txt) eq 0 then self.text='' else self.text=txt
	js0 = dt_tm_tojs('1970 Jan 1')	; systime(1)=seconds from 1970.
	gmtoff = gmt_offsec()		; Offset in sec to GMT.
	self.offset = js0 - gmtoff	; Offset to local Julian Seconds.
	self.start = systime(1)		; Timer start time.
 
	return, 1
	end
 
 
	;===========================================================
	;  timer object structure
	;===========================================================
 
	pro timer__define
 
	tmp = { timer,	$
		start: 0D0,  $ ; Timer start time (systime(1)). 
		offset:0D0,  $ ; Offset for systime(1) to get Julian Seconds.
		text:'' }      ; Optional text for list.
 
	end
