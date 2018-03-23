;-------------------------------------------------------------
;+
; NAME:
;       TAG_MOVE
; PURPOSE:
;       Move tags from one structure to another.
; CATEGORY:
; CALLING SEQUENCE:
;       tag_move, list, old, new
; INPUTS:
;       list = list of tags to move.       in
;         If list is a null string then all tags in old
;         are moved or copied.
; KEYWORD PARAMETERS:
;       Keywords:
;         /COPY Only copy tags, do not delete them.
;         /VERBOSE List operations as they happen.
; OUTPUTS:
;       old = Structure to move tags from. in, out
;       new = Structure to move tags to.   in, out
; COMMON BLOCKS:
; NOTES:
;       Notes: If new does not exist (or is not a structure)
;         it is created.  If all tags are moved from old
;         then old becomes a null string.
; MODIFICATION HISTORY:
;       R. Sterner, 2008 May 16
;       R. Sterner, 2008 Sep 08 --- Added /VERBOSE.
;       R. Sterner, 2009 Mar 05 --- Allowed list to be null to do all old tags.
;       R. Sterner, 2009 Mar 06 --- Fixed bug added yesterday.
;       R. Sterner, 2010 Dec 31 --- Fixed to exit after all tags are moved.
;
; Copyright (C) 2008, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro tag_move, list, old, new, copy=copy, verbose=verb, help=hlp
 
	if (n_params(0) lt 3) or keyword_set(hlp) then begin
	  print,' Move tags from one structure to another.'
	  print,' tag_move, list, old, new'
	  print,'   list = list of tags to move.       in'
	  print,'     If list is a null string then all tags in old'
	  print,'     are moved or copied.'
	  print,'   old = Structure to move tags from. in, out'
	  print,'   new = Structure to move tags to.   in, out'
	  print,' Keywords:'
	  print,'   /COPY Only copy tags, do not delete them.'
	  print,'   /VERBOSE List operations as they happen.'
	  print,' Notes: If new does not exist (or is not a structure)'
	  print,'   it is created.  If all tags are moved from old'
	  print,'   then old becomes a null string.'
	  return
	endif
 
	if max(where(list ne '')) lt 0 then list=tag_names(old)
 
	for i=0,n_elements(list)-1 do begin
	  if datatype(old) ne 'STC' then begin	; All tags moved?
	    if keyword_set(verb) then $
	      print,' TAG_MOVE: No tags in input structure.'
            return
          endif
	  tag = list[i]				; Next tag.
	  if keyword_set(verb) then $
	    print,' TAG_MOVE: Looking for '+tag
	  val = tag_value(old, tag, error=err)	; Get value.
	  if err ne 0 then begin
	    if keyword_set(verb) then $
	      print,'           Not found.'
	    continue				; Tag not there, ignore.
	  endif
	  if datatype(new) ne 'STC' then begin	; Is new already a structure?
	    new = create_struct(tag,val)	; No, create it.
	    if keyword_set(verb) then $
	      print,'           Output structure created with '+tag
	  endif else begin
	    tag_add, new, tag, val		; Yes, add tag to it.
	    if keyword_set(verb) then $
	      print,'           '+tag+' added to output structure.'
	  endelse
	  if keyword_set(copy) then continue	; Do not delete.
	  old = tag_drop(old,tag)		; Drop from old.
	  if keyword_set(verb) then $
	    print,'           '+tag+' dropped from input structure.'
	endfor ; i
 
	end
