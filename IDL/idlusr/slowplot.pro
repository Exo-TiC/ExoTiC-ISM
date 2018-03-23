;-------------------------------------------------------------
;+
; NAME:
;       SLOWPLOT
; PURPOSE:
;       Plot data slowly in fading colors.
; CATEGORY:
; CALLING SEQUENCE:
;       slowplot, x, y, n, wait = wt, fade = fade,  fast_fade = fast, 
;         overplot = over, help = hlp, _extra = extra
; INPUTS:
;       x,y = x,y arrays to plot.                           in
;       n = optional number of points displayed (def=50).   in
; KEYWORD PARAMETERS:
;       Keywords:
;         /FADE means use fade mode.
;         /FAST_FADE means use fast fade mode.
;         WAIT = w time delay in seconds between plotted points.
;           Def = 0 sec. 
;         /OVER overplot using existing plot on screen. 
;         _extra means regular plot keywords can be passed 
;           to the plot statement. 
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
;       Notes: Press the letter A to abort, @ to stop.
; MODIFICATION HISTORY:
;       R. Sterner, 16 Aug, 1991
;       R. Sterner, 24 Sep, 1991 --- cleaned up for library.
;       R. Sterner, 15 Oct, 1991 --- added /FAST_FADE mode.
;       R. Sterner, 1998 Jan 15 --- Dropped use of !d.n_colors. 
;              MRK, 29 OCT 2010 --- added _extra keyword, dropped 
;                                   regular plot keywords: title, 
;                                   xtitle, ytitle, charsize. 
;       R. Sterner, 2010 Nov 30 --- Converted arrays from () to [].
;
; Copyright (C) 1991, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
	pro slowplot, x, y, n, wait=wt, fade=fade, fast_fade=fast, $ 
	  overplot=over, help=hlp, _extra=extra
 
	if (n_params(0) lt 2) or keyword_set(hlp) then begin
	  print,' Plot data slowly in fading colors.'
	  print,' slowplot, x, y, [n], wait=wt, fade=fade,' 
          print,'   fast_fade=fast, overplot=over, help=hlp, '
	  print,'   _extra=extra' 
	  print,'   x,y = x,y arrays to plot.                           in'
	  print,'   n = optional number of points displayed (def=50).   in'
	  print,' Keywords:'
	  print,'   WAIT=w time delay in seconds between plotted points.'
	  print,'     Def=0 sec.'
	  print,'   /FADE means use fade mode.'
	  print,'   /FAST_FADE means use fast fade mode.' 
	  print,'   /OVER overplot using existing plot on screen.'
	  print,'   _extra means regular plot keywords can be passed '
	  print,'     to the plot statement. '
	  print,' Notes: Press the letter A to abort, @ to stop.'
	  return
	endif
 
	;------  Define plot keywords  -----  
	if n_elements(n) eq 0 then n=50
        fn = float(n)
	if n_elements(wt) eq 0 then wt=0
	lst = n_elements(x)-1
	c = [0, (!d.table_size / (fn-1))*((fn-1)-indgen(n)-1)]
	if not keyword_set(over) then begin
	  plot, x, y, /nodata, _extra=extra
	endif
	plots, x[1:n-1], y[1:n-1]
	n = long(n)
 
	;--------  Fade mode  ----------
	if keyword_set(fade) then begin
	for i = n-1L, lst-2 do begin
	  for j=n-1L, -1, -1 do begin
	    plots, [x[i-j], x[i-j+1]], $
           [y[i-j], y[i-j+1]], color=c[j>0]
	  endfor
	  wait, wt 
          k = get_kbrd(0)
          if k eq '@' then stop
	  if strupcase(k) eq 'A' then return
	endfor
	return
	endif 
 
	;---------  Fast fade mode  ----------
	if keyword_set(fast) then begin
	  c = reverse(c)
	  for i = 0L, lst-n do begin
	    plots, x[i:(i+n-1)], y[i:(i+n-1)], color=c 
	    wait, wt 
            k = get_kbrd(0)
            if k eq '@' then stop
	    if strupcase(k) eq 'A' then return
	  endfor
	  return
	endif
 
	;---------  Snake mode  -----------
	for i = n, lst-1 do begin
	  plots,x[(i-n):(i-n+1)], y[(i-n):(i-n+1)], color=0 
	  plots, x[i:i+1], y[i:i+1]
	  wait, wt 
          k = get_kbrd(0)
          if k eq '@' then stop
	  if strupcase(k) eq 'A' then return
	endfor
 
	return
	end
