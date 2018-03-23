;-------------------------------------------------------------
;+
; NAME:
;       LLPEN2KML
; PURPOSE:
;       Convert a txtdb file (or structure) with lon, lat, pen code to a kml file.
; CATEGORY:
; CALLING SEQUENCE:
;       llpen2kml, txtdb_file
; INPUTS:
;       txtdb_file = Name of txtdb file with data.   in
;         Must have lon and lat and may have pen, color, width,
;         pname, and pdesc under those names.  If pen is given must
;         have same number as lon and lat.  color, width, pname,
;         and pdesc are all optional and may be scalars or arrays
;         with same number of elements as sections (0s in pen).
;         May give a structure with the same values instead of a
;         txtdb file name.
; KEYWORD PARAMETERS:
;       Keywords:
;         NAME=nam Name displayed in Google Earth (def=file name).
;           Also used as output file name if given a structure.
;         COLOR=clr Give Google Earth color string for track color.
;           Def=3-D friendly yellow.  Use clr=tarclrge(...).
;         WIDTH=wid Width of curve(s) (def=1).
;         PNAME=pnam Section Name shown in Google Earth (def=000).
;         PDESC=pdes Section description shown in Google (Def=Curve).
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
;       Notes: Writes out kml and kmz files in current directory.
; MODIFICATION HISTORY:
;       R. Sterner, 2009 Aug 11 from shape2kml.pro written for the AT.
;
; Copyright (C) 2009, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro llpen2kml, txtdb_file, name=gnam, help=hlp, $
	  color=clr0, width=wid0, pname=pnam0, pdesc=pdes0
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Convert a txtdb file (or structure) with lon, lat, pen code to a kml file.'
	  print,' llpen2kml, txtdb_file'
	  print,'   txtdb_file = Name of txtdb file with data.   in'
	  print,'     Must have lon and lat and may have pen, color, width,'
	  print,'     pname, and pdesc under those names.  If pen is given must'
	  print,'     have same number as lon and lat.  color, width, pname,'
	  print,'     and pdesc are all optional and may be scalars or arrays'
	  print,'     with same number of elements as sections (0s in pen).'
	  print,'     May give a structure with the same values instead of a'
	  print,'     txtdb file name.'
	  print,' Keywords:'
	  print,'   NAME=nam Name displayed in Google Earth (def=file name).'
	  print,'     Also used as output file name if given a structure.'
	  print,'   COLOR=clr Give Google Earth color string for track color.'
	  print,'     Def=3-D friendly yellow.  Use clr=tarclrge(...).'
	  print,'   WIDTH=wid Width of curve(s) (def=1).'
	  print,'   PNAME=pnam Section Name shown in Google Earth (def=000).'
	  print,'   PDESC=pdes Section description shown in Google (Def=Curve).'
	  print,' Notes: Writes out kml and kmz files in current directory.'
	  return
	endif
 
	;------------------------------------------------------
	;  Read in data
	;
	;  Find curve breaks and prepare for output.
	;------------------------------------------------------
	typ = datatype(txtdb_file)
	if typ eq 'STR' then begin
	  print,' Reading data from a txtdb file ...'
	  s = txtdb_rd(txtdb_file,err=err)
	  if err ne 0 then return
	  filebreak, txtdb_file, name=fnam		; Grab file name.
	endif
	if typ eq 'STC' then begin
	  print,' Using data from the given structure ...'
	  s = txtdb_file
	  if n_elements(gnam) ne 0 then fnam=gnam else fnam='structure'
	endif
	if n_elements(s) eq 0 then begin
	  print,' Error in llpen2kml: Must given either a txtdb file name '+$
	    'or a structure with the same data.'
	  return
	endif
	if tag_test(s,'lon') eq 0 then begin
	  print,' Error in llpen2kml: lon not found.'
	  return
	endif
	if tag_test(s,'lat') eq 0 then begin
	  print,' Error in llpen2kml: lat not found.'
	  return
	endif
	lon = s.lon
	lat = s.lat
	if tag_test(s,'pen') then begin
	  pen = s.pen
	endif else begin
	  pen = intarr(n_elements(lon)) + 1
	  pen[0] = 0
	endelse
	npt = n_elements(lon)			; # points.
	lo = where(pen eq 0)			; Find all line breaks.
	hi = [lo[1:*]-1,n_elements(pen)-1]	; The i'th section: lo[i]:hi[i].
	n = n_elements(lo)			; Number of sections.
	lontxt = string(lon,form='(F13.8)')	; Prepare coordinates list.
	lattxt = string(lat,form='(F13.8)')
	coords = lontxt+','+lattxt+', 0'	; Coordinates as text.
	kfile = fnam+'.kml'			; Output kml file.
	zfile = fnam+'.kmz'			; Output kmz file.
 
	;------------------------------------------------------
	;  Set up headers and trailers
	;------------------------------------------------------
	;------------------------------------------------------
	;  File Header
	;------------------------------------------------------
	text_block, fheader, /quiet
;<?xml version="1.0" encoding="UTF-8"?>
;<kml xmlns="http://earth.google.com/kml/2.0">
;<Document>
;   <name>$$NAME$$</name>
;   <visibility>1</visibility>
;   <open>0</open>
;   <Folder>
;      <name>Shape</name>
;      <visibility>1</visibility>
;      <open>1</open>
 
	;------------------------------------------------------
	;  Deal with name
	;------------------------------------------------------
	if n_elements(gnam) ne 0 then namtxt=gnam else namtxt=fnam
	sb = {NAME:namtxt}
	rep_txtmarks, fheader, sb
 
	;------------------------------------------------------
	;  Section Header
	;------------------------------------------------------
	text_block, sheader0, /quiet
;      <Placemark>
;         <name>$$PNAME$$</name>
;         <visibility>1</visibility>
;         <open>1</open>
;         <description>$$PDESC$$</description>
;         <Style>
;           <LineStyle>
;              <color>$$COLOR$$</color>
;              <width>$$WIDTH$$</width>
;           </LineStyle>
;         </Style>
;         <LineString>
;	     <extrude>1</extrude>
;	     <tessellate>1</tessellate>
;	     <altitudeMode>clampedToGround</altitudeMode>
;	     <coordinates>
 
	;------------------------------------------------------
	;  Deal with parameters
	;    COLOR=clr    ; Section color.
	;    WIDTH=wid    ; Section width.
	;    PNAME=pnam	  ; Place name.
	;    PDESC=pdesc  ; Place description.
	;------------------------------------------------------
	;---  COLOR  ---
	np = n_elements(clr0)			; # elements this parameter.
	if np eq 0 then begin			; See if in structure.
	  clr0 = tag_value(s,'COLOR',err=err)
	  if err eq 0 then np=n_elements(clr0)	; Found.
	endif
	if np eq 0 then begin			; Not given.
	  clr = 'ff00B090'			; Default value.
	  flag_clr = 0				; All the same.
	endif else begin			; Was given.
	  if np eq 1 then begin			; Given one value.
	    clr = clr0				; Use it.
	    flag_clr = 0			; All the same.
	  endif else begin
	    if np lt npt then begin		; Too few values, repeat last.
	      clr = strarr(npt) + clr0[np-1]	; Fill with last value.
	      clr[0] = clr0			; Insert given colors.
	    endif
	    flag_clr = 1			; May be all different.
	  endelse
	endelse
	;---  WIDTH  ---
	np = n_elements(wid0)			; # elements this parameter.
	if np eq 0 then begin			; See if in structure.
	  wid0 = tag_value(s,'WIDTH',err=err)
	  if err eq 0 then np=n_elements(wid0)	; Found.
	endif
	if np eq 0 then begin			; Not given.
	  wid = '1'				; Default value.
	  flag_wid = 0				; All the same.
	endif else begin			; Was given.
	  if np eq 1 then begin			; Given one value.
	    wid = wid0				; Use it.
	    flag_wid = 0			; All the same.
	  endif else begin
	    if np lt npt then begin		; Too few values, repeat last.
	      wid = strarr(npt) + wid0[np-1]	; Fill with last value.
	      wid[0] = wid0			; Insert given colors.
	    endif
	    flag_wid = 1			; May be all different.
	  endelse
	endelse
	wid = strtrim(wid,2)
	;---  PNAME  ---
	np = n_elements(pnam0)			; # elements this parameter.
	if np eq 0 then begin			; See if in structure.
	  pnam0 = tag_value(s,'PNAME',err=err)
	  if err eq 0 then np=n_elements(pnam0)	; Found.
	endif
	if np eq 0 then begin			; Not given.
	  pnam = '000'			; Default value.
	  flag_pnam = 0				; All the same.
	endif else begin			; Was given.
	  if np eq 1 then begin			; Given one value.
	    pnam = pnam0			; Use it.
	    flag_pnam = 0			; All the same.
	  endif else begin
	    if np lt npt then begin		; Too few values, repeat last.
	      pnam = strarr(npt) + pnam0[np-1]	; Fill with last value.
	      pnam[0] = pnam0			; Insert given colors.
	    endif
	    flag_pnam = 1			; May be all different.
	  endelse
	endelse
	;---  PDESC  ---
	np = n_elements(pdes0)			; # elements this parameter.
	if np eq 0 then begin			; See if in structure.
	  pdes0 = tag_value(s,'PDESC',err=err)
	  if err eq 0 then np=n_elements(pdes0)	; Found.
	endif
	if np eq 0 then begin			; Not given.
	  pdes = 'Curve'			; Default value.
	  flag_pdes = 0				; All the same.
	endif else begin			; Was given.
	  if np eq 1 then begin			; Given one value.
	    pdes = pdes0			; Use it.
	    flag_pdes = 0			; All the same.
	  endif else begin
	    if np lt npt then begin		; Too few values, repeat last.
	      pdes = strarr(npt) + pdes0[np-1]	; Fill with last value.
	      pdes[0] = pdes0			; Insert given colors.
	    endif
	    flag_pdes = 1			; May be all different.
	  endelse
	endelse
 
	;---  Deal with any constant values  ---
	arr = [flag_clr, flag_wid, flag_pnam, flag_pdes]
	if total(arr) eq 0 then flag=0 else flag=1	; Any variable edits?
	if min(arr) eq 0 then begin
	  if flag_clr eq 0 then tag_add,sb,'COLOR',clr	; Build structure.
	  if flag_wid eq 0 then tag_add,sb,'WIDTH',wid
	  if flag_pnam eq 0 then tag_add,sb,'PNAME',pnam
	  if flag_pdes eq 0 then tag_add,sb,'PDESC',pdes
	  rep_txtmarks, sheader0, sb			; Edit header.
	endif
 
	;------------------------------------------------------
	;  Section Trailer
	;------------------------------------------------------
	text_block, strailer, /quiet
;            </coordinates>
;         </LineString>
;      </Placemark>
 
	;------------------------------------------------------
	;  File Trailer
	;------------------------------------------------------
	text_block, ftrailer, /quiet
;   </Folder>
;</Document>
;</kml>
 
	;------------------------------------------------------
	;  Write output KML file
	;------------------------------------------------------
	print,' Writing output file ...'
	openw,lun,kfile,/get_lun			; Open output file.
	printf,lun,fheader,form='(A)'			; Write file header.
	for i=0,n-1 do begin				; Loop through sections.
	  sheader = sheader0				; Copy section header.
	  if flag eq 1 then begin			; Do any edits.
	    if flag_clr eq 1 then tag_add,s,'COLOR',clr[i]
	    if flag_wid eq 1 then tag_add,s,'WIDTH',wid[i]
	    if flag_pnam eq 1 then tag_add,s,'PNAME',pnam[i]
	    if flag_pdes eq 1 then tag_add,s,'PDESC',pdes[i]
	    rep_txtmarks, sheader, s			; Edit header.
	  endif
	  printf,lun,sheader,form='(A)'			; Write section header.
	  printf,lun,coords[lo[i]:hi[i]],form='(A)'
	  printf,lun,strailer,form='(A)'
	endfor
	printf,lun,ftrailer,form='(A)'
	free_lun, lun					; Close file.
 
	;------------------------------------------------------
	;  Zip to get kmz file
	;------------------------------------------------------
	spawn,'zip '+zfile+' '+kfile
 
	print,' Output files complete:'+kfile
	print,'     KML: '+kfile
	print,'     KMZ: '+zfile
 
	end
