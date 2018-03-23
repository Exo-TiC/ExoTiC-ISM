;-------------------------------------------------------------
;+
; NAME:
;       FPRINT
; PURPOSE:
;       Turn print statements into a text file.
; CATEGORY:
; CALLING SEQUENCE:
;       fprint,a1,a2,a3,...
; INPUTS:
;       a1,a2,a3,... = args to fprint.  in
;         May have up to 20.
; KEYWORD PARAMETERS:
;       Keywords:
;         BUFFER='key' Use a file indicated by 'key' instead
;           a default file. Use BUFFER='key' on each call to
;           fprint.  Use with /INIT to get started, then
;           use this keyword on following calls.
;         /INIT Start a new text file.
;           May also give an initial text array: INIT=txt.
;         ADD=txt Add given text array to text file.
;         OUT=txt Return text from the file.
;         /PRINT print the entire text file to screen.
;         /NUMBERS Include text line indices for the /PRINT option.
;         /SCREEN Print the added line or lines to the screen also.
;         SAVE=file  Move the default text file to the given text file.
;         /QUIET do not show messages.
;         /REVERSE reverse text order (for /PRINT, OUT=, or SAVE=).
;         FORMAT=fmt Optional print format.
;         ERROR=err 0=ok, 1=error if OUT or /PRINT used with no text.
; OUTPUTS:
; COMMON BLOCKS:
;       fprint_com
; NOTES:
;       Notes: Intended to make it easy to take a set of print
;         statements in a program and change them to build up
;         a text file.  Uses the IDL string function in place
;         of the print statement to handle the arguments.  Can
;         then return the text array built up from multiple
;         fprint calls and use it elsewhere.
; MODIFICATION HISTORY:
;       R. Sterner, 2014 Oct 15 from tprint.pro
;
; Copyright (C) 2014, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro fprint, p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15, $
	  p16,p17,p18,p19,p20, $
	  init=init,out=out, print=print, error=err, reverse=rev, $
	  add=add, save=save, buffer=buf, quiet=quiet, verbose=verb, $
	  format=fmt, screen=screen, numbers=numbers ,help=hlp
 
	common fprint_com, txt, flag
	;--------------------------------------------------
	;  Internal memory
	;  txt = Internal text buffer.
	;  flag = Internal text flag: 0=no text, 1=text.
	;--------------------------------------------------
	;  If BUFFER=buf is used on each call to tprint
	;  then use the values in buf (external memory):
	;    buf.txt and buf.flag.
	;  If BUFFER is not used then use the values in
	;  internal memory (tprint_com common):
	;    txt and flag.
	;  In either case move the values to the working
	;  variables txt0 and flag0.  They are moved back
	;  to buf or common after any operation.
	;
	;  Any time text buffer is changed update the
	;  internal or external buffer.  This will happen
	;  for /INIT or INIT=txt, ADD=txt, or the
	;  straight tprint command.
	;--------------------------------------------------
 
	if keyword_set(hlp) then begin
	  print,' Turn print statements into a text file.'
	  print,' fprint,a1,a2,a3,...'
	  print,'   a1,a2,a3,... = args to fprint.  in'
	  print,'     May have up to 20.'
	  print,' Keywords:'
      print,"   BUFFER='key' Use a file indicated by 'key' instead"
      print,"     a default file. Use BUFFER='key' on each call to"
      print,'     fprint.  Use with /INIT to get started, then'
      print,'     use this keyword on following calls.'
      print,'   /INIT Start a new text file.'
      print,'     May also give an initial text array: INIT=txt.'
      print,'   ADD=txt Add given text array to text file.'
      print,'   OUT=txt Return text from the file.'
      print,'   /PRINT print the entire text file to screen.'
      print,'   /NUMBERS Include text line indices for the /PRINT option.'
      print,'   /SCREEN Print the added line or lines to the screen also.'
      print,'   SAVE=file  Move the default text file to the given text file.'
      print,'   /QUIET do not show messages.'
      print,'   /REVERSE reverse text order (for /PRINT, OUT=, or SAVE=).'
      print,'   FORMAT=fmt Optional print format.'
      print,'   ERROR=err 0=ok, 1=error if OUT or /PRINT used with no text.'
#####################
	  print,'   BUFFER=buf  Set up and use an external buffer, buf instead'
	  print,'     of internal buffer. Use BUFFER=buf on each call to'
	  print,'     tprint.  Will create and return it on /INIT, then'
	  print,'     send as an input on following calls.'
	  print,'   /INIT Clear internal text array.'
	  print,'     May also give an initial text array: INIT=txt.'
	  print,'   ADD=txt Add given text array to internal text.'
	  print,'   OUT=txt Return internal text array.'
	  print,'   /PRINT print the entire internal text array to screen.'
	  print,'   /NUMBERS Include text line indices for the /PRINT option.'
	  print,'   /SCREEN Print the added line or lines to the screen also.'
	  print,'   SAVE=file  Save internal text array in a text file.'
	  print,'   /QUIET do not show messages.'
	  print,'   /REVERSE reverse text array order (for /PRINT, OUT=, or SAVE=).'
	  print,'   FORMAT=fmt Optional print format.'
	  print,'   /VERBOSE Indicate progress for /save.'
	  print,'   ERROR=err 0=ok, 1=error if OUT or /PRINT used with no text.'
#####################
	  print,' Notes: Intended to make it easy to take a set of print'
	  print,'   statements in a program and change them to build up'
	  print,'   a text array.  Uses the IDL string function in place'
	  print,'   of the print statement to handle the arguments.  Can'
	  print,'   then return the text array built up from multiple'
	  print,'   tprint calls and use it elsewhere.'
	  return
	endif
 
	;-----------------------------------------------------------------
	;  Define internal buffer (even if not used)
	;-----------------------------------------------------------------
	if n_elements(flag) eq 0 then flag=0	; Define flag (0 = no text yet).
	if n_elements(txt) eq 0 then txt=''	; Define txt.
 
	;-----------------------------------------------------------------
	;  /INIT or INIT=text_array
	;  Initialize or add given text to working text array
	;  and update internal or external buffer.
	;-----------------------------------------------------------------
	if n_elements(init) gt 0 then begin	; Anything in INIT?
	  if (n_elements(init) eq 1) and (init[0] eq '1') then begin	; /INIT
	    txt0 = ''				; Define.
	    flag0 = 0				; Set no text flag.
	  endif else begin						; INIT=text
	    txt0 = init				; Start with given text.
	    flag0 = 1				; Set have text flag.
	  endelse
	  ;----  Update internal or external buffer  ----
	  if arg_present(buf) then begin	; Create a structure buffer.
	    buf = {txt:txt0, flag:flag0}	; External memory (buffer).
	  endif else begin			; Use internal memory (buffer).
	    txt = txt0
	    flag = flag0
	  endelse
	endif
 
	;-----------------------------------------------------------------
	;  Grab working values from  internal or external buffer
	;-----------------------------------------------------------------
	if arg_present(buf) then begin		; Use external buffer.
	  txt0 = buf.txt
	  flag0 = buf.flag
	endif else begin			; Use internal buffer.
	  txt0 = txt
	  flag0 = flag
	endelse
 
	;-----------------------------------------------------------------
	;  SAVE = file
	;  Save from working text array
	;-----------------------------------------------------------------
	if n_elements(save) ne 0 then begin	; Have a file name for save.
	  if flag0 eq 0 then begin		; If no text return error.
	    err = 1
	    return
	  endif
	  if keyword_set(rev) then tt=reverse(txt0) else tt=txt0
	  openw,lun,save,/get_lun		; Open save file.
	  ntt = n_elements(tt)
	  for i=0L,ntt-1 do begin
	    if keyword_set(verb) then if (i mod 1000) eq 0 then print,i,ntt
	    printf,lun,tt[i]			; Print text.
	  endfor
	  free_lun,lun
	  if not keyword_set(quiet) then print,' Text saved to '+save
	  err = 0				; OK.
	endif
 
	;-----------------------------------------------------------------
	;  /PRINT 
	;  Print to screen from working text array
	;-----------------------------------------------------------------
	if keyword_set(print) then begin
	  if flag0 eq 0 then begin		; If no text return error.
	    err = 1
	    return
	  endif
	  if keyword_set(rev) then tt=reverse(txt0) else tt=txt0
	  if keyword_set(numbers) then begin
	    for i=0L,n_elements(tt)-1 do print,i,tt[i],form='(i7,2x,a)'	; Print.
	  endif else begin
	    for i=0L,n_elements(tt)-1 do print,tt[i] ; Print text.
	  endelse
	  err = 0				; OK.
	endif
 
	;-----------------------------------------------------------------
	;  OUT = txt
	;  Return text from working text array
	;-----------------------------------------------------------------
	if arg_present(out) then begin		; Return text requested.
	  if flag0 eq 0 then begin
	    err = 1
	    return
	  endif
	  err = 0
	  if keyword_set(rev) then tt=reverse(txt0) else tt=txt0
	  out = tt
	  return
	endif
 
	;-----------------------------------------------------------------
	;  ADD = txt
	;  Add given text array to working text array
	;  and update internal or external buffer.
	;-----------------------------------------------------------------
	if n_elements(add) ne 0 then begin
	  if flag0 eq 0 then txt0=add else txt0=[txt0,add] ; Add it to array.
	  flag0 = 1				; Flag array as existing.
	  if keyword_set(screen) then begin
	    if not keyword_set(quiet) then more,add,lines=n_elements(add)+1
	  endif
	  ;----  Update internal or external buffer  ----
	  if arg_present(buf) then begin	; Use external buffer.
	    buf = {txt:txt0, flag:flag0}
	  endif else begin			; Use internal buffer.
	    txt = txt0
	    flag = flag0
	  endelse
	  return
	endif
 
	;-----------------------------------------------------------------
	;  TPRINT given items
	;  Add items to working text array
	;  and update internal or external buffer.
	;-----------------------------------------------------------------
	n = n_params(0)			; How many args?
	if n eq 0 then return		; None, nothing to do.
 
	case n of
1:	p = string(p1,form=fmt)
2:	p = string(p1,p2,form=fmt)
3:	p = string(p1,p2,p3,form=fmt)
4:	p = string(p1,p2,p3,p4,form=fmt)
5:	p = string(p1,p2,p3,p4,p5,form=fmt)
6:	p = string(p1,p2,p3,p4,p5,p6,form=fmt)
7:	p = string(p1,p2,p3,p4,p5,p6,p7,form=fmt)
8:	p = string(p1,p2,p3,p4,p5,p6,p7,p8,form=fmt)
9:	p = string(p1,p2,p3,p4,p5,p6,p7,p8,p9,form=fmt)
10:	p = string(p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,form=fmt)
11:	p = string(p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,form=fmt)
12:	p = string(p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,form=fmt)
13:	p = string(p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,form=fmt)
14:	p = string(p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,form=fmt)
15:	p = string(p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,form=fmt)
16:	p = string(p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,form=fmt)
17:	p = string(p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,form=fmt)
18:	p = string(p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,form=fmt)
19:	p = string(p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,form=fmt)
20:	p = string(p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,form=fmt)
	endcase
 
 
	if flag0 eq 0 then txt0=p else txt0=[txt0,p]	; Add it to array.
	flag0 = 1			; Flag array as existing.
	if keyword_set(screen) then if not keyword_set(quiet) then print,p
 
	;----  Update internal or external buffer  ----
	if arg_present(buf) then begin	; Use external buffer.
	  buf = {txt:txt0, flag:flag0}
	endif else begin		; Use internal buffer.
	  txt = txt0
	  flag = flag0
	endelse
 
	end
