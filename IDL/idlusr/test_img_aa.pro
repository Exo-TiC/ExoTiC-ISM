;---  test_img_aa.pro = Test img_aa object.   ------
;	R. Sterner, 2006 Sep 25

	pro test_img_aa

	;---  Set to 24-bit color mode  ---
	window,xs=50,ys=50,/pixmap,/free
	wdelete

	;---  Create img_aa object  ----
	bclr = tarclr(/hsv,120,.15,1)
	a = obj_new('img_aa',xs=600,ys=400,bg=bclr,/autoshow)

	;---  Add some random spots  ----
	n = 100
	x = randomu(k,n)
	y = randomu(k,n)
	sz = randomu(k,n)*16+1
	h = randomu(k,n)*360
	s = randomu(k,n)*.3
	clr = lonarr(n)
	for i=0,n-1 do clr(i)=tarclr(/hsv,h(i),s(i),1)
;	clr = randomu(k,200)*16777215
	polrec,1,maken(0,360,100),/deg,px,py
	a->multipoly,x,y,/norm,col=clr,size=sz,ocol=0,px=px,py=py

	;---  Make a plot  ----
	a->plot,sin(findgen(100)/10.),col=tarclr(0,128,0), $
	  xthick=3,ythick=3, thick=3, chars=2

	;---  Add a curve  ----
	a->plotp,cos(findgen(100)/10.),col=255, thick=3

	;---  Add text  ----
	a->text,'!17TEST',.5,.7,col=-1,charsiz=10,charthick=9,/norm,align=.5
	a->text,'!17TEST',.5,.7,col=255,charsiz=10,charthick=3,/norm,align=.5

	;---  Add more random spots  ----
	n = 100
	x = randomu(k,n)
	y = randomu(k,n)
	sz = randomu(k,n)*16+1
	h = randomu(k,n)*360
	s = randomu(k,n)*.3
	clr = lonarr(n)
	for i=0,n-1 do clr(i)=tarclr(/hsv,h(i),s(i),1)
	polrec,1,maken(0,360,100),/deg,px,py
	a->multipoly,x,y,/norm,col=clr,size=sz,ocol=0,px=px,py=py

	;---  Add small text  ----
	a->text,'!3Some rather small text',5,5,col=tarclr(0,0,255), $
	  charsiz=1,/dev

	obj_destroy, a

	end
