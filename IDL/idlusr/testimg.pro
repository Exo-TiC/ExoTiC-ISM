;-------  testimg.pro = Test interactive plotting on image.
;	R. Sterner, 2000 May 26
;       R. Sterner, 2010 Jun 04 --- Converted arrays from () to [].
 
	pro testimg, img
 
	;-------  Display image if given  ------------
	if n_elements(img) ne 0 then begin
	  sz=size(img) & nx=sz[1] & ny=sz[2]
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

	widget_control, top, /real
	widget_control, idxy, set_val=strtrim(string(x,y),2)

	mflag = 0
	dx=50 & dx2=2*dx
	dy=50 & dy2=2*dy
	polrec,1,maken(0,360,73),/deg,xx,yy & xx=xx*dx*.9 & yy=yy*dy*.9
 
	;---------  Cursor loop  ------------
loop:
	test = 0
	while test eq 0 do begin
	  cursor, x, y, /dev, /change
	  test = !err
	  empty
	  widget_control, idxy, set_val=strtrim(string(x,y),2)

	  if mflag then tv,mark,x0,y0,true=3
	  x0=x-dx & y0=y-dy
	  mark = tvrd(x0,y0,dx2,dy2,true=3)	; Save image patch.
	  plots,[x-40,x+40],[y-40,y+40],/dev,col=tarclr(255,0,0), thick=5
	  plots,[x-40,x+40],[y+40,y-40],/dev,col=tarclr(0,0,255), thick=5
	  plots,x+xx,y+yy,/dev,col=tarclr(0,255,0),thick=3
	  mflag = 1
	endwhile

	opt = xoption(['Quit','Continue'])
	if opt eq 1 then begin
          tvcrs, x, y                         ; Place cursor.
	  goto, loop
	endif
 
	widget_control, top, /dest
	if n_elements(img) ne 0 then swdelete
 
	return
	end
