;----  find_img_shift.pro = Find shift between two images -----
;	R. Sterner, 2005 May 11

	pro find_img_shift, img1, img2, ix10, iy10, ix2, iy2, $
	  kwid=kwid, fact=fact, error=err, help=hlp

	if (n_params(0) lt 6) or keyword_set(hlp) then begin
	  print,' Find shift between two images at a given location.'
	  print,' find_img_shift, img1, img2, ix1, iy1, ix2, iy2'
	  print,'   img1, img2 = The two images.                 input'
	  print,'   ix1,iy1 = Point in first image (pixels).     input'
	  print,'   ix2,iy2 = Corresponding point in 2nd image). output'
	  print,' Keywords:'
	  print,'   KWID=kwid Width of box in image 1 (def=50).'
	  print,'   FACT=f How many times bigger then search area in'
	  print,'     image 2 is than kwid (def=2).'
	  print,'   ERROR=err Error flag: 0=ok, 1=point too close edge.'
	  print,' Notes: Returned ix1,iy2 may not be valid in some cases.'
	  return
	endif

	;---------------------------------------------
	;  Initialize
	;---------------------------------------------
	if n_elements(kwid) eq 0 then kwid=50
	if n_elements(fact) eq 0 then fact=2
	ix1 = ix10				; Copy input point.
	iy1 = iy10
	nx = dimsz(img1,1)			; Image dimensions.
	ny = dimsz(img1,2)
	err = 0

	;---------------------------------------------
	;  Kernal
	;---------------------------------------------
	kwid2 = kwid/2				; Half width.
	if (ix1 lt kwid2) or (ix1 gt (nx-1-kwid2)) then begin
	  err = 1
	  return
	endif
	if (iy1 lt kwid2) or (iy1 gt (ny-1-kwid2)) then begin
	  err = 1
	  return
	endif
	lox1 = ix1-kwid2
	hix1 = ix1+kwid2
	loy1 = iy1-kwid2
	hiy1 = iy1+kwid2
	k = float(img1(lox1:hix1,loy1:hiy1))	; Kernal.

	;---------------------------------------------
	;  Search box
	;---------------------------------------------
	swid2 = kwid2*fact
	ixs1 = ix1				; Search box center.
	iys1 = iy1
	ixs1 = (ixs1>swid2)<(nx-swid2)		; Keep search box
	iys1 = (iys1>swid2)<(ny-swid2)		;   in bounds.
	lox2 = ixs1-swid2
	hix2 = ixs1+swid2
	loy2 = iys1-swid2
	hiy2 = iys1+swid2
	s = float(img2(lox2:hix2,loy2:hiy2))	; Search Box.

	;---------------------------------------------
	;  Convolution
	;---------------------------------------------
	r = convol(s,k)
	w = where(r eq max(r))
	one2two, w(0), r, ix, iy
	ix2 = ix - swid2 + ixs1
	iy2 = iy - swid2 + iys1

	end
