;--------  subarr.pro = Extract an array subset based on xy coordinates  -----
;	R. Sterner, 1994 Aug 9

	pro subarr, x, y, z, x2, y2, z2, xrange=xran, yrange=yran, help=hlp

	if (n_params(0) lt 6) or keyword_set(hlp) then begin
	  print,' Extract an array subset based on xy coordinates.'
	  print,' subarr, x, y, z, x2, y2, z2'
	  print,'   x = array of image x coordinates.       in'
	  print,'   y = array of image y coordinates.       in'
	  print,'   z = 2-d image or array.                 in'
	  print,'   x2 = subset of image x coordinates.     out'
	  print,'   y2 = subset of image y coordinates.     out'
	  print,'   z2 = subset image or array.             out'
	  print,' Keywords:'
	  print,'   XRANGE=xran  Desired range of x [start,end].'
	  print,'   YRANGE=xran  Desired range of y [start,end].'
	  return
	endif

        ;---------  Find image elements in specified ranges  --------
        ix = where((x ge min(xran)) and (x le max(xran)))
        iy = where((y ge min(yran)) and (y le max(yran)))
        xlo = min(ix, max=xhi)
        ylo = min(iy, max=yhi)

	;----------  New x,y coordinates  ----------------
	x2 = x(xlo:xhi)
	y2 = y(ylo:yhi)

	;-----------  Subarray  ---------------------------
	z2 = z(xlo:xhi,ylo:yhi)

	return
	end
