;-------------------------------------------------------------
;+
; NAME:
;       GETPOS
; PURPOSE:
;       Return current plot position.
; CATEGORY:
; CALLING SEQUENCE:
;       pos = getpos()
; INPUTS:
; KEYWORD PARAMETERS:
;       Keywords:
;         /DEV Return plot postion in device coordinates.
;         /NORM Return plot postion in normalized coordinates (def).
; OUTPUTS:
;       pos = Returned plot position array.  out
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 2001 Oct 31
;       R. Sterner, 2010 Jun 04 --- Converted arrays from () to [].
;
; Copyright (C) 2001, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	function getpos, dev=dev, norm=norm, help=hlp
 
	if keyword_set(hlp) then begin
	  print,' Return current plot position.'
	  print,' pos = getpos()'
	  print,'   pos = Returned plot position array.  out'
	  print,' Keywords:'
	  print,'   /DEV Return plot postion in device coordinates.'
	  print,'   /NORM Return plot postion in normalized coordinates (def).'
	  return,''
	endif
 
	pos = [!x.window[0],!y.window[0],!x.window[1],!y.window[1]]
 
	if keyword_set(dev) then $
	  pos = round(pos*[!d.x_size,!d.y_size,!d.x_size,!d.y_size])
 
	return, pos
 
	end
