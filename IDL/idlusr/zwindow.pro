;-------------------------------------------------------------
;+
; NAME:
;       ZWINDOW
; PURPOSE:
;       Z buffer window like normal x window.
; CATEGORY:
; CALLING SEQUENCE:
;       zwindow
; INPUTS:
; KEYWORD PARAMETERS:
;       Keywords:
;         XSIZE=xs  X size of window (def=!d.x_size).
;         YSIZE=ys  Y size of window (def=!d.y_size).
;         N_COLORS=n  Number of colors to use (def=!d.table_size).
;         /BITS8 Set for 8-bit color, else 24-bit color.
;         /CLOSE  Terminate z window and restore previous window.
;           Must close a zwindow first to resize it.
;         /COPY   Copy z window to visible window.
;         /FREE   Force copy to use a new window.
;         /LIST   List zwindow status.
;         /GET    Get image and color table:
;           IMAGE=img, RED=r, GRN=g, BLU=b.
; OUTPUTS:
; COMMON BLOCKS:
;       zwindow_com
; NOTES:
;       Notes: Easy 8 bit graphics on a 24 bit display.
;         Set up z window, then graphics commands use it.
;         Can read back image and color table with tvrd, tvlct,/get.
;         Use /copy to display results, /close when done.
;         WARNING: text and symbol sizes in normal graphics
;         windows are 3/4 the size in the Z-buffer.
; MODIFICATION HISTORY:
;       R. Sterner, 2000 Mar 28
;       R. Sterner, 2000 Apr 17 --- removed the close on /COPY.
;       R. Sterner, 2000 May 07 --- Fixed an entry device bug.
;       R. Sterner, 2000 May 22 --- Will resize X window on /copy if needed.
;       R. Sterner, 2001 Jan 29 --- Added /GET,IMAGE=img,R=r,G=g,B=b
;       R. Sterner, 2001 Mar 28 --- Added /FREE for /COPY.
;       R. Sterner, 2001 Dec 26 --- Trying to get to work without X.
;       R. Sterner, 2002 Jun 25 --- Trying again to get to work without X.
;       R. Sterner, 2009 May 21 --- Added 24-bit color and made default.
;       R. Sterner, 2011 May 04 --- Checked if previous was Z if /COPY.
;       R. Sterner, 2011 May 17 --- Should now be able to change window size.
;       R. Sterner, 2011 May 17 --- Upgraded /LIST and changed to /STATUS.
;
; Copyright (C) 2000, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro zwindow, xsize=xsize0, ysize=ysize0, n_colors=n_colors0, $
	  copy=copy, close=close, status=status, free=free, help=hlp, $
	  bits8=bits8, get=get, image=a, red=rr, grn=gg, blu=bb
 
	common zwindow_com, zflag, pdev, win, decomp, xsize, ysize, n_colors, cmode
	;-------------------------------------------------------------------
	;  zflag = Zwindow open? -1: never, 0=no, 1=yes.
	;  pdev = Plot device on entry (like X, Z, ...).
	;  win = Last visible window index for /copy.
	;  decomp = Decomp for previous state being restored.
	;  xsize = zwindow size.
	;  ysize = zwindow size.
	;  n_colors = zwindow number of colors.
	;  cmode = Color mode: 8=8-bit, 24=24-bit.
	;-------------------------------------------------------------------
 
	if keyword_set(hlp) then begin
	  print,' Z buffer window like normal x window.'
	  print,' zwindow'
	  print,'   All args are keywords.'
	  print,' Keywords:'
	  print,'   XSIZE=xs  X size of window (def=!d.x_size).' 
	  print,'   YSIZE=ys  Y size of window (def=!d.y_size).' 
	  print,'   N_COLORS=n  Number of colors to use (def=!d.table_size).'
	  print,'   /BITS8 Set for 8-bit color, else 24-bit color.'
	  print,'   /CLOSE  Terminate z window and restore previous window.'
	  print,'     Must close a zwindow first to resize it.'
	  print,'   /COPY   Copy z window to visible window.'
	  print,'   /FREE   Force copy to use a new window.'
	  print,'   /STATUS List zwindow status.'
	  print,'   /GET    Get image and color table:'
	  print,'     IMAGE=img, RED=r, GRN=g, BLU=b.'
	  print,' Notes: Easy 8 bit graphics on a 24 bit display.'
	  print,'   Set up z window, then graphics commands use it.'
	  print,'   Can read back image and color table with tvrd, tvlct,/get.'
	  print,'   Use /copy to display results, /close when done.'
	  print,'   WARNING: text and symbol sizes in normal graphics'
	  print,'   windows are 3/4 the size in the Z-buffer.'
	  return
	endif
 
	if n_elements(zflag) eq 0 then zflag=-1
 
	;-------  List zwindow status  -----------
	if keyword_set(status) then begin
	  print,' '
	  print,' ZWINDOW status:'
          txt = '.'
          if cmode eq 8 then txt=' with '+strtrim(n_colors,2)+' colors.'
          case zflag of
      -1:   print,'   A zwindow was never opened.'
       0:   print,'   The zwindow is closed.'
       1:   print,'   A zwindow is open and is ' + $
              strtrim(xsize,2) + ' x ' + strtrim(ysize,2) + $
              ' in ' + strtrim(cmode,2) + ' bit mode' + txt
          endcase
          if decomp eq 1 then txt=' and is decomp compatible.' $
            else txt=' and is not decomp compatible.'
          if !d.name eq pdev then begin
            adj = 'current'
            vrb = 'is'
          endif else begin
            adj = 'last'
            vrb = 'was'
          endelse
          print,'   The '+adj+' plot device '+vrb+' ' + pdev + txt
          print,'   The '+adj+' visible window '+vrb+' ' + strtrim(win,2)
	  return
	endif
        ;--------  END List  ---------
 
	;-------  Copy z window  -----------------
	if (keyword_set(copy)) or (keyword_set(get)) then begin
	  if zflag lt 0 then begin
	    print,' Error in zwindow: cannot copy zwindow, never opened.'
	    return
	  endif
	  if zflag eq 0 then begin
	    print,' Error in zwindow: cannot copy zwindow, not open.'
	    return
	  endif
	  pdev0 = !d.name			; Current plot device.
	  if pdev0 ne 'Z' then set_plot,'Z'	; Force to Z.
	  if cmode eq 8 then begin
	    a = tvrd()			; Read 8 bit image from z buffer.
	    tvlct,rr,gg,bb,/get
	  endif else begin
	    a = tvrd(tr=3)		; Read 24 bit image from z buffer.
	  endelse
	  if keyword_set(get) then begin
	    if pdev0 ne 'Z' then set_plot,pdev0
	    return
	  endif
	  img_shape, a, nx=nx, ny=ny, true=tr
	  set_plot,pdev			; Back to entry plot device.
          if pdev eq 'Z' then begin
            print,' Error in zwindow: Previous devices was Z, cannot copy window.'
            return
          endif
 
	  if keyword_set(free) then begin  ; Force new window.
            if (nx gt 1200) or (ny gt 900) then begin
              swindow,xs=nx,ys=ny,x_scr=nx<1200,y_scr=ny<900
            endif else begin
              window,/free,xs=nx,ys=ny
            endelse
	    win = !d.window		; Remember created window.
	    goto, dsply
	  endif
	  if win_open(win) then begin
	    wset, win			; Set to entry window.
	    dxs = !d.x_size		; Get size.
	    dys = !d.y_size
	  endif else begin		; Window not open.
	    dxs = 0			; Zero size.
	    dys = 0
	  endelse
	  if win lt 0 then begin	; No window, force size mismatch.
	    dxs = 0
	    dys = 0
	  endif
	  if win ge 32 then begin	; /free window.
	    if (nx ne dxs) or (ny ne dys) then begin  ; New window.
              if (nx gt 1200) or (ny gt 900) then begin
                swindow,xs=nx,ys=ny,x_scr=nx<1200,y_scr=ny<900
              endif else begin
                window,/free,xs=nx,ys=ny
              endelse
	      win = !d.window		; Remember created window.
	    endif
	  endif else begin
	    if (nx ne dxs) or (ny ne dys) then begin ; New window.
              if (nx gt 1200) or (ny gt 900) then begin
                swindow,xs=nx,ys=ny,x_scr=nx<1200,y_scr=ny<900
              endif else begin
                window,win>0,xs=nx,ys=ny
              endelse
	      win = !d.window		; Remember created window.
	    endif
	  endelse
dsply:	  if cmode eq 8 then begin
	    device, decomp=0		; Set to 8 bit display mode.
	    tvlct,rr,gg,bb
	    tv, a			; Display 8-bit image.
	    device, decomp=decomp
	  endif else begin
	    tv, a, true=tr		; Display 24-bit image.
	  endelse
	  set_plot,'z'			; Back to z buffer.
	  return
	endif
        ;-------  END Copy  ---------
 
	;-------  Close z window  -----------------
	if keyword_set(close) then begin
	  if zflag le 0 then return		; Never opened or not open now.
	  device, /close			; Close z buffer.
	  set_plot,pdev				; Back to entry plot device.
	  dflag = 0				; Decomp device flag, start no.
	  if pdev eq 'X' then dflag=1		; Yes, decomp compatible.
	  if pdev eq 'MAC' then dflag=1		; Yes, decomp compatible.
	  if pdev eq 'WIN' then dflag=1		; Yes, decomp compatible.
	  if dflag eq 1 then device, decomp=decomp  ; Set to previous state.
	  zflag = 0				; Set flag to closed.
	  return
	endif
        ;-------  END Close  --------
 
	;-------  Find entry state  ---------------
	pdev0 = !d.name				; Plot device.
        if n_elements(pdev) eq 0 then pdev=pdev0  ; Make sure pdev is defined.
        if pdev0 ne 'Z' then begin              ; If last was not Z ...
          pdev = pdev0                          ; Only copy if last was not Z.
	  win = !d.window			; Get any visible window.
        endif
	dflag = 0				; Decomp device flag, start no.
	if pdev eq 'X' then dflag=1		; Yes, decomp compatible.
	if pdev eq 'MAC' then dflag=1		; Yes, decomp compatible.
	if pdev eq 'WIN' then dflag=1		; Yes, decomp compatible.
	if dflag eq 1 then device, get_decomp=decomp	; Decomp flag.
 
	;--------  Set values  --------------------
	if n_elements(xsize0) eq 0 then xsize0=!d.x_size
	if n_elements(ysize0) eq 0 then ysize0=!d.y_size
	if n_elements(n_colors0) eq 0 then n_colors0=!d.table_size
	xsize=xsize0 & ysize=ysize0 & n_colors=n_colors0
 
	;--------  Set up window  ------------------
        if pdev0 eq 'Z' then device,/close      ; Close Z buffer in case open.
	set_plot,'z'                            ; Force to Z buffer.
	if not keyword_set(bits8) then begin
	  device, set_pixel_depth=24, set_res=[xsize,ysize], z_buff=0
	  cmode = 24
	endif else begin
	  device, set_colors=n_colors, set_res=[xsize,ysize], z_buff=0
	  cmode = 8
	endelse
	zflag = 1				; Set flag to open.
 
	return
 
	end
