;-------------------------------------------------------------
;+
; NAME:
;       TEXT_GRAB
; PURPOSE:
;       Copy and paste text into an IDL string array.
; CATEGORY:
; CALLING SEQUENCE:
;       text_grab, txt
; INPUTS:
; KEYWORD PARAMETERS:
;       Keywords:
;         EXIT_CODE=ex Exit code: 0=OK, 1=Cancel.
;         XSIZE=xsz Width of text entry area (def=80 char).
;         YSIZE=ysz Height of text entry area (def=20 lines).
; OUTPUTS:
;       txt = Resulting string array with text.   out
; COMMON BLOCKS:
; NOTES:
;       Notes: This simple text entry area can be used to paste
;       text copied from elsewhere and return it as a string array.
;       Simple editing may also be done, click to position the text
;       cursor.  Arrow keys and Page Up and Page Down should work,
;       and Home and End.  Insert toggles insert/overwrite.  Blocks
;       of text can be deleted by highlighting it and deleting.
;       Use Home and then Enter to open a blank line.
;       The OK button will return the text, Cancel will not.
; MODIFICATION HISTORY:
;       R. Sterner, 2009 Oct 06
;
; Copyright (C) 2009, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro text_grab_event, ev
 
	widget_control, ev.id, get_uval=cmd		; Button command.
	widget_control, ev.top, get_uval=s		; Info structure.
 
	if cmd eq 'OK' then begin			; Normal exit.
	  widget_control, s.id_txt, get_val=txt		; Grab text.
	  out = {txt:txt, flag:0}			; Output structure.
	  widget_control, s.res, set_uval=out		; Save output structure.
	  widget_control, ev.top, /dest			; Kill widget.
	  return
	endif
 
	if cmd eq 'CANCEL' then begin			; Cancel exit.
	  out = {txt:'', flag:1}			; Set cancel flag.
	  widget_control, s.res, set_uval=out		; Save output structure.
	  widget_control, ev.top, /dest			; Kill widget.
	  return
	endif
 
	end
 
 
	;--------------------------------------------------------------
	;  text_grab.pro = Paste some text into an IDL string array.
	;--------------------------------------------------------------
	pro text_grab, txt, xsize=xsz, ysize=ysz, exit_code=ex, $
	  title=ttl0, help=hlp
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Copy and paste text into an IDL string array.'
	  print,' text_grab, txt'
	  print,'   txt = Resulting string array with text.   out'
	  print,' Keywords:'
	  print,'   EXIT_CODE=ex Exit code: 0=OK, 1=Cancel.'
	  print,'   XSIZE=xsz Width of text entry area (def=80 char).'
	  print,'   YSIZE=ysz Height of text entry area (def=20 lines).'
	  print,' Notes: This simple text entry area can be used to paste'
	  print,' text copied from elsewhere and return it as a string array.'
	  print,' Simple editing may also be done, click to position the text'
	  print,' cursor.  Arrow keys and Page Up and Page Down should work,'
	  print,' and Home and End.  Insert toggles insert/overwrite.  Blocks'
	  print,' of text can be deleted by highlighting it and deleting.'
	  print,' Use Home and then Enter to open a blank line.'
	  print,' The OK button will return the text, Cancel will not.'
	  return
	endif
 
	;---  Defaults  ---
	if n_elements(ttl0) eq 0 then ttl0='Paste text into window'
	ttl = ttl0
	if n_elements(xsz) eq 0 then xsz=80
	if n_elements(ysz) eq 0 then ysz=20
 
	;---  Set up widget  ---
	top = widget_base(/col,title=ttl)
	b = widget_base(top,/row)
	id = widget_button(b,value='OK',uval='OK')
	id = widget_button(b,value='Cancel',uval='CANCEL')
	id_txt = widget_text(top,xsize=xsz,ysize=ysz,/edit)
	widget_control, top, /real
 
	;---  Unused base to return results from event handler  ---
	res = widget_base()
 
	;---  Save info structure and manage  ---
	widget_control, top, set_uval={id_txt:id_txt, res:res}
	xmanager, 'text_grab', top
 
	;---  Get results from event handler  ---
	widget_control, res, get_uval=out
	ex = out.flag
	txt = out.txt
 
	end
