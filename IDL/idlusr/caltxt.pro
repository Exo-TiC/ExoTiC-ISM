;-------------------------------------------------------------
;+
; NAME:
;       CALTXT
; PURPOSE:
;       Return a text array with calendar.
; CATEGORY:
; CALLING SEQUENCE:
;       txt = caltxt(yr,mon)
; INPUTS:
;       yr = Year.  Like 2008.                    in
;       mon = Month number, like 8.               in
;         Month must be numeric.
; KEYWORD PARAMETERS:
;       Keywords:
;         WDN1=wdn1 Weekday number of first day of month.
;            1 to 7, 1=Sun.
;         DAYS=days # days in month (eq last month day).
; OUTPUTS:
;       txt = returned text array with calendar.  out
;         Example:
;         August 2008
;         Sun Mon Tue Wed Thu Fri Sat
;                               1   2
;           3   4   5   6   7   8   9
;          10  11  12  13  14  15  16
;          17  18  19  20  21  22  23
;          24  25  26  27  28  29  30
;          31                        
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 2008 Aug 06
;
; Copyright (C) 2008, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	function caltxt, yr, mon, wdn1=wdn1, days=days, help=hlp
 
	if (n_params(0) lt 2) or keyword_set(hlp) then begin
	  print,' Return a text array with calendar.'
	  print,' txt = caltxt(yr,mon)'
	  print,'   yr = Year.  Like 2008.                    in'
	  print,'   mon = Month number, like 8.               in'
	  print,'     Month must be numeric.'
	  print,'   txt = returned text array with calendar.  out'
	  print,'     Example:'
	  print,'     August 2008'
	  print,'     Sun Mon Tue Wed Thu Fri Sat'
	  print,'                           1   2'
	  print,'       3   4   5   6   7   8   9'
	  print,'      10  11  12  13  14  15  16'
	  print,'      17  18  19  20  21  22  23'
	  print,'      24  25  26  27  28  29  30'
	  print,'      31                        '
	  print,' Keywords:'
	  print,'   WDN1=wdn1 Weekday number of first day of month.'
	  print,'      1 to 7, 1=Sun.'
	  print,'   DAYS=days # days in month (eq last month day).'
	  return,''
	endif
 
	;---   Find info for calendar  ---
        days = monthdays(yr, mon)		; Days in month.
	wd = weekday(yr, mon, 1, wdn1)		; Find weekday of 1st of month.
	wd2 = weekday(yr,mon,days,wdn2)		; Last weekday of month.
        rows = ceil((days+wdn1-1)/7.)		; Rows in calendar.
        mnam = monthnames()			; Array of month names.
        tt = ' ' + mnam[mon] + ' ' + strtrim(yr,2) ; Title.
	tt = tt + spc(28,tt,/notrim)		; Fixed length title.
 
	;---  Make days  ---
	dd = string(indgen(days)+1,form='(I4)')
	if wdn1 gt 1 then dd=[strarr(wdn1-1)+'    ', dd]
	if wdn2 lt 7 then dd=[dd,strarr(7-wdn2)+'    ']
 
	;---  Merge  ---
	txt = [tt,' Sun Mon Tue Wed Thu Fri Sat']
	in = indgen(7)
	for i=0,rows-1 do txt=[txt,string((byte(dd[in+7*i]))[0:*])]
	  
	return, txt
 
	end
