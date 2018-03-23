;-------------------------------------------------------------
;+
; NAME:
;       MONTHNAMES
; PURPOSE:
;       Returns a string array of month names.
; CATEGORY:
; CALLING SEQUENCE:
;       mnam = monthnames([num])
; INPUTS:
;       num = optional month number (can be array).  in
; KEYWORD PARAMETERS:
;       Keywords:
;         /FULL return full month name (else 3 letters only).
;         /UPPER force all upper case (else mixed).
;         /LOWER force all lower case (else mixed).
;         /ORDER adds the month number at front, like 04_Apr, so
;           the strings will sort in time order.  Useful in file
;           names.
;         /NOZERO Drop element 0 when returning an array of all
;           months.  The purpose of element 0 was to allow indexing
;           into the array using the month number.  But for
;           generating a list of file names that may not be wanted.
; OUTPUTS:
;       mnam = returned month name(s).               out
;         if num not given or is 0 a string array of all months
;         is returned: ['Error','January',...'December']
;         modified by the keywords.
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 18 Sep, 1989
;       R. Sterner, 2001 May 24 --- Now returns name of given month.
;       R. Sterner, 2010 May 04 --- Converted arrays from () to [].
;       R. Sterner, 2012 Mar 09 --- Added /ORDER, cleaned up code.
;       R. Sterner, 2012 Mar 09 --- Added /NOZERO.
;
; Copyright (C) 1989, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
	function monthnames, num0, upper=upper, lower=lower, full=full, $
             order=order, nozero=nozero, help=hlp
 
	if keyword_set(hlp) then begin
	  print,' Returns a string array of month names.'
	  print,' mnam = monthnames([num])'
	  print,'   num = optional month number (can be array).  in'
	  print,'   mnam = returned month name(s).               out'
	  print,'     if num not given or is 0 a string array of all months'
	  print,"     is returned: ['Error','January',...'December']"
          print,'     modified by the keywords.'
	  print,' Keywords:'
	  print,'   /FULL return full month name (else 3 letters only).'
	  print,'   /UPPER force all upper case (else mixed).'
	  print,'   /LOWER force all lower case (else mixed).'
	  print,'   /ORDER adds the month number at front, like 04_Apr, so'
          print,'     the strings will sort in time order.  Useful in file'
          print,'     names.'
          print,'   /NOZERO Drop element 0 when returning an array of all'
          print,'     months.  The purpose of element 0 was to allow indexing'
          print,'     into the array using the month number.  But for'
          print,'     generating a list of file names that may not be wanted.'
	  return, -1
	endif
 
        ;--------------------------------------------------------------
        ;  Set up array of all month names
        ;--------------------------------------------------------------
	nam = ['Error','January','February','March','April','May',$
	      'June','July','August','September','October',$
	      'November','December']
 
        ;--------------------------------------------------------------
        ;  Determine month number
        ;
        ;  If one or more month numbers are given use those months.
        ;  If none is given, or 0 is given then use all months.
        ;--------------------------------------------------------------
        if n_elements(num0) eq 0 then flag=0 else flag=1
        if (flag eq 1) and (n_elements(num0) eq 1) then begin
           if (num0[0] eq 0) then flag=0
        endif
        if flag eq 0 then num=indgen(13) else num=num0
 
        ;--------------------------------------------------------------
        ;  Pull out and modify requested months.
        ;--------------------------------------------------------------
	nam = nam[num]
	if not keyword_set(full) then nam=strmid(nam,0,3)
	if keyword_set(upper) then nam=strupcase(nam)
	if keyword_set(lower) then nam=strlowcase(nam)
	if keyword_set(order) then nam=string(num,form='(I2.2)')+'_'+nam
        if keyword_set(nozero) and (flag eq 0) then nam=nam[1:*]
 
        return, nam
 
	end
