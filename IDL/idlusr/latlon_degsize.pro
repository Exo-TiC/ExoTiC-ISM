;---  latlon_degsize.pro = Size of a degree or fraction.  ------
;	R. Sterner, 2006 Apr 20

	pro latlon_degsize, lat0, help=hlp

	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Size of a degree or fraction of lon or lat at given latitude.'
	  print,' latlon_degsize, lat'
	  print,'   lat = Latitude of calculation.   in'
	  return
	endif

	lat = lat0 + 0D0

	t = ['1.', '0.1', '0.01', '0.001', '0.0001', '0.00001', '0.000001']
	val = [spc(8), t + spc(8,t)]

	deg = t
	min = '0 ' + t[0:4]
	sec = '0 0 ' + t[0:3]

	ndeg = n_elements(deg)
	nmin = n_elements(min)
	nsec = n_elements(sec)

	units = ['nmile','mile','km','m','feet']
	cfact = [1/1852.,1./1609.344,0.001,1.,3.2808399]

	lon_deg = strarr(5+1,ndeg+1)
	lat_deg = lon_deg
	lon_min = strarr(5+1,nmin+1)
	lat_min = lon_min
	lon_sec = strarr(2+1,nsec+1)
	lat_sec = lon_sec


	;------  Deg tables  -------
	ell_ll2rb,0D0, lat, dms2d(deg), lat, rlon, a1, a2
	print,' '
	print,'               Degree of longitude at latitude '+strtrim(lat,2)
	lon_deg(1,0) = '        ' + units + spc(8,units)
	lon_deg(1,1) = string(cfact#rlon)
	lon_deg(0,0) = transpose(val)
	print,' '+lon_deg

	ell_ll2rb,0D0, lat, 0D0, lat+dms2d(deg), rlat, a1, a2
	lat_deg(1,0) = '        ' + units + spc(8,units)
	lat_deg(1,1) = string(cfact#rlat)
	lat_deg(0,0) = transpose(val)
	print,' '
	print,'               Degree of latitude at latitude '+strtrim(lat,2)
	print,' '+lat_deg

	;-------  Min tables  -------
	ell_ll2rb,0D0, lat, dms2d(min), lat, rlon, a1, a2
	print,' '
	print,'               Minutes of longitude at latitude '+strtrim(lat,2)
	lon_min(1,0) = '        ' + units + spc(8,units)
	lon_min(1,1) = string(cfact#rlon)
	lon_min(0,0) = transpose(val[0:5])
	print,' '+lon_min

	ell_ll2rb,0D0, lat, 0D0, lat+dms2d(min), rlat, a1, a2
	lat_min(1,0) = '        ' + units + spc(8,units)
	lat_min(1,1) = string(cfact#rlat)
	lat_min(0,0) = transpose(val[0:5])
	print,' '
	print,'               Minutes of latitude at latitude '+strtrim(lat,2)
	print,' '+lat_min

	;-------  Sec tables  -------
	ell_ll2rb,0D0, lat, dms2d(sec), lat, rlon, a1, a2
	print,' '
	print,'               Seconds of longitude at latitude '+strtrim(lat,2)
	lon_sec(1,0) = '        ' + units[3:4] + spc(8,units[3:4])
	lon_sec(1,1) = string((cfact#rlon)(3:4,0:3))
	lon_sec(0,0) = transpose(val[0:4])
	print,' '+lon_sec

	ell_ll2rb,0D0, lat, 0D0, lat+dms2d(sec), rlat, a1, a2
	lat_sec(1,0) = '        ' + units[3:4] + spc(8,units[3:4])
	lat_sec(1,1) = string((cfact#rlat)(3:4,0:3))
	lat_sec(0,0) = transpose(val[0:4])
	print,' '
	print,'               Seconds of latitude at latitude '+strtrim(lat,2)
	print,' '+lat_sec
	print,' '

	end
