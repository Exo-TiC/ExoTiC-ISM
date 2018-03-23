;-------------------------------------------------------------
;+
; NAME:
;       GETFILE_TAGS
; PURPOSE:
;       Get selected tags from a control/defaults file.
; CATEGORY:
; CALLING SEQUENCE:
;       s = getfile_tags(file, tags)
; INPUTS:
;       file = name of control/defaults file.        in
;         May also be a text array as if from file.
;       tags = list of tags to return (def=all).     in
;         See notes for allowed forms.
; KEYWORD PARAMETERS:
;       Keywords:
;         /CONTINUED or CONTINUED=char.  Merge continued lines
;           in file or given text array.  Continued lines have a
;           continuation character at the end of the line, $ by
;           default, but another character may be specified.
;         TYPE=typ  Optional type codes array, one for each item
;           in the full structure (not the subset).  The typ code
;           is the same as given by the size function.  Giving a type
;           code array will convert to the target data types.  A
;           good way to do the typ codes is to look at the structure
;           without it to see the tag order and number.
;           See x=txtgetkey(/help) for more on the type codes.
;         /NOSORT do not sort tags, keep same order as in file.
;         ERROR=err  Error flag: 0=ok, 1=file not opened,
;           2=no lines in file, 3 or 4=no tags found,
;           5=no tags given, null string returned.
; OUTPUTS:
;       s = Returned structure with requested tags.  out
; COMMON BLOCKS:
; NOTES:
;       Notes: The list of tags in tags is processed by
;         wordarray to allow a flexible input (list or array).
;         Examples: 'a b c d' or 'a,b,c,d' or ['a','b','c','d']
;         are example allowed as tag lists.
;         See wordarray,/help for allowed keywords.
;         See putfile_tags for adding or updating tags in a text
;         file.
; MODIFICATION HISTORY:
;       R. Sterner, 2006 Apr 14
;       R. Sterner, 2006 Apr 18 --- Modified to return nulls for all
;       tags if file does not exist.
;       R. Sterner, 2006 Jun 19 --- Added note pointing to putfile_tags.
;       R. Sterner, 2006 Jul 07 --- Added drop_comments.
;       R. Sterner, 2006 Sep 06 --- Added TYPE=typ and /NOSORT keywords.
;       R. Sterner, 2006 Sep 24 --- Made sure err defined.
;       R. Sterner, 2009 Jun 26 --- Added CONTINUED=cont.
;       R. Sterner, 2010 Jun 11 --- Converted arrays from () to [].
;       R. Sterner, 2010 Jun 11 --- Upgraded the help text.
;
; Copyright (C) 2006, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	function getfile_tags, file, tags, error=err,_extra=extra, $
	  type=typ, nosort=nosort, continued=cont, help=hlp
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Return a structure with selected tags from a control/defaults file.'
	  print,' s = getfile_tags(file, tags)'
	  print,'   file = name of control/defaults text file.              in'
	  print,'     May also be a text array as if from file.'
          print,'     Comments have * as the first non-blank character'
          print,'     and are ignored as are blank lines.  File contains lines'
          print,'     with tag = value pairs (spaces around = optional). Ex:'
          print,'       *---  comment line  ---'
          print,'       dir = /aaa/bbb/ccc'
          print,'       num=45'
          print,'       num = 54'
          print,'       num = 23'
          print,'       dist = 23.75'
          print,'       txt=This is a line of text'
          print,'     In the returned structure the default order will be:'
          print,'       DIR, DIST, NUM, TXT unless /NOSORT is used.'
          print,'     Repeated tags become arrays, NUM will have 3 elements.'
	  print,'   tags = list of tags to return (def=all).                in'
	  print,'     See notes for allowed forms.'
	  print,'   s = Returned structure with requested tags.             out'
	  print,' Keywords:'
	  print,'   /CONTINUED or CONTINUED=char.  Merge continued lines'
	  print,'     in file or given text array.  Continued lines have a'
	  print,'     continuation character at the end of the line, $ by'
	  print,'     default, but another character may be specified.'
	  print,'   TYPE=typ  Optional type codes array, one for each item'
	  print,'     in the full structure (not the subset).  The typ code'
	  print,'     is the same as given by the size function.  Giving a type'
	  print,'     code array will convert to the target data types.  A good'
	  print,'     way to do the typ codes is to look at the structure without'
	  print,'     it to see the tag order and number.  The types must be given'
          print,'     in the same order as the tags in the returned structure.'
          print,'     Some useful type codes - byte:1, int:2, long:3, float:4,'
          print,'     double:5, string:7, uint:12, ulong:13, long64:14, ulong64:15.'
          print,'     For the example above type=[7,4,2,7] would make DIST be float'
          print,'     and NUM be int by default (or just the opposite with /nosort).'
	  print,'     See x=txtgetkey(/help) for more on the type codes.'
	  print,'   /NOSORT do not sort tags, keep same order as in file.  If used'
          print,'     must keep repeated tags together in file or an error will.'
          print,'     occur (order does not matter by default since tags are sorted.'
	  print,'   ERROR=err  Error flag: 0=ok, 1=file not opened,'
	  print,'     2=no lines in file, 3 or 4=no tags found,'
	  print,'     5=no tags given, null string returned.'
	  print,' Notes: The list of tags in tags is processed by'
	  print,'   wordarray to allow a flexible input (list or array).'
	  print,"   Examples: 'a b c d' or 'a,b,c,d' or ['a','b','c','d']"
	  print,'   are example allowed as tag lists.'
	  print,'   See wordarray,/help for allowed keywords.'
	  print,'   See putfile_tags for adding or updating tags in a text'
	  print,'   file.'
	  return,''
	endif
 
	;-------------------------------------------------
	;  Read file into a structure
	;-------------------------------------------------
	err = 0
	if n_elements(file) gt 1 then begin
	  t = file
	endif else begin
	  t = getfile(file,err=err)		; Read file into string array.
	  if err ne 0 then begin
	    err = 1
	    return,''
	  endif
	endelse
	t = drop_comments(t,/quiet)		; Ignore comments.
	if n_elements(cont) gt 0 then begin	; Merge continued lines?
	  if strtrim(cont,2) eq '1' then cchr='$' else cchr=cont ; Set con char.
	  t = txtmercon(t,char=cchr)		; Merge lines.
	endif
	strfind,t,'=',index=in,/quiet,count=cnt	; Find tag=val lines.
	if cnt gt 0 then begin			; Found tag=val lines.
	  s0 = txtgetkey(init=t[in], $		; Grab all tag/value pairs.
	    type=typ, nosort=nosort, /structure)
	  if n_elements(tags) eq 0 then return,s0 ; Return all tags.
	  tags0 = tag_names(s0)			; All tags from file.
	  n0 = n_elements(tags0)		; Number of tags.
	  flag0 = lonarr(n0)			; Flags for each tag0 element.
	endif else begin			; No tag=val lines.
	  tags0 = ''				; Just set to null.
	  flag0 = ''
	endelse
 
	;-------------------------------------------------
	;  Preprocess input tag list
	;-------------------------------------------------
	if n_elements(tags) eq 0 then begin	; No tags given and file
	  err = 5				; wasn't found.
	  return,''
	endif
	wordarray, tags, taglist, del=',',/white,_extra=extra
	taglist = strupcase(taglist)		; All uppercase.
 
	;-------------------------------------------------
	;  Find and flag requested subset
	;  If a requested tag found set a flag in the
	;  the full list flag array, flag0.  If not found
	;  set a flag in the requested tags flag array,
	;  flag.  Not found items will return as NULLs.
	;-------------------------------------------------
	n = n_elements(taglist)			; Number of requested tags.
	flag = lonarr(n)			; Flags for each requested tag.
	for i=0,n-1 do begin			; loop through requested tags.
	  w = where(taglist[i] eq tags0,cnt)	; Find requested tag in file.
	  if cnt eq 0 then begin		; Was tag found?
	    flag[i] = 1				; No, set not found flag.
	  endif else begin
	    flag0[w[0]] = 1			; Yes, set found flag.
	  endelse
	endfor
 
	;-------------------------------------------------
	;  Extract found tags
	;-------------------------------------------------
	in = where(flag0 eq 1, cnt)		; Indices of found flags.
	if cnt gt 0 then begin			; Are there any?
	  s = substruct(s0,in)			; Yes, get subset.
	endif else err = 3			; No tags found.
 
	;-------------------------------------------------
	;  Deal with missing flags
	;-------------------------------------------------
	in = where(flag eq 1, cnt)		; Indices of not found flags.
	if cnt eq 0 then begin			; No unfound flags.
	  if n_elements(s) eq 0 then begin	; But no found flags either.
	    err = 4				; Shouldn't get here.
	    return,''
	  endif
	endif
	for i=0,cnt-1 do begin			; Loop through not found tags.
	  tagu = taglist[in[i]]			; Name of missing not found tag.
	  if tagu ne '' then begin
	    if n_elements(s) eq 0 then begin	; Output structure exist?
	      s = create_struct(tagu,'')	; No create it.
	    endif else begin			; Yes.
	      s = create_struct(s,tagu,'')	; Add not found to it as NULL.
	    endelse
	  endif
	endfor
 
	if n_elements(s) eq 0 then begin
	  err = 5
	  return,''
	endif
 
	return, s
 
	end
