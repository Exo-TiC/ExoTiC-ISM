;-----  globe_plot.pro = globe plot routine  -------
;	Only plot if changed.
;	R. Sterner, 1998 Apr 22

	pro globe_plot, lat, lng

	common globe_plot_com, lng0, lat0

	if n_elements(lng0) eq 0 then begin
	  lng0 = 0.
	  lat0 = 0.
	endif

	if (lng eq lng0) and (lat eq lat0) then return

	map_set,/cont,/iso,/hor,/ortho,lat,lng

	lng0 = lng
	lat0 = lat

	return
	end
