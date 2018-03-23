;-------------------------------------------------------------
;+
; NAME:
;       DT_TM_TOJS
; PURPOSE:
;       Convert a date/time string to "Julian Seconds".
; CATEGORY:
; CALLING SEQUENCE:
;       js = dt_tm_tojs( dt)
; INPUTS:
;       dt = date/time string (may be array).   in
;            (see date2ymd for format)
; KEYWORD PARAMETERS:
;       Keywords:
;         Use one of these keywords if all numeric:
;         /YMD Date is all numeric: Year, Month, Day
;         /YDM Date is all numeric: Year, Day, Year
;         /DMY Date is all numeric: Day, Month, Year
;         /MDY Date is all numeric: Month, Day, Year
;         /YDN Date is all numeric: Year, Day of year
;         /DNY Date is all numeric: Day of year, Year
;         FORMAT=fmt Specify format of input.
;           A format may be needed to indicate date and time.  Use
;           the letters y,n,d in the same positions as year, month
;           and day or y and # for year and day number in the input
;           string, and the pairs hh, mm, and ss[s...] for hour,
;           minute, second (the s format must include any decimal
;           point and places) Any other char may be used as
;           place holders. Case is ignored. Examples:
;             for txt='gs_06oct09_0208_multi.png' use
;                 fmt='xx_yynnndd_hhmm_xxxxx.xxx'
;             for txt='gs_20101600208_multi.png' use
;                 fmt='xx_yyyy###hhmm_xxxxx.xxx'
;             for txt='OCF_20110930T171924.430136' use
;                 fmt='xxxxyyyynnddxhhmmsssssssss'
;           If s and/or m are not used they default to 0.
;           Trailing placeholders are not really needed.
;           >>>===> Make sure to use n for month (m is for minute).
;           May also use with the all numeric keywords if needed.
;           All input strings must have the same format to use this.
;           Times given with no colons must use a format.
;         BASE=base Use to convert 2-digit years to 4-digit years.
;           If 2-digit year is not close to the current year then
;           give in base a year close to the years to convert.
;         ERROR=err  Error flag: 0=ok, else error.
;         /QUIET means inhibit error message.
; OUTPUTS:
;       js = "Julian Seconds".                  out
; COMMON BLOCKS:
; NOTES:
;       Notes: Julian seconds (not an official unit) serve the
;         same purpose as Julian Days, interval computations.
;         The zero point is 0:00 1 Jan 2000, so js < 0 before then.
;         Julian Seconds are double precision and have a precision
;         better than 1 millisecond over a span of +/- 1000 years.
;       
;         2 digit years (like 17 or 92) are changed to the closest
;         corresponding 4 digit year.
;       
;       See also dt_tm_fromjs, ymds2js, js2ymds, jscheck.
; MODIFICATION HISTORY:
;       R. Sterner, 23 Jul, 1992
;       R. Sterner, 1994 Mar 29 --- Modified to handle arrays.
;       R. Sterner, 1999 aug 04 --- Improved 2 digit year case.
;       R. Sterner, 2000 aug 17 --- Added /QUIET
;       R. Sterner, 2005 Jan 02 --- Allowed numeric dates.
;       R. Sterner, 2006 Nov 09 --- Added FORMAT=fmt.
;       R. Sterner, 2008 Aug 06 --- Passed QUIET in to yy2yyyy.
;       R. Sterner, 2009 May 14 --- Handled time correctly if given a format.
;       R. Sterner, 2009 May 14 --- Added keyword BASE=base.
;       R. Sterner, 2010 Apr 29 --- Converted arrays from () to [].
;       R. Sterner, 2010 Jun 17 --- Now can handle day of year.
;       R. Sterner, 2010 Sep 17 --- Now gets any fractional part of seconds.
;       R. Sterner, 2012 Apr 18 --- Formatted seconds now double (was float).
;       R. Sterner, 2012 Apr 18 --- Corrected help text for s format.
;       R. Sterner, 2012 Nov 29 --- Added /BOUND keyword.
;
; Copyright (C) 1992, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
	function dt_tm_tojs, dt, error=err, quiet=quiet, help=hlp, $
	  ymd=ymd, ydm=ydm, dmy=dmy, mdy=mdy, ydn=ydn, dny=dny, $
          format=fmt, base=base, bound=bound
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Convert a date/time string to "Julian Seconds".'
	  print,' js = dt_tm_tojs( dt)'
	  print,'   dt = date/time string (may be array).   in'
	  print,'        (see date2ymd for format)'
	  print,'   js = "Julian Seconds".                  out'
	  print,' Keywords:'
          print,'   Use one of these keywords if all numeric:'
	  print,'   /YMD Date is all numeric: Year, Month, Day'
	  print,'   /YDM Date is all numeric: Year, Day, Year'
	  print,'   /DMY Date is all numeric: Day, Month, Year'
	  print,'   /MDY Date is all numeric: Month, Day, Year'
          print,'   /YDN Date is all numeric: Year, Day of year'
          print,'   /DNY Date is all numeric: Day of year, Year'
	  print,'   FORMAT=fmt Specify format of input.'
          print,'     A format may be needed to indicate date and time.  Use'
	  print,'     the letters y,n,d in the same positions as year, month'
	  print,'     and day or y and # for year and day number in the input'
          print,'     string, and the pairs hh, mm, and ss[s...] for hour,'
	  print,'     minute, second (the s format must include any decimal'
          print,'     point and places) Any other char may be used as'
	  print,'     place holders. Case is ignored. Examples:'
          print,"       for txt='gs_06oct09_0208_multi.png' use"
          print,"           fmt='xx_yynnndd_hhmm_xxxxx.xxx'"
          print,"       for txt='gs_20101600208_multi.png' use"
          print,"           fmt='xx_yyyy###hhmm_xxxxx.xxx'"
          print,"       for txt='OCF_20110930T171924.430136' use"
          print,"           fmt='xxxxyyyynnddxhhmmsssssssss'"
	  print,'     If s and/or m are not used they default to 0.'
	  print,'     Trailing placeholders are not really needed.'
	  print,'     >>>===> Make sure to use n for month (m is for minute).'
	  print,'     May also use with the all numeric keywords if needed.'
	  print,'     All input strings must have the same format to use this.'
	  print,'     Times given with no colons must use a format.'
	  print,'   BASE=base Use to convert 2-digit years to 4-digit years.'
	  print,'     If 2-digit year is not close to the current year then'
	  print,'     give in base a year close to the years to convert.'
          print,'   /BOUND Bound day of month to no more than last day.  If a'
          print,'     larger day is given limit to last day.  This is mostly'
          print,"     useful for February: js=dt_tm_tojs('2001 Feb 31',/bound)"
          print,'     where the year may not be known ahead of time.'
	  print,'   ERROR=err  Error flag: 0=ok, else error.'
	  print,'   /QUIET means inhibit error message.'
   	  print,' Notes: Julian seconds (not an official unit) serve the'
   	  print,'   same purpose as Julian Days, interval computations.'
   	  print,'   The zero point is 0:00 1 Jan 2000, so js < 0 before then.'
   	  print,'   Julian Seconds are double precision and have a precision'
   	  print,'   better than 1 millisecond over a span of +/- 1000 years.'
	  print,' '
	  print,'   2 digit years (like 17 or 92) are changed to the closest'
	  print,'   corresponding 4 digit year.'
	  print,' '
	  print,' See also dt_tm_fromjs, ymds2js, js2ymds, jscheck.'
	  return, -1
	endif
 
	err = 0
        dt_tm_brk, dt, dat, tim, $	   ; Break into date and time strings.
	  format=fmt, date_format=dfmt
        date2ymd, dat, yy, mm, dd, $	   ; Break date into y,m,d.
	  ymd=ymd, ydm=ydm, dmy=dmy, mdy=mdy, $
          ydn=ydn, dny=dny, $
	  yymmmdd=dfmt.yymmmdd, ddmmmyy=dfmt.ddmmmyy
	w = where(yy lt 0, c)		   ; Find bad dates.
	if c gt 0 then begin
	  if not keyword_set(quiet) then begin
	    print,' Error in dt_tm_tojs: given date not valid or incomplete.'
	    print,'   Problem date(s):'
	    for i=0,c-1 do print,dat[w[i]]
	  endif
	  err = 1
	endif
	if n_elements(base) eq 0 then base=getwrd(systime(),/last)
	yy = yy2yyyy(yy,quiet=quiet,base=base,err=err)   ; Fix 2 digit years.
	if err ne 0 then return,0
	if n_elements(fmt) eq 0 then fmt=''
	fmtlc = strlowcase(fmt)		  ; Deal with time format.
	p = strpos(fmtlc,'hh')		  ; Look for hh in format.
	fmtlc = strmid(fmtlc,p)		  ; Match format to time string.
	if p ge 0 then begin		  ; Yes, format string has time also.
	  p = 0				  ; Position in trimmed format.
	  h = strmid(tim,p,2)+0.0	  ; Grab hours.
	  p = strpos(fmtlc,'mm')
	  if p ge 0 then m=strmid(tim,p,2)+0.0 else m=0.0
	  p = strpos(fmtlc,'ss')
	  ;if p ge 0 then s=strmid(tim,p,2)+0.0 else s=0.0
	  if p ge 0 then s=strmid(tim,p,20)+0.0D0 else s=0.0D0 ; Get all of sec.
	  ss = s + 60*m + 3600*h	   ; Total seconds.
	endif else begin
	  ss = secstr(tim)		   ; Convert time to seconds.
	endelse

        ;---  Bound month day to no more than last day  ---
        if keyword_set(bound) then begin
          for i=0,n_elements(mm)-1 do dd[i]=dd[i] < monthdays(yy[i],mm[i])
        endif

	js = ymds2js(yy,mm,dd,ss)	   ; Finish conversion.
 
	return, js
 
	end
