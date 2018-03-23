;-------------------------------------------------------------
;+
; NAME:
;       MEDIAN_MISS
; PURPOSE:
;       Median filter allowing missing values.
; CATEGORY:
; CALLING SEQUENCE:
;       b = median_miss(a, wid)
; INPUTS:
;       a = Input array to median filter.  in
;       wid = Width of filter.             in
; KEYWORD PARAMETERS:
;       Keywords:
;         MISSING_DATA=mval Value that represents missing data.
;           Default is no missing data.  Missing data is ignored
;           by the median filter.
;         Keywords for the median filter are also allowed.
; OUTPUTS:
;       b = Returned filtered array.       out
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 2007 Oct 16
;       R. Sterner, 2010 Jun 04 --- Converted arrays from () to [].
;
; Copyright (C) 2007, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	function median_miss, a, wid, missing_data=miss,_extra=extra,help=hlp 
 
	if (n_params(0) lt 2) or keyword_set(hlp) then begin
	  print,' Median filter allowing missing values.'
	  print,' b = median_miss(a, wid)'
	  print,'   a = Input array to median filter.  in'
	  print,'   wid = Width of filter.             in'
	  print,'   b = Returned filtered array.       out'
	  print,' Keywords:'
	  print,'   MISSING_DATA=mval Value that represents missing data.'
	  print,'     Default is no missing data.  Missing data is ignored'
	  print,'     by the median filter.'
	  print,'   Keywords for the median filter are also allowed.'
	  return,''
	endif
 
	;----------------------------------------------------------
	;  Get incoming data type
	;  Also set up promotion flag:
	;    0 = Type not handled by median,
	;    1 = promote to float, 2 = promote to double.
	;----------------------------------------------------------
	typ = size(a,/type)
	flag = [0,1,1,2,1,2,0,0,0,0,0,0,1,2,2,2]
 
	;----------------------------------------------------------
	;  Check and promote to working array
	;----------------------------------------------------------
	pr = flag[typ]					; Type promotion flag.
	if pr eq 0 then begin				; Unsupported type.
	  print,' Error in median_miss: Data type of '+datatype(a,1)+ $
	    ' not supported by median_miss.'
	  return,''
	endif
	if pr eq 1 then aa=float(a) else aa=double(a)	; Promote to working.
 
	;----------------------------------------------------------
	;  Flag missing data as NaN
	;----------------------------------------------------------
	if n_elements(miss) ne 0 then begin		; Missing given?
	  w = where(a eq miss, cnt)			; Are there any?
	  if cnt gt 0 then begin			; Yes, insert NaN.
	    if pr eq 1 then begin			; Working arr is float.
	      aa[w] = !values.f_nan			; Use float NaN.
	    endif else begin				; Working arr is double.
	      aa[w] = !values.d_nan			; Use double NaN.
	    endelse
	  endif
	endif
 
	;----------------------------------------------------------
	;  Do median filter.  Median filter ignores NaN.
	;----------------------------------------------------------
	aa = median(aa,wid,_extra=extra)
 
	;----------------------------------------------------------
	;  Replace NaN with miss
	;----------------------------------------------------------
	if n_elements(miss) gt 0 then begin
	  w = where(finite(aa,/nan), cnt)		; Are there any?
	  if cnt gt 0 then aa[w]=miss
	endif
 
	;----------------------------------------------------------
	;  Unpromote back to incoming type
	;----------------------------------------------------------
	aa = fix(aa,type=typ)
 
	return, aa
 
	end
