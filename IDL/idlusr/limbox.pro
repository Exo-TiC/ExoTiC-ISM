;-------------------------------------------------------------
;+
; NAME:
;       LIMBOX
; PURPOSE:
;       Interactively get new map limits.
; CATEGORY:
; CALLING SEQUENCE:
;       limbox, lim
; INPUTS:
; KEYWORD PARAMETERS:
;       Keywords:
;         EXIT=ex Exit code: 0=ok, else aborted.
; OUTPUTS:
;       lim = returned limit array.   out
; COMMON BLOCKS:
; NOTES:
;       Notes: Use left mouse button to drag open a box.
;       Move box by dragging inside it.  Move an edge or
;       corner by dragging it.  Middle button to exit.
;       Useful for rectangular projections.
; MODIFICATION HISTORY:
;       R. Sterner, 2001 Oct 10
;
; Copyright (C) 2001, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
        pro limbox, lim, exit=ex, help=hlp
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Interactively get new map limits.'
	  print,' limbox, lim'
	  print,'   lim = returned limit array.   out'
	  print,' Keywords:'
	  print,'   EXIT=ex Exit code: 0=ok, else aborted.'
	  print,' Notes: Use left mouse button to drag open a box.'
	  print,' Move box by dragging inside it.  Move an edge or'
	  print,' corner by dragging it.  Middle button to exit.'
	  print,' Useful for rectangular projections.'
	  return
	endif
 
        print,' '
        print,' Drag open a box on the map.  Move box by dragging inside.'
        print,' May drag a corner or edge.  Click middle button when done.'
        print,' '
 
        lim = [0,0,0,0]
 
        box2b, ix1, ix2, iy1, iy2, exit=ex
        if ex eq 1 then return
        tmp = convert_coord([ix1,ix2],[iy1,iy2],/dev,/to_data)
 
	x1 = tmp(0,0)
        x2 = tmp(0,1)
        y1 = tmp(1,0)
        y2 = tmp(1,1)
 
        lim = [y1,x1,y2,x2]
 
        end
