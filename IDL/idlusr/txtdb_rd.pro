;-------------------------------------------------------------
;+
; NAME:
;       TXTDB_RD
; PURPOSE:
;       Read a text file data base.
; CATEGORY:
; CALLING SEQUENCE:
;       s = txtdb_rd(file)
; INPUTS:
;       file = name of text file with data base.  in
;         File may instead be the text array that would have
;         been read from the file (same format).
; KEYWORD PARAMETERS:
;       Keywords:
;         ERROR=err Error flag: 0=ok.
;         /QUIET do not show warning and error messages.
;         TAB=tab Spaces/tab (def=8).
;         /DEBUG use debug mode.  Shows how text is processed.
;           May also do DEBUG=n to show details for n'th data item.
;         DROP=com_chars List of comment characters (def=';*').
;            Any line starting with any will be dropped.  By default
;            drops lines with ; or * in column 1.
;         /NODROP do not drop any lines.
;         /NOHEADERS  exclude header (or trailer) lines in output.
;            Any header variables will still be included.
;         /NOHVARS do not include header variables in output.
;         /NO_NULL do not replace <NULL> with a null string.
;           txtdb_wr uses <NULL> for null strings.
;         /EXECUTE Execute a statement (see below).  This allows
;           values that are functions of other values in the file.
;         /REFOPT Reference lines are optional, consider all header.
;           This is useful to use only header variables.  Do not
;           use /NOHEADERS with this option.
; OUTPUTS:
;       s = returned structure with data.         out
; COMMON BLOCKS:
; NOTES:
;       Note: The text file with the data to read must have a
;       certain layout.  It is an ordinary text file, perhaps
;       wider than normal if that is needed.  It can have the
;       following sections:
;         Header lines    (n lines, optional) |
;         Data decription (3 lines, required)  > This group may be
;         Data lines      (n lines, required) |  repeated any number
;         Blank line      (1 line, required)  |  of times.
;         Trailer lines   (n lines, optional)
;       An example: (The string "<--" below is not part of file):
;       Header line 1                 <-- Header lines
;       Header line 2                     ...
;       code  length  weight  color   <-- Tag line
;        int   flt     flt     str    <-- Type line
;       ----- ------  ------  -----   <-- Reference line
;         1    2.34    32.7     Red   <-- data lines
;         2    3.17    25.5    Blue       ...
;         3    1.42    14.3   Green
;                                     <-- Blank line, end of data
;       Trailer line 1                <-- Trailer lines
;       Trailer line 2                    ...
;       
;       Blank data entries are allowed and will be returned as 0 or
;       null strings.  However each data line must have at least
;       one entry since a blank line terminates the data block.
;       
;       After the blank line at the end of the data lines, the
;       pattern: header lines, tag line, type line, reference line,
;       data lines may be repeated any number of times.  Just
;       make sure each group of data lines is followed by a
;       blank line.  Header lines are optional as before.
;       
;       The reference line is the key line.  It defines the column
;       locations for the data, tag names, and data types, so those
;       items must all fall within the width defined in the
;       reference line. The reference line must use groups of dashes
;       to specify these positions.  Do help,typ2num() to see
;       how to specify the data types.  Also * or ; as data type
;       will ignore that column, useful for row labels.
;       
;       The column data will be in arrays with names given in the
;       tag line.
;       
;       Text before the data lines are returned in items named
;       __textxxx where xxx is a 3 digit count.
;       Any trailer text will be returned the same way.
;       
;       VARIABLES:
;       Headers and the trailer may contain optional variables in
;       the form: tag = value
;       (Comment lines are ignore and will not be processed)
;       The tags/values will be added to the output structure.
;       Header (Trailer) variable values are returned as string type.
;       Numeric strings may be converted by the user in their code.
;       Repeated header variables are allowed and return arrays:
;         tag1 = val1
;         tag1 = val2
;       
;       EXECUTE:
;       Header and trailer variables may contain expressions,
;       including values that have already been read from the
;       text file.  Add the string EXECUTE_ (case ignored) at the
;       front of the tag.  Values that have already been read from
;       the file are in the internal structure s, they may be used
;       from this structure.  For example:
;         execute_lat10 = 10*s.lat
;       will return a structure element lat10 that is 10 times
;       the structure element lat.
;       --> Executed variables may only reference values that
;       have been defined above in the file.  They are in the
;       internal structure named s.  Header variables will be strings
;       so must be converted to numeric if needed.
;       --> Must use the keyword /EXECUTE to process these variables.
;       The added item will normally be placed at the end of the
;       current structure.  It may be placed after a specified tag
;       by adding ; @ tag at the end of the line, where tag is the
;       name of the tag to follow.  Use ^ for tag to add it to the
;       front of the structure: @ ^.  The target tag must be the next
;       item after @ but the trailing comment may contain other text.
;       This is useful when resulting structure will be written
;       out using txtdb_wr.
;
; MODIFICATION HISTORY:
;       R. Sterner, 2003 Aug 26
;       R. Sterner, 2003 Aug 28 --- Allowed multiple data blocks.
;       R. Sterner, 2003 Sep 02 --- Renamed from rd_txtdb.pro.
;       R. Sterner, 2003 Sep 03 --- Allowed ignored data columns.
;       R. Sterner, 2003 Dec 09 --- Did strtrim on each item, instead of
;       strcompress,/remove_all.  That allows spaces in strings.
;       R. Sterner, 2004 Feb 25 --- Allowed text array to be given.
;       R. Sterner, 2006 Mar 21 --- Added new data type: DMS.
;       R. Sterner, 2006 Mar 27 --- Added new keywords: DROP=drop, /NODROP.
;       R. Sterner, 2006 Jun 08 --- Fixed loop limits to be long int.
;       R. Sterner, 2007 Dec 25 --- Allowed header variables.
;       R. Sterner, 2007 Dec 27 --- Check for blank headers, don't add.
;       R. Sterner, 2007 Dec 27 --- Added /NOHEADERS and /NOHVARS.
;       R. Sterner, 2008 Jan 04 --- Handled <NULL> for null strings.
;       R. Sterner, 2008 Jan 23 --- Header tag=val kept only if tag first item.
;       R. Sterner, 2008 Apr 14 --- Fixed minor problem with trailer vars.
;       R. Sterner, 2008 Apr 14 --- Added EXECUTE variables.
;       R. Sterner, 2008 Nov 20 --- Allowed placement of execute variables.
;       R. Sterner, 2009 Jun 02 --- Added /REFOPT to consider all one header.
;       R. Sterner, 2009 Jun 29 --- Now by default gives error if file not read.
;       R. Sterner, 2010 May 03 --- Converted arrays from () to [].
;       R. Sterner, 2010 May 03 --- DMS now uses llsigned instead of dms2d.
;       R. Sterner, 2012 Sep 10 --- Checks for blank line after reference line.
;       R. Sterner, 2013 Nov 19 --- Allowed repeated header variables (arrays).
;       R. Sterner, 2014 Jan 27 --- Allowed repeated trailer variables (arrays).
;       R. Sterner, 2014 Jan 27 --- Added CODE_BLOCKS=list, allowed merged lines ($).
;       R. Sterner, 2014 Apr 04 --- Cleaned up help text.
;
; Copyright (C) 2003, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	function txtdb_rd, file, error=err, debug=debug, quiet=quiet, $
	  tab=tab, drop=drop, nodrop=nodrop, $
	  noheaders=nohead, nohvars=nohvar, no_null=no_null, $
	  execute=exec, refopt=refopt, code_blocks=codevar, help=hlp
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Read a text file data base.'
	  print,' s = txtdb_rd(file)'
	  print,'   file = name of text file with data base.  in'
	  print,'     File may instead be the text array that would have'
	  print,'     been read from the file (same format).'
	  print,'   s = returned structure with data.         out'
	  print,' Keywords:'
	  print,'   ERROR=err Error flag: 0=ok.'
	  print,'   /QUIET do not show warning and error messages.'
	  print,'   TAB=tab Spaces per tab (def=8).'
	  print,'   /DEBUG use debug mode.  Shows how text is processed.'
	  print,"     May also do DEBUG=n to show details for n'th data item."
	  print,"   DROP=com_chars List of comment characters (def=';*')."
	  print,'      Any line starting with any will be dropped.  By default'
	  print,'      drops lines with ; or * in column 1.'
	  print,'   /NODROP do not drop any lines.'
	  print,'   /NOHEADERS  exclude header (or trailer) lines in output.'
	  print,'      Any header variables will still be included.'
	  print,'   /NOHVARS do not include header variables in output.'
	  print,'   /NO_NULL do not replace <NULL> with a null string.'
	  print,'     txtdb_wr uses <NULL> for null strings.'
	  print,'   /EXECUTE Execute a statement (see below).  This allows'
	  print,'     values that are functions of other values in the file.'
          print,'   CODE_BLOCKS=var_names  Execute blocks of code (see below).'
          print,'     This allows things like plots to be made of the data in'
          print,'     the txtdb file.  Multiple such blocks are allow and one'
          print,'     or more may be given here to execute.'
	  print,'   /REFOPT Reference lines are optional, consider all header.'
	  print,'     This is useful to use only header variables.  Do not'
	  print,'     use /NOHEADERS with this option.'
	  print,' Note: The text file with the data to read must have a'
	  print,' certain layout.  It is an ordinary text file, perhaps'
	  print,' wider than normal if that is needed.  It can have the'
	  print,' following sections:'
	  print,'   Header lines    (n lines, optional) |'
	  print,'   Data decription (3 lines, required)  > This group may be'
	  print,'   Data lines      (n lines, required) |  repeated any number'
	  print,'   Blank line      (1 line, required)  |  of times.'
	  print,'   Trailer lines   (n lines, optional)'
	  print,' An example: (The string "<--" below is not part of file):'
	  print,' Header line 1                 <-- Header lines'
	  print,' Header line 2                     ...'
	  print,' code  length  weight  color   <-- Tag line'
	  print,'  int   flt     flt     str    <-- Type line'
	  print,' ----- ------  ------  -----   <-- Reference line'
	  print,'   1    2.34    32.7     Red   <-- data lines'
	  print,'   2    3.17    25.5    Blue       ...'
	  print,'   3    1.42    14.3   Green'
	  print,'                               <-- Blank line, end of data'
	  print,' Trailer line 1                <-- Trailer lines'
	  print,' Trailer line 2                    ...'
	  print,' '
	  print,' Blank data entries are allowed and will be returned as 0 or'
	  print,' null strings.  However each data line must have at least'
	  print,' one entry since a blank line terminates the data block.'
	  print,' '
	  print,' After the blank line at the end of the data lines, the'
	  print,' pattern: header lines, tag line, type line, reference line,'
	  print,' data lines may be repeated any number of times.  Just'
	  print,' make sure each group of data lines is followed by a'
	  print,' blank line.  Header lines are optional as before.'
	  print,' '
	  print,' The reference line is the key line.  It defines the column'
	  print,' locations for the data, tag names, and data types, so those'
	  print,' items must all fall within the width defined in the'
	  print,' reference line. The reference line must use groups of dashes'
	  print,' to specify these positions.  Do help,typ2num() to see'
	  print,' how to specify the data types.  Also * or ; as data type'
	  print,' will ignore that column, useful for row labels.'
	  print,' '
	  print,' The returned column data will be in arrays with names given'
	  print,' in the tag line.'
	  print,' '
	  print,' Text before the data lines are returned in items named'
	  print,' __textxxx where xxx is a 3 digit count.'
	  print,' Any trailer text will be returned the same way.'
	  print,' '
	  print,' VARIABLES:'
	  print,' Headers and the trailer may contain optional variables in'
	  print,' the form: tag = value'
	  print,' (Comment lines are ignore and will not be processed)'
	  print,' The tags/values will be added to the output structure.'
	  print,' Header (Trailer) variable values are returned as string type.'
	  print,' Numeric strings may be converted by the user in their code.'
          print,' Repeated header variables are allowed and return arrays:'
          print,'   tag1 = val1'
          print,'   tag1 = val2'
	  print,' '
	  print,' EXECUTE:'
	  print,' Header and trailer variables may contain expressions,'
	  print,' including values that have already been read from the'
	  print,' text file.  Add the string EXECUTE_ (case ignored) at the'
	  print,' front of the tag.  Values that have already been read from'
	  print,' the file are in the internal structure s, they may be used'
	  print,' from this structure.  For example:'
	  print,'   execute_lat10 = 10*s.lat'
	  print,' will return a structure element lat10 that is 10 times'
	  print,' the structure element lat.'
          print,' Functions may also be used.  For example:'
          print,'   execute_dist_m = ell_track_dist(s.lon,s.lat)'
          print,' will add the variable dist_m to the returned structure.'
	  print,' --> Executed variables may only reference values that'
	  print,' have been defined above in the file.  They are in the'
	  print,' internal structure named s.  Header variables will be strings'
	  print,' so must be converted to numeric if needed.'
	  print,' --> Must use the keyword /EXECUTE to process these variables.'
	  print,' The added item will normally be placed at the end of the'
	  print,' current structure.  It may be placed after a specified tag'
	  print,' by adding ; @ tag at the end of the line, where tag is the'
	  print,' name of the tag to follow.  Use ^ for tag to add it to the'
	  print,' front of the structure: @ ^.  The target tag must be the next'
	  print,' item after @ but the trailing comment may contain other text.'
	  print,' This is useful when resulting structure will be written'
	  print,' out using txtdb_wr.  For example'
          print,'   EXECUTE_ETIME = elap_time(s.time,s.alt,s.v_vert)   ; @ TIME'
          print,' adds the variable ETIME to the returned structure following'
          print,' the variable TIME.  Case is ignored.'
          print,' '
          print,' CODE_BLOCKS:'
          print,' Blocks of IDL code can be given as header or trailer variables'
          print,' which may be repeated to give multiple lines of code.  Any'
          print,' number of independent such blocks may be included, each under'
          print,' their own variable name.  Then in the txtdb_rd call these can'
          print,' be listed to execute that code.  Some examples:'
          print,"   s = txtdb_rd(filename, code_block='plot1'"
          print,"   s = txtdb_rd(filename, code_blocks=['plot1','overlay1']"
          print,"   s = txtdb_rd(filename, code_blocks=['plot2','overlay1','overlay3']"
          print,' Some examples of such code in the txtdb file:'
          print,'   plot1 = plot,s.x,s.y,col=255'
          print,' '
          print,'   plot2 = x = s.x'
          print,'   plot2 = y = s.y'
          print,'   plot2 = plot,x,y,col=clr'
          print,' '
          print,'   overlay1 = hor, 50'
          print,'   overlay2 = hor, 100'
          print,'   overlay3 = hor, 150'
          print,' '
          print,' Long lines may be continued over multiple lines using a trailing $.'
          print,' Local variables may be defined and used.  The internal structure'
          print,' containing all the data in the file is called s so avoid that variable'
          print,' name, but other names should be safe (except for _i,_c,_r,_v,_iv).'
          print,' Possible useful code execution commands could be listed as'
          print,' comments in the file itself.'
          print,' -------------------------------------------------------------------'
	  return,''
	endif
 
	if n_elements(tab) eq 0 then tab=8
 
	;------------------------------------------------------------
	;  Get text
	;------------------------------------------------------------
	;---  Read text from file  ---
	if n_elements(file) eq 1 then begin
	  t = getfile(file,err=err)	; Read text file.
	  if err ne 0 then begin
	    if not keyword_set(quiet) then $
	      print,' Error in txtdb_rd: file not read: '+file
	    return,''
	  endif
	;---  Text was given  ---
	endif else begin
	  t = file
	endelse

	;------------------------------------------------------------
	;  Deal with any commented out lines
	;------------------------------------------------------------
	if not keyword_set(nodrop) then begin
	  if n_elements(drop) eq 0 then drop=';*'
	  t = drop_comments(t, ignore=drop, /notrim, /null)
	endif
 
	n = n_elements(t)		; # lines.
 
	;------------------------------------------------------------
	;  Deal with tabs
	;------------------------------------------------------------
	bt = byte(t)			; Convert to bytes.
	w = where(bt eq 9,cnt9)		; Check for tabs.
	if cnt9 ne 0 then begin		; Found tabs.
	  if not keyword_set(quiet) then begin
	    print,' Warning in txtdb_rd: tabs found in '+file
	    print,'   Removing assuming '+strtrim(tab,2)+' spaces/tab'
	  endif
	  for i=0L,n-1 do t[i]=detab(t[i],tab=tab)  ; Detab.
	endif
 
	;------------------------------------------------------------
	;  Search for reference line (all -)
	;------------------------------------------------------------
	tc = strcompress(t,/rem)	; Remove all whitespace.
	b = byte(tc)			; Convert to byte.
	flag = 0			; Ref line found yet? 0=no.
	if keyword_set(debug) then begin
	  print,' Read file '+file
	  print,' Removed all white space.'
	  print,' Number of lines in file = ',n
	endif
 
	irefa = [0]			; Start iref array with a seed value.
	for i=0L,n-1 do begin		; Search for reference line.
	  bb = b[*,i]			; I'th line (as bytes).
	  w = where((histogram(bb))[1:*] gt 0,cnt)  ; # diff chars in line.
	  if cnt eq 1 then begin	; Ref line should have only 1 kind.
	    if bb[0] ne 45 then continue   ; and must be a -.
	    flag = 1			; Found reference line.
	    irefa = [irefa,i]		; Remember index of ref line.
	    if keyword_set(debug) then begin
	      print,' Found reference line at line # ',i
	      print,' Ref line: '+t[i]
	    endif
	  endif
	endfor
 
	if flag ne 0 then begin		; Found reference line(s).
	  irefa=irefa[1:*]		; Drop seed value.
	  numref = n_elements(irefa)	; Number of reference lines.
	endif else begin		; No reference lines.
	  numref = 0
	endelse
 
	;------------------------------------------------------------
	;  No reference line found
	;
	;  Special Case:
	;  If the keyword /REFOPT (reference line(s) optional) was
	;  used then the entire text after dropping comments is
	;  treated as a header.  It may contain header variables.
	;  This is useful when some values may be scalars or arrays.
	;------------------------------------------------------------
	if flag eq 0 then begin
	  if keyword_set(refopt) then begin  ; Reference lines are optional.
	    hdr = t			; Consider all the text as a header.
	    hflag = 1			; Set header flag.
	    hdrcnt = 0			; Header counter.
	    goto, jump_refopt		; Process this special case.
	  endif else begin		; Must have reference lines.
	    print,' Error in txtdb_rd: could not find the reference line.'
	    print,'   The reference line uses groups of - to delimit columns.'
	    print,'   The groups are separated by a space. No other characters.'
	    print,'   are allowed in the reference line.  May use /REFOPT'
	    print,'   if no reference lines was really intended.'
	    err = -1
	    return,''
	  endelse
	endif
	if irefa[0] lt 2 then begin
	  print,' Error in txtdb_rd: Must have tag line and type line above'
	  print,'   reference line in data base file.  Reference line too'
	  print,'   close to top of file.'
	  err = -2
	  return,''
	endif
 
	itxt0 = 0			; Start index in text array t.
	hdrcnt = 0			; Header counter.
 
	;------------------------------------------------------------
	;  Loop through reference lines
	;------------------------------------------------------------
	for ir = 0L, numref-1 do begin
	  iref = irefa[ir]		; Next reference line index.
 
	  ;----------------------------------------------------------
	  ;  Get reference line, type line, tag line, header
	  ;----------------------------------------------------------
	  ref = t[iref]			; Reference line.
	  typ = t[iref-1]		; Data type line.
	  tag = t[iref-2]		; Tag name line.
	  ih_lo = itxt0			; First header line.
	  ih_hi = iref-3		; Last header line.
	  if ih_hi lt itxt0 then begin	; No header.
	    hflag = 0			; Indicate no header.
	    hdr = ''			; Null header.
	  endif else begin
	    hflag = 1			; Indicate a header.
	    hdr = t[ih_lo:ih_hi]	; Extract header lines.
	    if min(strcompress(hdr,/rem) eq '') eq 1 then hflag=0 ; All blanks.
	  endelse
	  if keyword_set(nohead) then hflag=0  ; Exclude headers in output.
	  if keyword_set(debug) then begin
	    if hflag then print,' Found header text' else $
	      print,' No header text'
	    print,' tag line: '+tag
	    print,' typ line: '+typ
	  endif
 
	  ;----------------------------------------------------------
	  ;  Get data lines
	  ;----------------------------------------------------------
	  w = where(strlen(tc[iref:*]) eq 0, cnt) ; Find blank line after data.
          if w[0] eq 1 then begin
	    print,' Error in txtdb_rd: Blank line not allowed after reference line.'
	    print,'   Reference line is the line of dashes that delimit the columns.'
	    print,'   Data must start on the line after the reference line.'
	    err = -6
	    return,''
          endif
	  if cnt eq 0 then begin
	    id_lo = iref+1	; First data line.
	    id_hi = n-1		; Last data line.
	  endif else begin
	    id_lo = iref+1	; First data line.
	    id_hi = iref+w[0]-1	; Last data line.
	  endelse
	  data = t[id_lo:id_hi]	; Extract data lines.
	  if keyword_set(debug) then begin
	    ndata = n_elements(data)
	    print,' Number of data lines: ',ndata
	  endif
	  itxt0 = id_hi + 2	; Start of next header if any.
 
	  ;----------------------------------------------------------
	  ;  Make sure number of items all agree
	  ;----------------------------------------------------------
	  fndwrd,ref,nref,loc,len		; Find columns of data items.
	  if nwrds(typ) ne nref then begin
	    print,' Error in txtdb_rd: Number of data types must match number'
	    print,'   of groups of dashes in reference line.'
	    err = -3
	    return,''
	  endif
	  if nwrds(tag) ne nref then begin
	    print,' Error in txtdb_rd: Number of tag names must match number'
	    print,'   of groups of dashes in reference line.'
	    err = -4
	    return,''
	  endif
 
	  ;----------------------------------------------------------
	  ;  Add header text to structure
	  ;
	  ;  Special case: if /REFOPT was set to indicate that
	  ;  reference lines were optional then all the text is
	  ;  considered as a header and that single header is
	  ;  processed.  After the header is processed the resulting
	  ;  structure is returned if there are no reference lines.
	  ;----------------------------------------------------------
jump_refopt:
	  if hflag eq 1 then begin			; Add only if header.
	    htag = '__text'+string(hdrcnt,form='(I3.3)')
	    hdrcnt = hdrcnt + 1
	    if n_elements(s) eq 0 then begin
	      s = create_struct(htag,hdr)
	    endif else begin
	      s = create_struct(s,htag,hdr)
	    endelse
	  endif ; hflag
 
	  ;----------------------------------------------------------
	  ;  Add any header variables to structure
	  ;    Note that txtgetkey will replace any spaces in
	  ;    a variable name with _.  This also applies to a
	  ;    leading EXECITE so EXECUTE a=10*s.a is added to
	  ;    the returned structure with a tag of EXECUTE_A
	  ;    and a string value of '10*s.a'.
	  ;----------------------------------------------------------
	  if not keyword_set(nohvar) then begin
            hdr = txtmercon(hdr)                        ; Merge any continued lines.
	    strfind,hdr,'=',/quiet,index=in,count=hcnt	; Search for tag = val
	    if hcnt gt 0 then begin			; If any ...
	      h2 = hdr[in]				; Grab tag = val lines.
	      eflag = intarr(hcnt)			; Set to 1 to keep.
	      for ih=0,hcnt-1 do begin			; Keep only tag=val.
	        t2 = stress(h2[ih],'r',1,'=',' = ')	; Add spaces around =.
	        if getwrd(t2,1) eq '=' then eflag[ih]=1	; Keep this line.
	      endfor ; ih
	      in = where(eflag eq 1,hcnt)		; See what's left.
	    endif ; hcnt
	    if hcnt gt 0 then begin			; If any ...
	      h2 = h2[in]				; Grab tag = val lines.
	      s2 = txtgetkey(init=h2,/struct,/nosort)	; Grab in a struct.
	      htagnm = tag_names(s2)			; Tag names.
	      for ih=0,n_elements(htagnm)-1 do begin	; Loop over headr tags.
		vtag = htagnm[ih]			; Tag for variable.
		val = s2.(ih)				; Grab value.
	        ;---  Deal with new item placement  ---
	        af0 = ' '+getwrd(val[0],1,del=';')	; Get any trailing cmt.
	        aftag = getwrd(af0,1,del='@')		; Try for tag after @.
	        if aftag eq '' then aftag='$'		; Default is at end.
	        ;--------------------------------------
		if strtrim(val[0]) eq '<NULL>' then $	; Deal with null str.
		  if not keyword_set(no_null) then val = ''
		if keyword_set(exec) then begin		; Process any executes.
		  if strmid(vtag,0,8) eq 'EXECUTE_' then begin ; Execute?
		    vtag = strmid(vtag,8)		; Grab actual tag.
		    exerr = execute('val = '+val)	; Execute statement.
		  endif ; EXECUTE_
		endif ; exec.
	        if n_elements(s) eq 0 then begin	; Add header var.
	          s = create_struct(vtag,val)		; Start structure.
	        endif else begin
	          tag_add,s,vtag,val,after=aftag	; Add to structure.
	        endelse
	      endfor ; ih
	    endif ; hcnt
	  endif ; nohvar
 
	  ;----------------------------------------------------------
	  ;  Special case escape: No reference lines, was all header.
	  ;----------------------------------------------------------
	  if numref eq 0 then return, s
 
	  ;----------------------------------------------------------
	  ;  Loop through data items adding to structure
	  ;----------------------------------------------------------
	  for i=0L,nref-1 do begin
	    start = loc[i]
	    length = len[i]
	    typ_i = strtrim(strmid(typ,start,length),2)
	    tag_i = strtrim(strmid(tag,start,length),2)
	    if (typ_i eq '*') or (typ_i eq ';') then continue
	    cnv = typ2num(typ_i,err=err,ftype=ftyp)
	    if err ne 0 then begin
	      print,' Error in txtdb_rd: Unknown data type: '+typ_i
	      print,'   Processig aborted.'
	      err = -5
	      return,''
	    endif
	    dat_i = strmid(data,start,length)
	    if keyword_set(debug) then begin
	      print,' '
	      print,'   Data item # '+strtrim(i,2)+'  Tag: '+tag_i
	      print,'     Start char: ',start
	      print,'     Length: ',length
	      print,'     Convert to typ: '+typ_i
	      print,'     Data = '+dat_i[0]
	    endif
	    datcnv = strtrim(dat_i,2) + cnv
	    if ftyp eq 'STR' then begin			; Deal with null str.
	      if not keyword_set(no_null) then begin
	        w = where(strtrim(datcnv,2) eq '<NULL>',cnt)
	        if cnt gt 0 then datcnv[w]=''
	      endif
	    endif
	    if ftyp eq 'DMS' then datcnv=llsigned(datcnv) ; Special case 'D M S'.
	    if n_elements(s) eq 0 then begin		; Add array.
	      s = create_struct(tag_i,datcnv)		; Start structure.
	    endif else begin
	      s = create_struct(s,tag_i,datcnv)		; Add to structure.
	    endelse
	  endfor
 
	endfor ; ir
 
	;------------------------------------------------------------
	;  Finish structure, add trailer if any
	;------------------------------------------------------------
	if itxt0 lt n then begin
	  hdr = t[itxt0:n-1]
	  hflag = 1			        	; Assume add.
	  if min(strcompress(hdr,/rem) eq '') eq 1 then hflag=0 ; All blanks.
	  if keyword_set(nohead) then hflag=0	; Exclude headers in output.
	  if hflag eq 1 then begin			; Add trailer.
	    htag = '__text'+string(hdrcnt,form='(I3.3)')
	    if n_elements(s) eq 0 then begin		; Add trailer.
	      s = create_struct(htag,hdr)		; Start structure.
	    endif else begin
	      s = create_struct(s,htag,hdr)		; Add to structure.
	    endelse
	  endif ; hflag
 
	  ;----------------------------------------------------------
	  ;  Add any trailer variables to structure
	  ;    See comments above under header variables.
	  ;----------------------------------------------------------
	  if not keyword_set(nohvar) then begin
            hdr = txtmercon(hdr)                        ; Merge any continued lines.
	    strfind,hdr,'=',/quiet,index=in,count=hcnt	; Search for tag = val
	    if hcnt gt 0 then begin			; If any ...
	      h2 = hdr[in]				; Grab tag = val lines.
	      s2 = txtgetkey(init=h2,/struct,/nosort)	; Grab in a struct.
	      htagnm = tag_names(s2)			; Tag names.
	      for ih=0,n_elements(htagnm)-1 do begin	; Loop over headr tags.
		vtag = htagnm[ih]			; Tag for variable.
		val = s2.(ih)				; Grab value.
	        ;---  Deal with new item placement  ---
	        af0 = ' '+getwrd(val[0],1,del=';')	; Get any trailing cmt.
	        aftag = getwrd(af0,1,del='@')		; Try for tag after @.
	        if aftag eq '' then aftag='$'		; Default is at end.
	        ;--------------------------------------
		if strtrim(val[0]) eq '<NULL>' then $	; Deal with null str.
		  if not keyword_set(no_null) then val = ''
		if keyword_set(exec) then begin		; Process any executes.
		  if strmid(vtag,0,8) eq 'EXECUTE_' then begin ; Execute?
		    vtag = strmid(vtag,8)		; Grab actual tag.
		    exerr = execute('val = '+val)	; Execute statement.
		  endif ; EXECUTE_
		endif ; exec.
	        if n_elements(s) eq 0 then begin	; Add trailer var.
	          s = create_struct(vtag,val)		; Start structure.
	        endif else begin
	          tag_add,s,vtag,val,after=aftag	; Add to structure.
	        endelse
	      endfor ; ih
	    endif ; hcnt gt 0
	  endif
	endif ; itxt0 lt n

	;------------------------------------------------------------
        ;  Process a given code block
        ;
        ;  Can create variables to use in the code but
        ;  avoid s for now (= internal structure).
        ;  Long lines of code (like plot statements) may be
        ;  continued on multiple lines by using trailing $.
	;------------------------------------------------------------
        if n_elements(codevar) ne 0 then begin          ; Any code blocks given?
          for _iv=0,n_elements(codevar)-1 do begin      ; Loop over code blocks.
            _v = codevar[_iv]                           ; Name of next code block.
            _c = tag_value(s,_v)                        ; Code text.
            for _i=0,n_elements(_c)-1 do begin          ; Loop over code lines.
              _r = execute(_c[_i])                      ; Try to execute line.
              if _r ne 1 then begin                     ; If an error ...
                print,' Error executing the statement:' ; List problem line.
                print,'     '+_c[_i]
                break                                   ; Skip rest of code block.
              endif
            endfor ; _i
          endfor ; _iv
        endif
 
	return, s
 
	end
