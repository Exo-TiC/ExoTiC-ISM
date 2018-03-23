;-------------------------------------------------------------
;+
; NAME:
;       MAP_CYL_RESCALE
; PURPOSE:
;       Rescale a cylindrical projection map in the current window.
; CATEGORY:
; CALLING SEQUENCE:
;       map_cyl_rescale
; INPUTS:
; KEYWORD PARAMETERS:
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
;       Notes: Sometimes the embedded scaling info in a map may
;       be lost.  This routine allows the info to be interactively
;       determined and embedded again.  This only works for the
;       cylindrical equadistant projection, the IDL default.
;       The user selects the map window and several labeled tick
;       marks to determine the scaling.
; MODIFICATION HISTORY:
;       R. Sterner, 2012 Aug 28
;
; Copyright (C) 2012, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
        pro map_cyl_rescale, help=hlp
 
        if keyword_set(hlp) then begin
          print,' Rescale a cylindrical projection map in the current window.'
          print,' map_cyl_rescale'
          print,'   No args.'
          print,' Notes: Sometimes the embedded scaling info in a map may'
          print,' be lost.  This routine allows the info to be interactively'
          print,' determined and embedded again.  This only works for the'
          print,' cylindrical equadistant projection, the IDL default.'
          print,' The user selects the map window and several labeled tick'
          print,' marks to determine the scaling.'
          return
        endif
 
        wshow
 
        ;---  Window size  ---
        xs = !d.x_size
        ys = !d.y_size
 
        ;---  Get position  ---
ll:     xmess,['LL: Lower Left corner:', $
               ' Scroll the window and use the crosshairs that will appear', $
               ' to select the lower left window corner']
        crossi,/xmode,/mag,/dev,ix1,iy1
        an = xyesno('Redo point?',def='N')
        if an eq 'Y' then goto, ll
ur:     xmess,['UR: Upper Right corner:',$
               ' Scroll the window and use the crosshairs that will appear', $
               ' to select the upper right window corner']
        crossi,/xmode,/mag,/dev,ix2,iy2
        an = xyesno('Redo point?',def='N')
        if an eq 'Y' then goto, ur
 
        ;---  Get Longitudes  ---
ln1:    xmess,['Lon 1:',$
               'Select first of two known longitude points']
        crossi,/xmode,/mag,/dev,ixp1,iy
        an = xyesno('Redo point?',def='N')
        if an eq 'Y' then goto, ln1
        xtxtin,ln1v,title='Enter longitude for selected point'
        ln1v = ln1v + 0.0
ln2:    xmess,['Lon 2:',$
               'Select second of two known longitude points']
        crossi,/xmode,/mag,/dev,ixp2,iy
        an = xyesno('Redo point?',def='N')
        if an eq 'Y' then goto, ln2
        xtxtin,ln2v,title='Enter longitude for selected point'
        ln2v = ln2v + 0.0
 
        ;---  Get Latitudes  ---
lt1:    xmess,['Lat 1:',$
               'Select first of two known latitude points']
        crossi,/xmode,/mag,/dev,ix,iyp1
        an = xyesno('Redo point?',def='N')
        if an eq 'Y' then goto, lt1
        xtxtin,lt1v,title='Enter latitude for selected point'
        lt1v = lt1v + 0.0
lt2:    xmess,['Lat 2:',$
               'Select second of two known latitude points']
        crossi,/xmode,/mag,/dev,ix,iyp2
        an = xyesno('Redo point?',def='N')
        if an eq 'Y' then goto, lt2
        xtxtin,lt2v,title='Enter latitude for selected point'
        lt2v = lt2v + 0.0
 
        ;---  Normalized position  ---
        pos = [ix1/xs, iy1/ys, ix2/xs, iy2/ys]
 
        ;---  Compute min/max longitudes  ---
        dx = (ln2v-ln1v)/(ixp2-ixp1)
        dx1 = dx*(ixp1-ix1)
        dx2 = dx*(ixp2-ix2)
        lon1 = ln1v - dx1
        lon2 = ln2v - dx2
 
        ;---  Compute min.max latitudes  ---
        dy = (lt2v-lt1v)/(iyp2-iyp1)
        dy1 = dy*(iyp1-iy1)
        dy2 = dy*(iyp2-iy2)
        lat1 = lt1v - dy1
        lat2 = lt2v - dy2
 
        ;---  Limit  ---
        lim = [lat1,lon1,lat2,lon2]
 
        ;---  Set map scaling ---
        map_set2,0,0,limit=lim,pos=pos,/noborder,/noerase
        map_put_scale
 
        map_set_scale,/list
 
        print,' '
        print,' Map scale embedded (may save map with scale).'
        print,' '
 
        end
        
