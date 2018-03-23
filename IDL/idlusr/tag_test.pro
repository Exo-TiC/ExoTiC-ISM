;-------------------------------------------------------------
;+
; NAME:
;       TAG_TEST
; PURPOSE:
;       Test if given tag is in given structure or hash.
; CATEGORY:
; CALLING SEQUENCE:
;       flag = tag_test(ss, tag)
; INPUTS:
;       ss = given structure or hash.      in
;       tag(s) = given tag(s) or key(s).   in
; KEYWORD PARAMETERS:
;       Keywords:
;         MINLEN=mn Minimum tag length to match (def=exact match).
;           SS may have the tag abbreviated down to mn characters.
;           (But tag must be at least as long as appears in ss).
;         INDEX=ind Index of first match (-1 means none).
; OUTPUTS:
;       flag = test result:                out
;          0=tag not found, 1=tag found.
; COMMON BLOCKS:
; NOTES:
;       Note: Tag may be a compound tag to test if a structure tag
;         or hash key exists at some nested depth.  For example:
;         tag = 'tag1.tag2.tag3' to test for ss.tag1.tag2.tag3
;         Nesting may mix structures and hashes.
;         Useful for testing if tag occurs. Example:
;         if tag_test(ss,'cmd') then call_procedure,ss.cmd
;         Structure tags are case insensitive, hash keys are
;         case sensitive.
; MODIFICATION HISTORY:
;       R. Sterner, 1998 Jun 30
;       R. Sterner, 2005 Jan 19 --- Added INDEX=ind.
;       R. Sterner, 2006 Sep 27 --- Added MINLEN.
;       R. Sterner, 2010 May 07 --- Converted arrays from () to [].
;       R. Sterner, 2012 Aug 13 --- Allowed hashes also.
;       R. Sterner, 2012 Aug 13 --- Allowed compound tags for nested structures.
;
; Copyright (C) 1998, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	function tag_test, ss, tag, index=ind, minlen=mn, help=hlp
 
	if (n_params(0) lt 2) or keyword_set(hlp) then begin
	  print,' Test if given tag is in given structure or hash.'
	  print,' flag = tag_test(ss, tag)'
	  print,'   ss = given structure or hash.      in'
	  print,'   tag(s) = given tag(s) or key(s).   in'
	  print,'   flag = test result:                out'
	  print,'      0=tag not found, 1=tag found.'
	  print,' Keywords:'
	  print,'   MINLEN=mn Minimum tag length to match (def=exact match).'
	  print,'     SS may have the tag abbreviated down to mn characters.'
	  print,'     (But tag must be at least as long as appears in ss).'
	  print,'   INDEX=ind Index of first match (-1 means none).'
	  print,' Note: Tag may be a compound tag to test if a structure tag'
          print,'   or hash key exists at some nested depth.  For example:'
          print,"   tag = 'tag1.tag2.tag3' to test for ss.tag1.tag2.tag3"
          print,'   Nesting may mix structures and hashes.'
          print,'   Useful for testing if tag occurs. Example:'
	  print,"   if tag_test(ss,'cmd') then call_procedure,ss.cmd"
          print,'   Structure tags are case insensitive, hash keys are'
          print,'   case sensitive.'
	  return,''
	endif
 
	;----------------------------------------
        ;  Check input for type
	;----------------------------------------
	if n_elements(ss) eq 0 then return,0	; Undefined.
        typ = 0
        if isa(ss,'STRUCT') then typ=1          ; Structure.
        if isa(ss,'HASH')   then typ=2          ; Hash.
        if typ eq 0 then begin                  ; Error.
          return,0
        endif
 
        ;----------------------------------------
        ;  Handled nested tags
        ;
        ;  If given tag is compound then assume
        ;  first part references a structure and
        ;  recurse with rest of tag on that.
        ;----------------------------------------
        if nwrds(tag,del='.') gt 1 then begin           ; Compound tag.
          tag1 = getwrd(tag,del='.')                    ; First level tag.
          tagr = getwrd(tag,1,999,del='.')              ; Rest of tag.
          v = tag_test(tag_value(ss,tag1),tagr, $       ; Drop down a level.
                       minlen=mn, index=in)
          return,v
        endif
 
	;----------------------------------------
	;  Initialize
	;----------------------------------------
        if typ eq 1 then begin                  ; Structure.
	  tagup = strupcase(tag)		; Uppercase copy of tag.
	  tnames = tag_names(ss)		; Get structure tags (UCase).
        endif else begin
	  tagup = tag   			; Use tag as given.
	  tnames = ss.keys()    		; List of hash keys.
        endelse
 
	len = strlen(tagup)			; # characters in given tag.
	if n_elements(mn) eq 0 then mn=len	; Min matching size allowed.
	mn = mn<len				; Match at least len.
 
 	;----------------------------------------
	;  Loop over allowed match lengths
	;----------------------------------------
	for i=len, mn, -1 do begin		; Test tag chars: all,all-1,...
	  tst = strmid(tagup,0,i)		; Pick off first i chars.
	  w = where(tst eq tnames, cnt)		; Is it in structure?
	  if cnt eq 1 then break		; Yes, exactly once.
	endfor ; i
 
	;----------------------------------------
	;  Tag not found, return 0
	;----------------------------------------
	if cnt eq 0 then begin
	  ind = -1
	  return, 0
	endif
 
	;----------------------------------------
	;  Tag appears in structure, return 1 
	;----------------------------------------
	ind = w[0]
	return, 1
 
	end
