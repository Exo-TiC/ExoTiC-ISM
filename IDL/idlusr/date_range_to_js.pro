;-------------------------------------------------------------
;+
; NAME:
;       DATE_RANGE_TO_JS
; PURPOSE:
;       Convert a given range of dates to Julian Seconds.
; CATEGORY:
; CALLING SEQUENCE:
;       date_range_to_js, date1, date2, js1, js2
; INPUTS:
;       date1 = Start date                      in
;         Like 2009 Feb 1.
;       date2 = End date                        in
;         Like 2009 Feb 29.
;         Full dates should have three items:
;           Year, Month, Day in any order.
;         Partial dates should have two items, month and day, for
;         date1 and date2, in this case all years will be used.
;         Instead date2 may be the number of days in range.
;         A single item in the date2 string is assumed to be the
;         number of days in the range.
; KEYWORD PARAMETERS:
;       Keywords:
;         YEARS=yrs Array of years to use with partial dates.
;         ERROR=err Error flag: 0=ok.
; OUTPUTS:
;       js1 = Start date at 00:00:00 in JS.     out
;       js2 =   End date at 00:00:00 in JS.     out
; COMMON BLOCKS:
; NOTES:
;       Notes: If a time interval crosses over the year end, like
;       date1 = 'Dec 1' and date2 = 'Feb 28' then adjustments will
;       be made to keep all intervals within the specified years.
;       For this example a new interval will be added to the first
;       year.  If the years are 2000,2001,2003 then
;       'Jan 1 200' to 'Feb 28 200' will be added, and the interval
;       in the last year will end at 'Dec 31 2003' instead of
;       'Feb 28 2004'.
; MODIFICATION HISTORY:
;       R. Sterner, 2012 Oct 10
;       R. Sterner, 2012 Oct 11 --- Handled year end crossing.
;       R. Sterner, 2012 Nov 29 --- Handled last day of month (Feb mostly).
;
; Copyright (C) 2012, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
        pro date_range_to_js, date10, date20, js1, js2, years=years, $
          error=err, help=hlp
 
        if (n_params(0) lt 4) or keyword_set(hlp) then begin
          print,' Convert a given range of dates to Julian Seconds.'
          print,' date_range_to_js, date1, date2, js1, js2'
          print,'   date1 = Start date                      in'
          print,'     Like 2009 Feb 1.'
          print,'   date2 = End date                        in'
          print,'     Like 2009 Feb 29.'
          print,'     Full dates should have three items:'
          print,'       Year, Month, Day in any order.'
          print,'     Partial dates should have two items, month and day, for'
          print,'     date1 and date2, in this case all years will be used.'
          print,'     Instead date2 may be the number of days in range.'
          print,'     A single item in the date2 string is assumed to be the'
          print,'     number of days in the range.'
          print,'   js1 = Start date at 00:00:00 in JS.     out'
          print,'   js2 =   End date at 00:00:00 in JS.     out'
          print,' Keywords:'
          print,'   YEARS=yrs Array of years to use with partial dates.'
          print,'   ERROR=err Error flag: 0=ok.'
          print,' Notes: When using a date with just month and day, the last'
          print,' day of the month may not be known if the month is February.'
          print,' The day of the month will be kept in bounds, so use anything'
          print,' big enough to catch the last day. 29 will work for February,'
          print,' or anything bigger.  This works for any month but is only'
          print,' needed for February since the last day depends on the year.'
          print,' If a time interval crosses over the year end, like'
          print," date1 = 'Dec 1' and date2 = 'Feb 29' then adjustments will"
          print,' be made to keep all intervals within the specified years.'
          print,' For this example a new interval will be added to the first'
          print,' year.  If the years are 2000,2001,2003 then'
          print," 'Jan 1 2000' to 'Feb 29 2000' will be added, and the interval"
          print," in the last year will end at 'Dec 31 2003' instead of"
          print," 'Feb 29 2004'."
          return
        endif
 
        err = 1
 
        ;--------------------------------------------
        ;  Error check
        ;
        ;  If date2 is partial then date1 must also
        ;  be partial.
        ;
        ;  Check partial dates to see if they cross
        ;  the year end.  They cross the year end if
        ;  the end date is before the start date when
        ;  a year is included with the dates.
        ;  In this case set a flag to 1, else 0.
        ;  Add this flag to the year when including
        ;  with the partial end date.
        ;--------------------------------------------
        if (nwrds(date20) eq 2) then begin
          if (nwrds(date10) ne 2) then begin
            print,' Error in date_range_to_js: '+$
             'if date2 is partial then date1 must be also.'
            return
          endif
          ;---  Both dates are partial.  Check if year end crossed  ---
;          js1t = dt_tm_tojs(date10+' 2000')
;          js2t = dt_tm_tojs(date20+' 2000')
          js1t = dt_tm_tojs(date10+' 2000',/bound)
          js2t = dt_tm_tojs(date20+' 2000',/bound)
          flag = js2t lt js1t   ; 1 if year end crossed, else 0.
        endif else flag=0
 
        ;--------------------------------------------
        ;  Start Date
        ;--------------------------------------------
        nw1 = nwrds(date10)                     ; # words in date1.
        case nw1 of
2:        begin
            if n_elements(years) eq 0 then begin
              print,' Error in date_range_to_js: needed array of years missing.'
              return
            endif
            yrs = strtrim(years,2)
;            js1 = dt_tm_tojs(date10+' '+yrs)    ; Do all years.
            js1 = dt_tm_tojs(date10+' '+yrs,/bound) ; Do all years.
          end
;3:        js1 = dt_tm_tojs(date10)              ; Full start date given.
3:        js1 = dt_tm_tojs(date10,/bound)       ; Full start date given.
else:   begin
          print,' Error in date_range_to_js: Invalid Start Date: '+date10
          return
        end
        endcase
 
        ;--------------------------------------------
        ;  End Date
        ;--------------------------------------------
        nw2 = nwrds(date20)                     ; # words in date2.
        case nw2 of
1:        js2 = js1 + (date20-1)*86400D0        ; Number of days in range.
2:        begin
            if n_elements(years) eq 0 then begin
              print,' Error in date_range_to_js: needed array of years missing.'
              return
            endif
            yrs = strtrim(fix(years) + flag,2)  ; Use the next year if flag=1.
;            js2 = dt_tm_tojs(date20+' '+yrs)    ; Do all years.
            js2 = dt_tm_tojs(date20+' '+yrs,/bound) ; Do all years.
          end
;3:        js2 = dt_tm_tojs(date20)              ; Full end date given.
3:        js2 = dt_tm_tojs(date20,/bound)        ; Full end date given.
else:   begin
          print,' Error in date_range_to_js: Invalid End Date: '+date20
          return
        end
        endcase
 
        ;--------------------------------------------
        ;  Correct any partial date year end crossing
        ;
        ;  If both start and end dates are partial
        ;  and the interval crosses the year end
        ;  then take the part of the interval that
        ;  extends beyond the last year and move it
        ;  to the front of the first year, from
        ;  Jan 1 of first year to end date in
        ;  first year.
        ;--------------------------------------------
        if flag then begin
          ;---  Add partial interval to front of first year  ---
          yr0 = ' ' + strtrim(min(years),2)     ; First year in set.
          js10 = dt_tm_tojs('Jan 1' + yr0)      ; Start of first year.
;          js20 = dt_tm_tojs(date20 + yr0)      ; End date in first year.
          js20 = dt_tm_tojs(date20 + yr0,/bound) ; End date in first year.
          js1 = [js10, js1]                     ; Insert partial interval
          js2 = [js20, js2]                     ; at front of list.
        endif
 
        ;--------------------------------------------
        ;  Clip if last end date extends beyond
        ;  last year in set
        ;
        ;  Correct last end date to Dec 31 of
        ;  last year.
        ;
        ;  This case can come up two ways:
        ;  (1) If two partial dates cross the end
        ;      of the year.
        ;  (2) If a partial start date and number of
        ;      days crosses the end of the last year.
        ;--------------------------------------------
        yrmx = dt_tm_fromjs(max(js2),form='Y$')
        if yrmx gt max(years) then begin
          ;---  Clip partial interval at end of last year  ---
          yr9 = ' ' + strtrim(max(years),2)     ; Last year in set.
          js29 = dt_tm_tojs('Dec 31' + yr9)     ; End of last year.
          lst = n_elements(js2) - 1             ; Last index in list.
          js2[lst] = js29                       ; Replace last interval end.
        endif
 
        err = 0
        
        end
