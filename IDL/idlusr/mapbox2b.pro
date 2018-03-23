;-------------------------------------------------------------
;+
; NAME:
;       MAPBOX2B
; PURPOSE:
;       Two button interactive map box, can return a position box.
; CATEGORY:
; CALLING SEQUENCE:
;       mapbox2b, x1, x2, y1, y2
; INPUTS:
; KEYWORD PARAMETERS:
;       Keywords:
;         POSBOX=posbox Return a position box (normalized by default).
;           Can be used in POSITION=posbox in a PLOT call.
;         /DEVICE means return position box in device coordinates.
;         DX=dx (x2-x1+1).
;         DY=dy (y2-y1+1).
;         /LOCK lock box to initial size (box must be defined).
;         /XMODE use XOR mode for box.
;         /STATUS  means display box size and position.
;           Use FACT=fct to correct for demagged image.
;         MENU=txtarr     Text array with exit menu options.
;           Def=['OK','Abort','Continue'].  Continue is added.
;         /NOMENU         Inhibits exit menu.
;         EXITCODE=code.  0=normal exit, 1=alternate exit.
;           If MENU is given then code is option index.
;         /YREVERSE makes y=0 be the top line.
;         FACT=fact  Factor to correct image coordinates.
;           If an image is dispayed half size give FACT=2 to get
;           full size image coordinates (def=1).
;         CHANGE=routine  Name of a procedure to execute when box
;           changed.  Do box2b,/ch_details for details.
;         CTEXT=txt change routine toggle text for menu.
; OUTPUTS:
;       x1, x2 = min and max lon.   in, out
;       y1, y2 = min and max lat.   in, out
;       Set all values to -1000 for new box.
; COMMON BLOCKS:
; NOTES:
;       Notes: Works in data coordinates.
;         Drag open a new box.  Corners or sides may be dragged.
;         Box may be dragged by clicking inside.
;         Click any other button to exit.
;         A returned value of -1 means box undefined.
; MODIFICATION HISTORY:
;       R. Sterner, 2014 Apr 15 from box2b.pro
;       R. Sterner, 2014 Apr 18 --- Got working.
;
; Copyright (C) 2014, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
;-------------------------------------------------------------
;  mapbox2b_stat = Update status display.
;-------------------------------------------------------------
 
	pro mapbox2b_stat, x1, x2, y1, y2, nid=nid
 
	;---------  Display results  ----------
	widget_control,nid[0],set_val='X1  X2  DX  =  '+strtrim(x1,2)+$
	  '   '+strtrim(x2,2)+'   '+strtrim(x2-x1+1,2)
	widget_control,nid[1],set_val='Y1  Y2  DY  =  '+strtrim(y1,2)+$
	  '   '+strtrim(y2,2)+'   '+strtrim(y2-y1+1,2)
	widget_control,nid[2],set_val='CX  CY  =  '+strtrim((x1+x2)/2,2)+$
	  '   '+strtrim((y1+y2)/2,2)
 
	end
 
 
;-------------------------------------------------------------
;  mapbox2b = main routine.
;-------------------------------------------------------------
	pro mapbox2b, x10, x20, y10, y20, status=stat, help=hlp, $
	  exitcode=exit, menu=menu0, nomenu=nomenu, $
	  xmode=xmode, change=change, ctext=ctext, $
	  ch_details=ch_details, ch_opts=ch_opts, ch_vals=ch_vals, $
	  info=info, lock=lock, ch_flag=ch_flag, $
          dx=dx, dy=dy
 
	if keyword_set(hlp) then begin
	  print,' Two button interactive map box, can return a position box.'
	  print,' mapbox2b, x1, x2, y1, y2'
	  print,'   x1, x2 = min and max data X.   in, out'
	  print,'   y1, y2 = min and max data Y.   in, out'
	  print,'   Set all values to -1 for new box.'
	  print,' Keywords:'
          print,'   DX=dx (x2-x1).'
          print,'   DY=dy (y2-y1).'
	  print,'   /LOCK lock box to initial size (box must be defined).'
	  print,'   /XMODE use XOR mode for box.'
	  print,'   /STATUS  means display box size and position.'
	  print,'     Use FACT=fct to correct for demagged image.'
          print,'   MENU=txtarr     Text array with exit menu options.'
          print,"     Def=['OK','Abort','Continue'].  Continue is added."
          print,'   /NOMENU         Inhibits exit menu.'
          print,'   EXITCODE=code.  0=normal exit, 1=alternate exit.' 
          print,'     If MENU is given then code is option index.'
	  print,'   CHANGE=routine  Name of a procedure to execute when box'
	  print,'     changed.  Do mapbox2b,/ch_details for details.'
          print,'     THIS IS NOT YET TESTED (IT WAS INHERITED FROM AN OLD ROUTINE).'
          print,'     THIS MIGHT WORK WITH A BIT OF TWEAKING.'
	  print,'   CTEXT=txt change routine toggle text for menu.'
	  print,' Notes: Works in data coordinates.'
	  print,'   Drag open a new box.  Corners may be dragged.'
	  print,'   Box may be dragged by clicking inside.'
	  print,'   Click any other button to exit.'
	  print,'   A returned value of -1 means box undefined.'
	  return
	endif
 
	if keyword_set(ch_details) then begin
	  print,' mapbox2b change routine details'
	  print,' '
	  print,' mapbox2b can execute a user routine every time the box is'
	  print,' moved or its sized changed.  This routine is intended to'
	  print,' display some value for the subarea indicated by the box.'
	  print,' This routine is passed to box2d through the keyword'
	  print,' CHANGE=routine_name.  Its calling may be toggled by a'
	  print,' new exit menu item which may be customized with CTEXT=txt.'
	  print,' That menu item allows the routine to be called only when'
	  print,' box changes and on a mouse button up, or during box moves,'
	  print,' or not at all. Set CH_FLAG to 0=none, 1=on mouse up, or 2=on move'
	  print,' to initialize this operation (can always change it by clicking'
	  print,' the middle mouse button.'
	  print,' This routine is called a change routine and must follow'
	  print,' a strict calling sequence.  It may also have optional'
	  print,' initialize and terminate modes which are called outside'
	  print,' mapbox2b.  It must take the 4 parameters x1,x2,y1,y2 which'
	  print,' are the box x and y device coordinates in the window.'
	  print,' It also must allow the following 2 keywords:'
	  print,' OPTION=opt, and INFO=info, although it need not use them.'
	  print,' The change routine can use these keywords and the raw'
	  print,' box device coordinates to compute actual indices into'
	  print,' the full image.  mapbox2b may be given a list of menu items'
	  print,' in ch_opts that are options to the change routine, the'
	  print,' corresponding values may be given in ch_vals.  When a menu'
	  print,' option is picked its value is sent to the change routine'
	  print,' through the OPTION keyword.  INFO may be any info to be'
	  print,' passed to the change routine from outside mapbox2b, it could'
	  print,' be a structure, maybe with image file name for example.  The'
	  print,' change routine must know what to do with it. The example'
	  print,' routine image_stats.pro may be used with mapbox2b.  It is'
	  print,' initialized with the raw image: image_stats, init=img0.'
	  print,' It sets up a small window to display the histogram of the'
	  print,' subarea in the box.  After mapbox2b completes the window may'
	  print,' be removed by image_stats,/terminate.'
	  print,' The mapbox2b keywords CH_OPTS and CH_VALS are used together to'
	  print,' give menu items and option values to pass into the change'
	  print," routine: box2b,change='image_stats',ch_opt='Snap JPEG',$"
	  print,"   ch_vals=1, info='test.png' will do the call:"
	  print,' image_stats, x1,x2,y1,y2,fact=fact,yrev=yrev,option=opt,info=info'
	  print,' when Snap JPEG is clicked on the mapbox2b exit menu.'
	  print,' This will snap an image and mapbox2b will then continue.'
	  print,' The contents of INFO is printed at the bottom of the'
	  print,' snapped image and could be the image file name.'
	  print,' CH_OPTS and CH_VALS may be arrays for change routines'
	  print,' that have multiple options.'
	  return
	endif
 
	tol = 5				; Closeness tolerence (5 pixels).
 
	xcl=-1000 & ycl=-1000		; Define last cursor position.
	noerase = 1			; Don't erase old box first time.
	chflag = 0			; Assume no change routine.
	exit = -99			; In case aborted on first click.
 
	img = tvrd(tr=3)		; Grab copy of image.
 
	if n_elements(ctext) eq 0 then begin
	  txt = 'processing'
	  if n_elements(change) ne 0 then txt=change
	  ctext='Turn '+txt+' on/off'
	endif
	
 
	;========  Set up menu  ==========
	;----  Change processing  ------------
	if n_elements(change) ne 0 then begin
	  menu = [ctext]		; Add change routine ctr to menu.
	  mvals = [-2]			; Change processing toggle = -2.
	  chflag = 1			; Change processing on by default.
	  if n_elements(ch_flag) ne 0 then chflag=ch_flag
	  ;----  Change options  -------------
	  n = n_elements(ch_opts)
	  if n ne 0 then begin		; Add change options to menu.
	    if n_elements(ch_vals) eq 0 then ch_vals=indgen(n)
	    menu = [menu,ch_opts]
	    mvals = [mvals,-100-ch_vals]	; Change options LE -100.
	  endif
	  if n_elements(menu0) ne 0 then begin	; Add given menu items.
	    menu = [menu, menu0]
	    mvals = [mvals, indgen(n_elements(menu0))]
	  endif else begin			; or if none add EXIT.
	    menu = [menu,'Exit']
	    mvals = [mvals,0]
	  endelse
	endif
        ;----  Make sure exit menu is setup   ---------
        if n_elements(menu) eq 0 then begin	; If no menu make default.
	  if n_elements(menu0) eq 0 then menu0=['OK','Abort']
	  menu = menu0
          mvals = indgen(n_elements(menu))
	endif
 
	;-------  Set up status display?  -----------
	if keyword_set(stat) then begin
	  xbb,wid=wid,nid=nid,res=[0,1,2],lines=[$
	    'X1 X2 DX = 000.00  000.00  000.00',$
	    'Y1 Y2 DY = 000.00  000.00  000.00',$
	    'CX CY = 000.00  000.00']
	endif
 
	;-------  Use entry box if available  ------------
	if n_elements(x10) eq 0 then x10=-1000	; Make sure box values
	if n_elements(x20) eq 0 then x20=-1000	; are not undefined.
	if n_elements(y10) eq 0 then y10=-1000
	if n_elements(y20) eq 0 then y20=-1000
	if min([x10,x20,y10,y20]) gt -1000 then begin
	  x1 = (x10<x20)	; Use given values.
	  x2 = (x10>x20)
	  y1 = (y10<y20)
	  y2 = (y10>y20)
          ;---  Plot entry box  ---
          map_latlng_rect,x1,x2,y1,y2,/xmode,thick=4
	  noerase = 0				; Have a box to erase now.
          tmp = convert_coord((x1+x2)/2, (y1+y2)/2,/data,/to_dev)
          ix = tmp[0] & iy=tmp[1]
	  tvcrs, ix, iy         		; Set cursor to midbox.
	  if keyword_set(stat) then begin	; Update status.
	    mapbox2b_stat, x1, x2, y1, y2, nid=nid
	  endif
	  goto, loop			; Go intereactive.
	endif
 
	;-------  Init box to first point  ----------
	cursor, x1, y1, 3, /data	; Wait for a button down.
        if !mouse.button gt 1 then begin  ; Other button.
	  if n_elements(wid) ne 0 then widget_control, wid, /dest
	  return
	endif
	x2=x1 & y2=y1			; Got one, set box to single point.
 
	xcl = x1  &  ycl = y1		; Last cursor position.
 
	;================================================
	;	Main cursor loop
	;================================================
loop:
        cursor, xc, yc, 0, /data		; Look for new values.
        if ((xc eq xcl) and (yc eq ycl)) then $   ; Not moved, or
          cursor,xc,yc,2,/data	        	; wait for a change.

	xcl=xc  &  ycl=yc			; Save last position.
 
	;-------  Exit box routine  ------------
        if !mouse.button gt 1 then begin	; Other button.
          ;----  Exit options: OK, Abort, Continue. 
          if keyword_set(nomenu) then begin
            exit = 0
          endif else begin
            exit = xoption(['Continue',menu],val=[-1,mvals],def=-1)
          endelse
	  ;----  Set change routine call option  -----------
	  if exit eq -2 then begin
	    chflag = xoption(['No '+change, $
		change+' only on mouse up', change+' during move'])
	    exit = -1				; Continue.
	  endif
	  ;---  Execute a change routine option, then continue  -----
	  if exit le -100 then begin
	    opt = -exit-100			; Recover option value.
	    if chflag ge 1 then begin
	      call_procedure,change,x1,x2,y1,y2,fact=fact,yrev=yrev, $
	       option=opt, info=info
	    endif
	    exit = -1				; Continue.
	  endif
	  ;-----  Exit and return menu item number  ----------
	  if exit ne -1 then begin
            ;---  Erase box and return  ---
            map_latlng_rect,x1,x2,y1,y2,/xmode,thick=4
	    x10=x1 & x20=x2 & y10=y1 & y20=y2	; Return box.
            dx=x2-x1 & dy=y2-y1                 ; Return box size.
	    if keyword_set(stat) then widget_control,wid,/dest
	    return
	  endif
	  ;------  Continue ----------------
	  tv, img,tr=3
	  if keyword_set(xmode) then noerase=1	; After image reload (for xmode).
          map_latlng_rect,x1,x2,y1,y2,/xmode,thick=4
	  noerase = 0
          tmp = convert_coord((x1+x2)/2, (y1+y2)/2,/data,/to_dev)
          ix = tmp[0] & iy=tmp[1]
	  tvcrs, ix, iy         		; Set cursor to midbox.
	  goto, loop
	endif
        ;---  End exit code  ---
 
	;-------  First point of a drag command  ----------
        if !mouse.button eq 1 then begin
	  wait,.2				; Debounce. 
        endif else begin
	  goto, loop
        endelse
 
	if keyword_set(lock) then goto, inside
 
	;------  Check if at a box corner  --------------
	ic = 0
        tmp=convert_coord([xc,x1,x2,x2,x1],[yc,y1,y1,y2,y2],/data,/to_dev)
        ixc=tmp[0,0] & iyc=tmp[1,0]  ; Cursor.
        ix1=tmp[0,1] & iy1=tmp[1,1]  ; SW corner.
        ix2=tmp[0,2] & iy2=tmp[1,2]  ; SE corner.
        ix3=tmp[0,3] & iy3=tmp[1,3]  ; NE corner.
        ix4=tmp[0,4] & iy4=tmp[1,4]  ; NW corner.
	if inbox(ixc,iyc,ix1-tol,ix1+tol,iy1-tol,iy1+tol) then ic=1
	if inbox(ixc,iyc,ix2-tol,ix2+tol,iy2-tol,iy2+tol) then ic=2
	if inbox(ixc,iyc,ix3-tol,ix3+tol,iy3-tol,iy3+tol) then ic=3
	if inbox(ixc,iyc,ix4-tol,ix4+tol,iy4-tol,iy4+tol) then ic=4
 
	;------  Was at a corner, drag it  ---------------
	if ic gt 0 then begin			; Move a corner.
	  while !mouse.button eq 1 do begin	; Drag current corner.
          cursor, xc, yc, 0, /data		; Look for new values.
          if ((xc eq xcl) and (yc eq ycl)) then $ ; Not moved, or
            cursor,xc,yc,2,/data		; wait for a change.
	  xcl=xc  &  ycl=yc			; Save last position.
	  cursor,xxx,yyy,0,/data		; Absorb button up.

          ;---  Keep on map  ---
          if not finite(xc) then continue       ; Was off map.
          if not finite(yc) then continue
 
	  case ic of				; Process a corner move.
1:	  begin
	    x1=xc  & y1=yc
	    if (x1 gt x2) and (y1 gt y2) then begin	; Handle any crossover.
	      swap, x1, x2 & swap, y1,y2 & ic=3		; 1 --> 3
	    endif else if x1 gt x2 then begin
	      swap, x1, x2 & ic=2			; 1 --> 2
	    endif else if y1 gt y2 then begin
	      swap, y1, y2 & ic=4			; 1 --> 4
	    endif
	  end
2:	  begin
	    x2=xc  & y1=yc
	    if (x2 lt x1) and (y1 gt y2) then begin	; Handle any crossover.
	      swap, x1, x2 & swap, y1,y2 & ic=4		; 2 --> 4
	    endif else if x2 lt x1 then begin
	      swap, x1, x2 & ic=1			; 2 --> 1
	    endif else if y1 gt y2 then begin
	      swap, y1, y2 & ic=3			; 2 --> 3
	    endif
	  end
3:	  begin
	    x2=xc  & y2=yc
	    if (x2 lt x1) and (y2 lt y1) then begin	; Handle any crossover.
	      swap, x1, x2 & swap, y1,y2 & ic=1		; 3 --> 1
	    endif else if x2 lt x1 then begin
	      swap, x1, x2 & ic=4			; 3 --> 4
	    endif else if y2 lt y1 then begin
	      swap, y1, y2 & ic=2			; 3 --> 2
	    endif
	  end
4:	  begin
	    x1=xc  & y2=yc
	    if (x1 gt x2) and (y2 lt y1) then begin	; Handle any crossover.
	      swap, x1, x2 & swap, y1,y2 & ic=2		; 4 -- 2
	    endif else if x1 gt x2 then begin
	      swap, x1, x2 & ic=3			; 4 --> 3
	    endif else if y2 lt y1 then begin
	      swap, y1, y2 & ic=1			; 4 --> 1
	    endif
	  end
	  endcase
 
            map_latlng_rect,x1,x2,y1,y2,/xmode,thick=4,/erase   ; Erase last box.
            map_latlng_rect,x1,x2,y1,y2,/xmode,thick=4          ; Plot new box.
	    noerase = 0					; Erase from now on.
	    if keyword_set(stat) then begin		; Update status.
	      mapbox2b_stat, x1, x2, y1, y2, nid=nid
	    endif
	    if !mouse.button eq 0 then begin
	      if chflag ge 1 then begin
		call_procedure, change, x1, x2, y1, y2, fact=fact, yrev=yrev
	      endif
	    endif
	  endwhile					; Keep dragging.

	  goto, loop			; Go look for another drag operation.
	endif
 
	;------  Inside box  -----------------------------
inside:
	if keyword_set(lock) then ex=5 else ex=0
	if outbox(xc,yc,x1,x2,y1,y2,expand=ex) then goto, loop
 
	while !mouse.button eq 1 do begin	; Drag current corner.
          cursor, xc, yc, 0, /data		; Look for new values.
          if ((xc eq xcl) and (yc eq ycl)) then $ ; Not moved, or
              cursor,xc,yc,2,/data		; wait for a change.
	  dcx=xc-xcl & dcy=yc-ycl		; Move in data coordinates..
	  xcl=xc  &  ycl=yc			; Save last position.
	  cursor,xxx,yyy,0,/data		; Absorb button up.

          if finite(dcx) then begin
	    x1 = x1+dcx         ; New box position.
            x2 = x2+dcx
          endif
 
          if finite(dcy) then begin
	    y1 = y1+dcy
            y2 = y2+dcy
          endif
 
          map_latlng_rect,x1,x2,y1,y2,/xmode,thick=4,/erase   ; Erase last box.
          map_latlng_rect,x1,x2,y1,y2,/xmode,thick=4          ; Plot new box.
	  if keyword_set(stat) then begin	; Update status.
	    mapbox2b_stat, x1, x2, y1, y2, nid=nid
	  endif
	  if chflag eq 2 then begin
	    call_procedure, change, x1, x2, y1, y2
	  endif
	  if !mouse.button eq 0 then begin
	    if chflag ge 1 then begin
	      call_procedure, change, x1, x2, y1, y2
	    endif
	  endif
 
	endwhile
 
	goto, loop
 
	end
