;-------------------------------------------------------------
;+
; NAME:
;       TVRDBOX2B
; PURPOSE:
;       Read part of screen image using an interactive box.
; CATEGORY:
; CALLING SEQUENCE:
;       tvrdbox2b, img, [x1,x2,y1,y2]
; INPUTS:
; KEYWORD PARAMETERS:
;       Keywords:
;         /NOPROMPT Do not display prompt text.
;         /BW Normally img is returned as a 24-bit color image.
;            Use this keyword to return as an 8-bit image.
;         TRUE=tr RGB band interleave dimension for img (def=3).
;         EXITCODE=ex  Returned exit code: 0=normal, 1=alternate.
;           For an alternate exit img will not be updated.
;         Other keywords known by box2b may also be used:
;            /STATUS,/XMODE,/NOMENU,... (see box2b,/help for details).
; OUTPUTS:
;       img = image read from screen.                      out
;       x1,x2,y1,y2 = optional device coordinates of box.  in,out
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 2008 Mar 27
;
; Copyright (C) 2008, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro tvrdbox2b, img, x1, x2, y1, y2 ,help=hlp, $
	  exitcode=ex, bw=bw, true=tr, noprompt=nopr, _extra=extra
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Read part of screen image using an interactive box.'
	  print,' tvrdbox2b, img, [x1,x2,y1,y2]'
	  print,'   img = image read from screen.                      out'
	  print,'   x1,x2,y1,y2 = optional device coordinates of box.  in,out'
	  print,' Keywords:'
	  print,'   /NOPROMPT Do not display prompt text.'
	  print,'   /BW Normally img is returned as a 24-bit color image.'
	  print,'      Use this keyword to return as an 8-bit image.'
	  print,'   TRUE=tr RGB band interleave dimension for img (def=3).'
	  print,'   EXITCODE=ex  Returned exit code: 0=normal, 1=alternate.'
	  print,'     For an alternate exit img will not be updated.'
	  print,'   Other keywords known by box2b may also be used:'
	  print,'      /STATUS,/XMODE,/NOMENU,... (see box2b,/help for details).'
	  return
	endif
 
	if not keyword_set(nopr) then begin
	  print,' '
	  print,' Interactive box'
	  print,' '
	  if n_elements(x1) eq 0 or n_elements(x2) eq 0 or $
	     n_elements(y1) eq 0 or n_elements(y2) eq 0 then $
	     print,' To create: drag open a box.'
	  print,' To resize: drag corners or sides.'
	  print,' To move: drag inside.'
	  print,' Click any other button to exit.'
	endif
 
	box2b, x1, x2, y1, y2, exit=ex, _extra=extra
 
	if ex eq 1 then return
 
	if n_elements(tr) eq 0 then tr=3
	dx = x2 - x1 + 1
	dy = y2 - y1 + 1
	if keyword_set(bw) then img=tvrd(x1,y1,dx,dy) $
	  else img=tvrd(x1,y1,dx,dy,tr=tr)
 
	end
