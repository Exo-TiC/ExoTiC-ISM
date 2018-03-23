;-------------------------------------------------------------
;+
; NAME:
;       TAG_ARR
; PURPOSE:
;       Concatenate scalars from one structure into arrays in another.
; CATEGORY:
; CALLING SEQUENCE:
;       tag_arr, ss, sa
; INPUTS:
;       ss = Structure with scalar values.  in
; KEYWORD PARAMETERS:
;       Keywords:
;         /INIT Initialize sa from ss.  Given a structure of scalars
;           create the structure of arrays sa with pointers to the
;           arrays.  The structure sa will be an output in this case.
;          This step is automatic if sa is undefined on the first call.
;         /CONVERT Free all the pointers in sa and convert to arrays.
;         ERROR=err Error flag: 0=ok, 1=no concatenations done.
; OUTPUTS:
;       sa = Structure with array values.   in, out
; COMMON BLOCKS:
; NOTES:
;       Notes: The Problem: A record from a data file is read into
;         a structure, one record at each of a series of time steps.
;         Want to end up with a structure of arrays with the time
;         series for each tag.  For the first time step structure sa,
;         the structure with the arrays, is derived from the first
;         structure ss using the keyword /INIT. If sa is undefined this
;         will be automatic (else do explicitly). Then for each time
;         step, the new record is sent in structure ss, with the values
;         in each tag tacked on the end of the arrays in structure sa.
;         Structure sa uses pointers.  After the arrays are completely
;         built, convert structure sa from a structure of pointers
;         to a structure of arrays using the keyword /CONVERT:
;           tag_arr, sa, /convert
; MODIFICATION HISTORY:
;       R. Sterner, 2008 Dec 30
;
; Copyright (C) 2008, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro tag_arr, ss, sa, error=err, init=init, convert=conv, help=hlp
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Concatenate scalars from one structure into arrays in another.'
	  print,' tag_arr, ss, sa'
	  print,'   ss = Structure with scalar values.  in'
	  print,'   sa = Structure with array values.   in, out'
	  print,' Keywords:'
	  print,'   /INIT Initialize sa from ss.  Given a structure of scalars'
	  print,'     create the structure of arrays sa with pointers to the'
	  print,'     arrays.  The structure sa will be an output in this case.'
	  print,'    This step is automatic if sa is undefined on the first call.'
	  print,'   /CONVERT Free all the pointers in sa and convert to arrays.'
	  print,'   ERROR=err Error flag: 0=ok, 1=no concatenations done.'
	  print,' Notes: The Problem: A record from a data file is read into'
	  print,'   a structure, one record at each of a series of time steps.'
	  print,'   Want to end up with a structure of arrays with the time'
	  print,'   series for each tag.  For the first time step structure sa,'
	  print,'   the structure with the arrays, is derived from the first'
	  print,'   structure ss using the keyword /INIT. If sa is undefined this'
	  print,'   will be automatic (else do explicitly). Then for each time'
	  print,'   step, the new record is sent in structure ss, with the values'
	  print,'   in each tag tacked on the end of the arrays in structure sa.'
	  print,'   Structure sa uses pointers.  After the arrays are completely'
	  print,'   built, convert structure sa from a structure of pointers'
	  print,'   to a structure of arrays using the keyword /CONVERT:'
	  print,'     tag_arr, sa, /convert'
	  return
	endif
 
	;----------------------------------------------------------
	;  Initialize.  Set up sa.
	;----------------------------------------------------------
	if keyword_set(init) then begin
	  tag = tag_names(ss)			; List of tag names in ss.
	  n = n_tags(ss)			; # of tags in ss.
	  for i=0, n-1 do begin			; Build structure of arrays.
	    tag_add,sa,tag[i],ptr_new([ss.(i)])	; Pointer to array for tag i.
	  endfor
	  err = 0
	  return
	endif
 
	;----------------------------------------------------------
	;  Convert.  Convert pointers in sa to arrays and free them.
	;----------------------------------------------------------
	if keyword_set(conv) then begin
	  if n_params() eq 1 then sa=ss		; Allow a one arg call.
	  tag = tag_names(sa)			; List of tag names in sa.
	  n = n_tags(sa)			; # of tags in sa.
	  for i=0,n-1 do begin			; Loop over tags.
	    val = *sa.(i)			; Get array.
	    tag_add, sout, tag[i], val		; Insert into output structure.
	    ptr_free, sa.(i)			; Free pointer.
	  endfor	  
	  if n_params() eq 1 then ss=sout else sa=sout
	  err = 0
	  return
	endif
 
	;----------------------------------------------------------
	;  Concatentate
	;----------------------------------------------------------
	if n_elements(sa) eq 0 then begin	; If sa is undefined init it.
	  tag_arr,ss,sa,/init
	  return
	endif
	tag = tag_names(ss)			; List of tag names in ss.
	n = n_tags(ss)				; # of tags in ss.
	cnt = 0					; # tags found.
	for i=0, n-1 do begin			; Loop over tags.
	  if tag_test(sa,tag[i],index=in) then begin  ; If tag in sa then ...
	    *sa.(in) = [*sa.(in), ss.(i)]	; Tack ss value into sa array.
	    cnt += 1				; Found tag, count it.
	  endif
	endfor
	if cnt eq 0 then err=1 else err=0	; Error if no tags found.
	
	end
