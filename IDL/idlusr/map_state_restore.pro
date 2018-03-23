;-------------------------------------------------------------
;+
; NAME:
;       MAP_STATE_RESTORE
; PURPOSE:
;       Restore last map_set state.
; CATEGORY:
; CALLING SEQUENCE:
;       map_state_restore
; INPUTS:
; KEYWORD PARAMETERS:
;       Keywords:
;         IN=in  Send structure with info to reset map.
; OUTPUTS:
; COMMON BLOCKS:
;       map_state_com
; NOTES:
;       Notes: The last map state is restored without IN. Any number
;        using the IN keyword.  Use map_state_save to
;        save state.  Useful to preserve map scaling info.
; MODIFICATION HISTORY:
;       R. Sterner, 2001 Dec 30
;       R. Sterner, 2008 Jun 11 --- Added !z and !p to save.
;
; Copyright (C) 2001, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro map_state_restore, in=in, help=hlp
 
	common map_state_com, map, x, y, z, p
 
	if keyword_set(hlp) then begin
	  print,' Restore last map_set state.'
	  print,' map_state_restore'
	  print,'   All args are keywords.'
	  print,' Keywords:'
	  print,'   IN=in  Send structure with info to reset map.'
	  print,' Notes: The last map state is restored without IN. Any number'
	  print,'  using the IN keyword.  Use map_state_save to'
 	  print,'  save state.  Useful to preserve map scaling info.'
	  return
	endif
 
	if n_elements(in) ne 0 then begin
	  map = in.map
	  x = in.x
	  y = in.y
	  z = in.z
	  p = in.p
	endif
 
	!map = map
	!x = x
	!y = y
	!z = z
	!p = p
 
	end
