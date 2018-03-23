;-------------------------------------------------------------
;+
; NAME:
;       LLSIGNED
; PURPOSE:
;       Give signed lat or long given deg min sec (dms) text.
; CATEGORY:
; CALLING SEQUENCE:
;       v = llsigned(txt)
; INPUTS:
;       txt = text string with lat or long. in
; KEYWORD PARAMETERS:
; OUTPUTS:
;       v = returned signed value.          out
; COMMON BLOCKS:
; NOTES:
;       Note: lat or long may have N, S, E, or W
;         in the string, case ignored.  If no such letter
;         then the string is assumed to be signed already.
;         Some example inputs:
;         '-33 27 15.2','33 27 15.2 S','S33 27 15.2','S 33 27 15.2'
;         '-33.454222','33.454222 S','33.454222S','33S 27 15.2'
;         all give the same result.
; MODIFICATION HISTORY:
;       R. Sterner, 2004 Sep 08
;       R. Sterner, 2006 Aug 29 --- More help.  Upgraded for D M S form.
;       R. Sterner, 2008 Mar 21 --- Handled units better.
;       R. Sterner, 2008 May 06 --- Fixed a few problems.
;       R. Sterner, 2010 May 03 --- Now allows arrays.
;       R. Sterner, 2012 Jan 20 --- Return a scalar for a single value.
;
; Copyright (C) 2004, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
	function llsigned, txt0, help=hlp
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Give signed lat or long given deg min sec (dms) text.'
	  print,' v = llsigned(txt)'
	  print,'   txt = text string with lat or long. in'
	  print,'   v = returned signed value.          out'
	  print,' Note: lat or long may have N, S, E, or W'
	  print,'   in the string, case ignored.  If no such letter'
	  print,'   then the string is assumed to be signed already.'
	  print,'   Some example inputs:'
	  print,"   '-33 27 15.2','33 27 15.2 S','S33 27 15.2','S 33 27 15.2'"
	  print,"   '-33.454222','33.454222 S','33.454222S','33S 27 15.2'"
	  print,'   all give the same result.'
	  return,''
	endif
 
	;--------------------------------------------------
	;  Work in upper case
	;--------------------------------------------------
        txt = strupcase(strtrim(txt0,2))  ; Uppercase, no space on ends.
        ntxt = n_elements(txt)
        deg = dblarr(ntxt)                ; Results in deg.
 
	;--------------------------------------------------
        ;  Loop over array
	;--------------------------------------------------
        for j=0, ntxt-1 do begin
	  t = txt[j]
	  sn = 1.
 
	  ;--------------------------------------------------
	  ;  Make a cleaned copy of the input
	  ;    Keep only the numbers.
	  ;--------------------------------------------------
	  t2 = ''			  ; Cleaned copy.
	  t3 = t
	  t3 = stress(t3,'D',0,'N')       ; Delete N.
	  t3 = stress(t3,'D',0,'E')       ; Delete E.
	  t3 = stress(t3,'D',0,'W')       ; Delete W.
	  t3 = stress(t3,'D',0,'S')       ; Delete S.
	  n = nwrds(t)			  ; Number of words.
	  for i=0,n-1 do begin		  ; Loop over words.
	    wd = getwrd(t3,i)		  ; i'th word.
	    c1 = strmid(wd,0,1)		  ; 1st char.
	    if c1 eq '-' then begin
	      t2 = t2 + wd + ' '
	    endif else begin
	      if isnumber(c1) then t2=t2+wd+' '
	    endelse
	  endfor
 
	  ;--------------------------------------------------
	  ;  Process any N, E, W, S letters
	  ;    Set sign based on letter.
	  ;    N and E will not change the assumed sign
	  ;    from +1 so ignore them.
	  ;--------------------------------------------------
	  ;---  Check if using deg, min, sec or d, m, s  ----
	  flag = 0			   ; Assume no deg, min, sec (d,m,s).
	  if strpos(t,'D') ge 0 then flag=1; Using deg (d), min (m) (maybe sec).
	  if strpos(t,'M') ge 0 then flag=1
 
	  ;---------------------------------------
	  ;  Using units in the string
	  ;  (like '10 deg 20 min 30 sec').
	  ;  If units are being used there will be a D
	  ;      and/or M used.  In this case W or S should
	  ;      be first or last.  S is the hardest case:
	  ;      '10 d 20 m 30 s S' or '10d 20m S'.
	  ;      If there are 3 numbers then if there is a
	  ;      second S it means south.  Else assume 2 or
	  ;      1 number(s) and assume the S means south.
	  ;---------------------------------------
	  if flag eq 1 then begin  ; Was using units.  Check only first or last.
	    c1 = strmid(t,0,1)		            ; First char.
	    c2 = strmid(t,0,1,/rev)	            ; Last char.
	    if (c1 eq 'W') or (c2 eq 'W') then begin ; W = -1.
	      sn = -1.
	      t = stress(t,'D',0,'W')		    ; Delete W.
	    endif else begin ; Not W.		    ; S.
	      if c1 eq 'S' then begin
	        sn = -1.			    ; S is first char = -1.
	      endif else if c2 eq 'S' then begin    ; S is last char.
	        nt2 = nwrds(t2)			    ; # of numbers.
	        if nt2 eq 3 then begin              ; 3 numbers.
		  ; # if there are 2 Ss then -1.
	          if strpos(t,'S',1,/reverse_search, $
	            /reverse_offset) ge 0 then sn = -1.
	        endif else begin                    ; Not 3 numbers (assume 2).
	          ; # Assume -1.
	          sn = -1.
	        endelse
	      endif                                 ; Last char is S.
	    endelse                                 ; Not W.
	  ;---------------------------------------
	  ;  Not using units in the string.
	  ;    Only S and W change sign.
	  ;---------------------------------------
	  endif else begin ; flag eq 1.
	    if strpos(t,'S') ge 0 then sn=-1.
	    if strpos(t,'W') ge 0 then sn=-1.
	  endelse
 
	  deg[j] = sn*dms2d(t2)
 
        endfor ; i
 
        if n_elements(deg) eq 1 then deg=deg[0]     ; Scalar if single value.
 
	return, deg
 
	end
 
