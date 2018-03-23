;-------------------------------------------------------------
;+
; NAME:
;       DT_TM_BRK
; PURPOSE:
;       Break a date and time string into separate date and time.
; CATEGORY:
; CALLING SEQUENCE:
;       dt_tm_brk, txt, date, time
; INPUTS:
;       txt = Input date and time string.               in
;         May be an array.
; KEYWORD PARAMETERS:
;       Keywords:
;         FORMAT=fmt Specify format of input.
;           Use the letters y,n,d to in the same positions as year,
;           month, and day or y and # for year and day number
;           in the input string, and the letters h, m,
;           and s for hour, minute, second.  Any other characters may
;           be used as place holders. Case is ignored. Examples:
;             for txt='gs_06oct09_0208_multi.png' use
;                 fmt='xx_yynnndd_hhmm_xxxxx.xxx'
;             for txt='gs_20101600208_multi.png' use
;                 fmt='xx_yyyy###hhmm_xxxxx.xxx'
;           If s and/or m are not used they default to 0.
;           Trailing placeholders are not really needed.
;           All input strings must have the same format to use this.
;         DATE_FORMAT=d Returned date format. This will be a
;           structure with {yymmmdd:k,ddmmmyy:1-k} where k is  1 for
;           /YYMMMDD date format.  Intended for use with date2ymd:
;           date2ymd,date,y,m,d,yymmmdd=d.yymmmdd, ddmmmyy=d.ddmmmyy
; OUTPUTS:
;       date = returned date string, null if no date.   out
;       time = returned time string, null if no time.   out
; COMMON BLOCKS:
; NOTES:
;       Note: works for systime: dt_tm_brk, systime(), dt, tm
;         The word NOW (case insensitive) is replaced
;         by the current sysem time.
; MODIFICATION HISTORY:
;       R. Sterner. 21 Nov, 1988.
;       RES 18 Sep, 1989 --- converted to SUN.
;       R. Sterner, 26 Feb, 1991 --- renamed from brk_date_time.pro
;       R. Sterner, 26 Feb, 1991 --- renamed from brk_dt_tm.pro
;       R. Sterner, 1994 Mar 29 --- Allowed arrays.
;       R. Sterner, 2006 Nov 09 --- Added FORMAT=fmt, DATE_FORMAT=dfmt.
;       R. Sterner, 2007 Jan 04 --- Made for loop index long.
;       R. Sterner, 2007 Jul 17 --- Now works if format has no time (hh:mm:ss).
;       R. Sterner, 2010 Apr 29 --- Converted arrays from () to [].
;       R. Sterner, 2010 Jun 17 --- Added format character # for day of year.
;       R. Sterner, 2011 Oct 11 --- Cleaned up a few rough edges, more comments.
;
; Copyright (C) 1988, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
	pro dt_tm_brk, txt, dt, tm, help=hlp, format=fmt0, date_format=dfmt
 
	if (n_params(0) lt 3) or keyword_set(hlp) then begin
	  print,' Break a date and time string into separate date and time.'
	  print,' dt_tm_brk, txt, date, time'
	  print,'   txt = Input date and time string.               in'
	  print,'     May be an array.'
	  print,'   date = returned date string, null if no date.   out'
	  print,'   time = returned time string, null if no time.   out'
	  print,' Keywords:'
	  print,'   FORMAT=fmt Specify format of input.'
	  print,'     Use the letters y,n,d to in the same positions as year,'
	  print,'     month, and day or y and # for year and day number'
          print,'     in the input string, and the letters h, m,'
	  print,'     and s for hour, minute, second.  Any other characters may'
	  print,'     be used as place holders. Case is ignored. Examples:'
	  print,"       for txt='gs_06oct09_0208_multi.png' use"
	  print,"           fmt='xx_yynnndd_hhmm_xxxxx.xxx'"
	  print,"       for txt='gs_20101600208_multi.png' use"
	  print,"           fmt='xx_yyyy###hhmm_xxxxx.xxx'"
	  print,'     If s and/or m are not used they default to 0.'
	  print,'     Trailing placeholders are not really needed.'
	  print,'     All input strings must have the same format to use this.'
	  print,'   DATE_FORMAT=d Returned date format. This will be a'
	  print,'     structure with {yymmmdd:k,ddmmmyy:1-k} where k is  1 for'
	  print,'     /YYMMMDD date format.  Intended for use with date2ymd:'
	  print,'     date2ymd,date,y,m,d,yymmmdd=d.yymmmdd, ddmmmyy=d.ddmmmyy'
	  print,' Note: works for systime: dt_tm_brk, systime(), dt, tm'
	  print,'   The word NOW (case insensitive) is replaced'
	  print,'   by the current sysem time.'
	  return
	endif
 
	n = n_elements(txt)
 
        ;-------------------------------------------------
	;  Format case
        ;
        ;  This section deals with a format if given.
        ;  A format is made from the characters Y, N, D,
        ;  and #, any other characters are ignored.  The
        ;  locations of these characters must match the
        ;  corresponding elements in the date/time string
        ;  which are then extracted from those locations.
        ;-------------------------------------------------
	if n_elements(fmt0) gt 0 then begin
	  fmt = strupcase(fmt0)
 
          ;===  DATE  ===
          ;---  Year  --- 
	  ylo = strpos(fmt,'Y')			; Date: Year start.
	  yhi = strpos(fmt,'Y',/reverse_search)	; Year end.
          ;---  Month  ---
	  nlo = strpos(fmt,'N')			; Month start.
	  nhi = strpos(fmt,'N',/reverse_search)	; Month end.
          ;---  Day of year  ---
	  dlo = strpos(fmt,'#')			; Day number start.
	  dhi = strpos(fmt,'#',/reverse_search)	; Day number end.
          if dlo ge 0 then begin
            flag_dn = 1                         ; Set day number flag.
          ;---  Or day of month  ---
          endif else begin
	    dlo = strpos(fmt,'D')		  ; Day start.
	    dhi = strpos(fmt,'D',/reverse_search) ; Day end.
            flag_dn = 0                         ; Clear day number flag.
          endelse
          ;---  Find date start and end  ---
	  dtlo = [ylo,nlo,dlo]			; List of possible date starts.
	  dtlo = min(dtlo[where(dtlo ge 0)])	; Find min where ne -1.
	  dthi = [yhi,nhi,dhi]			; List of possible date ends.
	  dthi = max(dthi[where(dthi ge 0)])	; Find max where ne -1.
	  dtlen = (dtlo ge 0)?dthi-dtlo+1:0
	  dt = strmid(txt,dtlo,dtlen)		; Pick off date.
 
          ;---  Deal with returned keywords  ---
	  if dtlo eq ylo then k1=1 else k1=0
	  if dtlo eq dlo then k2=1 else k2=0
	  dfmt = {yymmmdd:k1, ddmmmyy:k2}	; Format for date2ymd.
 
          ;===  TIME  ===
	  hlo = strpos(fmt,'H')			; Time: Hour start.
	  if hlo lt 0 then begin		; No time in format.
            if n eq 1 then tm='00:00:00' else $ ; Default to 0.
	      tm=strarr(n)+'00:00:00'
	    return
	  endif
	  hhi = strpos(fmt,'H',/reverse_search)
	  mlo = strpos(fmt,'M')
	  mhi = strpos(fmt,'M',/reverse_search)
	  slo = strpos(fmt,'S')
	  shi = strpos(fmt,'S',/reverse_search)
	  tmlo = [hlo,mlo,slo]
	  tmlo = min(tmlo[where(tmlo ge 0)])
	  tmhi = [hhi,mhi,shi]
	  tmhi = max(tmhi[where(tmhi ge 0)])
	  tmlen = (tmlo ge 0)?tmhi-tmlo+1:0
	  tm = strmid(txt,tmlo,tmlen)		; Pick off time.
 
	  if n eq 1 then begin	; Return scalars if given a scalar.
	    tm = tm[0]
	    dt = dt[0]
	  endif
 
	  return
	endif
 
        ;-----------------------------------------------------
	;  No format
        ;
        ;  This sectin handles the case where no format
        ;  was given.  May give a single date/time string
        ;  or an array of such strings.  Process each
        ;  string, look for a time in the string, indicated
        ;  by a colon (:).  If a time is found save it and
        ;  then drop it from the string, what is left is
        ;  assumed to be the date part of the string.
        ;  This breaks the string into date and time.
        ;-----------------------------------------------------
	dt = strarr(n)                          ; Storage for returned values.
	tm = strarr(n)
	dfmt = {yymmmdd:0, ddmmmyy:0}		; Returned format for date2ymd.
 
	for j = 0L, n-1 do begin                ; Loop over input array.
	  tt = strupcase(txt[j])                ; Grab next line.
	  if tt eq 'NOW' then tt = systime()    ; Handle special case 'now'.
	  if tt ne '' then begin                ; If not a null string ...
	    flag = 0		                ; No items found yet.
	    for i = 0, nwrds(tt)-1 do begin     ; Look at each item in string.
	      if flag eq 0 then begin           ; If nothing found yet ...
	        tim = getwrd(tt, i)             ; Grab next item.
	        if strpos(tim,':') gt -1 then begin  ; Look for a time (:).
	          dat = strtrim(stress(tt, 'D', 1, tim),2) ; Drop time from str.
	          tm[j] = tim                   ; Time part of string.
	    	  dt[j] = dat                   ; What's left assumed date.
		  flag = 1	                ; Found date and time.
	        endif
	      endif  ; flag
	    endfor  ; i
	    if flag eq 0 then begin
              dt[j] = tt                ; No time was found, assume just date.
              tm[j] = '00:00:00'        ; Time defaults to 00:00:00.
            endif
	  endif  ; tt ne ''
	endfor  ; j
 
	if n eq 1 then begin	; Return scalars if given a scalar.
	  tm = tm[0]
	  dt = dt[0]
	endif
 
	return
 
	end
