;---  test_ell_3pt_circle.pro = Test circle fit  ---
;  R. Sterner, 2007 Sep 17

	pro test_ell_3pt_circle, p1, p2, p3

	txt = ''
loop:
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
	wait,.2
	print,' Pt 3'
	xcursor,x,y
	if !mouse.button ne 1 then return
	help,x,y
	p3={lon:x,lat:y}
	ell_plot_pt, p3
	ell_plot_pt,p2,p3
	ell_plot_pt,p3,p1
	ell_3pt_circle, p1, p2, p3, pc, rad=r ,/debug
	help,pc,/st
	plots,pc.lon,pc.lat,psym=2
	ell_rb2ll, pc.lon,pc.lat,r,maken(0,360,300),xx,yy,a1
	plots,xx,yy
	print,' Press RETURN'
	read,txt
	if strupcase(txt) eq 'Q' then return
	goto, loop
 
	end
