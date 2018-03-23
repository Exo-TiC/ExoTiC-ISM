;-------------------------------------------------------------
;+
; NAME:
;       TAG_ADD
; PURPOSE:
;       Add or update a tag in a structure or hash.
; CATEGORY:
; CALLING SEQUENCE:
;       tag_add, ss, tag, val
; INPUTS:
;       ss = given structure or hash.              in
;         Created if undefined.
;       tag = given tag or key.                    in
;         May be a compound tag or key, like
;         'aaa.bbb.ccc' to allow a nested
;         value to be added or modified.
;         The word tag means tag or key below.
;       val = Value for tag or key.                in
;         The new value may be a different data type from the old
;         (but not if /ARRAY is used).
; KEYWORD PARAMETERS:
;       Keywords:
;         /ARRAY If tag already exists in the structure then insert
;           val as the next element in an array for that tag.
;           Otherwise just replace the old value with the new.
;           If this keyword is used the new value must be compatible
;           with the old value to avoid a type conversion error.
;         MINLEN=mn Minimum tag length to match (def=exact match).
;           SS may have the tag abbreviated down to mn characters.
;           (But tag must be at least as long as appears in ss).
;         AFTER=aft If tag is new then add it after tag aft.
;           aft='^' to add at front, aft='$' to add at end (default).
;           This keyword is ignored if the tag is in the structure,
;           in which case it is updated with the new value.
;           For a compound tag this keyword applies to the tags at
;           the target level of nesting, aft is always a single tag.
;           This keyword is ignored for a hash.
;         FLAG=flag 0=added, 1=updated.
;         /NEWHASH If the input ss is undefined then create it as
;           a hash instead of the default structure.
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
;       Notes: If ss does not contain the tag it is added.
;       GIVEN TAG MUST BE AS BIG OR BIGGER than the tag to match
;       in ss or it will be considered a new tag and added.
; MODIFICATION HISTORY:
;       R. Sterner, 2006 Sep 27
;       R. Sterner, 2007 Dec 18 --- Upgraded to not require matching type.
;       R. Sterner, 2007 Dec 18 --- Added keyword AFTER=aft.
;       R. Sterner, 2008 Nov 20 --- New structure created if undefined.
;       R. Sterner, 2011 Sep 14 --- Added /ARRAY.
;       R. Sterner, 2012 Oct 09 --- Now handles compound tags to work at depth.
;       R. Sterner, 2012 Oct 09 --- Now handles hashes, structures, or mixed.
;
; Copyright (C) 2006, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro tag_add, ss, tag, val, array=array, minlen=mn, $
          flag=flag, after=aft, newhash=newhash, help=hlp
 
	if (n_params(0) lt 3) or keyword_set(hlp) then begin
	  print,' Add or update a tag in a structure or hash.'
	  print,' tag_add, ss, tag, val'
	  print,'   ss = given structure or hash.              in'
	  print,'     Created if undefined.'
	  print,'   tag = given tag or key.                    in'
          print,'     May be a compound tag or key, like'
          print,"     'aaa.bbb.ccc' to allow a nested"
          print,'     value to be added or modified.'
          print,'     The word tag means tag or key below.'
	  print,'   val = Value for tag or key.                in'
	  print,'     The new value may be a different data type from the old'
          print,'     (but not if /ARRAY is used).'
	  print,' Keywords:'
          print,'   /ARRAY If tag already exists in the structure then insert'
          print,'     val as the next element in an array for that tag.'
          print,'     Otherwise just replace the old value with the new.'
          print,'     If this keyword is used the new value must be compatible'
          print,'     with the old value to avoid a type conversion error.'
	  print,'   MINLEN=mn Minimum tag length to match (def=exact match).'
	  print,'     SS may have the tag abbreviated down to mn characters.'
	  print,'     (But tag must be at least as long as appears in ss).'
	  print,'   AFTER=aft If tag is new then add it after tag aft.'
	  print,"     aft='^' to add at front, aft='$' to add at end (default)."
	  print,'     This keyword is ignored if the tag is in the structure,'
	  print,'     in which case it is updated with the new value.'
          print,'     For a compound tag this keyword applies to the tags at'
          print,'     the target level of nesting, aft is always a single tag.'
          print,'     This keyword is ignored for a hash.'
	  print,'   FLAG=flag 0=added, 1=updated.'
          print,'   /NEWHASH If the input ss is undefined then create it as'
          print,'     a hash instead of the default structure.'
	  print,' Notes: If ss does not contain the tag it is added.'
	  print,' GIVEN TAG MUST BE AS BIG OR BIGGER than the tag to match'
	  print,' in ss or it will be considered a new tag and added.'
	  return
	endif
 
	;----------------------------------------
        ;  Deal with compound (nested) tag
        ;
        ;  Tags like aaa.bbb.ccc are compound
        ;  tags and are handled using recursion.
	;----------------------------------------
        if nwrds(tag,del='.') gt 1 then begin   ; If tag is compound then ...
          tag1 = getwrd(tag,0,del='.')          ; First part of compound tag.
          tag2 = getwrd(tag,1,99,del='.')       ; Rest of compound tag.
          ss2 = tag_value(ss,tag1)              ; First part of item.
          tag_add, ss2, tag2, val, $            ; Try to add val now.
            array=array, flag=flag, minlen=mn, after=aft  ; May recurse again.
          tag_add,ss,tag1,ss2                   ; Add modified item back.
          return                                ; Finished.
        endif
 
	;----------------------------------------
	;  Initialize
	;----------------------------------------
	if n_elements(ss) eq 0 then begin	; Undefined. Create it.
          if keyword_set(newhash) then begin    ; Force to be a hash.
            ss = hash(tag,val)
          endif else begin                      ; Default is structure.
	    ss = create_struct(tag,val)
          endelse
	  return
	endif
        typ = 0                                 ; Data type flag for ss.
        if isa(ss,'STRUCT') then typ=1          ; Was a structure.
        if isa(ss,'HASH')   then typ=2          ; Was a hash.
        if typ eq 0 then return                 ; Not a structure or hash.
        if typ eq 1 then begin                  ; Structure.
	  tagup = strupcase(tag)		; Uppercase copy of tag.
	  tnames = tag_names(ss)		; Get structure tags (UCase).
	  ntags = n_tags(ss)			; # tags in structure.
        endif else begin                        ; Hash.
	  tagup = tag			        ; Keep case of tag.
	  tnames = ss.keys()    		; Get hash keys.
	  ntags = ss.count()			; # keys in hash.
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
	  iu = w[0]				; Index where tag found.
	  if cnt eq 1 then break		; Yes, exactly once.
	endfor ; i
 
	;----------------------------------------
	;  Tag not found, add it
	;
        ;  For a HASH the elements are unordered.
        ;
        ;  For a STRUCTURE:
	;    Set position flag pos:
	;      0=start, 1=mid, 2=end.
	;----------------------------------------
	if cnt eq 0 then begin
	  flag = 0				; Added.
          ;===  HASH  ===
          if typ eq 2 then begin
            ss[tag] = val                       ; Add new value to hash.
            return
          endif
          ;===  STRUCTURE  ===
	  ;---  Find where to add: front, middle, end  ---
	  if n_elements(aft) eq 0 then begin	; Default is add to end.
	    pos = 2
	  endif else begin			; AFTER given.
	    pos = 1				; Assume add to middle
	    aftup = strupcase(aft)		; Upper case after.
	    wa = where(aftup eq tnames, cnta)	; See if AFTER occurs in ss.
	    ia = wa[0]				; Index of match to AFTER.
	    if cnta eq 0 then begin		; No match.
	      pos=2				; Default, add to end.
	      if aft eq '^' then pos=0		; Add to front.
	      if aft eq '$' then pos=2		; Add to end.
	    endif else begin			; Found match to AFTER.
	      if ia eq ntags-1 then pos=2	; Add after last.
	    endelse
	  endelse
	  ;---  Add at specified position  ---
	  if pos eq 0 then begin		; FRONT
	    ss = create_struct(tag,val,ss)
	    return
	  endif
	  if pos eq 2 then begin		; END
	    ss = create_struct(ss,tag,val)
	    return
	  endif
	  ss0 = ss				; MIDDLE.  Copy structure.
	  ss = create_struct(tnames[0],ss0.(0))	; Start output structure.
	  for i=1,ia do begin			; Copy up to add point.
	    ss = create_struct(ss,tnames[i],ss0.(i))
	  endfor
	  ss = create_struct(ss,tag,val)	; Add new item.
	  for i=ia+1, ntags-1 do begin		; Copy rest of structure.
	    ss = create_struct(ss,tnames[i],ss0.(i))
	  endfor
	  return
	endif
 
	;----------------------------------------
	;  Tag appears in structure or hash,
        ;    update
        ;
        ;  If hash just update item.
        ;  If structure must rebuild it all.
        ;  If /ARRAY is set then concatenate new
        ;  value with old, else replace old value
        ;  with new.
	;----------------------------------------
	flag = 1				; Updated.
	ss0 = ss				; Copy structure.
        ;===  HASH  ===
        if typ eq 2 then begin
          if keyword_set(array) then begin      ; Concatenate if /ARRAY.
            ss[tag] = [ss[tag],val]
          endif else begin                      ; Else replace.
            ss[tag] = val
          endelse
          return
        endif
        ;===  STRUCTURE  ===
	if iu eq 0 then begin			; Update is first tag.
          if keyword_set(array) then $          ; If /ARRAY is set then
            val2=[ss0.(iu),val] else val2=val   ;   concatenate, else replace.
	  ss = create_struct(tag,val2)		; Update first item.
	  for i=1,ntags-1 do begin		; Copy rest of structure.
	    ss = create_struct(ss,tnames[i],ss0.(i))
	  endfor
	endif else begin			; Update is after first item.
	  ss = create_struct(tnames[0],ss0.(0))	; Start output structure.
	  for i=1,iu-1 do begin			; Copy up to item.
	    ss = create_struct(ss,tnames[i],ss0.(i))
	  endfor
          if keyword_set(array) then $          ; If /ARRAY is set then
            val2=[ss0.(iu),val] else val2=val   ;   concatenate, else replace.
	  ss = create_struct(ss,tag,val2)	; Update item.
	  for i=iu+1,ntags-1 do begin		; Copy to end.
	    ss = create_struct(ss,tnames[i],ss0.(i))
	  endfor
	endelse
 
	end
