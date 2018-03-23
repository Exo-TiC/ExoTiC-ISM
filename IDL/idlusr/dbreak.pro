;-------  dbreak.pro = Break a data set based on a max allowed gap size  ----
;	R. Sterner, 12 Aug, 1993
;       R. Sterner, 2010 May 04 --- Converted arrays from () to [].

	pro dbreak, x, y, gap=gap, tag_value=tag, low=w, help=hlp

	if (n_params(0) lt 2) or keyword_set(hlp) then begin
	  print,' Break a data set based on a max allowed gap size.'
	  print,' dbreak, x, y'
	  print,'   x,y = points in a given data set.'
	  print,' Keywords:'
	  print,'   GAP=g  Maximum allowed gap in x.  Any larger'
	  print,'     gap causes a break in the data set.  The break'
	  print,'     is caused by inserting a point with a tag value'
	  print,'     in the gap.'
	  print,'   TAG_VALUE=t  Tag value for gap points (def=32000).'
	  print,'   LOW=lo  returned indices of points just below gaps.'
	  print,' Notes: May plot the data set showing the gaps by the'
	  print,'   the command: plot,x,y,max_value=v  where v is a value'
	  print,'   larger than any valid data but less than the tag value.'
	  print,'   WARNING: the x and y arrays are modified.'
	  return
	endif

	w = where(x[1:*]-x gt gap, cnt)
	if cnt eq 0 then return
	w = w + lindgen(n_elements(w))		; Allow for inserted points.

	if n_elements(tag) eq 0 then tag = 32000

	for i = 0, n_elements(w)-1 do begin
	  lo = w[i]
	  hi = lo+1
	  x = [x[0:lo], total(x[lo:hi])/2., x[hi:*]]	; Insert a point.
	  y = [y[0:lo], tag, y[hi:*]]
	endfor

	return
	end 
