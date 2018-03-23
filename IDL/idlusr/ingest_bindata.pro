;-------------------------------------------------------------
;+
; NAME:
;       INGEST_BINDATA
; PURPOSE:
;       Ingest binary data in a byte array into a structure.
; CATEGORY:
; CALLING SEQUENCE:
;       s = ingest_bindata(text, bindata)
; INPUTS:
;       text = String array with data description.  in
;       bindata = Byte array with binary data.      in
; KEYWORD PARAMETERS:
;       Keywords:
;         COMMENTS=cmt  Returned array of comments for each tag.
;         /REVBITS means extract bit fields starting from most
;           significant bit (else least).
;         /SWAP_ENDIAN means swap endian of each item.
;           (does not apply to extracted bit fields).
;         /CHECK means check text for total bytes.
;           Returns check text in s.  Does not extract data.
;           Use TOT_BYTES=nbyts to return total number of bytes.
;         LENCHECK=maxlen check tag names for length (def=8 char).
;           Use /COMMENT to check comment lengths (def=48).
;         /QUIET do not list check text for /CHECK mode or LENCHECK
;            mode.  Still lists any error messages.
;         /DETAILS gives details on text description.
;         /NOCOPY do not grab lines with + in column 1.
;         /NOMOD ignore any modification commands (see /DETAILS).
;         ERROR=err Error count (0=none).
; OUTPUTS:
;       s = Returned structure.                     out
; COMMON BLOCKS:
; NOTES:
;       Note: Ex comment check: t=ingest_bindata(txt,bin,comment=cmt)
;                             more,tag_names(t)+' --- '+cmt
;         From the total number of bytes returned by TOT_BYTES in
;         /CHECK can get a structure for directly reading the data:
;         s=ingest_bindata(text,bytarr(nrec),comment=cmt)
;         (Can do direct reads only if there are no bit extractions)
; MODIFICATION HISTORY:
;       R. Sterner, 2002 Oct 10
;       R. Sterner, 2002 Oct 22 --- Added LENCHECK=maxlen, COMMENT=cmt.
;       R. Sterner, 2002 Nov 19 --- Added + to copy text to structure (/nocopy).
;       R. Sterner, 2002 Nov 20 --- Added comment check to /lencheck.
;       R. Sterner, 2003 Jan 17 --- Returned total number of bytes.
;       R. Sterner, 2003 May 02 --- Changed default comments length to 48.
;       R. Sterner, 2004 Oct 12 --- Cleared up some help text.
;       R. Sterner, 2011 May 25 --- Converted () to [].
;       R. Sterner, 2011 May 25 --- Adjusted /CHECK listing width.
;       R. Sterner, 2011 May 27 --- Mentioned portable data types in help text.
;       R. Sterner, 2011 May 29 --- Handled Modify Commands in data description.
;       R. Sterner, 2011 Aug 25 --- Changed call to getbits to bit_get.
;
; Copyright (C) 2002, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	function ingest_bindata, text, bin, check=check, quiet=quiet, $
	  details=details, revbits=revbits, swap_endian=endian, $
	  error=errcnt, lencheck=lencheck, comments=cmt, $
	  nocopy=nocopy, nomod=nomod, tot_bytes=tot_bytes, help=hlp
 
	if keyword_set(hlp) then begin
hlp:	  print,' Ingest binary data in a byte array into a structure.'
	  print,' s = ingest_bindata(text, bindata)'
	  print,'   text = String array with data description.  in'
	  print,'   bindata = Byte array with binary data.      in'
	  print,'   s = Returned structure.                     out'
	  print,' Keywords:'
	  print,'   COMMENTS=cmt  Returned array of comments for each tag.'
	  print,'   /REVBITS means extract bit fields starting from most'
	  print,'     significant bit (else least).'
	  print,'   /SWAP_ENDIAN means swap endian of each item.'
	  print,'     (does not apply to extracted bit fields).'
	  print,'   /CHECK means check text for total bytes.'
	  print,'     Returns check text in s.  Does not extract data.'
	  print,'     Use TOT_BYTES=nbyts to return total number of bytes.'
	  print,'   LENCHECK=maxlen check tag names for length (def=8 char).'
	  print,'     Use /COMMENT to check comment lengths (def=48).'
	  print,'   /QUIET do not list check text for /CHECK mode or LENCHECK'
	  print,'      mode.  Still lists any error messages.'
	  print,'   /DETAILS gives details on text description.'
	  print,'   /NOCOPY do not grab lines with + in column 1.'
          print,'   /NOMOD ignore any modification commands (see /DETAILS).'
	  print,'   ERROR=err Error count (0=none).'
	  print,' Note: Ex comment check: t=ingest_bindata(txt,bin,comment=cmt)'
	  print,"                       more,tag_names(t)+' --- '+cmt"
	  print,'   From the total number of bytes returned by TOT_BYTES in'
	  print,'   /CHECK can get a structure for directly reading the data:'
	  print,'   s=ingest_bindata(text,bytarr(nrec),comment=cmt)'
	  print,'   (Can do direct reads only if there are no bit extractions)'
	  return,''
	endif
 
	if keyword_set(details) then begin
	  print,' Details on ingest_bindata data description string array'
	  print,' '
	  print,' Each line in the data description string array defines'
	  print,' an item in the binary data. Each line has a tag name and'
	  print,' the data type of the item.  Arrays are allowed.'
	  print,' A description may follow the data type.  For example:'
	  print,'   ONE    INT       First item.'
	  print,'   TWO    FLT       Second item.'
	  print,'   THREE  LON(2,3)  Third item.'
	  print,'   FOUR   BYT(10)   Fourth item.'
	  print,' Allowed data types are: BYT, INT, LON, FLT, DBL, COMPLEX,'
	  print,'   DCOMPLEX, UINT, ULON, LONG64, ULONG64.  Case is ignored.'
	  print,'   Any array dimensions follow the data type in parantheses.'
          print,'   In addition a set of portable data types are available:'
          print,'     I8, I16, I32, I64, UI8, UI16, UI32, UI32, F32, F64, C64, C128'
          print,'   I* are signed integers, UI* are unsigned integers, '
          print,'   F* are floats, C* are complex.  I8 does not exist in IDL,'
          print,'   it will return a byte value.  These items are intended to'
          print,'   allow language and machine independent data descriptions.'
          print,'   So using these types LON(2,3) would be I32(2,3).'
	  print,' '
	  print,' Bit fields may be extracted.  Bit fields are indicated by a'
	  print,' tag of # followed by a data type giving the number of bits'
	  print,' to extract from.  An example of bit fields:'
	  print,'   #       UINT'
	  print,'   SOURCE  4 bits  Data source.'
	  print,'   FLAG    1 bit   Flag value.'
	  print,' There could be up to 16 bits extracted from this UINT. The'
	  print,' first item after a bit field tag is the number of bits, only'
	  print,' this number is used.'
	  print,' '
	  print,' A ! instead of or as the first character of a tag means'
	  print,' do not return that item or bit field in the structure.'
	  print,' Such ignored items are still needed in the description'
	  print,' to account for the bits in the binary data.'
	  print,' '
	  print,' * or ; in column 1 are considered comments and dropped.'
	  print,' Only the first two items on each line are used.  The'
	  print,' first is a tag or the bit field indicator.  The second'
	  print,' is the data type or number of bits to extract.  So the'
	  print,' data type may be followed by a description of the item.'
	  print,' White space, comments, and null lines could be used freely'
	  print,' in the text file.'
	  print,' '
	  print,' If + occurs in column 1 then the following text is included'
	  print,' in the returned structure with tags names of ___$xxxx'
	  print,' where xxxx is a 4 digit counter (0001,0002,...). Use'
	  print,' /NOCOPY to avoid picking up such text.'
	  print,' '
	  print,' Sometimes the ingested value is a scaled version of the'
	  print,' final desired value.  A set of functions may be defined to'
	  print,' apply to specified items.  These functions are placed in'
          print,' a section between the delimiter lines <modify> and </modify>'
          print,' For example:'
          print,'   <modify>'
          print,'     orbital_inclination = _value/8192.*!radeg'
          print,'     nodal_crossing_longitude = _value/8192.*!radeg'
          print,'     right_ascension_ascending_node = _value/8192.*!radeg'
          print,'   </modify>'
	  print,' Use the tag _value to refer to the value as read from the'
	  print,' binary data.  In the above example each original value was'
	  print,' in radians multiplied by 8192.  The above functions will'
	  print,' convert the values to degrees before they are put the in'
	  print,' returned structure.  This section is optional.'
	  return,''
	endif
 
	;--------------------------------------------------
	;  Preprocess text
        ;    Drop comments, split off any modify commands.
        ;    txt will contain data description.
        ;    modtxt will contain any modify commands.
        ;    Set mod_flag is there are any modifaction
        ;      commands to apply, and set up lookup table.
	;--------------------------------------------------
	if n_elements(text) eq 0 then goto, hlp		; No args.
        txt_keysection,text,after='<modify>',/quiet, $  ; Data desc & mods.
          before='</modify>',out=modtxt,inverse=txt0
;x	txt = drop_comments(txt0,/trailing)		; Drop comments.
	txt = drop_comments(txt0)	        	; Drop comments.
	n = n_elements(txt)				; # data descr lines.
        if modtxt[0] eq '' then mod_flag=0 $            ; Set flag if any mods.
          else mod_flag=1
        if keyword_set(nomod) then mod_flag=0           ; Force no mods.
        if mod_flag then begin                          ; Set up lookup table.
          for i=0,n_elements(modtxt)-1 do begin         ; Loop over modify cmds.
            tmp = modtxt[i]                             ; i'th modify command.
            key = getwrd(tmp,0,del='=')                 ; Variable name.
            val = getwrd(tmp,1,del='=')                 ; Modify function.
            modtab = aarr(modtab,key,val=val,/add)      ; Insert in lookup tbl.
          endfor
        endif
 
	;--------------------------------------------------
	;  Length check
	;--------------------------------------------------
	if n_elements(lencheck) ne 0 then begin
	  lenchk = lencheck
	  if lenchk eq 1 then begin		; Default length limit.
	    if keyword_set(cmt) then begin
	      lenchk = 48			; FITS comment.
	    endif else begin
	      lenchk = 8			; FITS tag.
	    endelse
	  endif
	  lentxt = strtrim(lenchk,2)
	  out0 = spc(75)			; Blank line.
	  out = out0				; Blank text line.
	  if keyword_set(cmt) then begin	; Comments.
	    pt1 = 3				; Comment.
	    pt2 = 8+lenchk			; Comment length.
	    pt3 = 14+lenchk			; Error flag.
	    strput,out,'Comment',pt1		; Insert items into text line.
	    strput,out,'Length',pt2		; Insert items into text line.
	  endif else begin			; Tags.
	    pt1 = 6				; Tag name.
	    pt2 = 17+lenchk			; Tag length.
	    pt3 = 22+lenchk			; Error flag.
	    strput,out,'Tag',pt1		; Insert items into text line.
	    strput,out,'Length',pt2		; Insert items into text line.
	  endelse
	  tprint,out,/init		; Add line into internal text array.
	  tprint,' '
	  ;----------  Loop through items in data description  ---------
	  for i=0,n-1 do begin			; Loop through text.
	    t = txt[i]				; i'th item.
	    tg0 = strmid(t,0,1)			; First tag char.
	    a = getwrd(t,1)			; Datatype.
	    if tg0 eq '+' then begin		; Comment.
	      tprint,strmid(t,1,999)		; Print it.
	      goto, skiplc
	    endif
	    if (tg0 ne '#') and (tg0 ne '!') then begin	 ; Line with tag.
	      if keyword_set(cmt) then begin	; Checking comment length.
	        if isnumber(a) then begin
		  tg = getwrd(t,3,99)		; Bit Field comment.
		endif else begin
		  tg = getwrd(t,2,99)		; Tag comment.
		endelse
	      endif else begin			; Checking tag length.
	        tg = getwrd(t,0)		; Get tag.
	      endelse
	      len0 = strlen(tg)
	      len = string(len0,form='(I2)')
	      out = out0
	      if len0 le lenchk then begin
	        tg2 = tg + spc(lenchk,tg) + ' '
	        errtxt = ''
	      endif else begin
                tg2 = strmid(tg,0,lenchk) + ' ' + strmid(tg,lenchk,99)
	        errtxt = '<-- Too long.  Limit = '+lentxt
	      endelse
	      strput,out,tg2,pt1
	      strput,out,len,pt2
	      strput,out,errtxt,pt3
	      tprint,out
	    endif
skiplc:
	  endfor
	  tprint,out=chk_txt				; Get internal text.
	  if not keyword_set(quiet) then tprint,/print	; Print internal text.
	  return, chk_txt				; Return text.
	endif
 
	;--------------------------------------------------
	;  Check text (do not extract data)
	;--------------------------------------------------
	if keyword_set(check) then begin
          ;---  Get max tag length to adjust output width  ---
          mxlen = -1                        ; Find max tag length.
          for i=0,n-1 do begin              ; Loop over tags.
            leni = strlen(getwrd(txt[i],0)) ; Length of i'th tag.
            mxlen = mxlen>leni              ; Keep max length.
          endfor
          add = (mxlen-17)>0                ; OK up to 17 char tags.
          ;---  Set up output line layout  ---
	  out0 = spc(75+add)	; Blank line.
	  pt1 = 6		; Tag name.
	  pt2 = 25+add		; Data Type.
	  pt3 = 35+add		; Bits in data type.
	  pt4 = 45+add		; Start byte in array of binary data.
	  pt5 = 55+add		; Total bits including current item.
	  pb1 = 10+add		;   Bit field name.
	  pb2 = 30+add		;   Number of bits.
	  pb3 = 45+add		;   Offset bits into source item.
	  out = out0			; Blank text line.
	  strput,out,'Tag',pt1		; Insert items into text line.
	  strput,out,'Type',pt2
	  strput,out,'Bits',pt3
	  strput,out,'Byte #',pt4
	  strput,out,'Tot Bits',pt5
	  tprint,' ',/init		; Add line into internal text array.
	  tprint,out
	  tprint,' '
 
	  tot_bits = 0L				; Cumulative bits.
	  bit_offset = 0			; Offset into bitfield.
	  errcnt = 0				; Total errors found.
 
	  ;----------  Loop through items in data description  ---------
	  for i=0,n-1 do begin			; Loop through text.
	    t = txt[i]				; i'th item.
	    tg = getwrd(t,0)			; Tag.
	    tg0 = strmid(tg,0,1)		; First tag char.
	    a = getwrd(t,1)			; Datatype.
	    out = out0
	    if tg0 eq '+' then begin		; Comment.
	      tprint,strmid(t,1,999)		; Print it.
	      goto, skip
	    endif
	    ;------  Datatype or #  --------------
	    if not isnumber(a) then begin	; Actual datatype.
	      num = typ2num(a,bits=nbits,err=err,/quiet) ; # bits for item.
	      if err ne 0 then begin
		tprint,' >>>===> '+tg+': has unkown datatype of '+a+'. Skipped.'
		errcnt = errcnt + 1
		goto, skip
	      endif
	      start_byte = tot_bits/8		; Byte index into binary data.
	      tot_bits = tot_bits + nbits	; Running sum of bits.
	      if tg0 eq '!' then begin		; Ignore items tagged !.
		tg1 = strmid(tg,1,99)
		if tg1 eq '' then tg1='Ignored'
		strput,out,'<<'+tg1+'>>',pt1
		strput,out,a,pt2
	      endif else begin			; Actual data item to extract.
		strput,out,tg,pt1
		strput,out,a,pt2
	      endelse
	      strput,out,string(nbits,form='(I5)'),pt3
	      strput,out,string(start_byte,form='(I5)'),pt4
	      strput,out,string(tot_bits,form='(I5)'),pt5
	      if tg eq '#' then begin		; Start bit fields.
		strput,out,'Bitfield:',pt1
		strput,out,a,pt2
	        bit_offset = 0			; Reset offset into bit field.
	      endif
	    ;------  Bit field  -----------------------
	    endif else begin			; Datatype was bits to extract.
	      if tg0 eq '!' then begin		; Ignore items tagged !.
		tg1 = strmid(tg,1,99)
		if tg1 eq '' then tg1='Ignored'
		strput,out,'<<'+tg1+'>>',pb1
		strput,out,'Bits: '+string(a,form='(I2)'),pb2
		strput,out,'Offset: '+string(bit_offset,form='(I2)'),pb3
	      endif else begin			; Actual bit field to extract.
		strput,out,tg,pb1
		strput,out,'Bits: '+string(a,form='(I2)'),pb2
		strput,out,'Offset: '+string(bit_offset,form='(I2)'),pb3
	      endelse
	      if (a gt (nbits-bit_offset)) or (bit_offset ge nbits) then begin
		tprint,' >>>===> '+tg+': does not fit in bit field.' 
		errcnt = errcnt + 1
		goto, skip
	      endif
	      bit_offset = bit_offset + a	; Offset to next bit field.
	    endelse
	    tprint,out
skip:
	  endfor
 
	  tprint,' '
	  tot_bytes = tot_bits/8
	  tprint,' Total number of bytes: '+strtrim(tot_bytes,2)
	  tprint,' '
	  if errcnt gt 0 then begin
	    tprint,' Byte count will be off because there '+ $
	      plural(errcnt,'was ','were ')+strtrim(errcnt,2)+$
	      ' error'+plural(errcnt)+'.'
	  endif
 
          ;--- List any MODIFY COMMANDS here ---
          if mod_flag then begin
            tprint,' MODIFY COMMANDS (Modifies indicated items):'
            tprint,add=modtxt
	    tprint,' '
          endif else begin
            tprint,' No Modify commands'
	    tprint,' '
          endelse
 
	  tprint,out=chk_txt				; Get internal text.
	  if not keyword_set(quiet) then tprint,/print	; Print internal text.
	  return, chk_txt				; Return text.
	endif
 
	;--------------------------------------------------
	;  Extract data
	;--------------------------------------------------
	tot_bits = 0L			; Cumulative bits.
	bit_offset = 0			; Offset into bitfield.
	errcnt = 0			; Total errors found.
	cmt = ['']			; Array of comments.
	copy_pre = '___$'		; Prefix for text to copy.
	copy_cnt = 0L			; Counter for text to copy.
 
	for i=0,n-1 do begin	; Loop through items in data description text.
	  t = txt[i]			; i'th item.
	  tg = getwrd(t,0)		; Tag.
	  tg0 = strmid(tg,0,1)		; First tag char.
	  a = getwrd(t,1)		; Datatype.
	  offset = tot_bits/8		; Byte offset into binary data.
	  ;------  Deal with text to copy to structure  ----------
	  if tg0 eq '+' then begin
	    if keyword_set(nocopy) then goto, skip2	; Ignore.
	    tg = copy_pre+string(copy_cnt,form='(I4.4)'); Make up tag name.
	    copy_cnt = copy_cnt + 1L
	    val = strmid(t,1,999)			; Drop leading +.
	    if n_elements(s) eq 0 then $
	      s = create_struct(tg,val) else $		; Create structure.
	      s = create_struct(s,tg,val)		; Add to structure.
	    cmt = [cmt,'']				; Keep comments synced.
	    goto, skip2
	  endif
	  ;------  Datatype or #  --------------
	  if not isnumber(a) then begin	; Actual data item (datatype=a).
	    ;--------  Extract item  ------------
	    if tg0 ne '!' then begin	; Extract data.
;x	      num = typextract(a,offset,bin,bits=nbits,err=err)
	      _value = typextract(a,offset,bin,bits=nbits,err=err)
	      if err ne 0 then begin
		print,' Error in ingest_bindata:'
	        print,' >>>===> '+tg+': has unkown datatype of '+a+'. Skipped.'
	        errcnt = errcnt + 1
	        goto, skip2
	      endif
	      ;-------  Swap endian?  -------------
;x	      if keyword_set(endian) then num=swap_endian(num)
	      if keyword_set(endian) then _value=swap_endian(_value)
	      if tg0 ne '#' then begin			; Don't add bit field
                ;---  Apply any modify command to _value to get val ---
                if mod_flag then begin            ; Modify value if function.
                  modfun = aarr(modtab,tg,err=err,/quiet)  ; Get mod function.
                  if err eq 0 then begin          ; Have a function for tag tg.
                    errx = execute('val='+modfun) ; Apply mod function.
                    if errx eq 0 then begin
                      print,' #############################################'
                      print,' Error executing: val='+modfun
                      print,' #############################################'
                      stop                        ; Fatal error.
                    endif
                  endif else val=_value           ; No function for this tag.
                endif else begin                  ; Use original value.
                  val = _value
                endelse
                ;---  Insert value into output structure  ---
	        if n_elements(s) eq 0 then $
;x		  s = create_struct(tg,num) else $	; Create structure.
;x		  s = create_struct(s,tg,num)		; Add to structure.
		  s = create_struct(tg,val) else $	; Create structure.
		  s = create_struct(s,tg,val)		; Add to structure.
	        cmt = [cmt,getwrd(t,2,99)]		; Grab any comment.
	      endif
	    ;--------  Just count bits  -------------
	    endif else begin
	      tmp = typ2num(a,bits=nbits,err=err,/quiet) ; # bits for item.
	    endelse
	    tot_bits = tot_bits + nbits		; Running sum of bits.
	    ;--------  Get ready for a bit field  ----------
	    if tg eq '#' then bit_offset=0	; Reset offset into bitfield.
	  ;------  Bit field  -----------------------
	  endif else begin			; Datatype was bits to extract.
	    start_bit = bit_offset		; Extract from lsb.
	    if keyword_set(revbits) then $	; Extract from msb.
		start_bit = nbits-bit_offset-a
	    ;-------  Check for fit  ----------------
	    if (start_bit + a) gt nbits then begin
		print,' Error in ingest_bindata: ' + $
		  tg + ': does not fit in bit field.'
	        print,' '+tg+' is '+strtrim(a,2)+' bits starting at bit '+$
		  strtrim(start_bit,2)
		errcnt = errcnt + 1
		goto, skip2
	    endif
	    if (tg0 ne '!') then begin		        ; Extract bits.
	      cmt = [cmt,getwrd(t,3,99)]		; Grab any comment.
              num = _value
;x	      _value = getbits(num,start_bit,a,/reduce)	; Extract bits.
	      _value = bit_get(num,start_bit,a,/reduce)	; Extract bits.
              ;---  Apply any modify command to _value to get val ---
              if mod_flag then begin            ; Modify value if function.
                modfun = aarr(modtab,tg,err=err,/quiet)  ; Get mod function.
                if err eq 0 then begin          ; Have a function for tag tg.
                  errx = execute('val='+modfun) ; Apply mod function.
                  if errx eq 0 then begin
                    print,' #############################################'
                    print,' Error executing: val='+modfun
                    print,' #############################################'
                    stop                        ; Fatal error.
                  endif
                endif else val=_value           ; No function for this tag.
              endif else begin                  ; Use original value.
                val = _value
              endelse
              ;---  Insert value into output structure  ---
;x	      cmt = [cmt,getwrd(t,3,99)]		; Grab any comment.
	      if n_elements(s) eq 0 then $
		s = create_struct(tg,val) else $	; Create structure.
		s = create_struct(s,tg,val)		; Add to structure.
	    endif
	    bit_offset = bit_offset + a
	  endelse
skip2:
	endfor ; i
 
	cmt = cmt[1:*]		; Drop seed value.
 
	return, s
 
	end
