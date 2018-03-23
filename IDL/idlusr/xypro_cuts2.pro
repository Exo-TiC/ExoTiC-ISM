;-----------------------------------------------------------------------------
;  xypro_cuts2.pro = xypro routine to be called by crossi to plot array cuts.
;  R. Sterner, 2013 Mar 19 from xypro_cuts.pro
;-----------------------------------------------------------------------------

	pro xypro_cuts2, xx, yy, init=s

	common xypro_cuts_com, arr, winx, winy, x, y

	win0 = !d.window

	if n_elements(arr0) ne 0 then begin
	  arr = s.z
	  xax = s.x
	  yax = s.y
	  window,xs=400,ys=200,/free
	  winx = !d.window
	  window,xs=200,ys=400,/free
	  winy = !d.window
	  wset, win0
	  return
	endif

	wset, winx
	plot,xax,arr[*,yy],title='Y = '+strtrim(fix(yy),2),psym=-4
	ver,x
	wset, winy
	plot,arr[xx,*],yax,title='X = '+strtrim(fix(xx),2),psym=-4
	hor,y
	wset, win0

	end
