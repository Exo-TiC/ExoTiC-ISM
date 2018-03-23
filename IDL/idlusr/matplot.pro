;-------------------------------------------------------------
;+
; NAME:
;       MATPLOT
; PURPOSE:
;       Display an image with color bar roughly as in Matlab.
; CATEGORY:
; CALLING SEQUENCE:
;       matplot, img
; INPUTS:
;       img = 8-bit image scaled for display.         in
; KEYWORD PARAMETERS:
;       Keywords:
;         XAXIS=x, YAXIS=x Optional x and y axis arrays.
;         VMIN=vmn, VMAX=vmx = Image min and max data values.
;           These are the values that are displayed as
;           0 and 255.  Def: 0, 255.
;         POSITION=pos  Over-ride default image potision.
;         TITLE=tt  Image title (def=none).
;         XTITLE=tx Image X axis title (def=none).
;         YTITLE=ty Image Y axis title (def=none).
;         BTITLE=btt  Bar title (def=none).
;         BLABEL=blab Bar label (def=none).
;         Some keywords known by PLOT may be given, such as
;           CHARSIZE=csz, ... 
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
;       Notes: Can use IDL color tables.  Do first:
;         device,decomp=0 & loadct,3
;         Also the image x,y scaling info is embedded and may be
;         at a later time such as when a saved image of the plot
;         has been reloaded.  After loading use xcursor to see if
;         the image x,y coordinates are known.  If not call
;         set_scale to set them.
; MODIFICATION HISTORY:
;       R. Sterner, 2008 May 28
;
; Copyright (C) 2008, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro matplot, img, vmin=vmn, vmax=vmx, xaxis=x, yaxis=y, $
	  position=pos, bposition=bpos, $
	  title=ttl, xtitle=ttx, ytitle=tty, btitle=bttl, $
	  blabel=blab, _extra=extra, help=hlp
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Display an image with color bar roughly as in Matlab.'
	  print,' matplot, img'
	  print,'   img = 8-bit image scaled for display.         in'
	  print,' Keywords:'
	  print,'   XAXIS=x, YAXIS=x Optional x and y axis arrays.'
	  print,'   VMIN=vmn, VMAX=vmx = Image min and max data values.'
	  print,'     These are the values that are displayed as'
	  print,'     0 and 255.  Def: 0, 255.'
	  print,'   POSITION=pos  Over-ride default image potision.'
	  print,'   TITLE=tt  Image title (def=none).'
	  print,'   XTITLE=tx Image X axis title (def=none).'
	  print,'   YTITLE=ty Image Y axis title (def=none).'
	  print,'   BTITLE=btt  Bar title (def=none).'
	  print,'   BLABEL=blab Bar label (def=none).'
	  print,'   Some keywords known by PLOT may be given, such as'
	  print,'     CHARSIZE=csz, ... '
	  print,' Notes: Can use IDL color tables.  Do first:'
	  print,'   device,decomp=0 & loadct,3'
	  print,'   Also the image x,y scaling info is embedded and may be'
	  print,'   at a later time such as when a saved image of the plot'
	  print,'   has been reloaded.  After loading use xcursor to see if'
	  print,'   the image x,y coordinates are known.  If not call'
	  print,'   set_scale to set them.'
	  return
	endif
 
	;---  Defaults  ---
	if n_elements(pos) eq 0 then pos=[0.12,0.15,0.78,0.9]
	if n_elements(bpos) eq 0 then bpos=[0.83,0.15,0.88,0.9]
	if n_elements(x) eq 0 then x=makex(0,dimsz(img,1)-1,1)
	if n_elements(y) eq 0 then y=makex(0,dimsz(img,2)-1,1)
	if n_elements(vmn) eq 0 then vmn=0
	if n_elements(vmx) eq 0 then vmx=255
	if n_elements(ttl) eq 0 then ttl=''
 
	;---  Default some values that might come in through _extra  ---
	if n_elements(extra) eq 0 then extra={init:0}	; Force defined.
	if tag_test(extra,'CHARSIZE',minlen=5) eq 0 then $
	  extra=create_struct(extra,'CHARSIZE',1.75)
 
	;---  Hard coded values  ---
	clr = 0
	
	;---  Image plot  ---
	ticklen, -5,-5,xtk,ytk,pos=pos
	erase, -1
	izoom,x,y,img,pos=pos,col=clr,/noerase,xticklen=xtk,yticklen=ytk,$
	  title='!A'+ttl, xtitle=ttx, ytitle=tty, _extra=extra
 
	;---  Bar plot  ---
	ticklen, -5,-5,xtk,ytk,pos=bpos
	cbar,pos=bpos,/vert,col=clr,vmin=vmn,vmax=vmx,yticklen=ytk, $
	  title=bttl, ytitle=blab, _extra=extra
 
	end
