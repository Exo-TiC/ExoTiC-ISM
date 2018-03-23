;-------------------------------------------------------------
;+
; NAME:
;       TXTGETKEY
; PURPOSE:
;       Get a keyword value from a string array.
; CATEGORY:
; CALLING SEQUENCE:
;       val = txtgetkey(key)
; INPUTS:
;       key = keyword to find. Case ignored.    in
; KEYWORD PARAMETERS:
;       Keywords:
;         INIT=txtarr  string array to search.  Must be given as an
;           initialization array before asking for values. If txtarr
;           stays the same it need be given only on first call.
;         DELIMITER=del  Set keyword/value delimiter (def is =).
;         /LIST lists keywords and values.
;         /STRUCTURE return all keywords and values in a structure.
;           Repeated keywords returned as an array in structure
;           with the elements the same order as in the input.
;           Can check returned structure for a tag using tag_test().
;           Beware that IDL reserved words if used as keywords
;           will cause an error (not allowed as structure tags).
;         TYPE=typ  Use with /STRUCTURE to convert values to a data
;           type other than the default string.  Must give an array
;           of type codes (as returned by the size function), one for
;           each item in the returned structure and in the same
;           order.  Repeated items are returned as an array, the
;           array counts as one item in the structure so give only
;           one type code for the array.
;         /NOSORT The tag is obsolete and not used or needed. It was
;           used with /STRUCTURE and may be dropped in the future.
;         /START  start search at beginning of array, else
;           continue from last position (can pick up multiple
;           copies of a keyword by not using /START).
;         INDEX=indx  Index where key was found.
; OUTPUTS:
;       val = returned value of keyword.        out
;         See notes below.  Null string if key not found.
; COMMON BLOCKS:
;       txtgetkey_com
; NOTES:
;       Notes: File must contain keywords and values separated by an
;         equal sign (=) or DELIM.  When a matching keyword is found
;         everything following the equal is returned as a text
;         string.  Spaces are optional.  Some examples:
;           title = This is a test.
;           n=128
;           xrange = 10, 20
;         Example call: v = txtgetkey(init=txt, key).
;         Comment lines have * as first non-blank character.
;         Comment lines and blank lines are ignored so may be used.
; MODIFICATION HISTORY:
;       R. Sterner, 17 Mar, 1993
;       R. Sterner, 25 Oct, 1993 --- Added DELIMITER keyword.
;       R. Sterner, 1994 May 6 --- Added /START and fixed minor bugs.
;       R. Sterner, 1995 Jun 26 --- Added INDEX keyword.
;       R. Sterner, 2001 May 23 --- Added /STRUCTURE keyword.
;       R. Sterner, 2002 Jul 01 --- Allowed repeated keywords with structure.
;       R. Sterner, 2003 May 22 --- Minor cleanup, help text.
;       R. Sterner, 2003 May 22 --- Allowed comment char after 1st col.
;       R. Sterner, 2004 Mar 25 --- Added /NOSORT keyword.
;       R. Sterner, 2005 Sep 07 --- Added comment on IDL reserved words.
;       R. Sterner, 2006 Sep 06 --- Allowed an optional type code array.
;       R. Sterner, 2006 Sep 24 --- Used typ[]instead of typ().
;       R. Sterner, 2010 May 04 --- Converted arrays from () to [].
;       R. Sterner, 2011 Sep 14 --- Rewrote structure section using tag_add,
;       array elements are now returned in correct order.
;
; Copyright (C) 1993, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
	function txtgetkey, key, initialize=init0, list=list, $
	  delimiter=del, start=start, index=indx, $
	  structure=structure, nosort=nosort, type=typ0, help=hlp
 
	common txtgetkey_com, keywds, val, last, curr
 
	if keyword_set(hlp) or $
	  ((n_params(0) eq 0) and $
	   (n_elements(init0) eq 0) and $
	   (n_elements(list) eq 0)) then begin
	  print,' Get a keyword value from a string array.'
	  print,' val = txtgetkey(key)'
 	  print,'   key = keyword to find. Case ignored.    in'
 	  print,'   val = returned value of keyword.        out'
	  print,'     See notes below.  Null string if key not found.'
	  print,' Keywords:'
 	  print,'   INIT=txtarr  string array to search.  Must be given as an'
	  print,'     initialization array before asking for values. If txtarr'
	  print,'     stays the same it need be given only on first call.'
	  print,'   DELIMITER=del  Set keyword/value delimiter (def is =).'
	  print,'   /LIST lists keywords and values.'
	  print,'   /STRUCTURE return all keywords and values in a structure.'
	  print,'     Repeated keywords returned as an array in structure'
          print,'     with the elements the same order as in the input.'
	  print,'     Can check returned structure for a tag using tag_test().'
	  print,'     Beware that IDL reserved words if used as keywords'
	  print,'     will cause an error (not allowed as structure tags).'
	  print,'   TYPE=typ  Use with /STRUCTURE to convert values to a data'
	  print,'     type other than the default string.  Must give an array'
	  print,'     of type codes (as returned by the size function), one for'
	  print,'     each item in the returned structure and in the same'
	  print,'     order.  Repeated items are returned as an array, the'
	  print,'     array counts as one item in the structure so give only'
	  print,'     one type code for the array.'
	  print,'   /NOSORT The tag is obsolete and not used or needed. It was'
	  print,'     used with /STRUCTURE and may be dropped in the future.'
	  print,'   /START  start search at beginning of array, else'
	  print,'     continue from last position (can pick up multiple'
	  print,'     copies of a keyword by not using /START).'
	  print,'   INDEX=indx  Index where key was found.'
	  print,' Notes: File must contain keywords and values separated by an'
	  print,'   equal sign (=) or DELIM.  When a matching keyword is found'
	  print,'   everything following the equal is returned as a text'
	  print,'   string.  Spaces are optional.  Some examples:'
	  print,'     title = This is a test.'
	  print,'     n=128'
	  print,'     xrange = 10, 20'
	  print,'   Example call: v = txtgetkey(init=txt, key).'
	  print,'   Comment lines have * as first non-blank character.'
	  print,'   Comment lines and blank lines are ignored so may be used.'
	  return,''
	endif
 
        ;----------------------------------------------------
	;  Initialize
        ;----------------------------------------------------
	if n_elements(del) eq 0 then del = '='          ; Default delimiter.
	if n_elements(init0) ne 0 then begin            ; Init array given.
	  w = where(strcompress(init0,/rem) ne '', cnt)	; Drop null lines.
	  if cnt gt 0 then txt = init0[w]
	  w = where(strmid(txt,0,1) ne '*', cnt)	; Drop comment lines.
 	  if cnt gt 0 then txt = txt[w]
	  keywds = txt                                  ; Space for keywds,vals.
	  val = txt
	  last = n_elements(txt)-1                      ; Last index.
	  for i=0, last do begin			; Grab keywords/values.
	    keywds[i] = strupcase(getwrd(txt[i],delim=del)) ; Keyword.
	    val[i] = getwrd(txt[i],1,99,delim=del)          ; Value.
	  endfor
	  w = where(strmid(keywds,0,1) ne '*', cnt)	; Drop leftover cmnts.
	  if cnt gt 0 then begin                        ; Still have lines left.
	    keywds = keywds[w]                          ; Remaining keywords.
	    val = val[w]                                ; Remaining values.
	  endif
	  curr = 0	                                ; Search start.
	endif
 
        ;----------------------------------------------------
	;  List keyword/value pairs
        ;----------------------------------------------------
	if keyword_set(list) then begin
	  if n_elements(keywds) eq 0 then begin
            print,' Error in txtgetkey: must initialize first.'
            return,''
          endif
	  for i = 0, n_elements(keywds)-1 do begin
	    out = strtrim(i)+' --- '+keywds[i]+' = '+val[i]
	    if strlen(out) ge 79 then out = strmid(out,0,75)+'...'
	    print,out
	  endfor
	endif
 
        ;----------------------------------------------------
	;  Return a structure with keywords:values
        ;
        ;  If a keyword is repeated return all the values
        ;  for that keyword as an array in the structure.
        ;  (done by tag_add with /array option).
        ;
        ;  Do any data type conversion after the array is
        ;  complete.
        ;----------------------------------------------------
        ;---  Make sure INIT=txt was called first  ---
	if keyword_set(structure) then begin
	  if n_elements(keywds) eq 0 then begin
            print,' Error in txtgetkey: must initialize first.'
            return,''
          endif
 
	  lst = n_elements(keywds)-1		; Last index.
 
          ;---  Loop over keyword/value pairs  ---
          for i=0,lst do begin
            tag_add,out,keywds[i],val[i],/array ; Add item to structure.
          endfor
 
          ;---  Deal with type conversion if given  ---
          ntyp = n_elements(typ0)               ; Number of type conversions.
          if ntyp gt 0 then begin               ; Any type conversions?
            tag = tag_names(out)                ; Current tag names in out.
            ntag = n_tags(out)                  ; Number of tags in out.
	    typ = intarr(ntag) + 7	        ; Max # needed (may be fewer).
	    if n_elements(typ0) ne 0 then $	; Insert requested types
 	      typ[0]=typ0			; into default types.
            for i=0,ntag-1 do begin             ; Yes, loop over tags.
              ty = typ[i]                       ; target data type.
              if ty eq 7 then continue          ; If string skip (already str).
              tag_add,out,tag[i],to_datatype(out.(i),ty) ; Convert type.
            endfor
          endif
 
	  return, out
	endif  ; structure
 
	if n_params(0) eq 0 then return, ''
 
        ;----------------------------------------------------
	;  Search for given keyword and return value
        ;----------------------------------------------------
	if n_elements(keywds) eq 0 then begin
	  print,' Error in txtgetkey: must initialize first.'
	  return,''
	endif
 
	if keyword_set(start) then curr = 0
	if curr gt last then begin
	  curr = 0
	  indx = -1		; Not found.
	  return, ''
	endif
	w = where(strupcase(key) eq keywds, cnt)
	if cnt eq 0 then begin
	  curr = 0		; Reset search to array start.
	  indx = -1		; Not found.
	  return, ''
	endif
	w2 = where(w ge curr,cnt)
	if cnt eq 0 then begin
	  curr = 0		; Reset search to array start.
	  indx = -1		; Not found.
	  return, ''
	endif
	ww = w[w2]
	curr = ww[0]
	out = val[curr]
	indx = curr		; Index found.
	curr = curr + 1
 
	return, out
 
	end
