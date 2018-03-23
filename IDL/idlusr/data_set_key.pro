;-------------------------------------------------------------
;+
; NAME:
;       DATA_SET_KEY
; PURPOSE:
;       Get data set info given a key.
; CATEGORY:
; CALLING SEQUENCE:
;       data_set_key, key, s
; INPUTS:
;       key = key for data set.   in
; KEYWORD PARAMETERS:
;       Keywords:
;        /LIST List data sets.
;        /INIT initialize internal copy again.
;        ERROR=err Error flag: 0=ok.
; OUTPUTS:
;       s = structure with info.  out
; COMMON BLOCKS:
;       data_set_key_com
; NOTES:
;       Notes: The info is from the text file named data_set_key.txt
;       which must be located in the users home directory.
;       Layout of data_set_key.txt:
;       Comments (* as first character) and null lines are allowed.
;       For each key must have one line:
;          key_dataset = value
;       Example: etopo1_dataset = /elevation/etopo1_ice_c.res
;       May also have any number (0 or more) of lines:
;          key_tag1 = line 1
;          key_tag1 = line 2
;          . . .
;       For example:
;          key_notes = line 1
;          key_notes = line 2
;          . . .
;       May have lines prefixed by key_ as needed, like
;           ybs_mag = m1
;           ybs_mag = m2
;          . . .
;       Use the key 'ybs' to access all the ybs_* lines.
;       The key_ is dropped in the returned structure, so the
;       main value will always by under the tag s.datatset.
;       It is useful to have one or more description comments in
;       front of the dataset and notes lines.
; MODIFICATION HISTORY:
;       R. Sterner, 2010 Feb 23
;
; Copyright (C) 2010, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro data_set_key, key, s, help=hlp, list=list, init=init, error=err
 
	common data_set_key_com, s0, file
 
	if keyword_set(hlp) then begin
	  print,' Get data set info given a key.'
	  print,' data_set_key, key, s'
	  print,'   key = key for data set.   in'
	  print,'   s = structure with info.  out'
	  print,' Keywords:'
	  print,'  /LIST List data sets.'
	  print,'  /INIT initialize internal copy again.'
	  print,'  ERROR=err Error flag: 0=ok.'
	  print,' Notes: The info is from the text file named data_set_key.txt'
	  print,' which must be located in the users home directory.'
	  print,' Layout of data_set_key.txt:'
	  print,' Comments (* as first character) and null lines are allowed.'
	  print,' For each key must have one line:'
	  print,'    key_dataset = value'
	  print,' Example: etopo1_dataset = /elevation/etopo1_ice_c.res'
	  print,' May also have any number (0 or more) of lines:'
	  print,'    key_tag1 = line 1'
	  print,'    key_tag1 = line 2'
	  print,'    . . .'
	  print,' For example:'
	  print,'    key_notes = line 1'
	  print,'    key_notes = line 2'
	  print,'    . . .'
	  print,' May have lines prefixed by key_ as needed, like'
	  print,'     ybs_mag = m1'
	  print,'     ybs_mag = m2'
	  print,'    . . .'
	  print," Use the key 'ybs' to access all the ybs_* lines."
	  print,' The key_ is dropped in the returned structure, so the'
	  print,' main value will always by under the tag s.datatset.'
	  print,' It is useful to have one or more description comments in'
	  print,' front of the dataset and notes lines.' 
	  return
	endif
 
	;-------------------------------------------------------
	;  Initialize common
	;-------------------------------------------------------
	iflag = 0
	if n_elements(s0) eq 0 then iflag = 1
	if keyword_set(init) then iflag = 1
	if iflag then begin
	  home = getenv('HOME')
	  if home eq '' then begin
	    print,' Error in data_set_key: Must define the environment'
	    print,'   variable HOME to point to the users home directory.'
	    err = 1
	    return
	  endif
	  kfile = 'data_set_key.txt'
	  file = filename(home,kfile,/nosym)
	  f= file_search(file,count=cnt)
	  if cnt eq 0 then begin
	    print,' Error in data_set_key: must set up a file named'
	    print,'   data_set_key.txt in the home directory.'
	    print,'   See data_set_key, /help for details.'
	    err = 1
	    return
	  endif
	  t = getfile(file)
	  t = drop_comments(t)
	  s0 = txtgetkey(init=t,/structure)
	endif
 
	;-------------------------------------------------------
	;  List
	;-------------------------------------------------------
	if keyword_set(list) then begin
	  tag = tag_names(s0)
	  strfind, tag, '_DATASET', out=txt,/quiet
	  print,' '
	  print,' Data sets defined in '+file
	  print,' '
	  for i=0, n_elements(txt)-1 do begin
	    print,' '+txt[i]+' = '+tag_value(s0,txt[i])
	  print,' '
	  endfor
	  err = 0
	  return
	endif
 
	;-------------------------------------------------------
	;  Return values for requested key
	;-------------------------------------------------------
	if n_elements(key) eq 0 then begin
	  print,' Error in data_set_key: Given key is undefined.'
	  err = 1
	  return
	endif
	tag = tag_names(s0)
	strfind, tag, key, out=txt,/quiet,count=cnt
	if cnt eq 0 then begin
	  print,' Error in data_set_key: Given key was not found in '+file
	  err = 1
	  return
	endif
	tag2 = strmid(tag,strlen(key)+1)
	v = tag_value(s0,tag[0])
	s = create_struct(tag2[0],v)
	for i=1,n_elements(tag)-1 do begin
	  v = tag_value(s0,tag[i])
	  s = create_struct(s,tag2[i],v)
	endfor
	err = 0
 
	end
