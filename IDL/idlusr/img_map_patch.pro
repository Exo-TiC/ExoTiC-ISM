;---  img_map_patch.pro = Apply map_patch to a 2-d or 3-d image  ----
;   R. Sterner, 2010 Feb 21
;   R. Sterner, 2014 Sep 10 --- Handled undefined miss.

	function img_map_patch, img, lon, lat, $
	  missing=miss, xstart=ix, ystart=iy, xsize=xsz, ysize=ysz, $
	  error=err,_extra=extra, nodisplay=nodisp, quiet=quiet, help=hlp
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Do map_patch for a 24 bit color image or a 2-d array.'
	  print,' out = img_map_patch(img,lon,lat)'
	  print,'   img = input image (2-D or 3-D).              in'
	  print,'   lon, lat = Optional arrays of lon and lat.   in'
	  print,'     See help for map_patch for details.'
	  print,'   out = returned remapped image.               out'
	  print,' Keywords:'
	  print,'   MISSING=miss  Value to use for values outside the remapped'
	  print,'     image.  This should be a 24-bit color for color images.'
	  print,'     It should be a value not in the image to be remapped.'
	  print,'     It can be used with img_tv for the transparent value.'
	  print,'   Any map_patch keywords map be given.'
	  print,'   Will need at least XSTART=ix, YSTART=iy to display the image.'
	  print,'   /NODISPLAY means just return results, do not display'
	  print,'     them.  Otherwise the image will be displayed.'
	  print,'   /QUIET Do not show messages.'
	  print,'   ERROR=err Error flag: 0=ok.'
	  return,''
	endif
 
	;------  2-D or 3-D ?  ---------------------
	img_shape, img, true=tr
 
    ;------  Handle missing value  ------------
    if n_elements(miss) eq 0 then miss=max(img) + 1

	;------  Handle 2-D case  -----------------
	if tr eq 0 then begin
	  if not keyword_set(quiet) then print,' img_map_patch: remapping 2-d image ...'
	  out = map_patch(img, lon, lat, xsize=xsz, ysize=ysz, $
	    xstart=ix, ystart=iy, miss=miss, _extra=extra)
	  if keyword_set(nodisp) then return, out
	  img_tv, out, ix, iy, trans=miss
	  return, out
	endif
 
	;------  Split input images  ---------------
	img_split, img, r, g, b, tr=tr, err=err
	if err ne 0 then return, -1
 
	;-------  Do map_patch on components  -------
	if n_elements(miss) ne 0 then c2rgb, miss, rmiss,gmiss,bmiss
	if not keyword_set(quiet) then print,' img_map_patch: remapping 3-d image: R ...'
	rr = map_patch(r, lon, lat, xsize=xsz, ysize=ysz, $
	    xstart=ix, ystart=iy, miss=rmiss, _extra=extra)
	if not keyword_set(quiet) then print,' img_map_patch: remapping 3-d image: G ...'
	gg = map_patch(g, lon, lat, xsize=xsz, ysize=ysz, $
	    xstart=ix, ystart=iy, miss=gmiss, _extra=extra)
	if not keyword_set(quiet) then print,' img_map_patch: remapping 3-d image: B ...'
	bb = map_patch(b, lon, lat, xsize=xsz, ysize=ysz, $
	    xstart=ix, ystart=iy, miss=bmiss, _extra=extra)
 
	;-------  Merge color channels back into a 24-bit image  -------
	out = img_merge(rr,gg,bb,true=tr)
	if keyword_set(nodisp) then return, out
 
	;-------  Display result  ---------
	img_tv, out, ix, iy, trans=miss
	return, out
 
	end
