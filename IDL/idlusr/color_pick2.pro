;-------------------------------------------------------------
;+
; NAME:
;       COLOR_PICK2
; PURPOSE:
;       Color picker widget using RGB and HSV sliders.
; CATEGORY:
; CALLING SEQUENCE:
;       color_pick2, new, old
; INPUTS:
;       old = Original color.            in
; KEYWORD PARAMETERS:
;       Keywords:
;         TITLE=tt  Title text.
;         XOFFSET=xoff, YOFFSET=yoff, position.
;         GROUP_LEADER=grp Group leader.
; OUTPUTS:
;       new = New color (-1 for Cancel). out
; COMMON BLOCKS:
; NOTES:
;       Note: See color_pick for a color wheel.
; MODIFICATION HISTORY:
;       R. Sterner, 2008 Jan 07
;
; Copyright (C) 2008, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro color_pick2_rgb, ev, text=text, sliders=sliders
 
	widget_control, ev.top, get_uval=s	; Get info.	
 
	if keyword_set(text) then begin
	  widget_control, s.id_r, get_val=r	; Read RGB text values.
	  widget_control, s.id_g, get_val=g
	  widget_control, s.id_b, get_val=b
	  widget_control, s.id_rs, set_val=r	; Update RGB slider values.
	  widget_control, s.id_gs, set_val=g
	  widget_control, s.id_bs, set_val=b
	endif
 
	if keyword_set(sliders) then begin
	  widget_control, s.id_rs, get_val=r	; Read RGB slider values.
	  widget_control, s.id_gs, get_val=g
	  widget_control, s.id_bs, get_val=b
	  rrt = string(r,form='(I3.3)')		; Update RGB text values.
	  ggt = string(g,form='(I3.3)')	
	  bbt = string(b,form='(I3.3)')
	  widget_control, s.id_r, set_val=rrt
	  widget_control, s.id_g, set_val=ggt
	  widget_control, s.id_b, set_val=bbt
	endif
 
	c = tarclr(r,g,b)			; 24 bit color value.
	cct = 'C24: '+strtrim(c,2)		; Color text.
	widget_control, s.id_c24, set_val=cct	; Update 24-bit color.
	c2hsv,c,hh,ss,vv			; Convert to HSV.
	hht = string(hh,form='(I3.3)')		; HSV text.
	sst = string(ss,form='(F4.2)')
	vvt = string(vv,form='(F4.2)')
	widget_control, s.id_h, set_val=hht	; Update HSV text.
	widget_control, s.id_s, set_val=sst
	widget_control, s.id_v, set_val=vvt
	widget_control, s.id_hs, set_val=hh	; Update HSV sliders.
	widget_control, s.id_ss, set_val=ss
	widget_control, s.id_vs, set_val=vv
	wset, s.win_new				; Update color patch.
	erase, c
	s.new = c				; Update and save info.
	widget_control, ev.top, set_uval=s
 
	end
 
	;----------------------------------------------------------
	;  HSV: Deal with HSV text or sliders.
	;----------------------------------------------------------
	pro color_pick2_hsv, ev, text=text, sliders=sliders
 
	widget_control, ev.top, get_uval=s	; Get info.	
 
	if keyword_set(text) then begin
	  widget_control, s.id_h, get_val=hh	; Read HSV text values.
	  widget_control, s.id_s, get_val=ss
	  widget_control, s.id_v, get_val=vv
	  widget_control, s.id_hs, set_val=hh	; Update HSV slider values.
	  widget_control, s.id_ss, set_val=ss
	  widget_control, s.id_vs, set_val=vv
	endif
 
	if keyword_set(sliders) then begin
	  widget_control, s.id_hs, get_val=hh	; Read HSV slider values.
	  hh = round(hh)
	  widget_control, s.id_ss, get_val=ss
	  widget_control, s.id_vs, get_val=vv
	  hht = string(hh,form='(I3.3)')	; Update HSV text values.
	  sst = string(ss,form='(F4.2)')	
	  vvt = string(vv,form='(F4.2)')
	  widget_control, s.id_h, set_val=hht
	  widget_control, s.id_s, set_val=sst
	  widget_control, s.id_v, set_val=vvt
	endif
 
	c = tarclr(/hsv,hh,ss,vv)		; 24 bit color value.
	cct = 'C24: '+strtrim(c,2)		; Color text.
	widget_control, s.id_c24, set_val=cct	; Update 24-bit color.
	c2rgb,c,rr,gg,bb			; Convert to RGB.
	rrt = string(rr,form='(I3.3)')		; RGB text.
	ggt = string(gg,form='(i3.3)')
	bbt = string(bb,form='(i3.3)')
	widget_control, s.id_r, set_val=rrt	; Update RGB text.
	widget_control, s.id_g, set_val=ggt
	widget_control, s.id_b, set_val=bbt
	widget_control, s.id_rs, set_val=rr	; Update RGB sliders.
	widget_control, s.id_gs, set_val=gg
	widget_control, s.id_bs, set_val=bb
	wset, s.win_new				; Update color patch.
	erase, c
	s.new = c				; Update and save info.
	widget_control, ev.top, set_uval=s
 
	end
 
 
	;----------------------------------------------------------
	;  Event handler
	;----------------------------------------------------------
	pro color_pick2_event, ev
 
	widget_control, ev.id, get_uval=uval
 
        if uval eq 'OK' then begin
          widget_control, ev.top, get_uval=s
          widget_control, ev.top, /dest
          widget_control, s.res, set_uval=s.new
          return
        endif
 
	if uval eq 'CANCEL' then begin
	  widget_control, ev.top, /destroy
	  return
	endif
 
	;---  RGB  ---
	if uval eq 'R' then color_pick2_rgb, ev, /text
	if uval eq 'G' then color_pick2_rgb, ev, /text
	if uval eq 'B' then color_pick2_rgb, ev, /text
	if uval eq 'RS' then color_pick2_rgb, ev, /sliders
	if uval eq 'GS' then color_pick2_rgb, ev, /sliders
	if uval eq 'BS' then color_pick2_rgb, ev, /sliders
 
	;---  HSV  ---
	if uval eq 'H' then color_pick2_hsv, ev, /text
	if uval eq 'S' then color_pick2_hsv, ev, /text
	if uval eq 'V' then color_pick2_hsv, ev, /text
	if uval eq 'HS' then color_pick2_hsv, ev, /sliders
	if uval eq 'SS' then color_pick2_hsv, ev, /sliders
	if uval eq 'VS' then color_pick2_hsv, ev, /sliders
 
	end
 
 
	;----------------------------------------------------------
	;  color_pick2 = Main routine
	;----------------------------------------------------------
	pro color_pick2, new, old0, xoffset=xoff, yoffset=yoff, $
          group_leader=group, title=ttl, help=hlp
 
        if keyword_set(hlp) then begin
          print,' Color picker widget using RGB and HSV sliders.'
          print,' color_pick2, new, old'
          print,'   new = New color (-1 for Cancel). out'
          print,'   old = Original color.            in'
          print,' Keywords:'
          print,'   TITLE=tt  Title text.'
          print,'   XOFFSET=xoff, YOFFSET=yoff, position.'
          print,'   GROUP_LEADER=grp Group leader.'
	  print,' Note: See color_pick for a color wheel.'
          return
        endif
 
	;---  Defaults  ---
	nx = 220				; Color patch size.
	ny = 75
	if n_elements(old0) ne 0 then begin	; Initialize new color.
	  new = old0				; Set new = old if old given.
	endif else begin
	  new = 16777215			; Else default to white.
	endelse
	c2rgb, new, rr,gg,bb			; Break new color into RGB.
	rrt = string(rr,form='(I3.3)')		; RGB text.
	ggt = string(gg,form='(I3.3)')
	bbt = string(bb,form='(I3.3)')
	c2hsv, new, hh,ss,vv			; Break new color into HSV.
	hht = string(hh,form='(I3.3)')		; HSV text.
	sst = string(ss,form='(F4.2)')
	vvt = string(vv,form='(F4.2)')
	cct = strtrim(new,2)
 
	;---  Set up widget  ---
        top = widget_base(/col,xoff=xoff,yoff=yoff,group=group,title=' ')
        if n_elements(ttl) ne 0 then id=widget_label(top,val=ttl)
 
	;---  Color patch(s)  ---
	b = widget_base(top,/row)		; Will have 1 or 2 patches.
	if n_elements(old0) ne 0 then begin	; Old patch first if given.
	  b2 = widget_base(b,/col)
	  id_old = widget_draw(b2,xsize=nx,ysize=ny)
	  id = widget_label(b2,val='Original')
	endif
	b2 = widget_base(b,/col)		; New color patch.
	id_new = widget_draw(b2,xsize=nx,ysize=ny)
	id = widget_label(b2,val='New color')
 
	;---  RGB sliders  ---
	b = widget_base(top,/col,/frame)
 
	b2 = widget_base(b,/row)	; Red text and slider.
	id = widget_label(b2,val='R')
	id_r = widget_text(b2,val=rrt,xsize=4,/edit,uval='R')
	id_rs = cw_dslider(b2,size=370,val=rr,min=0.,max=255., $
	  color=tarclr(/hsv,0,.5,1),uval='RS')
 
	b2 = widget_base(b,/row)	; Green text and slider.
	id = widget_label(b2,val='G')
	id_g = widget_text(b2,val=ggt,xsize=4,/edit,uval='G')
	id_gs = cw_dslider(b2,size=370,val=gg,min=0.,max=255., $
	  color=tarclr(/hsv,120,.5,1),uval='GS')
 
	b2 = widget_base(b,/row)	; Blue text and slider.
	id = widget_label(b2,val='B')
	id_b = widget_text(b2,val=bbt,xsize=4,/edit,uval='B')
	id_bs = cw_dslider(b2,size=370,val=bb,min=0.,max=255., $
	  color=tarclr(/hsv,240,.5,1),uval='BS')
 
	;---  HSV sliders  ---
	b = widget_base(top,/col,/frame)
 
	b2 = widget_base(b,/row)	; Hue text and slider.
	id = widget_label(b2,val='H')
	id_h = widget_text(b2,val=hht,xsize=4,/edit,uval='H')
	id_hs = cw_dslider(b2,size=370,val=hh,min=0.,max=360., $
	  color=tarclr(/hsv,60,.1,1),uval='HS')
 
	b2 = widget_base(b,/row)	; Saturation text and slider.
	id = widget_label(b2,val='S')
	id_s = widget_text(b2,val=sst,xsize=4,/edit,uval='S')
	id_ss = cw_dslider(b2,size=370,val=ss,min=0.,max=1.0, $
	  color=tarclr(/hsv,180,.1,1),uval='SS')
 
	b2 = widget_base(b,/row)	; Value text and slider.
	id = widget_label(b2,val='V')
	id_v = widget_text(b2,val=vvt,xsize=4,/edit,uval='V')
	id_vs = cw_dslider(b2,size=370,val=vv,min=0.,max=1.0, $
	  color=tarclr(/hsv,300,.1,1),uval='VS')
 
	;---  C24 display  ---
	id_c24 = widget_label(top,val='C24: '+cct, $
	  /align_left, /dynamic)
 
	;---  Buttons  ---
	b = widget_base(top,/row)
	id = widget_button(b,val='OK',uval='OK')
	id = widget_button(b,val='Cancel',uval='CANCEL')
 
        ;---  Return value  ---
        res = widget_base()		; Unused base for return color.
        widget_control, res, set_uval=-1
 
	;---  Activate widget  ---
	widget_control, top, /real
 
	;---  Do the color patches  ---
	widget_control, id_new, get_val=win_new		; New color window.
	wset, win_new					; Set as current.
	erase, new					; Fill with new color.
	if n_elements(old0) ne 0 then begin
	  widget_control, id_old, get_val=win_old	; Old color window.
	  wset, win_old					; Set as current.
	  erase, old0					; Fill with old color.
	endif else win_old=0
 
	;---  Pack up info  ---
	s = {new:new, win_new:win_new, $
	  id_new:id_new, id_r:id_r, id_g:id_g, id_b:id_b, $
	  id_rs:id_rs, id_gs:id_gs, id_bs:id_bs, $
	  id_h:id_h, id_s:id_s, id_v:id_v, $
	  id_hs:id_hs, id_ss:id_ss, id_vs:id_vs, $
	  id_c24:id_c24, res:res }
 
	widget_control, top, set_uval=s			; Save info structure.
 
	;---  Manage widget  ---
	xmanager, 'color_pick2', top, /modal
 
	;---  Get returned new color value  ---
	widget_control, res, get_uval=new
 
	end
