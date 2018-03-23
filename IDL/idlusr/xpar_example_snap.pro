;-------  xpar_example.pro = Test xpar user routine  -------
;	R. Sterner, 2006 Nov 02

;--------------------------------------------------------------------------
;  Example user routine for xpar.  Is sent the info structure that
;  contains the parameter values so must have info=s as the one and
;  only keyword.  No need to use it for anything.
;
;  This example shows how to access the current parameter values.
;  It saves the current window, overwriting the result each time.
;  It could be easily modifed to use a time-tagged image name.
;--------------------------------------------------------------------------

	pro xpar_example_snap, info=s

	nam = strlowcase(s.par_nam)		; Grab parameter names
	cur = s.par_cur				; and current values.
	lon = (cur(where(nam eq 'lon')))[0]	; Extract some selected
	lat = (cur(where(nam eq 'lat')))[0]	; items.
	ang = (cur(where(nam eq 'ang')))[0]
	lonc = (cur(where(nam eq 'lonc')))[0]
	latc = (cur(where(nam eq 'latc')))[0]
	radc = (cur(where(nam eq 'radc')))[0]

	xyouts,/dev,10,100,'Map info:',chars=1.5  ; Display values on image.
	xyouts,/dev,10,80,'Lon: '+string(lon,form='(F6.1)'),chars=1.2
	xyouts,/dev,10,60,'Lat: '+string(lat,form='(F5.1)'),chars=1.2
	xyouts,/dev,10,40,'Lat: '+string(ang,form='(F5.1)'),chars=1.2

	xyouts,/dev,540,100,'Circle info:',chars=1.5
	xyouts,/dev,540,80,'Lon: '+string(lonc,form='(F6.1)'),chars=1.2
	xyouts,/dev,540,60,'Lat: '+string(latc,form='(F5.1)'),chars=1.2
	xyouts,/dev,540,40,'Rad: '+string(radc,form='(F5.1)'),chars=1.2

	pngscreen,'snap.png'			; Save image.

	end
