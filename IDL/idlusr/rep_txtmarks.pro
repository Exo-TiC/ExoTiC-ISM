;-------------------------------------------------------------
;+
; NAME:
;       REP_TXTMARKS
; PURPOSE:
;       Replace marker strings in a text array.
; CATEGORY:
; CALLING SEQUENCE:
;       rep_txtmarks, txt, s
; INPUTS:
;       s = Structure with replacement strings.  in
; KEYWORD PARAMETERS:
;       Keywords:
;         DELIMITER=del Delimiter string (def='$$').
; OUTPUTS:
;       txt = Text array to edit.                in, out
; COMMON BLOCKS:
; NOTES:
;       Notes: Lines in the text array may contain marker strings
;         to be replaced by specified values.  For example:
;            Date = $$date$$, Temperature = $$TEMP$$
;         could be a line in the text array.
;         The given structure, s, might contain the tags DATE
;         and TEMP with the current values.  The values from the
;         structure will replace the marker strings (including the
;         delmiters).  The tag in the marker string must match a
;         tag in the structure or it will not be changed.
;         Valid marker strings will be replaced from left to right
;         in each line, consuming the delimiters that go with them.
;         Case is ignored for the tag names in the marker strings.
; MODIFICATION HISTORY:
;       R. Sterner, 2009 May 28
;       R. Sterner, 2009 Jun 01 --- Handled the case when tag not found.
;       R. Sterner, 2010 May 07 --- Improved one line description.
;       R. Sterner, 2010 Jul 20 --- Added rep_marked_lines.
;
; Copyright (C) 2009, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro rep_txtmarks, txt, s, delimiter=del0, help=hlp
 
	if (n_params(0) lt 2) or keyword_set(hlp) then begin
	  print,' Edit a text array by replacing marker strings.'
	  print,' rep_txtmarks, txt, s'
	  print,'   txt = Text array to edit.                in, out'
	  print,'   s = Structure with replacement strings.  in'
	  print,' Keywords:'
	  print,"   DELIMITER=del Delimiter string (def='$$')."
	  print,' Notes: Lines in the text array may contain marker strings'
	  print,'   to be replaced by specified values.  For example:'
	  print,'      Date = $$date$$, Temperature = $$TEMP$$'
	  print,'   could be a line in the text array.'
	  print,'   The given structure, s, might contain the tags DATE'
	  print,'   and TEMP with the current values.  The values from the'
	  print,'   structure will replace the marker strings (including the'
	  print,'   delmiters).  The tag in the marker string must match a'
	  print,'   tag in the structure or it will not be changed.'
	  print,'   Valid marker strings will be replaced from left to right'
	  print,'   in each line, consuming the delimiters that go with them.'
	  print,'   Case is ignored for the tag names in the marker strings.'
          print,'   As a special case, entire lines may be replaced by one or'
          print,'   more lines.  The marker string must be the only item on'
          print,'   the line for this case.  The replacement values in the'
          print,'   structure may be scalars or arrays.  Line replacement'
          print,'   is done first, and then in line subsitution.  So the'
          print,'   the inserted lines may have markers in them if needed.'
	  return
	endif
 
	;---------------------------------------------------------
	;  Deal with delimiter
	;
	;  Default delimiter is $$.
	;  Add escape characters to each delimiter string
	;  character.  They are needed for special characters
	;  (like $) and harmless for any others.
	;---------------------------------------------------------
	if n_elements(del0) eq 0 then del0='$$'	; Default delimiter string.
	nd = strlen(del0)			; Length of delimiter string.
	del = ''
	for i=0,strlen(del0)-1 do begin
	  del = del + '\'+strmid(del0,i,1)	; Escape all delimiter chars.
	endfor
 
	;---------------------------------------------------------
        ;  Deal with line replacement first
	;---------------------------------------------------------
        rep_marked_lines,txt,s, del=del0

	;---------------------------------------------------------
	;  Find text array lines with marker strings
	;
	;  Any lines containing 1 or more characters between
	;  delimiter strings is found.  Delimiter strings
	;  are identical at each end of the marker strings.
	;---------------------------------------------------------
	strfind, txt, del+'.+'+del, /quiet, index=in, count=cnt
	if cnt eq 0 then return
 
	;---------------------------------------------------------
	;  Process marker strings
	;
	;  A line of text in the text array may contain
	;  zero or more marker strings.  Marker strings
	;  consist of a start delimiter, a tag, and an end delimiter
	;  = del+tag+del.  The start and end delimiters must be idendical.
	;  Delimiters consist of one or more characters that are
	;  chosen in a sequence not to normally occur in the text (def='$$').
	;  A line may contain none or multiple marker strings,
	;  and perhaps unpaired delimiters.  All these cases must be handled.
	;  Marker strings containing tags not in the structure will be ignored.
	;  If gtag is in the structure but btag is not, and the delimiter
	;  is $$ then $$gtag$$btag$$ will give GVALbtag$$ where GVAL is
	;  the value  for gtag.  $$btag$$gtag$$ will give $$btagGVAL.
	;
	;  Loop over lines found to contain marker strings.
	;    Extract line and find start delimiter.
	;    While start delimiter exists do:
	;      Find corresponding end delimiter.
	;      If there is an end delimiter:
	;        Compute marker string length.
	;        If there is no tag (just 2 delimiters):
	;          Jump back, might be a start delimiter.
	;        else
	;          Extract marker string (like $$tag$$).
	;          Extract tag from marker string.
	;          Try to get tag value from structure.
	;          If tag in structure:
	;            Replace marker string in line with tag value.
	;            Find length of value.
	;            Adjust new search start for length difference.
	;          else jump start delimiter by 1 and try again.
	;      else no end del so break out of while.
	;      Find next start delimiter (checked on while).
	;    Keep looping in while.
	;    Replace edited line.    
	;  Keep loop over lines.
	;---------------------------------------------------------
	for i=0,cnt-1 do begin			; Loop over lines to edit.
	  t = txt[in[i]]			; Line to edit.
	  p2 = -nd				; Init marker search.
	  p1 = strpos(t,del0,p2+nd)		; Start del of 1st marker.
	  while p1 ge 0 do begin		; While start delimiter exists..
	    p2 = strpos(t,del0,p1+nd)		; End del.
	    if p2 ge 0 then begin		; End del exists?
	      lenm = p2-p1+nd			; Yes, length of marker string.
	      if lenm eq 2*nd then begin	; No tag, just two delimiters.
	        p2 = p2 - nd			; Jump back, was start del?
	      endif else begin			; Found marker string tag.
	        mrk = strmid(t,p1,lenm)		; marker string: del+tag+del.
	        tag = strmid(mrk,nd,lenm-2*nd)	; Grab just tag part.
	        val = tag_value(s,tag,err=err)	; Is tag in structure?
	        if err eq 0 then begin		; Yes, use it.
	          t = stress(t,'R',1,mrk,val)	; Edit string, first only. 
		  lenv = strlen(val)		; Length of replacement.
		  p2 = p2 + (lenv-lenm)		; Adjust search start.
	        endif ; err
	      endelse ; lenm
	    endif else break			; No end delimiter, line done.
	    if err eq 0 then begin		; Successful substitution.
	      p1 = strpos(t,del0,p2+nd)		; Look for another start del.
	    endif else begin			; Failed substitution.
	      p1 = p1 + 1			; Step by 1 char.
	    endelse
	  endwhile
	  txt[in[i]] = t			; Update line.
	endfor
 
	end
