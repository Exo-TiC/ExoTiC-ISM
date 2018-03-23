;-------------------------------------------------------------
;+
; NAME:
;       TXT_KEYSECTION
; PURPOSE:
;       Extract a section of a text array between given keys.
; CATEGORY:
; CALLING SEQUENCE:
;       txt_keysection, txt
; INPUTS:
; KEYWORD PARAMETERS:
;       Keywords:
;         OUT=txt2 Return section in txt2.  Using this keyword
;           the original array, txt, is not modified.
;         AFTER=k1  Section to extract starts after this key.
;           Uses first match found.
;         BEFORE=k2 Section to extract ends before this key.
;           A key is text that matches an element of txt.
;           Uses first match after the first AFTER key.
;         INDICES=ind Returned indices of matched keys.
;           The matched keys are not returned by OUT=txt.
;         /MATCH_CASE means match case, else case is ignored.
;         /INVERSE  Return all lines but the section between
;           the AFTER and BEFORE keys (keys not included).
;              Or
;         INVERSE=itxt  Section lines returned in txt or txt2,
;           and the remaining lines returned in itxt.
;           So one call returns both section lines and all the rest.
;         COUNT=cnt Number of elements returned.
;         /QUIET inhibit some error messages.
;         ERROR=err Error flag: 0=ok.
; OUTPUTS:
;       txt = Text array to modify.        in, out
; COMMON BLOCKS:
; NOTES:
;       Notes: The text array txt is modified if the given
;       keys are found.  An example.  Let txt be:
;         Line 1
;         Line 2
;         Line 3
;         <windows_start>
;         Line 4
;         Line 5
;         Line 6
;         <windows_end>
;         Line 7
;       txt_keysection,txt,after='<windows_start>', $
;         before='<windows_end>'
;         Returns lines 4,5,6.
;       txt_keysection,txt,after='<windows_start>', $
;         before='<windows_end>',/inverse
;         Returns lines 1,2,3,7.
;       txt_keysection,txt,after='<windows_start>', $
;         before='<windows_end>',inverse=txt2
;         Returns lines 4,5,6 in txt, lines 1,2,3,7 in txt2.
; MODIFICATION HISTORY:
;       R. Sterner, 2006 Sep 06
;       R. Sterner, 2008 Jan 21 --- Added OUT=txt2.
;       R. Sterner, 2008 Oct 21 --- Allowed null section (but count=0).
;       R. Sterner, 2009 Jan 07 --- Forced BEFORE key to be after AFTER.
;       R. Sterner, 2009 Jan 07 --- Returned indices of matched keys.
;       R. Sterner, 2010 Aug 18 --- Converted arrays from () to [].
;       R. Sterner, 2011 May 27 --- Allowed INVERSE=txt2.  Simplified code.
;       R. Sterner, 2011 May 29 --- Initialized txtout to ''.
;       R. Sterner, 2011 May 29 --- Now returns inverse if wanted even if err.
;
; Copyright (C) 2006, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro txt_keysection, txt, after=k1, before=k2, match_case=mcase, $
	  inverse=inv, error=err, count=cnt, quiet=quiet, $
	  out=txtout, indices=ind, help=hlp
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Extract a section of a text array between given keys.'
	  print,' txt_keysection, txt'
	  print,'   txt = Text array to modify.        in, out'
	  print,' Keywords:'
	  print,'   OUT=txt2 Return section in txt2.  Using this keyword'
	  print,'     the original array, txt, is not modified.'
	  print,'   AFTER=k1  Section to extract starts after this key.'
	  print,'     Uses first match found.'
	  print,'   BEFORE=k2 Section to extract ends before this key.'
	  print,'     A key is text that matches an element of txt.'
	  print,'     Uses first match after the first AFTER key.'
	  print,'   INDICES=ind Returned indices of matched keys.'
	  print,'     The matched keys are not returned by OUT=txt.'
	  print,'   /MATCH_CASE means match case, else case is ignored.'
	  print,'   /INVERSE  Return all lines but the section between'
	  print,'     the AFTER and BEFORE keys (keys not included).'
          print,'          Or'
          print,'   INVERSE=itxt  Section lines returned in txt or txt2,'
          print,'     and the remaining lines returned in itxt.'
          print,'     So one call returns both section lines and all the rest.'
	  print,'   COUNT=cnt Number of elements returned.'
	  print,'   /QUIET inhibit some error messages.'
	  print,'   ERROR=err Error flag: 0=ok.'
	  print,' Notes: The text array txt is modified if the given'
	  print,' keys are found.  An example.  Let txt be:'
	  print,'   Line 1'
	  print,'   Line 2'
	  print,'   Line 3'
	  print,'   <windows_start>'
	  print,'   Line 4'
	  print,'   Line 5'
	  print,'   Line 6'
	  print,'   <windows_end>'
	  print,'   Line 7'
	  print," txt_keysection,txt,after='<windows_start>', $"
	  print,"   before='<windows_end>'"
	  print,'   Returns lines 4,5,6.'
	  print," txt_keysection,txt,after='<windows_start>', $"
	  print,"   before='<windows_end>',/inverse"
	  print,'   Returns lines 1,2,3,7.'
	  print," txt_keysection,txt,after='<windows_start>', $"
	  print,"   before='<windows_end>',inverse=txt2"
	  print,'   Returns lines 4,5,6 in txt, lines 1,2,3,7 in txt2.'
	  return
	end
 
	;------------------------------------------------------------
	;  Check for needed parameters
	;------------------------------------------------------------
	err = 0
	cnt = 0
        txtout = ''
	if n_elements(k1) eq 0 then begin
	  print,' Error in txt_keysection: Must give AFTER key.'
	  err = 1
	  return
	endif
	if n_elements(k2) eq 0 then begin
	  print,' Error in txt_keysection: Must give BEFORE key.'
	  err = 1
	  return
	endif
 
	;------------------------------------------------------------
	;  Deal with case
	;------------------------------------------------------------
	if keyword_set(mcase) then begin
	  txt2 = strtrim(txt,2)
	  k12 = strtrim(k1,2)
	  k22 = strtrim(k2,2)
	endif else begin
	  txt2 = strtrim(strupcase(txt),2)
	  k12 = strtrim(strupcase(k1),2)
	  k22 = strtrim(strupcase(k2),2)
	endelse
 
	;------------------------------------------------------------
	;  Locate keys
	;    Use first BEFORE key found and first AFTER key found
	;    after the first BEFORE key.
	;------------------------------------------------------------
	w1 = (where(txt2 eq k12, c1))[0]
	if c1 eq 0 then begin
	  if not keyword_set(quiet) then $
	    print,' Error in txt_keysection: AFTER key not found.  Was '+k1
	  err = 1
	endif
	w2 = where(txt2 eq k22, c2)	; Find all BEFORE keys.
	if c2 eq 0 then begin
	  if not keyword_set(quiet) then $
	    print,' Error in txt_keysection: BEFORE key not found.  Was '+k2
	  err = 1
	endif
	w = where(w2 gt w1,c2)		; Want one following AFTER key.
	if c2 eq 0 then begin
	  if not keyword_set(quiet) then begin
	    print,' Error in txt_keysection: BEFORE key not after AFTER key.'
	    print,' BEFORE = '+k1+'  AFTER = '+k2
          endif
	  err = 1
	endif

        if err ne 0 then begin             ; Return if error.
          if arg_present(inv) then inv=txt ; Return inverse if requested.
          return
        endif

	w2 = w2[w[0]]			; Grab 1st in new list.
 
	;------------------------------------------------------------
        ;  Flag parts of input array
        ;    Non-section lines = 0
        ;    Section keys = 1
        ;    Section lines = 2 if any
	;------------------------------------------------------------
	n = n_elements(txt)
	flag = bytarr(n)                ; Set up a flag for each input line.
	flag[w1:w2] = 1                 ; Set all section lines to 1.
        if (w1+1) le (w2-1) then $      ; Set any section non-key lines to 2.
          flag[w1+1:w2-1] = 2

	;------------------------------------------------------------
        ;  Find parts
        ;    txt0 = Non-section lines
        ;    txt2 = Section lines
	;------------------------------------------------------------
        w = where(flag eq 0, cnt)       ; Find non-section lines.
        if cnt gt 0 then txt0=txt[w] else txt0=''
        w = where(flag eq 2, cnt)       ; Find section lines.
        if cnt gt 0 then txt2=txt[w] else txt2=''

	;------------------------------------------------------------
        ;  Return requested parts
        ;
        ;  Normal:     txt=txt2 or txtout=txt2  INV_FLAG=0
        ;  /INVERSE:   txt=txt0 or txtout=txt0  INV_FLAG=1
        ;  INVERSE=inv:                         INV_FLAG=2
        ;              txt=txt2 or txtout=txt2
        ;              and inv=txt0
	;------------------------------------------------------------
        inv_flag = 0                            ; Inverse requested?
        if keyword_set(inv) then inv_flag=1     ; Set if /INVERSE.
        if arg_present(inv) then inv_flag=2     ; Set if INVERSE=inv.
        ;---  return requested section  ---
        case inv_flag of
0:      if arg_present(txtout) then txtout=txt2 else txt=txt2
1:      if arg_present(txtout) then txtout=txt0 else txt=txt0
2:      begin
          if arg_present(txtout) then txtout=txt2 else txt=txt2
          inv = txt0
        end
        endcase

	ind = [w1,w2]                   ; Section indices.
 
	return
 
	end
