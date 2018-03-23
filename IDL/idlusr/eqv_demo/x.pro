;------------  x.pro = example parametric equation  --------
;	R. Sterner, 5 Nov, 1993

	pro x

	loadct,4
	clr = maken(200,50,1500)
	clr(1438:*)=180
	clr(1499) = 255
	t = maken(0.,500.,1500)
	b = makex(0.,2.,.001)
	x1 = -10.  &  x2 = 10.
	y1 = -10.  &  y2 = 10.

	window,xs=700,ys=700
	plot,[x1,x2],[y1,y2],/nodata,xstyle=5,ystyle=5
	xlst = [0]  &  ylst = [0]

	timer, /start
	for i=0,n_elements(b)-1 do begin
	  plots,xlst,ylst,color=0
	  x = .3*t  &  y = .5*sin(b(i)*t) + .05*x
;	  x = .3*t  &  y = .175*sin(b(i)*t) + .05*x
	  xlst = y*cos(x)  &  ylst = y*sin(x)
	  plots,xlst,ylst,color=clr
	endfor
	timer, /stop, /print

	return
	end
