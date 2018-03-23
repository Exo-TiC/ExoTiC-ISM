;-------------------------------------------------------------
;+
; NAME:
;       MAPCURR
; PURPOSE:
;       Set current window to a cylindrical map, no margins.
; CATEGORY:
; CALLING SEQUENCE:
;       mapcurr, [lon]
; INPUTS:
;       lon = Optional central longitude (def=0).  in
; KEYWORD PARAMETERS:
;       Keywords:
;         May use map_set keywords except for the following:
;         /NOERASE, /NOBORDER, POSITION=pos.
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 2012 Nov 20
;       R. Sterner, 2012 Nov 27 --- Used _extra.
;
; Copyright (C) 2012, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
        pro mapcurr, lon0, _extra=extra, help=hlp
 
        if keyword_set(hlp) then begin
          print,' Set current window to a cylindrical map, no margins.'
          print,' mapcurr, [lon]'
          print,'   lon = Optional central longitude (def=0).  in'
          print,' Keywords:'
          print,'   May use map_set keywords except for the following:'
          print,'   /NOERASE, /NOBORDER, POSITION=pos.'
          return
        endif
 
        if n_elements(lon0) eq 0 then lon0=0.
 
        map_set, 0, lon0, /noerase, /nobord, pos=[0,0,1,1], _extra=extra
 
        end
