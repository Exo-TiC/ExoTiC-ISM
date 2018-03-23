;-------------------------------------------------------------
;+
; NAME:
;       MOVEMARK
; PURPOSE:
;       Move a marker in a window.
; CATEGORY:
; CALLING SEQUENCE:
;       movemark, ix, iy
; INPUTS:
; KEYWORD PARAMETERS:
;       Keywords:
;         /INIT Initialize.
;         MAG=mag Mag factor (for ix,iy, def=1).  /init only.
;        PSYM=sym Marker plot symbol (def=6).     /init only.
;        SYMSIZE=ssiz Symbol size (def=1).        /init only.
;        Thick=thk Symbol thickness (def=1).      /init only.
; OUTPUTS:
; COMMON BLOCKS:
;       movemark_com
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 2008 May 13
;
; Copyright (C) 2008, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro movemark, ix, iy, init=init, mag=mag, psym=sym, symsize=ssiz, $
	  thick=thk, help=hlp
 
	common movemark_com, ix0, iy0, mag0, sym0, ssiz0, thk0, win0
 
	if ((n_params(0) lt 2) and (not keyword_set(init))) $
	  or keyword_set(hlp) then begin
	  print,' Move a marker in a window.'
	  print,' movemark, ix, iy'
	  print,'   ix, iy = New marker position (dev coord).'
	  print,' Keywords:'
	  print,'   /INIT Initialize.'
	  print,'   MAG=mag Mag factor (for ix,iy, def=1).  /init only.'
	  print,'  PSYM=sym Marker plot symbol (def=6).     /init only.'
	  print,'  SYMSIZE=ssiz Symbol size (def=1).        /init only.'
	  print,'  Thick=thk Symbol thickness (def=1).      /init only.'
	  return
	endif
 
	;---  Initialize  ---
	if keyword_set(init) then begin
	  if n_elements(mag) gt 0 then mag0=mag else mag0=1
	  if n_elements(sym) gt 0 then sym0=sym else sym0=6
	  if n_elements(ssiz) gt 0 then ssiz0=ssiz else ssiz0=1
	  if n_elements(thk) gt 0 then thk0=thk else thk0=1
	  win0 = !d.window
	  ix0 = -100
	  iy0 = -100
	  return
	endif
 
	;---  Check if initialized  ---
	if n_elements(mag0) eq 0 then begin
	  print,' Must initialize movemark before calling.'
	  return
	endif
 
	;---  Make sure last position defined  ---
	if n_elements(ix0) eq 0 then begin
	  ix0 = -100
	  iy0 = -100
	endif
 
	;---  Incoming window  ---
	cwin = !d.window
	wset,win0
 
	;---  Erase old, plot new marker  ---
	device, set_graph=6
	jx = ix0*mag0
	jy = iy0*mag0
	plots, /dev, jx, jy, psym=sym0, symsize=ssiz0, thick=thk0
	empty
	jx = ix*mag0
	jy = iy*mag0
	plots, /dev, jx, jy, psym=sym0, symsize=ssiz0, thick=thk0
	empty
	device, set_graph=3
	ix0 = ix
	iy0 = iy
 
	;---  Restore incoming window  ---
	wset, cwin
 
	end
