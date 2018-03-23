;-------------------------------------------------------------
;+
; NAME:
;       ALTAZI_POINTER
; PURPOSE:
;       Plot an altazimuth pointer on display.
; CATEGORY:
; CALLING SEQUENCE:
;       altazi_pointer, alt, azi, ix0, iy0
; INPUTS:
;       alt = Altitude (deg).      in
;       azi = Azimuth (deg).       in
;       ix0, iy0 = Circle center.  in
;         Device coordinates.
; KEYWORD PARAMETERS:
;       Keywords:
;        SIZE=rd  Radius in pixels (def=100).
;        TITLE=ttl Title (def=none).
;           May be an array.
;        CHARSIZE=chsz base character size (def=1).
;        COLOR=clr Text color (def=white).
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 2007 Oct 23
;       R. Sterner, 2007 Oct 25 --- Added head.
;
; Copyright (C) 2007, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro altazi_pointer, alt, azi, ix0, iy0, size=rd, title=ttl, $
	  charsize=chsz, color=clr0, help=hlp
 
	if (n_params(0) lt 4) or keyword_set(hlp) then begin
	  print,' Plot an altazimuth pointer on display.'
	  print,' altazi_pointer, alt, azi, ix0, iy0'
	  print,'   alt = Altitude (deg).      in'
	  print,'   azi = Azimuth (deg).       in'
	  print,'   ix0, iy0 = Circle center.  in'
	  print,'     Device coordinates.'
	  print,' Keywords:'
	  print,'  SIZE=rd  Radius in pixels (def=100).'
	  print,'  TITLE=ttl Title (def=none).'
	  print,'     May be an array.'
	  print,'  CHARSIZE=chsz base character size (def=1).'
	  print,'  COLOR=clr Text color (def=white).'
	  return
	endif
 
	;---------------------------------------------------
	;  Defaults
	;---------------------------------------------------
	if n_elements(clr0) eq 0 then clr0=tarclr(255,255,255)
	if n_elements(chsz) eq 0 then chsz=1.
	if n_elements(rd) eq 0 then rd=100.
	if n_elements(ttl) eq 0 then ttl=''
	csz = chsz*rd/50.
	if alt ge 0 then clr1=tarclr(/hsv,45,.5,1) $	; Disk color.
	  else clr1=tarclr(/hsv,45+180,.5,1)
	clr2 = tarclr(/hsv,45,.5,.5)			; Pointer color.
	alen = 0.2					; Head length.
;	thk = 3.					; Pointer thickness.
	thk = rd*alen/4
 
	;---------------------------------------------------
	;  Make reference disk
	;---------------------------------------------------
	n = 201
	polrec,rd,maken(0,360,n),/deg,x0,y0
	z0 = fltarr(n)
 
	;---------------------------------------------------
	;  Pointer tip
	;---------------------------------------------------
	xt0 = 0.
	yt0 = 0.
	zt0 = rd
 
	;---------------------------------------------------
	;  Base of arrowhead
	;---------------------------------------------------
	xb = x0*alen/2				; Head radius.
	yb = y0*alen/2
	fr = 1.-alen
	zb = fr*rd + x0*0		; Head start z.
 
	;---------------------------------------------------
	;  Tilt by alt
	;---------------------------------------------------
	rot_3d, 2, x0,y0,z0,-(90-alt),/deg,x1,y1,z1		; Disk.
	rot_3d, 2, xt0,yt0,zt0,-(90-alt),/deg,xt1,yt1,zt1	; Pointer.
	rot_3d, 2, xb,yb,zb,-(90-alt),/deg,xb1,yb1,zb1		; Arrow head.
 
	;---------------------------------------------------
	;  Rotate by azi
	;---------------------------------------------------
	rot_3d, 3, x1,y1,z1,-(90-azi),/deg,x2,y2,z2		; Disk.
	rot_3d, 3, xt1,yt1,zt1,-(90-azi),/deg,xt2,yt2,zt2	; Pointer.
	rot_3d, 3, xb1,yb1,zb1,-(90-azi),/deg,xb2,yb2,zb2	; Pointer.
 
	;---------------------------------------------------
	;  Plot
	;
	;  If alt ge 0 then plot disk, then pointer,
	;  else plot pointer, then disk.
	;---------------------------------------------------
	;---  Frame  ---
	plots,/dev,x0+ix0,y0+iy0,col=clr0			; Ref disk.
 
	if alt ge 0 then begin
	  ;---  Disk  ---
	  polyfill,/dev,x2+ix0,y2+iy0,color=clr1		; Pointer disk.
	  plots,/dev,x2+ix0,y2+iy0,col=clr0			; Disk outline.
	  polyfill,/dev,x2/rd*thk+ix0,y2/rd*thk+iy0,color=clr2	; Pointer base.
	  ;---  Pointer  ---
	  plots,/dev,ix0+[0,fr*xt2],iy0+[0,fr*yt2], $		; Shaft.
	    col=clr2,thick=thk
	  polyfill,/dev,ix0+xb2,iy0+yb2,color=clr2		; Head.
	  polyfill,/dev,ix0+[xb2[50],xb2[150],xt2], $
		        iy0+[yb2[50],yb2[150],yt2],color=clr2
	  plots,/dev,ix0+xt2,iy0+yt2,col=clr0,psym=3
	endif else begin
	  ;---  Pointer  ---
	  plots,/dev,ix0+[0,fr*xt2],iy0+[0,fr*yt2], $		; Shaft.
	    col=clr2,thick=thk
	  polyfill,/dev,ix0+xb2,iy0+yb2,color=clr2		; Head.
	  polyfill,/dev,ix0+[xb2[50],xb2[150],xt2], $
		        iy0+[yb2[50],yb2[150],yt2],color=clr2
	  plots,/dev,ix0+xt2,iy0+yt2,col=clr0,psym=3
	  ;---  Disk  ---
	  polyfill,/dev,x2+ix0,y2+iy0,color=clr1		; Pointer disk.
	  plots,/dev,x2+ix0,y2+iy0,col=clr0			; Disk outline.
	  polyfill,/dev,x2/rd*thk+ix0,y2/rd*thk+iy0,color=clr2	; Pointer base.
	endelse
 
	;---------------------------------------------------
	;  Labels
	;---------------------------------------------------
	txt = 'Alt = '+string(alt,form='(F5.1)') + $
	  ', Azi = '+string(azi,form='(F5.1)')
	dy = csz*!d.y_ch_size					; Char height.
	ixt = ix0
	ixt=ix0 & iyt=iy0-rd-1.5*dy
	xyouts,/dev,ixt,iyt,align=0.5,chars=csz,txt,col=clr0
	ntt = n_elements(ttl)
	ixt=ix0 & iyt=iy0+rd+0.5*dy+(ntt-1)*1.5*dy
	for i=0,ntt-1 do $
	  xyouts,/dev,ixt,iyt-1.5*i*dy,align=0.5,chars=csz,ttl[i],col=clr0
 
	end
