;-------------------------------------------------------------
;+
; NAME:
;       BASECON
; PURPOSE:
;       Convert an integer number from one base to another.
; CATEGORY:
; CALLING SEQUENCE:
;       out = basecon(in)
; INPUTS:
;       in = input as a text string or numeric value. in
;          May be an array.
; KEYWORD PARAMETERS:
;       Keywords:
;         FROM=n1    Original number base (def=10).
;           From 2 to 36.
;         TO=n2      Resulting number base (def=10).
;           From 2 to 36.
;           If n2 is 2, 8, or 16 then the native IDL formatting
;           will be used.  This can handle any integer type
;           including negative LL values.
;           If the keyword /NOIDL is given this routine will use
;           the same method as for the other bases but will be
;           limited to the value given below and no negative LL.
;         DIGITS=n   Minimum number of digits in output.
;           If result has fewer then 0s are placed on left.
;           A default number of digits is set for base 2, 8, or 16.
;           To over-ride this default set DIGITS=0.
;         GROUP=g    Number of digits to group together (def=all).
;           Spaces will be placed between groups.  Useful for
;           showing bytes or words for example.
;         /BITS Convert the input to a bits display.  Assumes
;            base 10 input,base 2 output. 0 show as . and 1 as |.
;            Each value is grouped into 8 bit bytes and have
;            extra trailing spaces added for display.
;         ERROR=err  error flag:
;           0 = ok
;           1 = input digit not 0-9 or A-Z.
;           2 = FROM base not in the range 2-36.
;           3 = TO base not in the range 2-36.
;           4 = input digit too big for FROM base.
;           5 = input number too big to handle.
;           6 = Data type not supported.
; OUTPUTS:
;       out = converted number as a text string.      out
;         If an error occurs a null string is returned.
;         Will have the same dimensions as the input.
; COMMON BLOCKS:
; NOTES:
;       Notes: maximum number base is 36.  Example:
;         out = basecon('1010',from=2,to=16) gives out='A'.
;         May give an array of input values.
;         Can handle negative 16 and 32 bit integers.
;         May group digits in an input string.
;         Maximum positive integer that can be handled is
;         9223372036854775807 = 2LL^63-1
; MODIFICATION HISTORY:
;       R. Sterner, 5 Mar, 1993
;       R. Sterner, 30 Sep, 1993 --- Added DIGITS keyword.
;       R. Sterner, 1999 Jun 03 --- Added GROUP keyword.
;       R. Sterner, 2002 Jun 13 --- Extended range by using LONG64.
;       R. Sterner, 2005 Nov 21 --- Supported negative integers.
;       R. Sterner, 2005 Nov 21 --- Allowed spaces in input string.
;       R. Sterner, 2008 Dec 30 --- Fixed problem with string input.
;       R. Sterner, 2009 Nov 17 --- Fixed loop limit.
;       R. Sterner, 2010 Apr 30 --- Converted arrays from () to [].
;       R. Sterner, 2011 Jun 27 --- Allowed byte type.
;       R. Sterner, 2011 Jun 27 --- Fixed to handle ULL type better (< limit).
;       R. Sterner, 2011 Jun 28 --- Added IDL format code handling for to=2,8,
;       or 16. Can now do any integer including LONG64 both positive
;       and negative.
;       R. Sterner, 2011 Jun 30 --- Added keyword /BITS.
;       R. Sterner, 2011 Jul 01 --- Output reformed to match input shape.
;
; Copyright (C) 1993, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
	function basecon, in0, from=from, to=to, error=err, $
	  digits=digits, group=g, noidl=noidl, bits=bits, help=hlp
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Convert an integer number from one base to another.'
	  print,' out = basecon(in)'
	  print,'   in = input as a text string or numeric value. in'
          print,'      May be an array.'
 	  print,'   out = converted number as a text string.      out'
	  print,'     If an error occurs a null string is returned.'
          print,'     Will have the same dimensions as the input.'
 	  print,' Keywords:'
 	  print,'   FROM=n1    Original number base (def=10).'
	  print,'     From 2 to 36.'
	  print,'   TO=n2      Resulting number base (def=10).'
	  print,'     From 2 to 36.'
          print,'     If n2 is 2, 8, or 16 then the native IDL formatting'
          print,'     will be used.  This can handle any integer type'
          print,'     including negative LL values.'
          print,'     If the keyword /NOIDL is given this routine will use'
          print,'     the same method as for the other bases but will be'
          print,'     limited to the value given below and no negative LL.'
	  print,'   DIGITS=n   Minimum number of digits in output.'
	  print,'     If result has fewer then 0s are placed on left.'
          print,'     A default number of digits is set for base 2, 8, or 16.'
          print,'     To over-ride this default set DIGITS=0.'
	  print,'   GROUP=g    Number of digits to group together (def=all).'
	  print,'     Spaces will be placed between groups.  Useful for'
	  print,'     showing bytes or words for example.'
          print,'   /BITS Convert the input to a bits display.  Assumes'
          print,'      base 10 input,base 2 output. 0 show as . and 1 as |.'
          print,'      Each value is grouped into 8 bit bytes and have'
          print,'      extra trailing spaces added for display.'
	  print,'   ERROR=err  error flag:'
	  print,'     0 = ok'
	  print,'     1 = input digit not 0-9 or A-Z.'
	  print,'     2 = FROM base not in the range 2-36.'
	  print,'     3 = TO base not in the range 2-36.'
	  print,'     4 = input digit too big for FROM base.'
	  print,'     5 = input number too big to handle.'
	  print,'     6 = Data type not supported.'
	  print,' Notes: maximum number base is 36.  Example:'
	  print,"   out = basecon('1010',from=2,to=16) gives out='A'."
	  print,'   May give an array of input values.'
	  print,'   Can handle negative 16 and 32 bit integers.'
	  print,'   May group digits in an input string.'
          print,'   Maximum positive integer that can be handled is'
          print,'   9223372036854775807 = 2LL^63-1'
	  return,''
	endif
 
	nin = n_elements(in0)   ; # of elements in input.
        dims = size(in0,/dim)   ; Dimensions of input.
	out = strarr(nin)       ; Output string array.
        gsep = '   '            ; Separator between array elements.
 
        ;-----------------------------------------------
        ;  Deal with /BITS
        ;-----------------------------------------------
        if keyword_set(bits) then begin
          from = 10             ; Assume input base 10.
          to = 2                ; Want binary output.
          g = 8                 ; Group into 8 bit bytes.
        endif
 
        ;-----------------------------------------------
	;  Make sure FROM and TO defined and valid
        ;-----------------------------------------------
        ;---  FROM  ---
	if n_elements(from) eq 0 then from=10		; Default = base 10.
	if (from lt 2) or (from gt 36) then begin
	  err = 2
	  return, ''
	endif
        ;---  TO  ---
	if n_elements(to) eq 0 then to=10		; Default = base 10.
	if (to lt 2) or (to gt 36) then begin
	  err = 3
	  return, ''
	endif
        ;---  Base 2, 8, or 16  ---
        flag = 0                        ; Handle internally.
        if from eq 10 then begin        ; If input in base 10 then handle these
          if to eq  2 then flag=1       ; cases using IDL format codes.
          if to eq  8 then flag=3       ; flag=n where base=2^n.
          if to eq 16 then flag=4
        endif
        if keyword_set(noidl) then flag=0               ; Force internal.
 
        ;------------------------------------------------------------------
        ;  Loop over input values
        ;------------------------------------------------------------------
	for j = 0L, nin-1 do begin
 
	  in = in0[j]
 
          ;-----------------------------------------------
          ;  Handle internally
          ;-----------------------------------------------
          if flag eq 0 then begin
 
            ;-----------------------------------------------
	    ;  Deal with negative values
            ;-----------------------------------------------
	    typ = datatype(in)
	    if typ eq 'BYT' then in=in+0U       ; Force non-byte.
	    if typ ne 'STR' then  begin
	      if in lt 0 then begin
	        if typ eq 'INT' then in=0U+in
	        if typ eq 'LON' then in=0UL+in
	        if typ eq 'LLO' then begin
	          print,' Error in basecon: Long64<0 not supported with /NOIDL.'
	          err = 6
	          return,''
	        endif
	      endif
	    endif
 
            ;-----------------------------------------------
	    ;  Prepare text string
            ;-----------------------------------------------
	    t = strtrim(strupcase(in),2)	; Start with all upper case.
	    t = strcompress(t,/rem)		; Allow spaces in input.
	    b = byte(t)			; Convert to ascii codes.
            ;-----------------------------------------------
	    ;  Invalid error check
            ;-----------------------------------------------
	    w = where(b lt 48, cnt)		; Any digit < '0' ?
	    if cnt gt 0 then begin
	      err = 1
	      return, ''
	    endif
	    w = where((b gt 57) and (b lt 65), cnt) ; Digit between '9' and 'A'?
	    if cnt gt 0 then begin
	      err = 1
	      return, ''
	    endif
	    w = where(b gt 90, cnt)		; Any digit > 'Z' ?
	    if cnt gt 0 then begin
	      err = 1
	      return, ''
	    endif
 
            ;-----------------------------------------------
	    ;  Drop alphabetic digits down to range
            ;-----------------------------------------------
	    w = where(b gt 57, cnt)		; Any alphabetic digits?
	    if cnt gt 0 then b[w] = b[w] - 7	; Yes, fix them.
 
            ;-----------------------------------------------
	    ;  Now drop all digits to correct values
            ;-----------------------------------------------
	    b = b - 48				; Ascii code of '0' is 48.
 
            ;-----------------------------------------------
	    ;  Check if digits valid for specified base
            ;-----------------------------------------------
	    w = where(b gt (from-1), cnt)
	    if cnt gt 0 then begin
	      err = 4
	      return, ''
 	    endif
 
            ;-----------------------------------------------
	    ;  Convert input number to base 10
            ;-----------------------------------------------
;	    ten=long64(total(double(b*(long64(from)^reverse(lindgen(n_elements(b)))))))
	    ten=long64(total(/integer,b*(long64(from)^reverse(lindgen(n_elements(b))))))
	    if ten lt 0 then begin
	      err = 5
	      return, ''
	    endif
 
            ;-----------------------------------------------
	    ;  Find digits in base TO
            ;-----------------------------------------------
	    d = [0]			; Digits array seed.
	    while ten ge 1 do begin	; Pick off digits in reverse order.
	      d = [d, ten mod to]
	      ten = ten/to
	    endwhile
	    if n_elements(d) gt 1 then d = reverse(d[1:*])
 
            ;-----------------------------------------------
	    ;  Make ascii codes for output number
            ;-----------------------------------------------
	    w = where(d gt 9, cnt)		; Look for alphabetic digits.
	    if cnt gt 0 then d[w] = d[w] + 7	; Handle them.
	    d = d + 48				; Convert to ascii codes.
	    t = string(byte(d))			; Convert to a string.
 
          ;-----------------------------------------------
          ;  Handle using IDL format codes
          ;-----------------------------------------------
          endif else begin
            case flag of
1:            t = strtrim(string(in,form='(B)'),2)
3:            t = strtrim(string(in,form='(O)'),2)
4:            t = strtrim(string(in,form='(Z)'),2)
            endcase
            if n_elements(digits) eq 0 then begin
              tmp = datatype(in,integer_bits=nbits)
              digits = ceil(nbits/float(flag))
            endif
 
          endelse
 
          ;-----------------------------------------------
	  ;  Handle minimum digits
          ;-----------------------------------------------
	  if keyword_set(digits) then begin
	    len = strlen(t)
	    add = digits - len			; # 0s needed.
	    if add gt 0 then begin
	      t = string(bytarr(add)+48B)+t	; Add 0s on left.
	    endif
	  endif
 
          ;-----------------------------------------------
	  ;  Handle grouped digits
          ;-----------------------------------------------
	  if n_elements(g) gt 0 then begin
	    if g gt 0 then begin
	      b = byte(t)			; Convert string to byte array.
	      n = n_elements(b)			; Number of digits.
	      rem = n mod g			; Remainder after grouped.
	      if rem ne 0 then b=[bytarr(g-rem)+48B,b]  ; Pad with 0s on left.
	      t = string((byte(string(reform(b,g,n_elements(b)/g))+' '))[0:*])
	    endif
	  endif
 
          ;-----------------------------------------------
          ;  Handle /BITS
          ;-----------------------------------------------
          if keyword_set(bits) then begin
            t = stress(t,'R',0,'0','.')
            t = stress(t,'R',0,'1','|')
          endif
 
	  err = 0
	  out[j] = t
 
	endfor ; j
        ;------------------------------------------------------------------
        ;  End of loop
        ;------------------------------------------------------------------
 
        out = out + gsep          ; Extra trailing space.
        out = reform(out,dims>1)  ; Original dimensions.
	if n_elements(out) eq 1 then out=out[0]
	return, out
 
	end
