;-----------------------------------------------------------------------------
;  xypro_izoom.pro = xypro routine to be called by crossi to plot izoom cuts.
;  R. Sterner, 2013 Mar 19 from xypro_cuts2.pro
;  R. Sterner, A. Najmi, 2013 Apr 15 --- Added averages.
;-----------------------------------------------------------------------------

	pro xypro_izoom, xd, yd, init=s, xavg=xavg, yavg=yavg

	common xypro_cuts_com, arr, winx, winy, x, y, xst, yst, pst, $
               mxx, mxy, xavg0, yavg0

	win0 = !d.window

	if n_elements(s) ne 0 then begin
          xst = !x
          yst = !y
          pst = !p
	  arr = s.z
          mxx = dimsz(arr,1)-1
          mxy = dimsz(arr,2)-1
	  x = s.x
	  y = s.y
	  window,xs=400,ys=200,/free
	  winx = !d.window
	  window,xs=200,ys=400,/free
	  winy = !d.window
	  wset, win0
          if n_elements(xavg) eq 0 then xavg=0
          if n_elements(yavg) eq 0 then yavg=0
          xavg0 = xavg
          yavg0 = yavg
	  return
	endif

        d = abs(x-xd)
        ix = (where(d eq min(d)))[0]
        d = abs(y-yd)
        iy = (where(d eq min(d)))[0]

	wset, winx
        if yavg0 eq 0 then begin
	  plot,x,arr[*,iy],title='Y = '+strtrim(yd,2)
        endif else begin
	  plot,x,mean(dim=2,arr[*,((iy-yavg0)>0):((iy+yavg0)<mxy)]),title='Y = '+strtrim(yd,2)
        endelse
	ver,xd
	wset, winy
        if xavg0 eq 0 then begin
	  plot,arr[ix,*],y,title='X = '+strtrim(xd,2)
        endif else begin
	  plot,mean(dim=1,arr[((ix-xavg0)>0):((ix+xavg0)<mxx),*]),y,title='X = '+strtrim(xd,2)
        endelse
	hor,yd
	wset, win0
        !x = xst
        !y = yst
        !p = pst

	end
