;-------------------------------------------------------------
;+
; NAME:
;       STRESS
; PURPOSE:
;       String edit by sub-string. Precede, Follow, Delete, Replace.
; CATEGORY:
; CALLING SEQUENCE:
;       new = stress(old,cmd,n,oldss,newss,ned)
; INPUTS:
;       old = string to edit.                               in
;       cmd = edit command:                                 in
;         'P' = precede.
;         'F' = follow.
;         'D' = delete.
;         'R' = replace.
;       n = occurrence number to process (0 = all).         in
;       oldss = reference substring.                        in
;       oldss may have any of the following forms:
;         1. s	  a single substring.
;         2. s...    start at substring s, end at end of string.
;         3. ...e    from start of string to substring e.
;         4. s...e   from subs s to subs e.
;         5. ...     entire string.
;       newss = substring to add. Not needed for 'D'        in
; KEYWORD PARAMETERS:
; OUTPUTS:
;       ned = number of occurrences actually changed.       out
;       new = resulting string after editing.               out
; COMMON BLOCKS:
; NOTES:
;       Notes: oldss and newss may be arrays.
; MODIFICATION HISTORY:
;       Written by R. Sterner, 6 Jan, 1985.
;       Johns Hopkins University Applied Physics Laboratory.
;       RES --- 23 May, 1988 fixed a bug in SSTYP = 2.
;       Converted to SUN 13 Aug, 1989 --- R. Sterner. (FOR loop change).
;       --- 8 Dec, 1992 added recursion so that OLDSS and NEWSS may be arrays
;       T.J.Harris, University of Adelaide.
;       R. Sterner, 2010 Apr 29 --- Converted arrays from () to [].
;       R. Sterner, 2010 Dec 20 --- Added some comments.
;       R. Sterner, 2013 Dec 12 --- Now checks occurrence number.
;       R. Sterner, 2013 Dec 12 --- Added error flag.
;       R. Sterner, 2013 Dec 12 --- Now input may be an array.
;       R. Sterner, 2013 Dec 12 --- Added /DOTS keyword.
;
; Copyright (C) 1985, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
	function stress,strng,cmdx,n,old_in,new_in,ned, error=err, $
          dots=dots, help=hlp
 
	if (n_params(0) lt 3) or keyword_set(hlp) then begin
	  print,' String edit by sub-string. Precede, Follow, Delete, Replace.'
	  print,' new = stress(old,cmd,n,oldss,newss,ned)'
	  print,'   old = string to edit.                               in'
          print,'     May be an array.'
	  print,'   cmd = edit command:                                 in'
	  print,"     'P' = precede."
	  print,"     'F' = follow."
	  print,"     'D' = delete."
	  print,"     'R' = replace."
	  print,'   n = occurrence number to process (0 = all).         in'
	  print,'   oldss = reference substring.                        in'
	  print,'   oldss may have any of the following forms:'
	  print,'     1. s	  a single substring.'
	  print,'     2. s...    start at substring s, end at end of string.'
	  print,'     3. ...e    from start of string to substring e.'
	  print,'     4. s...e   from subs s to subs e.'
	  print,'     5. ...     entire string.'
	  print,"   newss = substring to add. Not needed for 'D'        in"
	  print,'   ned = number of occurrences actually changed.       out'
	  print,'   new = resulting string after editing.               out'
          print,'         Original string if an error.'
          print,' Keywords:'
          print,'   ERROR=err, Error flag, 0=ok.'
          print,'     Original string returned on error.'
          print,'   /DOTS means treat ... in oldss as literal dots.'
          print,' Notes: The input string to edit may be an array of strings.'
          print,'   The same edit will be done to each element for an input'
          print,'   array.  The old and new substrings (oldss and newss) may'
          print,'   be arrays.  If they are arrays then oldss is replaced'
          print,'   by newss element by element if they are the same size.'
          print,'   The last element of newss is reused if newss is smaller'
          print,'   then oldss.  The number edited, ned will be an array if'
          print,'   the input was an array'
	  return, ''
	endif

        ;------------------------------------------------------
        ;  Handle array of strings to edit
        ;------------------------------------------------------
        n_strng = n_elements(strng)     ; # elements in input.
        if n_strng gt 1 then begin      ; If an array ...
          strng_out = strarr(n_strng)   ; Returned edited strings.
          nedout = intarr(n_strng)      ; Number of edits for each string.
          for i=0L, n_strng-1L do begin ; Loop over array elements.
            txt = stress(strng[i],cmdx,n,old_in,new_in,nedt,$  ; Edit next.
              err=err,dots=dots)
            if err ne 0 then return,strng ; Abort on any errors.
            strng_out[i] = txt          ; Save edited element.
            nedout[i] = nedt            ; # of edits for element.
          endfor
          ned = nedout                  ; Return # of edits.
          return, strng_out             ; Return edited array.
        endif


        err = 0

        ;---  Check if occurrence number given correctly  ---
        if n_elements(n) ne 1 then begin
          print, ' Error in stress: Occurrence number, n, must be a scalar.'
          err = 1
          return, strng
        endif
 
	;--- If old_in an array then do the first element then call recursively
	old = old_in[0]
	if (n_elements(new_in) Gt 0) then new = new_in[0]
 
        ;---  Determine old substring form as listed in the help text above  ---
	cmd = strupcase(cmdx)                   ; Upper case command.
	pdot = strpos(old,'...')                ; Position of any ...
	ssl = strlen(old)                       ; Length of oldss.
	sstyp = 0                               ; oldss form unknown.
	pos1 = -1                               ; ?
	pos2 = -1                               ; ?
	rstr = strng                            ; Working copy of string to edit.
	if (pdot eq -1) then sstyp = 1                  ; s 
	if (pdot gt 0) and (pdot eq ssl-3) then sstyp=2 ; s...
	if (pdot eq 0) and (ssl gt 3) then sstyp=3      ; ...e
	if (pdot gt 0) and (pdot lt ssl-3) then sstyp=4 ; s...e
	if (pdot eq 0) and (ssl eq 3) then sstyp=5      ; ...

        ;---  Treat dots (...) as literal if set  ---
        if keyword_set(dots) then sstyp=1       ; Simple substring.

	ned = 0		; Number of occurrences actually changed.
 
 
	case sstyp of                   ; Pick off start and end of subnstring.
1:	  begin                                 ; s
	    s = old
	    e = ''
	  end
2:	  begin                                 ; s...
	    s = strsub(old,0,ssl-4)
	    e = ''
    	  end
3:  	  begin                                 ; ...e
	    s = ''
	    e = strsub(old,3,ssl-1)
	  end
4:  	  begin                                 ; s...e
	    s = strsub(old,0,pdot-1)
	    e = strsub(old,pdot+3,ssl-1)
	  end
5:  	  begin                                 ; ...
	    s = ''
	    e = ''
	  end
else: 	  begin
            print, ' Error in stress: Error in oldss, unknown form.'
            err = 1
            return, rstr
          end
	endcase
 
 
;---------------  Find substring # N start  ---------------
	pos = -1
	nfor = n>1
loop:
	for i = 1, nfor do begin
	  pos = pos + 1
	  case sstyp of
    1:      pos = strpos(rstr,s,pos)    ; s
    2:      pos = strpos(rstr,s,pos)    ; s...
    3:      pos = strpos(rstr,e,pos)    ; ...e
    4:      pos = strpos(rstr,s,pos)    ; s...e
    5:      pos = 0                     ; ...
	  endcase
  	  if pos lt 0 then goto, done
	endfor
 
;----------  Find substring # N END  ----------------
    	case sstyp of
1:  	  begin                         ; s
	    pos1 = pos
	    pos2 = pos + strlen(s) - 1
	  end
2:  	  begin                         ; s...
	    pos1 = pos
	    pos2 = strlen(rstr) - 1
	  end
3:  	  begin                         ; ...e
	    pos1 = 0
	    pos2 = pos + strlen(e) - 1
	  end
4:  	  begin                         ; s...e
	    pos1 = pos
	    pos2 = strpos(rstr,e,pos+1)
	    if (pos2 lt 0) then goto, done
	    pos2 = pos2 + strlen(e) - 1
	  end
5:  	  begin                         ; ...
	    pos1 = 0
	    pos2 = strlen(rstr) - 1
	  end
	endcase
 
;------------  edit string  --------------
    	case cmd of
'P':  	  begin
	    rstr = strep(rstr,cmd,pos1,new)
	    pos = pos + strlen(new)
	  end
'F':  	  begin
	    rstr = strep(rstr,cmd,pos2,new)
	    pos = pos + strlen(new)
	  end
'R':  	  begin
	    rstr = strep(rstr,'D',pos1,pos2-pos1+1)
	    if (pos1 gt 0) then $
	      rstr = strep(rstr,'F',pos1-1,new)
	    if (pos1 eq 0) then $
	      rstr = strep(rstr,'P',0,new)
	    pos = pos + strlen(new) - 1
	  end
'D':  	  begin
	    rstr = strep(rstr,cmd,pos1,pos2-pos1+1)
	    pos = pos - 1
	  end
else: 	  begin
	    print, 'Error in stress: unknown command.  Given command: '+cmd
            err = 1
	    return,rstr
	  end
endcase
 
	ned = ned + 1
	if sstyp eq 5 then return,rstr
	if n eq 0 then goto, loop
 
done:
 
	;--- if old_in an array then do the first element then call recursively
	;--- and accumulate the results
	if (n_elements(old_in) gt 1) then begin	;call again until done all
		old = old_in[1:*]
		if (n_elements(new_in) gt 1) then new = new_in[1:*]
		tmp = 0
		rstr = stress(rstr,cmdx,n,old,new,tmp,err=err)
		ned = ned+tmp
	endif
	return, rstr
	end
