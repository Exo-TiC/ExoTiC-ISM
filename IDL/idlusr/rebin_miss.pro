;-------------------------------------------------------------
;+
; NAME:
;       REBIN_MISS
; PURPOSE:
;       rebin allowing missing values.
; CATEGORY:
; CALLING SEQUENCE:
;       b = rebin(a, d1, [d2, ...d8])
; INPUTS:
;       a = Input array to rebin.    in
;       d1,...= final dimension(s).  in
; KEYWORD PARAMETERS:
;       Keywords:
;         MISSING_DATA=mval Value that represents missing data.
;           Default is no missing data.  Missing data is ignored
;           while rebinning.
; OUTPUTS:
;       b = Returned rebinned array. out
; COMMON BLOCKS:
; NOTES:
;       Note, the rebin /SAMPLE keyword is not allowed.
; MODIFICATION HISTORY:
;       R. Sterner, 2007 Oct 17
;
; Copyright (C) 2007, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	function rebin_miss, a0, d1,d2,d3,d4,d5,d6,d7,d8, $
	  missing_data=miss, help=hlp
 
	if (n_params(0) lt 2) or keyword_set(hlp) then begin
          print,' rebin allowing missing values.'
          print,' b = rebin(a, d1, [d2, ...d8])'
          print,'   a = Input array to rebin.    in'
          print,'   d1,...= final dimension(s).  in'
          print,'   b = Returned rebinned array. out'
          print,' Keywords:'
          print,'   MISSING_DATA=mval Value that represents missing data.'
          print,'     Default is no missing data.  Missing data is ignored'
          print,'     while rebinning.'
          print,'   Note, the rebin /SAMPLE keyword is not allowed.'
          return,''
	endif
 
	;-------------------------------------------------------------
	;  Get incoming data type
	;-------------------------------------------------------------
	a = a0					; Working copy.
	typ = size(a,/type)
 
	;-------------------------------------------------------------
	;  Deal with final dimensions
	;-------------------------------------------------------------
	case n_params(0) of
2:	dim = [d1]
3:	dim = [d1,d2]
4:	dim = [d1,d2,d3]
5:	dim = [d1,d2,d3,d4]
6:	dim = [d1,d2,d3,d4,d5]
7:	dim = [d1,d2,d3,d4,d5,d6]
8:	dim = [d1,d2,d3,d4,d5,d6,d7]
9:	dim = [d1,d2,d3,d4,d5,d6,d7,d8]
else:	begin
	  print,' Error in rebin_miss: incorrect number of dimensions given.'
	  return,''
	end
	endcase
 
	;-------------------------------------------------------------
	;  Look for missing values
	;
	;  If any missing values find and set them to 0.
	;  Then find fraction of non-missing values in each
	;  output bin to be used to correct straight rebin.
	;-------------------------------------------------------------
	mflag = 0				; 0 means no missing data.
	if n_elements(miss) ne 0 then begin	; Missing given?
	  w = where(a eq miss, cnt)		; Are there any?
	  if cnt gt 0 then begin		; Yes, deal with them.
	    m = a ne miss			; Find all good elements.
	    fr = rebin(double(m),dim)		; Fraction not missing.
	    wz = where(fr eq 0, cntz)		; fr eq 0 where all missing.
	    frac = fr + (fr eq 0)		; Corrected to avoid x/0 err.
	    a[w] = 0				; Set missing to 0.
	    mflag = 1				; Set missing data flag.
	  endif
	endif
 
	;-------------------------------------------------------------
	;  Do rebin
	;-------------------------------------------------------------
	r = rebin(a,dim)
 
	;-------------------------------------------------------------
	;  Correct for missing values
	;-------------------------------------------------------------
	if mflag then begin			; If any missing values then
	  r = fix(r/frac,type=typ)		; correct for fraction good.
	  if cntz ne 0 then r[wz]=miss		; If no good in bin set to miss.
	endif
 
	return, r
 
	end
