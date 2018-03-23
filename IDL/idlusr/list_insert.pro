;-------------------------------------------------------------
;+
; NAME:
;       LIST_INSERT
; PURPOSE:
;       Insert a 1-d array into another 1-d array.
; CATEGORY:
; CALLING SEQUENCE:
;       output = list_insert(input, cmd, line, [add])
; INPUTS:
;       input = Initial 1-d array.               in
;       cmd = Edit command:                      in
;             'P': Preceded line by add.
;             'R': Replace line by add.
;             'F': Follow line by add.
;             'D': Delete line (add array ignored).
;       line = Index in old (first index=0).     in
;         This may also be a range of indices: [lo,hi].
;       add = 1-d array to insert.               in
; KEYWORD PARAMETERS:
;       Keywords:
;         COUNT=cnt Returned number of elements in output array.
;         ERROR=err Error flag: 0=ok.
; OUTPUTS:
;       output = Returned modified array.        out
; COMMON BLOCKS:
; NOTES:
;       Note: For a scalar out of range index the array
;         is not changed.  For an index range the array
;         will be changed for commands other than delete.
; MODIFICATION HISTORY:
;       R. Sterner, 2009 May 20
;
; Copyright (C) 2009, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	function list_insert, input, cmd, line, add, $
	  count=cnt, error=err, help=hlp
 
	if (n_params(0) lt 3) or keyword_set(hlp) then begin
	  print,' Insert a 1-d array into another 1-d array.'
	  print,' output = list_insert(input, cmd, line, [add])'
	  print,'   input = Initial 1-d array.               in'
	  print,'   cmd = Edit command:                      in'
	  print,"         'P': Preceded line by add."
	  print,"         'R': Replace line by add."
	  print,"         'F': Follow line by add."
	  print,"         'D': Delete line (add array ignored)."
	  print,'   line = Index in old (first index=0).     in'
	  print,'     This may also be a range of indices: [lo,hi].'
	  print,'   add = 1-d array to insert.               in'
	  print,'   output = Returned modified array.        out'
	  print,' Keywords:'
	  print,'   COUNT=cnt Returned number of elements in output array.'
	  print,'   ERROR=err Error flag: 0=ok.'
	  print,' Note: For a scalar out of range index the array'
	  print,'   is not changed.  For an index range the array'
	  print,'   will be changed for commands other than delete.'
	  return,''
	endif
 
	lst = n_elements(input)-1
	err = 0
 
	;-------------------------------------------------------
	;  Line or lines divides the input array into a front
	;  and tail in general.  In some cases one or the other
	;  may not exist.
	;-------------------------------------------------------
	;-------------------------------------------------------
	;  For scalar line ignore if out of range
	;-------------------------------------------------------
	if n_elements(line) eq 1 then begin
	  if (line lt 0) or (line gt lst) then begin
	    cnt = n_elements(input)	; No change.
	    return, input
	  endif 
	endif
	;-------------------------------------------------------
	;  Get front
	;-------------------------------------------------------
	hi_f = (min(line)-1)<lst	; Keep in range.
	lo_f = 0
	if hi_f lt 0 then begin
	  flag_f = 0
	endif else begin
	  flag_f = 1
	  front  = input[lo_f:hi_f]	; Front.
	  if hi_f lt lst then begin	; Anything left?
	    afront = input[hi_f+1:*]	; All the rest.
	    flag_af = 1
	  endif else begin
	    flag_af = 0			; There is no all the rest.
	  endelse
	endelse
	;-------------------------------------------------------
	;  Get tail
	;-------------------------------------------------------
	lo_t = (max(line)+1)>0		; Keep in range.
	hi_t = lst
	if lo_t gt lst then begin
	  flag_t = 0
	endif else begin
	  flag_t = 1
	  tail  = input[lo_t:hi_t]	; Tail.
	  if lo_t gt 0 then begin	; Anything left?
	    atail = input[0:lo_t-1]	; All the rest.
	    flag_at = 1
	  endif else begin
	    flag_at = 0			; There is no all the rest.
	  endelse
	endelse
 
	;-------------------------------------------------------
	;  Deal with commands
	;-------------------------------------------------------
	case strupcase(cmd) of
'D':	begin
	  ;---  Delete all  ---
	  if (flag_f eq 0) and (flag_t eq 0) then begin
	    cnt = 0
	    return, -1
	  endif
	  ;---  Delete front  ---
	  if flag_f eq 0 then begin
	    cnt = n_elements(tail)
	    return, tail
	  endif
	  ;---  Delete tail  ---
	  if flag_t eq 0 then begin
	    cnt = n_elements(front)
	    return, front
	  endif
	  ;---  Delete in-between  ---
	  output = [front,tail]
	  cnt = n_elements(output)
	  return, output
	end
'P':	begin
	  ;---  Precede front  ---
	  if flag_f eq 0 then begin
	    output = [add, input]
	    cnt = n_elements(output)
	    return, output
	  endif
	  ;---  Precede in-between  ---
	  output = [front,add]
	  if flag_af eq 1 then output=[output,afront]
	  cnt = n_elements(output)
	  return, output
	end
'F':	begin
	  ;---  Follow tail  ---
	  if flag_t eq 0 then begin
	    output = [input, add]
	    cnt = n_elements(output)
	    return, output
	  endif
	  ;---  Follow in-between  ---
	  output = [add,tail]
	  if flag_at eq 1 then output=[atail,output]
	  cnt = n_elements(output)
	  return, output
	end
'R':	begin
	  ;---  Replace all  ---
	  if (flag_f eq 0) and (flag_t eq 0) then begin
	    output = add
	    cnt = n_elements(output)
	    return, output
	  endif
	  ;---  Replace front  ---
	  if flag_f eq 0 then begin
	    output = [add,tail]
	    cnt = n_elements(output)
	    return, output
	  endif
	  ;---  Replace tail  ---
	  if flag_t eq 0 then begin
	    output = [front,add]
	    cnt = n_elements(output)
	    return, output
	  endif
	  ;---  Replace in-between  ---
	  output = [front,add,tail]
	  cnt = n_elements(output)
	  return, output
	end
else:	begin
	  print,' Error in list_insert: Unknown command: '+cmd
	  err = 1
	  return, -1
	end
	endcase
 
	end
