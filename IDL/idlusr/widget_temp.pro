;--------  widget_temp.pro = Widget template  ------------
;	R. Sterner, 1994 Oct 14

;==========================================================
;	xxx_event = xxx event handler.
;==========================================================

	pro xxx_event, ev

	widget_control, ev.id, get_uval=uval
	widget_control, ev.top, get_uval=m

	if uval eq 'QUIT' then begin
	  widget_control, m.id_s, get_val=v
	  widget_control, m.res, set_uval=v
	  widget_control, ev.top, /dest
	  return
	endif

	return
	end

;===========================================================
;	xxx.pro = Widget based routine template.
;	R. Sterner, 1994 Oct 14.
;===========================================================

	pro xxx, in, out, help=hlp

	if keyword_set(hlp) then begin
	  print,' Widget based routine template.'
	  print,' xxx, in, out'
	  print,'   in = initial slider setting (%).      in'
	  print,'   out = returned final slider setting.  out'
	  return
	endif

	;----------  Defaults  ---------------------
	if n_elements(in) eq 0 then in = 50

	;----------  Widget layout  ----------------
	top = widget_base(/column, title=' ')
	b = widget_base(top, /row)		; Avoid wide buttons.
	id = widget_button(b, value='Quit', uval='QUIT')
	id_s = widget_slider(top, title='Slider', xsize=400, val=in, $
	  uval='SLIDE')

	;-------  Return path  --------
	res = widget_base()		; Unused base.

	;------  Realize widget  -------
	widget_control, top, /real

	;-------  Pass needed info  ----------
	map = {id_s:id_s, res:res}
	widget_control, top, set_uval=map

	;--------  Register  ------------------
	xmanager, 'xxx', top

	;--------  Retrieve returned info  --------
	widget_control, res, get_uval=out

	return
	end

	
