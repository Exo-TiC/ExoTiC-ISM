;------------------------------------------------------------------
;  test_2_pt_dist_2.pro = Check midazimuths.
;  R. Sterner, 2007 Sep 20
;
;  For 2 points on an ellipsoid, find an equadistant pt.
;  Then find the midazimuth and how equadistant points
;  long it are.
;------------------------------------------------------------------

	pro test_2_pt_dist_2

	p3rng = 5000E3
	rrng = maken(-10.,10,100)	; Relative range.

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

	m12 = ell_geo_mid(p1, p2, azi2=a12)	; Midpoint of p1, p2 = m12.
	ell_rb2ll, m12.lon,m12.lat,p3rng,a12-90,p3lon,p3lat
	p3 = {lon:p3lon,lat:p3lat}
	ell_plot_pt, p3
	ell_ll2rb,p3lon,p3lat,m12.lon,m12.lat,r,a1
	ell_dist_match, p1, p2, p3, a1+90, pm, azi=aa	; Dist match pt=pm.
	ell_ll2rb,pm.lon,pm.lat,m12.lon,m12.lat,rng0,azi
	azi_eq = mean(fixang(aa)) mod 360		; Mid azimuth.
  d1 = ell_point_sep(pm,p1)
  d2 = ell_point_sep(pm,p2)
help,d1,d2,azi_eq
more,aa
  d12 = 1000*abs(d1-d2)
  print,' Start point dist match error (mm): ',d12
	rng02 = ell_point_sep(pm,m12)			; Range: pm,m12.
	help,rng0,rng02,rng0-rng02

	rng = rng0 + rrng				; Range to check.
	ell_rb2ll,pm.lon,pm.lat,rng,azi,xx,yy		; Points to check.

	
	n = n_elements(xx)
	diff = fltarr(n)
	for i=0,n-1 do begin
	  pt = {lon:xx[i],lat:yy[i]}
	  d1 = ell_point_sep(pt,p1)
	  d2 = ell_point_sep(pt,p2)
	  diff[i] = 1000*abs(d1-d2)
	endfor
	wset,2
	plot,rrng,diff,titl='Difference in m', $
	  xtitl='Relative Range (m)',ytitl='Diff (mm)'
hlp,diff


	print,' Press RETURN'
	read,txt
	if strupcase(txt) eq 'Q' then return
	goto, loop
 
	end
