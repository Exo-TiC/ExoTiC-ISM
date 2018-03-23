;-------------------------------------------------------------
;+
; NAME:
;       TAG_FUNCT
; PURPOSE:
;       Process structure elements through specified functions.
; CATEGORY:
; CALLING SEQUENCE:
;       s2 = tag_funct(s)
; INPUTS:
;       s = Input structure.    in
; KEYWORD PARAMETERS:
;       Keywords:
;         PREFIX=pref This is what the first word of a structure
;           element is to make the second word be applied to the
;           rest of the element as a function.  Default='apply'.
;           May not be a number. Case ignored.
;         ERROR=err Error flag: 0=ok.
; OUTPUTS:
;       s2 = Output structure.  out
; COMMON BLOCKS:
; NOTES:
;       Notes: An example structure element:
;         apply list2array [2,3,5,7,11,13,17,19]
;         would apply the function named list2array to the rest
;         of the element ([2,3,...).  THE FUNCTION MUST TAKE A
;         STRING INPUT and may return anything allowed as a
;         structure element.  For example:
;           s = {aaa:'apply sqrt 16',bbb:'apply sin 1.57080'}
;         would return a structure with the numeric values
;         4.00000 and 1.00000 for aaa and bbb.
;       
;         Only string elements will be processed this way and only
;         if they start with the prefix (def=apply) and have at
;         least one more word to use as the function.
; MODIFICATION HISTORY:
;       R. Sterner, 2006 Jul 10
;       R. Sterner, 2010 May 07 --- Renamed from tags_funct.pro.
;       R. Sterner, 2010 May 07 --- Converted arrays from () to [].
;
; Copyright (C) 2006, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	function tag_funct, s, help=hlp, error=err, action=action
 
	if (n_params(0) lt 0) or keyword_set(hlp) then begin
	  print,' Process structure elements through specified functions.'
	  print,' s2 = tag_funct(s)'
	  print,'   s = Input structure.    in'
	  print,'   s2 = Output structure.  out'
	  print,' Keywords:'
	  print,'   ACTION=act This is what the first word of a structure'
	  print,'     element is to make the second word be applied to the'
	  print,"     rest of the element as a function.  Default='apply'."
	  print,'     May not be a number. Case ignored.'
	  print,'   ERROR=err Error flag: 0=ok.'
	  print,' Notes: An example structure element:'
	  print,'   apply list2array [2,3,5,7,11,13,17,19]'
	  print,'   would apply the function named list2array to the rest'
	  print,'   of the element ([2,3,...).  THE FUNCTION MUST TAKE A'
	  print,'   STRING INPUT and may return anything allowed as a'
	  print,'   structure element.  For example:'
	  print,"     s = {aaa:'apply sqrt 16',bbb:'apply sin 1.57080'}"
	  print,'   would return a structure with the numeric values'
	  print,'   4.00000 and 1.00000 for aaa and bbb.'
	  print,' '
	  print,'   Only string elements will be processed this way and only'
	  print,'   if they start with the action (def=apply) and have at'
	  print,'   least one more word to use as the function.'
	  return,''
	endif
 
	;----------------------------------------------------------
	;  Make sure input is a structure
	;----------------------------------------------------------
	if datatype(s) ne 'STC' then begin
	  print,' Error in tag_funct: Argument must be a structure.'
	  err = 1
	  return,''
	endif
	err = 0
 
	;----------------------------------------------------------
	;  Defaults
	;----------------------------------------------------------
	if n_elements(action) eq 0 then action='apply'
 
	;----------------------------------------------------------
	;  Find tag names
	;----------------------------------------------------------
	tags = tag_names(s)
	n = n_elements(tags)
 
	;----------------------------------------------------------
	;  Process each tag/value pair
	;----------------------------------------------------------
	for i=0,n-1 do begin
	  val = s.(i)				; Value i.
	  if isnumber(val) eq 0 then begin	; Process if not a number.
	    w1 = strlowcase(getwrd(val))	; Get first word.
	    if w1 eq action then begin		; Is it the action?
	      fun = getwrd(val,1)		; Yes, get the function name
	      arg = getwrd(val,2,999)		; and the argument.
	      val = call_function(fun,arg)	; Apply function to argument.
	    endif
	  endif
	  if i eq 0 then begin			; First tag, create output.
	    s2 = create_struct(tags[i],val)
	  endif else begin			; Add to output if not first.
	    s2 = create_struct(s2,tags[i],val)
	  endelse
	endfor
 
	return, s2
 
	end
