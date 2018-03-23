;------------------------------------------------------------------
;  test_2_pt_dist_1.pro = Check how equal a bisector stays
;  R. Sterner, 2007 Sep 20
;
;  For 2 points on an ellipsoid, check the points along the
;  perpendicular bisector to see how equidistant they are
;  from the segment endpoints.
;------------------------------------------------------------------

	pro test_2_pt_dist_1

	txt = ''
	window,1,xs=800,ys=800
	window,2,xs=600,ys=400
loop:
	wset,1
	map_set,/ortho,/iso,/hor,/cont,40,-77,/grid
	wshow
	print,' Pt 1'
	xcursor,x,y
	if !mouse.button ne 1 then return
	help,x,y
	p1={lon:x,lat:y}
	ell_plot_pt, p1
	wait,.2
	print,' Pt 2'
	xcursor,x,y
	if !mouse.button ne 1 then return
	help,x,y
	p2={lon:x,lat:y}
	ell_plot_pt, p2
	ell_plot_pt,p1,p2

	m12 = ell_geo_mid(p1, p2, azi2=a12)	; Midpoint of p1, p2.
	rng = makex(0.,500E4,1000)
	ell_rb2ll, m12.lon,m12.lat,rng,a12-90,xx,yy
	plots,xx,yy
	n = n_elements(xx)
	diff = fltarr(n)
	for i=0,n-1 do begin
	  pt = {lon:xx[i],lat:yy[i]}
	  d1 = ell_point_sep(pt,p1)
	  d2 = ell_point_sep(pt,p2)
	  diff[i] = abs(d1-d2)
	endfor
	wset,2
	plot,rng/1000.,diff,titl='Difference in m', $
	  xtitl='Range (km)',ytitl='Diff (m)'

	print,' Press RETURN'
	read,txt
	if strupcase(txt) eq 'Q' then return
	goto, loop
 
	end
