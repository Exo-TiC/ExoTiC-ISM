;-------------------------------------------------------------
;+
; NAME:
;       TAG_SORT
; PURPOSE:
;       Sort structure tags based on a specified tag.
; CATEGORY:
; CALLING SEQUENCE:
;       s2 = tag_sort(s)
; INPUTS:
;       s = Input structure to sort.     in
; KEYWORD PARAMETERS:
;       Keywords:
;         KEY=ktag Tag name to sort on (def=null string).
;           If ktag is a null string the structure will be copied
;           as is, but names may be changed with ALIAS.
;         ALIAS=new Optional list of new names to use for structure.
;           Give one for each original tag in same order.
;           If given will be used in returned structure.
;           Also use the alias to sort the original structure
;           and in the INCLUDE and EXCLUDE lists.
;         /REVERSE Reverse the sort.
;         INCLUDE=list List of tags to sort (include ktag). Def=all.
;         EXCLUDE=listx List of tags not to sort.
; OUTPUTS:
;       s2 = returned sorted structure.  out
; COMMON BLOCKS:
; NOTES:
;       Note: Arrays with the same number of elements as ktag
;         will be sorted.  Any other items are ignored.
;         Intended for 1-d arrays but not restricted to them.
; MODIFICATION HISTORY:
;       R. Sterner, 2008 Nov 20
;       R. Sterner, 2008 Nov 21 --- Made default ktag='' (copy).
;       R. Sterner, 2008 Nov 24 --- Added ERROR=err and INDEX=is.
;       R. Sterner, 2010 May 07 --- Converted arrays from () to [].
;
; Copyright (C) 2008, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	function tag_sort, s, key=ktag, reverse=rev, help=hlp, $
	  include=list0, exclude=listx0, alias=new0, $
	  index=is, error=err
 
	if (n_params() lt 1) or keyword_set(hlp) then begin
	  print,' Sort structure tags based on a specified tag.'
	  print,' s2 = tag_sort(s)'
	  print,'   s = Input structure to sort.     in'
	  print,'   s2 = returned sorted structure.  out'
	  print,' Keywords:'
	  print,'   KEY=ktag Tag name to sort on (def=null string).'
	  print,'     If ktag is a null string the structure will be copied'
	  print,'     as is, but names may be changed with ALIAS.'
	  print,'   ALIAS=new Optional list of new names to use for structure.'
	  print,'     Give one for each original tag in same order.'
	  print,'     If given will be used in returned structure.'
	  print,'     Also use the alias to sort the original structure'
	  print,'     and in the INCLUDE and EXCLUDE lists.'
	  print,'   /REVERSE Reverse the sort.'
	  print,'   INCLUDE=list List of tags to sort (include ktag). Def=all.'
	  print,'   EXCLUDE=listx List of tags not to sort.'
	  print,'   INDEX=is Returned sort index array (-1 if error).'
	  print,'   ERROR=err Error flag: 0=ok.'
	  print,' Note: Arrays with the same number of elements as ktag'
	  print,'   will be sorted.  Any other items are ignored.'
	  print,'   Intended for 1-d arrays but not restricted to them.'
	  return, ''
	endif
 
	;---  Include and Exclude lists and alias  ---
	if n_elements(ktag) eq 0 then ktag=''	; Default is copy.
	xflag = n_elements(listx0) gt 0		; Exclude flag: 0=none.
	if xflag then listx=strupcase(listx0)	; Uppercase.
	tags = tag_names(s)			; Complete tag list.
	n = n_elements(tags)			; Number of tags.
	if n_elements(new0) eq 0 then new0=tags ; Default new names = old.
	new = new0
	if n_elements(new) ne n_elements(tags) then new=tags ; Must match #.
	tags2 = strupcase(new)			; Output names.
	if n_elements(list0) eq 0 then list0=new ; Def include is all.
	list = strupcase(list0)			; Uppercase.
 
	;---  Initial sort  ---
	if ktag eq '' then begin
	  na = -1				; Copy everything.
	endif else begin
	  w = where(tags2 eq strupcase(ktag),cnt)
	  if cnt eq 0 then begin
	    print,' Error in tag_sort:  Given sort tag not found: '+ktag
	    is = -1
	    err = 1
	    return,''
	  endif
	  ktag2 = tags[w[0]]
	  a = tag_value(s,ktag2,err=err)	; Grab key array.
	  if err ne 0 then begin		; Not found.
	    print,' Error in tag_sort: Given sort tag not found: '+ktag2
	    is = -1
	    err = 1
	    return,''
	  endif
	  is = sort(a)				; Sort it.
	  if keyword_set(rev) then is=reverse(is) ; Reverse sort.
	  na = n_elements(a)			; Size of array a.
	endelse
 
	;---  Loop over tags in structure  ---
	for i=0, n-1 do begin
	  t = tags[i]				; Next tag.
	  val = tag_value(s,t)			; It's value.
	  t = tags2[i]				; Use alias.
	  if n_elements(val) ne na then begin	; Check size.
	    tag_add, s2, t, val			; Wrong size, copy unsorted.
	    continue
	  endif
	  if xflag then begin			; If exclude list given ...
	    w = where(listx eq t,cnt)		; Check if tag excluded.
	    if cnt ne 0 then begin		; Yes.
	      tag_add, s2, t, val		; Copy unsorted.
	      continue
	    endif ; cnt
	  endif ; xflag
	  w = where(list eq t,cnt)		; Check if in include list.
	  if cnt eq 1 then val=val[is]		; Yes, sort it.
	  tag_add, s2, t, val			; Add to output.
	endfor ; i
 
	err = 0
	return, s2				; Return result.
 
	end
