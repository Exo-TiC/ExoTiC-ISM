;-------  ximg.pro = Image explore routine  -----------
;	R. Sterner, 2000 May 26
 
	pro ximg, img, a1=a1, t1=t1, a2=a2, t2=t2, a3=a3, t3=t3, $
	  a4=a4, t4=t4, a5=a5, t5=t5, lat=lat, lon=lon, units=units, help=hlp
 
	if keyword_set(hlp) then begin
	  print,' Image explore utility.'
	  print,' ximg, img'
	  print,'   img = image to display (scaled for tv command).'
	  print,' Keywords:'
	  print,'   LAT=lat, LON=lon  Latitude and Longitude arrays.'
	  print,'   UNITS=un  Units for distance from marked point.'
	  print,"     Do x=earthrad(/help) for units (def='km')"
	  print,'   A1=a1, T1=t1  Data array/label text pairs.'
	  print,'     a1 is same size and shape as img and contains'
	  print,'     values to be displayed.  t1 is the ;abel for the'
	  print,'     value.  Up to 5 such pairs are allowed: A2=a2,T2=t2,...'
	  return
	endif

	;-------  Display image if given  ------------
	if n_elements(img) ne 0 then begin
	  sz=size(img) & nx=sz(1) & ny=sz(2)
	  if (nx gt 1000) or (ny gt 900) then begin
	    swindow,xs=nx,ys=ny,x_scr=(nx<1000),y_scr=(ny<900)
	  endif else begin
	    window,xs=nx,ys=ny
	  endelse
	  tv,img
	endif
 
	;-------  Set cursor initial position  ----------
	x=!d.x_size/2 & y=!d.y_size/2
        tvcrs, x, y                         ; Place cursor.
 
	;-------  Set up display widget  ----------
	top = widget_base(/column,title=' ')
	id = widget_label(top,val='Image coordinates')
	id = widget_label(top,val='    Press any button to exit    ')
	idxy = widget_label(top,val=' ',/dynamic_resize)
	if n_elements(lon) ne 0 then begin
          lonflag = 1
          b = widget_base(top,/row)
          id = widget_label(b,val='Long:')
          idlon = widget_label(b,val=' ',/dynamic_resize)
        endif else lonflag=0
	if n_elements(lat) ne 0 then begin
          latflag = 1
          b = widget_base(top,/row)
          id = widget_label(b,val='Lat:')
          idlat = widget_label(b,val=' ',/dynamic_resize)
        endif else latflag=0
	if (lonflag and latflag) then begin
          dstflag = 1
          b = widget_base(top,/row)
	  if n_elements(units) eq 0 then units='km'
          id = widget_label(b,val='distance ('+units+'):')
          iddst = widget_label(b,val=' ',/dynamic_resize)
	  mflag = 0		; Mark flag starts 0.
	endif else dstflag=0
	if n_elements(a1) ne 0 then begin
	  a1flag = 1
	  b = widget_base(top,/row)
	  if n_elements(t1) eq 0 then t1=' A1 = '
	  id = widget_label(b,val=t1)
	  ida1 = widget_label(b,val=' ',/dynamic_resize)
	endif else a1flag=0
	if n_elements(a2) ne 0 then begin
	  a2flag = 1
	  b = widget_base(top,/row)
	  if n_elements(t2) eq 0 then t2=' A2 = '
	  id = widget_label(b,val=t2)
	  ida2 = widget_label(b,val=' ',/dynamic_resize)
	endif else a2flag=0
	if n_elements(a3) ne 0 then begin
	  a3flag = 1
	  b = widget_base(top,/row)
	  if n_elements(t3) eq 0 then t3=' A3 = '
	  id = widget_label(b,val=t3)
	  ida3 = widget_label(b,val=' ',/dynamic_resize)
	endif else a3flag=0
	if n_elements(a4) ne 0 then begin
	  a4flag = 1
	  b = widget_base(top,/row)
	  if n_elements(t4) eq 0 then t4=' A4 = '
	  id = widget_label(b,val=t4)
	  ida4 = widget_label(b,val=' ',/dynamic_resize)
	endif else a4flag=0
	if n_elements(a5) ne 0 then begin
	  a5flag = 1
	  b = widget_base(top,/row)
	  if n_elements(t5) eq 0 then t5=' A5 = '
	  id = widget_label(b,val=t5)
	  ida5 = widget_label(b,val=' ',/dynamic_resize)
	endif else a5flag=0

	widget_control, top, /real
	widget_control, idxy, set_val=strtrim(string(x,y),2)
 
	;---------  Cursor loop  ------------
loop:
	test = 0
	while test eq 0 do begin
	  cursor, x, y, /dev, /change
	  test = !err
	  empty
	  widget_control, idxy, set_val=strtrim(string(x,y),2)
	  if lonflag then widget_control,idlon,set_val=strtrim(lon(x,y),2)
	  if latflag then widget_control,idlat,set_val=strtrim(lat(x,y),2)
	  if mflag then begin
	    lat1=lat(x,y) & lon1=lon(x,y)
	    d = sphdist(lon0,lat0,lon1,lat1,/deg)/!radeg*earthrad(units)
	    widget_control, iddst, set_val=strtrim(d,2)
	  endif
	  if a1flag then widget_control,ida1,set_val=strtrim(a1(x,y),2)
	  if a2flag then widget_control,ida2,set_val=strtrim(a2(x,y),2)
	  if a3flag then widget_control,ida3,set_val=strtrim(a3(x,y),2)
	  if a4flag then widget_control,ida4,set_val=strtrim(a4(x,y),2)
	  if a5flag then widget_control,ida5,set_val=strtrim(a5(x,y),2)
	endwhile

	opt = xoption(['Quit','Continue','Mark point'])
	if opt eq 2 then begin
	  if mflag then tv,mark,x0,y0,true=3
	  x0=x-10 & y0=y-10
	  mark = tvrd(x0,y0,20,20,true=3)	; Save image patch.
	  plots,/dev,x,y,psym=6,col=tarclr(255,0,255)
	  if n_elements(lat) ne 0 then lat0=lat(x,y)
	  if n_elements(lon) ne 0 then lon0=lon(x,y)
	  mflag = 1
          tvcrs, x, y                         ; Place cursor.
	  goto, loop
	endif
	if opt eq 1 then begin
          tvcrs, x, y                         ; Place cursor.
	  goto, loop
	endif
 
	widget_control, top, /dest
	if n_elements(img) ne 0 then swdelete
 
	return
	end
