;------------------------------------------------------------------------------
;  izoom_ng.pro = New graphics izoom.
;  R. Sterner, 2010 Sep 23
;
;  Experimental version.  Not completely functional yet.
;    Does not handle xrange and yrange yet.
;    Yes it does, image has those keywords so they just pass through
;    in the extra keyword.  But they can't be abbreviated, why???
;------------------------------------------------------------------------------

	pro izoom_ng, x, y, z, position=pos, axis_style=axstyl, $
	  aspect_ratio=asprat, xtickdir=xtkdir, ytickdir=ytkdir, $
	  xticklen=xtklen, yticklen=ytklen, $
	  _extra=extra, help=hlp

	if (n_params(0) lt 3) or keyword_set(hlp) then begin
	  print,' izoom_ng'
	  return
	endif

	;-----------------------------------------
	;  Defaults
	;-----------------------------------------
	if n_elements(pos) eq 0 then pos=[0.15,0.15,0.90,0.85]
	if n_elements(axstyl) eq 0 then axstyl=2
	if n_elements(asprat) eq 0 then asprat=0
	if n_elements(xtkdir) eq 0 then xtkdir=1
	if n_elements(ytkdir) eq 0 then ytkdir=1
	if n_elements(xtklen) eq 0 then xtklen=0.03
	if n_elements(ytklen) eq 0 then ytklen=0.03

	;-----------------------------------------
	;  Display image
	;-----------------------------------------
	im = image(z,x,y,position=pos, aspect_ratio=asprat, $
	  axis_style=axstyl, xtickdir=xtkdir, ytickdir=ytkdir, $
	  xticklen=xtklen, yticklen=ytklen, _extra=extra)

	end
