;-------------------------------------------------------------
;+
; NAME:
;       DATE2YMD
; PURPOSE:
;       Date text string to the numbers year, month, day.
; CATEGORY:
; CALLING SEQUENCE:
;       date2ymd,date,y,m,d
; INPUTS:
;       date = date string.		in
; KEYWORD PARAMETERS:
;       Keywords:
;         /YMD Date is all numeric: Year, Month, Day
;         /YDM Date is all numeric: Year, Day, Year
;         /DMY Date is all numeric: Day, Month, Year
;         /MDY Date is all numeric: Month, Day, Year
;         /YDN Date is all numeric: Year, Day of year
;         /DNY Date is all numeric: Day of year, Year
;         /YYYY Make sure year is 4 digits.
;         /YYMMMDD allows dates like 06jul25.
;         /DDMMMYY allows dates like 25jul06.
;         keywords is given.
;         Dashes, commas, periods, or slashes are allowed.
;         Some examples: 23 sep, 1985     sep 23 1985   1985 Sep 23
;         23/SEP/85   23-SEP-1985   85-SEP-23   23 September, 1985.
;         Doesn't check if month day is valid. Doesn't
;         change year number (like 86 does not change to 1986)
;         unless the /YYYY keyword is given.  Non-numeric
;         dates may have only 2 numeric values, year and day. If
;         both year & day values are < 31 then day is assumed first.
;         systime() can be handled: date2ymd,systime(),y,m,d
;         For invalid dates y, m and d are all set to -1.
;         Some example numeric dates: 051506, 05/15/06
;         (May 15, 2006 with /YYYY), 05152006.  All would use /MDY.
; OUTPUTS:
;       y = year number.		out
;       m = month number.		out
;       d = day number.		out
; COMMON BLOCKS:
; NOTES:
;       Notes: The format of the date is flexible except that the
;         month must be month name unless one of the all numeric
; MODIFICATION HISTORY:
;       Written by R. Sterner, 29 Oct, 1985.
;       Johns Hopkins University Applied Physics Laboratory.
;       25-Nov-1986 --- changed to REPCHR.
;       RES 18 Sep, 1989 --- converted to SUN.
;       R. Sterner, 1994 Mar 29 --- Modified to handle arrays.
;       R. Sterner, 2005 Jan 02 --- Allowed all numeric dates.  Also may
;       convert from 2 to 4 digit year.
;       R. Sterner, 2006 Jun 07 --- Allowed dates like 051506.
;       R. Sterner, 2006 Jul 25 --- Added /YYMMMDD for dates like 06jul25.
;       Added /DDMMMYY for dates like 25jul06.
;       R. Sterner, 2007 Jan 04 --- Made for loop index long.
;       R. Sterner, 2010 Jan 18 --- Allowed 4 digit years with /yymmmdd and /ddmmmyy
;       R. Sterner, 2010 Apr 29 --- Converted arrays from () to [].
;       R. Sterner, 2010 Jun 17 --- Added /YDN and /DNY keywords.
;       R. Sterner, 2011 Apr 07 --- Punctuation removal now gets it all.
;       R. Sterner, 2011 Oct 11 --- Fixed the /DDMMMYY case if not 1 word string.
;       R. Sterner, 2014 Feb 10 --- More error handling. Check monthday.
;
; Copyright (C) 1985, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
	pro date2ymd_1,date,y,m,d, help=hlp, $
	  ymd=ymd, ydm=ydm, dmy=dmy, mdy=mdy, $
          ydn=ydn, dny=dny, $
	  yymmmdd=yymmmdd, ddmmmyy=ddmmmyy
 
        ;-----------------------------------------------------------------
	;  Get just date part of string (ignore any time)
        ;-----------------------------------------------------------------
	dt_tm_brk, date, dt, tmp
 
        ;-----------------------------------------------------------------
	;  Edit out punctuation
        ;
        ;  Find all digits, upper case letters, and lower case letters.
        ;  Set anything else to a space.
        ;-----------------------------------------------------------------
	b = byte(dt)				 ; String to byte.
	flag = 0*b				 ; 1 means keep.
	w = where((b ge 48) and (b le 57), cnt)	 ; Keep 0 to 9.
	if cnt gt 0 then flag[w]=1
	w = where((b ge 65) and (b le 90), cnt)	 ; Keep A to Z.
	if cnt gt 0 then flag[w]=1
	w = where((b ge 97) and (b le 122), cnt) ; Keep a to z.
	if cnt gt 0 then flag[w]=1
	w = where(flag eq 0,cnt)		 ; Anything to drop?
	if cnt gt 0 then b[w]=32B		 ; If so, set to spaces.
	dt = string(b)				 ; Convert back to string.
 
        ;-----------------------------------------------------------------
	;  Deal with all numeric dates
        ;
        ;  For these cases the year, month and day are all numeric
        ;  values.  The year may be 2 or 4 digits.  The digits may be
        ;  separated by a space or all together with no spaces.
        ;  THE MONTH AND DAY NUMBERS ARE ASSUMED TO BE 2 DIGITS.
        ;-----------------------------------------------------------------
        ;---  YMD  ---
	if keyword_set(ymd) then begin
	  if nwrds(dt) eq 1 then begin		; Like 000101 or 20000101.
	    len = strlen(dt)			; Length of single string.
	    y = strmid(dt,0,len-4)		; Allow for 2 or 4 digit yr.
	    m = strmid(dt,len-4,2)		; Always 2 digits.
	    d = strmid(dt,len-2,2)		; Always 2 digits.
	  endif else begin			; Like 2000 1 1.
	    y = getwrd(dt,0)
	    m = getwrd(dt,1)
	    d = getwrd(dt,2)
	  endelse
	  return
	endif
        ;---  YDM  ---
	if keyword_set(ydm) then begin
	  if nwrds(dt) eq 1 then begin		; Like 000101 or 20000101.
	    len = strlen(dt)			; Length of single string.
	    y = strmid(dt,0,len-4)		; Allow for 2 or 4 digit yr.
	    d = strmid(dt,len-4,2)		; Always 2 digits.
	    m = strmid(dt,len-2,2)		; Always 2 digits.
	  endif else begin
	    y = getwrd(dt,0)
	    d = getwrd(dt,1)
	    m = getwrd(dt,2)
	  endelse
	  return
	endif
        ;---  DMY  ---
	if keyword_set(dmy) then begin
	  if nwrds(dt) eq 1 then begin		; Like 010100 or 01012000.
	    d = strmid(dt,0,2)			; Always 2 digits.
	    m = strmid(dt,2,2)			; Always 2 digits.
	    y = strmid(dt,4,4)			; May be 2 or 4 digits.
	  endif else begin
	    d = getwrd(dt,0)
	    m = getwrd(dt,1)
	    y = getwrd(dt,2)
	  endelse
	  return
	endif
        ;---  MDY  ---
	if keyword_set(mdy) then begin
	  if nwrds(dt) eq 1 then begin		; Like 010100 or 01012000.
	    m = strmid(dt,0,2)			; Always 2 digits.
	    d = strmid(dt,2,2)			; Always 2 digits.
	    y = strmid(dt,4,4)			; May be 2 or 4 digits.
	  endif else begin
	    m = getwrd(dt,0)
	    d = getwrd(dt,1)
	    y = getwrd(dt,2)
	  endelse
	  return
	endif
        ;---  YDN  ---
	if keyword_set(ydn) then begin
	  if nwrds(dt) eq 1 then begin		; Like 10161 or 2010161.
	    len = strlen(dt)			; Length of single string.
	    y = strmid(dt,0,len-3)		; Allow for 2 or 4 digit yr.
	    dn = strmid(dt,len-3,3)		; Always 3 digits.
	    ydn2md, y, dn, m, d                 ; Year and Day of year to m & d.
	  endif else begin			; Like 2010 161.
	    y = getwrd(dt,0)
	    dn = getwrd(dt,1)
	    ydn2md, y, dn, m, d                 ; Year and Day of year to m & d.
	  endelse
	  return
	endif
        ;---  DNY  ---
	if keyword_set(dny) then begin
	  if nwrds(dt) eq 1 then begin		; Like 16110 or 1612010.
	    dn = strmid(dt,0,3)			; Always 3 digits.
	    y = strmid(dt,3,4)			; May be 2 or 4 digits.
	    ydn2md, y, dn, m, d                 ; Year and Day of year to m & d.
	  endif else begin
	    dn = getwrd(dt,0)
	    y = getwrd(dt,1)
	    ydn2md, y, dn, m, d                 ; Year and Day of year to m & d.
	  endelse
	  return
	endif
 
        ;-----------------------------------------------------------------
	;  YYMMMDD or DDMMMYY
        ;
	;    /YYMMMDD allows dates like 06jul25.
	;    /DDMMMYY allows dates like 25jul06.
        ;      Handle case with no spaces are in the date string
        ;      (but spaces are added here for later processing).
        ;-----------------------------------------------------------------
        if nwrds(dt) eq 1 then begin
	  if keyword_set(YYMMMDD) then begin ; Just add spaces.
	    if strlen(dt) eq 9 then off=2 else off=0
;	    dt = strmid(dt,5+off,2)+' '+strmid(dt,2+off,3)+' '+strmid(dt,0,2+off)
	    dt = strmid(dt,0,2+off)+' '+strmid(dt,2+off,3)+' '+strmid(dt,5+off,2)
	  endif
	  if keyword_set(DDMMMYY) then begin ; Just add spaces.
	    if strlen(dt) eq 9 then off=2 else off=0
	    dt = strmid(dt,0,2)+' '+strmid(dt,2,3)+' '+strmid(dt,5,2+off)
	  endif
        endif
 
	;----  Want 1 monthname and 2 numbers. Start counts at 0.  -----------
	nmn = 0			; Number of month names found is 0.
	nnm = 0			; Number of numbers found is 0.
	nums = [0]		; Start numbers array.

	;----  Loop through words in text string  -------------
	for iw = 0, nwrds(dt)-1 do begin
	  wd = strupcase(getwrd(dt,iw))	; Get word as upper case.
	  ;---- check if month name  -------
	  txt = strmid(wd,0,3)		; Check only first 3 letters.
	  i = strpos('JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC',txt)  ; find month.
	  if i ge 0 then begin		; Found month name.
	    m = 1 + i/3			; month number.
	    nmn = nmn + 1		; Count month name.
	    goto, skip			; Skip over number test.
	  endif
	  ;----  Check for a number  -------
	  if isnumber(wd) then begin
	    nnm = nnm + 1		; Count number.
	    nums = [nums,wd+0]		; Store it.
	  endif
skip:
	endfor
 
	;----  Test for only 1 month name  -------
	if nmn ne 1 then begin		; Must be exactly 1 month name.
	  y = -1
	  m = -1
	  d = -1
	  return
	endif
 
	;----  Look for y and m -----
	if nnm ne 2 then begin		; Must be exactly 2 numeric items.
	  y = -1
	  m = -1
	  d = -1
	  return
	endif
	nums = nums[1:*]		; Trim off leading 0.
	if max(nums) gt 31 then begin	; Assume a number > 31 is the year.
	  y = max(nums)
	  d = min(nums)
	  return
	endif
	if min(nums) eq 0 then begin	; Allow a year of 0 (but not a day).
	  y = min(nums)
	  d = max(nums)
	  return
	endif

        ;---  Both id and y are < 31, assume day was first unless told  ---
        if keyword_set(YYMMMDD) then begin ; Year was first.
	  y = nums[0]
	  d = nums[1]
        endif else begin ; Assume day was first.
	  d = nums[0]
	  y = nums[1]
        endelse

	return
 
	end
 
 
;===============================================================
;	Wrapper to feed single values to the main routine.
;===============================================================
	pro date2ymd,date,y,m,d, yyyy=yyyy, $
	  ymd=ymd, ydm=ydm, dmy=dmy, mdy=mdy, $
          ydn=ydn, dny=dny, $
	  yymmmdd=yymmmdd, ddmmmyy=ddmmmyy, help=hlp
 
	if (n_params(0) lt 4) or keyword_set(hlp) then begin
	  print,' Date text string to the numbers year, month, day.'
	  print,' date2ymd,date,y,m,d'
	  print,'   date = date string.		in'
	  print,'   y = year number.		out'
	  print,'   m = month number.		out'
	  print,'   d = day number.		out'
	  print,' Keywords:'
	  print,'   /YMD Date is all numeric: Year, Month, Day'
	  print,'   /YDM Date is all numeric: Year, Day, Year'
	  print,'   /DMY Date is all numeric: Day, Month, Year'
	  print,'   /MDY Date is all numeric: Month, Day, Year'
	  print,'   /YDN Date is all numeric: Year, Day of year'
	  print,'   /DNY Date is all numeric: Day of year, Year'
	  print,'   /YYYY Make sure year is 4 digits.'
	  print,'   /YYMMMDD allows dates like 06jul25.'
	  print,'   /DDMMMYY allows dates like 25jul06.'
	  print,' Notes: The format of the date is flexible except that the'
	  print,'   month must be month name unless one of the all numeric'
	  print,'   keywords is given.'
	  print,'   Dashes, commas, periods, or slashes are allowed.'
	  print,'   Some examples: 23 sep, 1985     sep 23 1985   1985 Sep 23'
	  print,'   23/SEP/85   23-SEP-1985   85-SEP-23   23 September, 1985.'
	  print,"   Doesn't check if month day is valid. Doesn't"
	  print,'   change year number (like 86 does not change to 1986)'
	  print,'   unless the /YYYY keyword is given.  Non-numeric'
	  print,'   dates may have only 2 numeric values, year and day. If'
	  print,'   both year & day values are < 31 then day is assumed first.'
	  print,'   systime() can be handled: date2ymd,systime(),y,m,d'
	  print,'   For invalid dates y, m and d are all set to -1.'
	  print,'   Some example numeric dates: 051506, 05/15/06'
	  print,'   (May 15, 2006 with /YYYY), 05152006.  All would use /MDY.'
	  return
	endif
 
	n = n_elements(date)
 
	y = intarr(n)
	m = intarr(n)
	d = intarr(n)
 
	for i = 0L, n-1 do begin
	  date2ymd_1, date[i], yy, mm, dd, ymd=ymd, ydm=ydm, $
	    dmy=dmy, mdy=mdy, ydn=ydn, dny=dny, $
            yymmmdd=yymmmdd, ddmmmyy=ddmmmyy
          ;---  Validity check  ---
          flag = 0                              ; Invalid date flag.
          if isnumber(yy) eq 0 then flag=1      ; Numbers?
          if isnumber(mm) eq 0 then flag=1
          if isnumber(dd) eq 0 then flag=1
          if flag eq 0 then begin
            if mm gt 12 then flag=1             ; In range?
            if mm lt 1 then flag=1
            if dd gt 31 then flag=1
            if dd lt 1 then flag=1
          endif
          if flag eq 0 then begin               ; Check month day.
            maxday = monthdays(yy,mm)           ; Max month day.
            if dd gt maxday then flag=1
          endif
          if flag eq 1 then begin               ; Bad date.
            yy = -1
            mm = -1
            dd = -1
          endif
	  y[i] = yy
	  m[i] = mm
	  d[i] = dd
	endfor
 
	if n eq 1 then begin	; Return scalars for a scalar input.
	  y = y[0]
	  m = m[0]
	  d = d[0]
	endif
 
	if keyword_set(yyyy) then y=yy2yyyy(y)
 
	return
	end
