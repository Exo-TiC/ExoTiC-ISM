;---  clrcontrast.pro = compute luminance difference between two colors  ---
;	R. Sterner, 2003 Mar 28

	function clrcontrast, c1, c2, help=hlp

	if (n_params(0) lt 2) or keyword_set(hlp) then begin
	  print,' Compute luminance difference between two colors.'
	  print,' delta = clrcontrast( c1, c2)'
	  print,'   c1, c2 = first and second colors as 24-bit values.  in'
	  print,'   delta = Luminance of c1 - c2.                       out'
	  print,' Note: Gives a measure of contrast between colors.'
	  print,' c1 might be the background color, and c2 a plot'
	  print,' color.  Can use to test visibility.'
	  return,''
	endif

	c2rgb, c1, r1, g1, b1
	c2rgb, c2, r2, g2, b2

	lum1 = ct_luminance(r1,g1,b1)/255.
	lum2 = ct_luminance(r2,g2,b2)/255.

	return, lum1-lum2

	end
