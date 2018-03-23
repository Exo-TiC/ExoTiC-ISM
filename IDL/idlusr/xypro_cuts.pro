;-----------------------------------------------------------------------------
;  xypro_cuts.pro = xypro routine to be called by crossi to plot array cuts.
;  R. Sterner, 2006 Jun 28
;       R. Sterner, 2010 Jun 04 --- Converted arrays from () to [].
;       R. Sterner, 2013 Mar 19 --- Added Y plot.
;-----------------------------------------------------------------------------

	pro xypro_cuts, x, y, init=arr0

	common xypro_cuts_com, arr, winx, winy, xax, yax

	win0 = !d.window

	if n_elements(arr0) ne 0 then begin
	  arr = arr0
	  xax = findgen(dimsz(arr,1))
	  yax = findgen(dimsz(arr,2))
	  window,xs=400,ys=200,/free
	  winx = !d.window
	  window,xs=200,ys=400,/free
	  winy = !d.window
	  wset, win0
	  return
	endif

	wset, winx
	plot,xax,arr[*,y],title='Y = '+strtrim(fix(y),2),psym=-4
	ver,x
	wset, winy
	plot,arr[x,*],yax,title='X = '+strtrim(fix(x),2),psym=-4
	hor,y
	wset, win0

	end
