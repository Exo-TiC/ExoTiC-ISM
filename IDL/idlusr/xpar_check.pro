;--------------------------------------------------------------------
;  xpar_check.pro = test xpar routines
;  R. Sterner, 2006 Oct 18
;  Returns a text array to parse.
;--------------------------------------------------------------------
;  Some example lines:
;  title: Interactive Globe
;  frame: 1, row=1
;  par: lat, -90, 90, 0, col=13421823
;  par: s004, 1, 101, 77, /int, fram=2
;  sliders: 3
;  slider_len: 520
;  flags: cut=0, disp=1
;  code: plot,x,y & for i=0, s003 do print,i
;--------------------------------------------------------------------

	pro xpar_check, txt

	txt = [ 'init: print,"Hello"', $
		'init: wset,0', $
		'init: erase,128', $
		'exit: wdelete', $
		'exit: print,"Good-bye"', $
		'title: Interactive Globe', $
		'frame: 0, /row', $
		'frame: 1, /row', $

		'par: lat, -90, 90, 0, col=13421823', $
		'par: lon, 180, -180, 0, col=13421823', $
		'par: ang, -180, 180, 0, col=13421823', $

		'par: latc, -90, 90, 0, col=12582847, fr=1', $
		'par: lonc, -180, 180, 0, col=12582847, fr=1', $
		'par: radc, 0, 90, 10, col=12582847, fr=1', $

		'flag_frame: 0, /row',$
		'flag_frame: 1, /row, /exclusive',$

		'flags: cont=1, usa=1, iso=1, hor=1', $
		'flags: ortho=1, merc=0, goode=0, cyl=0, frame=1', $

		'sliders: 3', $
		'slider_len: 520', $
		'code: map_set,lat,lon,ang,cont=cont,usa=usa,$', $
		'  iso=iso,hor=hor, $', $
		'  ortho=ortho,merc=merc,goode=goode,cyl=cyl &$', $
		'  rb2ll,lonc,latc,radc,/deg,maken(0,360,100),x,y &$', $
		' plots,x,y,col=12582847']

	end
