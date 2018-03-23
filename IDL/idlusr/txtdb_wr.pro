;-------------------------------------------------------------
;+
; NAME:
;       TXTDB_WR
; PURPOSE:
;       Write a file in txtdb format (columns) from a structure.
; CATEGORY:
; CALLING SEQUENCE:
;       txtdb_wr, file, s
; INPUTS:
;       file = Name of text file to write.     in
;         If file is a null string no file is written.
;       s = Structure with contents to write.  in
; KEYWORD PARAMETERS:
;       Keywords:
;         MAXLEN=mxlen Maximum line length for groups
;           of columns (arrays).  Def=80 characters.
;         HEADER=hdr Optional array of text to write first in file.
;         TRAILER=trl Optional array of text to write last in file.
;         /NOSCALARS Force scalar items to use column output.
;         /NONULL Write a space instead of <NULL> for null strings.
;         OUT=txt Return result in a text array.
;         /LIST list result to screen.
;         /QUIET Do not print messages.
;         ALIAS=new Array of new names to use for structure.
;           If given must have one for each tag in structure.
;         /PADTXT Pad text arrays so all elements are same length.
;         TAGFORMATS=tgfm Formats for specified tags.  Text array
;           with 2 elements for each entry: tag name, format.  Ex:
;             TAGFORMATS=['ANG','(I3.3)','DIST','(F5.2)']
;           The tag in structure s with the name ANG will be have
;           format (I3.3) and the tag named DIST formatted (F5.2).
;           The specified formats will override the defaults.  This
;           can make the output much more compact. Case is ignored.
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
;       Notes: The output file is an ordinary text file
;       and may be modified using a text editor.  It is
;       in a format that may be read back into a structure
;       using txtdb_rd.  Only scalars and 1-d arrays
;       are written from the structure, arrays of 2 or
;       more dimensions are ignored.  Also only string
;       and numeric data types are written, other data types
;       are ignored (such as structures, pointers, objects).
;       Complex data types are currently not handled, they
;       could be added in a future version if needed.
;       String arrays are considered text blocks if the string
;       lengths vary within the array. If the lengths are constant
;       over the array and the number of elements is the same
;       as arrays adjacent in the structure then the string array
;       will be grouped with other adjacent arrays having the same
;       number of elements.  Use /PADTXT to equalize lengths.
; MODIFICATION HISTORY:
;       R. Sterner, 2008 Jan 03
;       R. Sterner, 2008 Aug 15 --- Added optional header and trailer text.
;       R. Sterner, 2008 Oct 28 --- Added /QUIET.  Fixed long tag name problem.
;       R. Sterner, 2008 Nov 20 --- Used tprint. To file, array, or screen.
;       R. Sterner, 2008 Nov 20 --- Added ALIAS to allow renaming.
;       R. Sterner, 2008 Nov 21 --- Added /PADTXT keyword.
;       R. Sterner, 2009 Jan 11 --- Added /NONULL.
;       R. Sterner, 2009 Jan 13 --- Added TAGFORMATS=tgfm.
;       R. Sterner, 2009 Jan 14 --- Data type else (integers) now does formats.
;       R. Sterner, 2009 Sep 10 --- Added /NOSCALARS.
;       R. Sterner, 2014 Feb 12 --- Cleaned up the error handling.
;       R. Sterner, 2014 Feb 12 --- Added error flag.
;
; Copyright (C) 2008, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro txtdb_wr, file, s, maxlen=mxlen0, $
	  header=head, trailer=trail, quiet=quiet, $
	  out=outtxt, list=list, alias=new0, padtxt=pad, $
	  nonull=nonull, tagformats=tgfm, noscalars=noscalars, $
          error=err, help=hlp
 
	if (n_params(0) lt 2) or keyword_set(hlp) then begin
	  print,' Write a file in txtdb format (columns) from a structure.'
	  print,' txtdb_wr, file, s'
	  print,'   file = Name of text file to write.     in'
	  print,'     If file is a null string no file is written.'
	  print,'   s = Structure with contents to write.  in'
	  print,' Keywords:'
	  print,'   MAXLEN=mxlen Maximum line length for groups'
	  print,'     of columns (arrays).  Def=80 characters.'
	  print,'   HEADER=hdr Optional array of text to write first in file.'
	  print,'   TRAILER=trl Optional array of text to write last in file.'
	  print,'   /NOSCALARS Force scalar items to use column output.'
	  print,'   /NONULL Write a space instead of <NULL> for null strings.'
	  print,'   OUT=txt Return result in a text array.'
	  print,'   /LIST list result to screen.'
	  print,'   /QUIET Do not print messages.'
	  print,'   ALIAS=new Array of new names to use for structure.'
	  print,'     If given must have one for each tag in structure.'
	  print,'   /PADTXT Pad text arrays so all elements are same length.'
	  print,'   TAGFORMATS=tgfm Formats for specified tags.  Text array'
	  print,'     with 2 elements for each entry: tag name, format.  Ex:'
	  print,"       TAGFORMATS=['ANG','(I3.3)','DIST','(F5.2)']"
	  print,'     The tag in structure s with the name ANG will be have'
	  print,'     format (I3.3) and the tag named DIST formatted (F5.2).'
	  print,'     The specified formats will override the defaults.  This'
	  print,'     can make the output much more compact. Case is ignored.'
          print,'   ERROR=err Write error flag: 0=ok.'
	  print,' Notes: The output file is an ordinary text file'
	  print,' and may be modified using a text editor.  It is'
	  print,' in a format that may be read back into a structure'
	  print,' using txtdb_rd.  Only scalars and 1-d arrays'
	  print,' are written from the structure, arrays of 2 or'
	  print,' more dimensions are ignored.  Also only string'
	  print,' and numeric data types are written, other data types'
	  print,' are ignored (such as structures, pointers, objects).'
	  print,' Complex data types are currently not handled, they'
	  print,' could be added in a future version if needed.'
	  print,' String arrays are considered text blocks if the string'
	  print,' lengths vary within the array. If the lengths are constant'
	  print,' over the array and the number of elements is the same'
	  print,' as arrays adjacent in the structure then the string array'
	  print,' will be grouped with other adjacent arrays having the same'
	  print,' number of elements.  Use /PADTXT to equalize lengths.'
	  return
	endif
 
        err = 0

	;------------------------------------------------------------------
	;  Check for structure
	;------------------------------------------------------------------
	if datatype(s) ne 'STC' then begin
	  if not keyword_set(quiet) then $
	    print,' Error in txtdb_wr: Must give data packed in a structure.'
          err = 1
	  return
	endif
 
	;------------------------------------------------------------------
	;  Initialize
	;------------------------------------------------------------------
	tags = tag_names(s)			; Tag names.
	if n_elements(new0) eq 0 then new0=tags ; Default new names = old.
	new = new0
	if n_elements(new) ne n_elements(tags) then new=tags ; Must match #.
	tags2 = new				; Output names.
	n = n_tags(s)				; # tags.
	acnt = 0				; Array counter.
	numlst = 0				; Last array length.
	sep = '  '				; Some space.
	slen = strlen(sep)			; Length of space.
	tlen = 0				; Total length so far.
	if n_elements(mxlen0) gt 0 then begin	; Set max allowed length.
	  mxlen = mxlen0
	endif else mxlen=80
	add_blnk = 0				; Add a blank line. 0=no.
	;---  Default formats for data types  ---
	def_fmt = ['B','','F','(G16.8)','D','(G26.17)','S','','ELSE','']
 
	;------------------------------------------------------------------
	;  Start output
	;------------------------------------------------------------------
	tprint,/init
	tprint,' '
 
	;------------------------------------------------------------------
	;  Write out any header text
	;------------------------------------------------------------------
	if n_elements(head) gt 0 then begin
	  for i=0,n_elements(head)-1 do begin
	    tprint,sep+head[i]
	  endfor
	  tprint,' '
	endif
 
	;------------------------------------------------------------------
	;  Loop over structure tags
	;------------------------------------------------------------------
	for i=0,n-1 do begin
 
	  ;----------------------------------------------------
	  ;  Deal with i'th value in structure
	  ;    Ignore multidimensional arrays and
	  ;    non-numeric items.  Format for output.
	  ;----------------------------------------------------
	  v = s.(i)				; i'th value.
	  if dimsz(v,0) gt 1 then begin		; Ignore arrays with dim>1.
	    if not keyword_set(quiet) then $
	      print,' Warning in txtdb_wr: Ignoring multidimensional array: '+$
	        tags[i]
	    continue
	  endif
	  typ0 = datatype(v,4)			; Get data type.
	  skip = 0				; Skip this item? 0=no.
 
	  fmt = aarr(def_fmt,typ0,/q)		; Get default format.
	  if n_elements(tgfm) ne 0 then begin
	    fmt1 = aarr(tgfm,tags[i],/quiet,/ignore)  ; See if tag has format.
	    ;---  Check for format errors  ---
	    catch, error_status
	    if error_status ne 0 then begin
	      PRINT, ' Error in txtdb_wr: Problem with given format for tag '+tags[i]
	      PRINT, '  '+!ERROR_STATE.MSG
	      fmt1 = ''				; If format is bad ignore it.
	      CATCH, /CANCEL
	    endif
	    test = string(1,form=fmt1)		; Test format. Catch any error.
	    CATCH, /CANCEL
	    ;---  End format check  ---
	    if fmt1 ne '' then fmt=fmt1		; If no error then use it.
	  endif
 
	  case typ0 of				; Convert to string.
'B':	  begin
	    if fmt eq '' then begin
	      tv = string(fix(v))		; Must promote bytes.
	    endif else begin
	      tv = string(fix(v),form=fmt)	; Given format.
	    endelse
	  end
'F':	  begin
	    tv = string(v,form=fmt)		; More figures for float.
	  end
'D':	  begin
	    tv = string(v,form=fmt)		; Even more for double.
	  end
'S':	  begin					; Strings.
	    w = where(v eq '',cnt)		; txtdb_rd does not read
	    if cnt gt 0 then begin		; null strings well. So use
	      if keyword_set(nonull) then begin
		v[w] = ' '			; a space instead (if /nonull)
	      endif else begin
	        v[w]='<NULL>'			; or <NULL> as a placeholder.
	      endelse
	    endif
	    if fmt eq '' then begin
	      tv = v
	    endif else begin
	      tv = string(strtrim(v,2),form=fmt)
	    endelse
	  end
else:	  begin					; All other types.
	    if isnumber(v) ge 1 then begin	; Number (integer types).
	      if fmt eq '' then begin
	        tv = string(v)
	      endif else begin
	        tv = string(v,form=fmt)
	      endelse
	    endif else begin
	      skip = 1				; Ignore non-numeric.
	    endelse
	  end
	  endcase
 
	  if skip then begin			; Skip non-numeric.
	    if not keyword_set(quiet) then $
	      print,' Warning in txtdb_wr: Ignoring non-numeric item: '+ $
	        tags[i]
	    continue
	  endif
	  num = n_elements(v)			; Size of v.
 
	  ;----------------------------------------------------
	  ;  Item is an array
	  ;    If the string lengths vary in the array
	  ;    then write it as a text block instead of
	  ;    grouping it with other arrays.  Otherwise
	  ;    add it to an array group if it has the same
	  ;    number of elements (and the group width is not
	  ;    over the limit).
	  ;----------------------------------------------------
;	  if num gt 1 then begin		; Array.
	  if (num gt 1) or keyword_set(noscalars) then begin	; Array.
	    ;---  Check and handle text blocks  ---
	    if typ0 eq 'S' then begin		  ; Check if text block.
	      if keyword_set(pad) then tv=txtpad(tv) ; Equalize lengths.
	      len = strlen(tv)			  ; Get lengths of each line.
	      if min(len) ne max(len) then begin  ; They vary, Text block.
		for j=0,n_elements(tv)-1 do tprint,sep+tv[j]
		tprint,' '
		continue			; Done with this item.
	      endif
	    endif
	    ;--  Deal with array  ---
	    len = strlen(tv[0])>strlen(tags2[i]); Length of stringed array.
	    tv = strmid(tv+spc(len),0,len)	; Adjust array string length.
	    frm = '(A'+strtrim(len,2)+')'	; String of length len.
	    nam = string(tags2[i],form=frm)	; Tag name.
	    typ = string(typ0,form=frm)		; Data type.
	    ref = spc(len,char='-')		; Reference line.
	    tv = sep + transpose([nam,typ,ref,tv]) ; Column with array.
	    tlen = tlen + len + slen		; Total length with new item.
	    if tlen gt mxlen then numlst=0	; Trigger a new group.
	    if num ne numlst then begin		; If different length new grp.
	      if acnt gt 0 then begin		; Write old if any.
		frm = '('+strtrim(dimsz(tt,1),2)+'A)'
	        if add_blnk then tprint,' '
	        tt2 = string(tt,form=frm)	; Format array group.
	        tprint,tt2			; Write it out.
	        tprint,' '
	        add_blnk = 0
	        acnt = 0
	        tlen = 0
	      endif ; acnt
	    endif ; num
	    numlst = num			; Remember array length.
	    if acnt eq 0 then begin		; If no arrays in group
	      tt = tv				;   Start a new array group.
	    endif else begin
	      tt = [tt,tv]			;   Else add to existing group.
	    endelse
	    acnt += 1				; Count added array.
 
	  ;----------------------------------------------------
	  ;  Item is a scalar
	  ;    If a group of arrays was being built write
	  ;    it out before writing the scalar.
	  ;----------------------------------------------------
	  endif else begin
	    ;---  Write any array block out  ---
	    if acnt gt 0 then begin
	      frm = '('+strtrim(dimsz(tt,1),2)+'A)'
	      if add_blnk then tprint,' '
	      tt2 = string(tt,form=frm)
	      tprint,tt2
	      tprint,' '
	      acnt = 0
	      tlen = 0
	    endif
	    ;---  Write out the scalar  ---
	    tprint,sep + tags2[i] + ' = ' + string(v)
	    add_blnk = 1
	  endelse
 
	endfor ; i
	;------------------------------------------------------------------
	;  End loop over structure tags
	;------------------------------------------------------------------
 
	;------------------------------------------------------------------
	;  Write out any left over array blocks
	;------------------------------------------------------------------
	if acnt gt 0 then begin			 ; Write any array block out.
	  frm = '('+strtrim(dimsz(tt,1),2)+'A)'
	  if add_blnk then tprint,' '
	  tt2 = string(tt,form=frm)
	  tprint,tt2
	  tprint,' '
	endif
 
	;------------------------------------------------------------------
	;  Write out any trailer text
	;------------------------------------------------------------------
	if n_elements(trail) gt 0 then begin
	  for i=0,n_elements(trail)-1 do begin
	    tprint,sep+trail[i]
	  endfor
	  tprint,' '
	endif
 
	;------------------------------------------------------------------
	;  Output result
	;------------------------------------------------------------------
        ;---  Catch any write error  ---
        catch, error_status
        if error_status ne 0 then begin
          PRINT, ' Problem saving the file '+file
          print, ' '+ !ERROR_STATE.MSG
          print,' Check that directory exists, and has permission to write.'
          print,' Write ignored.'
          CATCH, /CANCEL
          err = 1
          return
        endif

        if file ne '' then tprint,save=file,quiet=quiet
        CATCH, /CANCEL

	if arg_present(outtxt) then tprint,out=outtxt
	if keyword_set(list) then tprint,/print
 
	end
