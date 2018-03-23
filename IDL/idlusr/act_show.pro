;-------------------------------------------------------------
;+
; NAME:
;       ACT_SHOW
; PURPOSE:
;       Display color bars for the given list of color tables.
; CATEGORY:
; CALLING SEQUENCE:
;       act_show, list
; INPUTS:
;       list = List of 1 or more absolute color tables.  in
; KEYWORD PARAMETERS:
;       Keywords:
;         FACTOR=fact Size factor (def=1).
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
;       Notes: Creates a window and shows color bars.
; MODIFICATION HISTORY:
;       R. Sterner, 2008 Nov 18
;       R. Sterner, 2010 Nov 09 --- Changed list to clist, 
;          and added /LIST,/LOCAL,DIR=dir.
;
; Copyright (C) 2008, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro act_show, clist, factor=fact, list=list, dir=dir0, local=local, help=hlp
 
	if keyword_set(hlp) then begin
hlp:	  print,' Display color bars for the given list of color tables.'
	  print,' act_show, act_list'
	  print,'   act_list = List of 1 or more absolute color tables.  in'
	  print,' Keywords:'
          print,'   /LIST list any files with names like act_*.txt.'
          print,'     By default in the library directory of this routine (act_show.pro).'
          print,'     /LOCAL look in current directory for act_*.txt.'
          print,'     DIR=dir look in directory dir for act_*.txt.'
	  print,'   FACTOR=fact Size factor (def=1).'
	  print,' Notes: if act_list is given then creates a window and shows color bars.'
	  return
	endif
 
        if keyword_set(list) then begin
          whoami, dir
          if keyword_set(local) then cd,curr=dir
          if n_elements(dir0) ne 0 then dir=dir0
          wld = filename(dir,'act_*.txt',/nosym)
          f = file_search(wld,count=cnt)
          if cnt eq 0 then begin
            print,' No act_*.txt files found in '+dir
            return
          endif
          filebreak, f, nvfile=nam
          print,' act_*.txt files found in '+dir+':'
          for i=0,cnt-1 do print,'    '+nam[i]
          return
        endif else if n_params(0) eq 0 then goto, hlp

	if n_elements(fact) eq 0 then fact=1.
 
	;---  Initialize  ---
	mxy = 5			; Max # bars down.
	xmar1 = 40*fact		; Margins.
	xmar2 = 20*fact
	ymar1 = 30*fact
	ymar2 = 20*fact
	dx = 200*fact		; Bar size.
	dy = 50*fact
	csz = 1.*fact		; Charsize.
	px = xmar1 + dx + xmar2	; Single plot size.
	py = ymar1 + dy + ymar2
	filebreak, clist, nvfile=nam, dir=dir
 
	;---  Layout  ---
	n = n_elements(clist)
	mxy = mxy<n
	ny = n
	nx = 1
	if ny gt mxy then begin
	  nx = ceil(float(ny)/mxy)
	  ny = mxy
	endif
	wx = nx*px		; Window size.
	wy = ny*py + py
	window, /free, xs=wx, ys=wy
	erase,-1
 
 
	;---  Loop over color tables  ---
	zz = makez(50,50)
	iymx = mxy - 1
 
	for i=0,n-1 do begin
	  f = clist[i]
	  ix = i/ny
	  iy = iymx - (i mod ny)
	  lox = px*ix + xmar1
	  hix = lox + dx
	  loy = py*iy + ymar1 + py
	  hiy = loy + dy
	  pos = float([lox,loy,hix,hiy])/[wx,wy,wx,wy]
	  img = act_apply(zz,file=f)
	  z = act_info('z')
	  act_cbar,min(z),max(z),col=0,charsiz=csz,title=nam[i],pos=pos
	end ; i
 
	xyouts,align=0.0,/dev,xmar1,py/2,col=0,chars=csz*1.5, $
	  'Directory: '+dir[0]
 
 
	end
