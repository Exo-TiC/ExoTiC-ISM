;-----  ell_geo_plot.pro = Plot a labeled geodesic on current map.  ----
;	R. Sterner, 2008 Feb 04

	pro ell_geo_plot, p1, p2, color=clr, thickness=thk, linestyle=sty, $
	  lab1=lab1, lab2=lab2, nticks=ntk, tickpix=tkpx, offset=offst, $
	  charsize=csz, bold=bld, units=units, error=err, help=hlp

	if (n_params(0) lt 2) or keyword_set(hlp) then begin
	  print,' Plot a labeled geodesic on current map.'
	  print,' ell_geo_plot, p1, p2'
          print,'   p1 = Start point of the geodesic {lon:lon, lat:lat}. in'
          print,'   p2 = End point of the geodesic {lon:lon, lat:lat}.   in'
	  print,' Keywords:'
	  print,' COLOR=clr Plot color (def=!p.color).'
	  print,' THICKNESS=thk Plot thickness (def=1).'
	  print,' LINESTYLE=sty Plot thickness linestyle (def=0).'
	  print," LAB1=lab1 Start point label (def='A')."
	  print," LAB2=lab2 End point label (def='B')."
	  print,' NTICKS=ntk Approximate number of labeled ticks (def=5).'
	  print,' TICKPIX=tkpx Length of tick in pixels at map center (def=10).'
	  print,' OFFSET=offst Offset of ticks (0.0-1.0, def=0.5).'
	  print,' CHARSIZE=csz Character size (def=1).'
	  print,' BOLD=bld Text bold value (def=1).'
	  print,' UNITS=units Distance units (def=m).  Known units:'
	  print,'   nmiles=Nautical miles, miles=Statute miles, kms=Kilometers,'
	  print,'   meters (or m)=Meters, yards=Yards, feet (or foot)=Feet.'
	  print,' ERROR=err  Error flag: 0=ok.'
	  return
	endif

	;---------------------------------------------------------------
	;  Set defaults
	;---------------------------------------------------------------
	err = 0
	if n_elements(clr) eq 0 then clr=!p.color
	if n_elements(thk) eq 0 then thk=1
	if n_elements(sty) eq 0 then sty=0
	if n_elements(lab1) eq 0 then lab1='A'
	if n_elements(lab2) eq 0 then lab2='B'
	if n_elements(ntk) eq 0 then ntk=5
	if n_elements(tkpx) eq 0 then tkpx=10
	if n_elements(offst) eq 0 then offst=0.5
	if n_elements(csz) eq 0 then csz=1.
	if n_elements(bld) eq 0 then bld=1
	if n_elements(units) eq 0 then units='m'

	;---------------------------------------------------------------
	;  Get points along the geodesic
	;---------------------------------------------------------------
	ell_geo_pts,p1,p2,lon,lat		; Points along geodesic.
	npts = n_elements(lon)			; # points.
	lon1 = p1.lon
	lat1 = p1.lat
	lon2 = p2.lon
	lat2 = p2.lat
	ell_geo_pt_sep,[lon1,lon2],[lat1,lat2],d  ; Length in m.
	dmaxm = d[0]				; Length of geodesic (m).
	dmax = from_meters(dmaxm,units=units)	; Length in units.
	ell_ll2rb,lon1,lat1,lon2,lat2,r,azi	; Get azi from p1 to p2.

	;---------------------------------------------------------------
	;  Get ticklength in meters
	;---------------------------------------------------------------
	map_set_scale,out=sc,err=err		; Get map scaling info.
	if err ne 0 then begin
	  print,' Error in ell_geo_plot: No map scaling in current window.'
	  return
	endif
	t = convert_coord(sc.lon_cen,sc.lat_cen,/data,/to_dev)
	ix = round(t[0])	; Pixel coordinates at map center.
	iy = round(t[1])
	t = convert_coord(ix,iy+tkpx,/dev,/to_data)
	lonx = t[0]		; Lon, lat tkpx pixels above map center.
	latx = t[1]
	ell_geo_pt_sep, [sc.lon_cen,lonx],[sc.lat_cen,latx],d
	tkm = d[0]		; Tick length in meters.
	tkm1 = tkm*(1-offst)
	tkm2 = tkm*offst
	
	;---------------------------------------------------------------
	;  Get labeled tick positions
	;---------------------------------------------------------------
	naxes,0,dmaxm,5,tx1,tx2,nt,xinc,ndec	; Find axes numbers.
	dtkm = makex(tx1,tx2,xinc)		; Labeled tick distances (m).
	naxes,0,dmax,5,tx1,tx2,nt,xinc,ndec	; Find axes numbers.
	dtk = makex(tx1,tx2,xinc)		; Labeled tick distances.
	if ndec eq 0 then fmt='(I)' else fmt='(F20.'+strtrim(ndec,2)+')'
	tklab = strtrim(string(dtk,form=fmt),2)	; Formatted labels.

	;---------------------------------------------------------------
	;  Plot geodesic
	;---------------------------------------------------------------
	plots,lon,lat,color=clr,thick=thk,linestyle=sty

	;---------------------------------------------------------------
	;  Label ends
	;---------------------------------------------------------------
	t = convert_coord(lon[0],lat[0],/data,/to_dev)	; Start.
	ix0=t[0] & iy0=t[1]
	t = convert_coord(lon[1],lat[1],/data,/to_dev)	; Next pt.
	ix1=t[0] & iy1=t[1]
	recpol,(ix1-ix0),(iy1-iy0),r,ang,/deg	; Angle to next point.
	flag = 0				; Normal orientation.
	if ((ang gt 90) and (ang lt 270)) then flag=1 ; Invert.
	loff = -(strlen(lab1)+1)/2.
help,ang
	if flag eq 1 then begin
	  ang = ang+180
	  loff = -loff
	endif
	textplot,ix0,iy0,/dev,orient=ang,lab1,chars=csz, $
	  offset=loff, $
	  align=[.5,.5],color=clr,bold=bld
	
	t = convert_coord(lon[npts-2],lat[npts-2],/data,/to_dev) ; Last pt.
	ix0=t[0] & iy0=t[1]
	t = convert_coord(lon[npts-1],lat[npts-1],/data,/to_dev) ; End.
	ix1=t[0] & iy1=t[1]
	recpol,(ix1-ix0),(iy1-iy0),r,ang,/deg	; Angle to next point.
	loff = (strlen(lab2)+1)/2.
help,ang
	if flag eq 1 then begin
	  ang = ang+180
	  loff = -loff
	endif
	textplot,ix0,iy0,/dev,orient=ang,lab2,chars=csz, $
	  offset=loff, $
	  align=[.5,.5],color=clr,bold=bld

	;---------------------------------------------------------------
	;  Plot ticks
	;---------------------------------------------------------------
	for i=0, n_elements(dtk)-1 do begin
	  ;---  Find tick ends and plot  ---
	  d = dtkm[i]			; Tick dist from 0.
	  ell_rb2ll, lon1,lat1,d,azi,lont,latt,azi2 ; Tick middle.
	  if tkm1 ne 0 then begin	; Tick + side.
	    ell_rb2ll, lont,latt,tkm1,azi2+90,lontp,lattp
	  endif else begin
	    lontp = lont		; + side = middle.
	    lattp = latt
	  endelse
	  if tkm2 ne 0 then begin	; Tick - side.
	    ell_rb2ll, lont,latt,tkm2,azi2-90,lontm,lattm
	  endif else begin
	    lontm = lont		; - side = middle.
	    lattm = latt
	  endelse
	  ell_geo_pts,lontm,lattm,lontp,lattp,lontg,lattg,azi=aa
	  plots,lontg,lattg,color=clr,thick=thk,linestyle=sty
print,aa
	  ;---  Add tick label  ---
	  ell_rb2ll, lontp,lattp,1000,aa[0]+90,lontp2,lattp2
	  t = convert_coord(lontp,lattp,/data,/to_dev)
	  ix0=t[0] & iy0=t[1]
	  t = convert_coord(lontp2,lattp2,/data,/to_dev)
	  ix1=t[0] & iy1=t[1]
	  recpol,(ix1-ix0),(iy1-iy0),r,ang,/deg	; Angle to next point.
	  alny = -1.0
	  if flag eq 1 then begin
	    ang = ang+180
	    alny = 1.5
	  endif
	  textplot,ix0,iy0,/dev,orient=ang,tklab[i],chars=csz, $
	    align=[.5,alny],color=clr,bold=bld

	endfor


stop

	end
