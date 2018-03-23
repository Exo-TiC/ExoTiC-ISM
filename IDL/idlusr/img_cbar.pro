;-----  img_cbar.pro = Plot an antialiased color bar on an image  ---
;	R. Sterner, 2007 Sep 20

	pro img_cbar, img, vmin=vmn, vmax=vmx, cmin=cmn, cmax=cmx, $
	  horizontal=hor, vertical=ver, help=hlp, $
	  top=top, bottom=bottom, left=left, right=right, $
	  position=pos, device=device, color=col, cclip=cclip, $
	  title=ttl, charsize=csz, charthick=cthk, _extra=extra

	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Plot an antialiased color bar on an image.'
	  print,' img_cbar, img'
	  print,'   img = Image to plot color bar on.'
	  print,' Keywords:'
	  print,'   See cbar, /help , most of those keywords work.'
	  print,'   COLOR=clr Axes color.  Use 24-bit color even'
	  print,'     when working in 8-bit mode.  Can get 24-bit'
	  print,'     colors using clr=tarclr(/c24,r,g,b).'
	  print,' Notes: This routine uses the display so is not'
	  print,'   independent of X windows.'
	  return
	endif

	;---  Deal with a few non-optional items  ---
	if n_elements(csz) eq 0 then csz=1.
	if n_elements(cthk) eq 0 then cthk=1.

	;---  Use antialias image object to do axes  ---
	a = obj_new('img_aa',img)	; img = Current frame image.
	a->procedure,'cbar2', $         ; Bar antialiased axes.
	  vmin=vmn, vmax=vmx, cmin=cmn, cmax=cmx, $
	  horizontal=hor, vertical=ver, $
	  top=top, bottom=bottom, left=left, right=right, $
	  position=pos, device=device, color=col, cclip=cclip, $
	  title=ttl, charsize=csz*3, charthick=cthk*3, _extra=extra, $
	  /axes_only,/keep
	a->get, img=img2, tr=3
	tv,tr=3,img2
	obj_destroy, a				; Done with object.

	;---  Add bar  ---
	cbar2,last_image=z2, last_pos=pos2, $   ; Grab last values
	  last_xs=xs2,last_ys=ys2,last_ps=ps2
	imgunder,z2				; Put it in bar.

	;---  Outline bar  ----
	device,get_decomp=decomp
	device,decomp=1
	plot_posbox, pos2,col=col,thick=cthk	; Bar outline.
	device,decomp=decomp
	!x=xs2 & !y=ys2 & !p=ps2		; Restore image scaling.

	end
