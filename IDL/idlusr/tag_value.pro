;-------------------------------------------------------------
;+
; NAME:
;       TAG_VALUE
; PURPOSE:
;       Return the value for a given structure or hash tag.
; CATEGORY:
; CALLING SEQUENCE:
;       val = tag_value(ss, tag)
; INPUTS:
;       ss = given structure or hash.  in
;       tag = given tag(s) or key(s).  in
; KEYWORD PARAMETERS:
;       Keywords:
;         INDEX=in Index where tag is found (-1 if none).
;           Only indexes the level referenced by the compound tag.
;           Could access value as val=ss.(in) if a structure.
;           Also works for hashes but indirectly through an array
;           of hash keys at the referenced level.
;         MINLEN=mn Minimum tag length to match (def=exact match).
;           SS may have the tag abbreviated down to mn characters.
;           (But tag must be at least as long as appears in ss).
;         TRUNCATE=len Length to optionally truncate SS tag names to.
;           First match, if any, of truncated tags will be returned.
;           So tag of 'GRIB_PAT' and TRUNCATE=8 will match
;           'GRIB_PAT_00Z' or 'GRIB_PAT_12Z' if they are in SS.
;         ERROR=err Error flag: 0=ok, else tag not found.
;           On error returned value is a null string.
; OUTPUTS:
;       val = returned value.          out
; COMMON BLOCKS:
; NOTES:
;       Notes: The word tag means structure tag or hash key here.
;         Tag may be a compound tag to access any item in a
;         nested structure.  For example:
;         tag = 'tag1.tag2.tag3' to access value of ss.tag1.tag2.tag3
;         Nesting may mix structures and hashes.
; MODIFICATION HISTORY:
;       R. Sterner, 2004 May 05
;       R. Sterner, 2006 Sep 27 --- Added MINLEN.
;       R. Sterner, 2008 Oct 24 --- Added INDEX=in.
;       R. Sterner, 2009 Mar 27 --- Added TRUNCATE=len.
;       R. Sterner, 2011 Jul 11 --- Now gives error if ss undefined.
;       R. Sterner, 2012 Aug 10 --- Allowed compound tags for nested structures.
;       R. Sterner, 2012 Aug 13 --- Now works for structures or hashes.
;       R. Sterner, 2013 Mar 19 --- Now returns error if input undefined.
;
; Copyright (C) 2004, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	function tag_value, ss, tag, error=err, minlen=mn, $
	  index=in, truncate=lentr, help=hlp
 
	if (n_params(0) lt 2) or keyword_set(hlp) then begin
	  print,' Return the value for a given structure or hash tag.'
	  print,' val = tag_value(ss, tag)'
	  print,'   ss = given structure or hash.  in'
	  print,'   tag = given tag(s) or key(s).  in'
	  print,'   val = returned value.          out'
	  print,' Keywords:'
	  print,'   INDEX=in Index where tag is found (-1 if none).'
          print,'     Only indexes the level referenced by the compound tag.'
	  print,'     Could access value as val=ss.(in) if a structure.'
          print,'     Also works for hashes but indirectly through an array'
          print,'     of hash keys at the referenced level.'
	  print,'   MINLEN=mn Minimum tag length to match (def=exact match).'
	  print,'     SS may have the tag abbreviated down to mn characters.'
	  print,'     (But tag must be at least as long as appears in ss).'
	  print,'   TRUNCATE=len Length to optionally truncate SS tag names to.'
	  print,'     First match, if any, of truncated tags will be returned.'
	  print,"     So tag of 'GRIB_PAT' and TRUNCATE=8 will match"
	  print,"     'GRIB_PAT_00Z' or 'GRIB_PAT_12Z' if they are in SS."
	  print,'   ERROR=err Error flag: 0=ok, else tag not found.'
	  print,'     On error returned value is a null string.'
          print,' Notes: The word tag means structure tag or hash key here.'
          print,'   Tag may be a compound tag to access any item in a'
          print,'   nested structure.  For example:'
          print,"   tag = 'tag1.tag2.tag3' to access value of ss.tag1.tag2.tag3"
          print,'   Nesting may mix structures and hashes.'
	  return,''
	endif
 
	;----------------------------------------
        ;  Check input for type
	;----------------------------------------
        err = 1
	if n_elements(ss) eq 0 then return,''           ; Undefined input.
        typ = 0
        if isa(ss,'STRUCT') then typ=1                  ; Structure.
        if isa(ss,'HASH')   then typ=2                  ; Hash.
        if typ eq 0 then begin                          ; Error.
          err = 1
          return,''
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
          v = tag_value(tag_value(ss,tag1),tagr, $      ; Drop down a level.
            error=err, minlen=mn, index=in, truncate=lentr)
          return,v
        endif
 
	;----------------------------------------
	;  Initialize
	;----------------------------------------
        err = 1
        if typ eq 1 then begin                  ; Structure.
	  tagup = strupcase(tag)		; Uppercase copy of tag.
	  tnames = tag_names(ss)		; Get structure tags (UCase).
        endif else begin                        ; Hash.
          tagup = tag                           ; Use tag as given.
          tnames = ss.keys()                    ; List of hash keys.
          tnames0 = tnames                      ; Original keys.
        endelse
	if n_elements(lentr) ne 0 then $	; Truncate ss tag names.
	  tnames=strmid(tnames,0,lentr)
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
	;  Tag not found, return null string
	;----------------------------------------
	if cnt eq 0 then begin
	  err = 1
	  return, ''
	endif
 
	;----------------------------------------
	;  Tag found, return value
	;----------------------------------------
	err = 0
	in = w[0]                               ; Where found in list of tags.
        if typ eq 1 then begin                  ; Structure.
          return, ss.(in)                       ; Return struct value by index.
        endif else begin                        ; Hash.
          key = tnames0[in]                     ; Get actual key.
          return,ss[key]                        ; Return hash value by key.
        endelse
 
	end
