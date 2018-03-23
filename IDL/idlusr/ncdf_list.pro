;-------------------------------------------------------------
;+
; NAME:
;       NCDF_LIST
; PURPOSE:
;       List variables in a Net CDF file.
; CATEGORY:
; CALLING SEQUENCE:
;       ncdf_list, file
; INPUTS:
;       file = name of Net CDF file.   in
; KEYWORD PARAMETERS:
;       Keywords:
;         /DIMENSIONS List dimension names and sizes.
;         /GATT List global attributes.
;         /VARIABLES List variables.
;         /VATT List variable attributes.
;         OUT=txt Returned listing in a text array.
;         VNAME=vnam Returned variable names (use with /VARIABLES).
;         /QUIET do not show listing on screen.
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 2012 Jan 04 from wrf_list.pro.
;       R. Sterner, 2012 Jun 27 --- Fixed to handle scalars.
;       R. Sterner, 2012 Aug 15 --- Added new keyword VNAME.
;       R. Sterner, 2013 Apr 08 --- Allow no dimensions.
;
; Copyright (C) 2012, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro ncdf_list, file, gatt=gatt, variables=vars, $
	  dimensions=dims, vatt=vatt, out=outtxt, vname=vnam, $
	  quiet=quiet, help=hlp
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' List variables in a Net CDF file.'
	  print,' ncdf_list, file'
	  print,'   file = name of Net CDF file.   in'
	  print,' Keywords:'
	  print,'   /DIMENSIONS List dimension names and sizes.'
	  print,'   /GATT List global attributes.'
	  print,'   /VARIABLES List variables.'
	  print,'   /VATT List variable attributes.'
	  print,'   OUT=txt Returned listing in a text array.'
          print,'   VNAME=vnam Returned variable names (use with /VARIABLES).'
	  print,'   /QUIET do not show listing on screen.'
	  return
	endif
 
	fid = ncdf_open(file)		; Open Net CDF file.
	sf = ncdf_inquire(fid)		; Get file info.
 
	tprint,/init			; Start text array.
 
	;-----------------------------------------------------------
	;  File details
	;-----------------------------------------------------------
	tprint,' '
	tprint,' '+file
	tprint,'     # dimensions: '+strtrim(sf.ndims,2)
	tprint,'     # Variables: '+strtrim(sf.nvars,2)
	tprint,'     # Global attributes: '+strtrim(sf.ngatts,2)
	if sf.recdim lt 0 then begin
	  tprint,'     There are no unlimited dimensions.'
	endif else begin
	  tprint,'     The unlimited dimension is '+strtrim(sf.recdim,2)
	endelse
 
	;-----------------------------------------------------------
	;  Dimensions
	;-----------------------------------------------------------
        if sf.ndims gt 0 then begin
	  dimnam = strarr(sf.ndims)
	  dimsz = lonarr(sf.ndims)
	  for i=0,sf.ndims-1 do begin
	    ncdf_diminq, fid, i, nam, sz
	    dimnam[i] = nam
	    dimsz[i] = sz
	  endfor
	  if keyword_set(dims) then begin
	    tprint,' '
	    tprint,'     Dimensions'
	    for i=0,sf.ndims-1 do begin
	      tprint,'         ',i,'  Name: ',dimnam[i], $
	        '  Size: '+strtrim(dimsz[i],2)
	    endfor
	  endif
        endif
 
	;-----------------------------------------------------------
	;  Global attributes
	;-----------------------------------------------------------
	if keyword_set(gatt) then begin
	  tprint,' '
	  tprint,'     Global Attributes'
	  for i=0,sf.ngatts-1 do begin
	    attnam = ncdf_attname(fid,i,/global)
	    ncdf_attget,fid,/global,attnam,val
	    if datatype(val) eq 'BYT' then begin
	      txt = string(val)
	    endif else begin
	      txt = strtrim(val,2)
	    endelse
	    tprint,'         '+string(i)+'  '+attnam+': '+txt
	  endfor
	endif
 
	;-----------------------------------------------------------
	;  Variables
	;-----------------------------------------------------------
	if keyword_set(vars) then begin
	  vnam = strarr(sf.nvars)		; Variable names.
	  vdim = strarr(sf.nvars)		; Variable dimensions.
	  natt = intarr(sf.nvars)		; # variable attributes.
	  for i=0,sf.nvars-1 do begin
	    sv = ncdf_varinq(fid,i)		; Info on var i.
            if sv.ndims gt 0 then begin
	      dmsz = '('+commalist(dimsz[sv.dim])+')'
	      dmnm = '('+commalist((' '+dimnam)[sv.dim])+')'
	      txt = ''+sv.datatype+dmsz+' = '+sv.datatype+dmnm
            endif else begin
              ncdf_varget, fid, i, vval
              txt = ''+sv.datatype+'  '+strtrim(vval,2)
            endelse
	    vnam[i] = sv.name			; Var name.
	    vdim[i] = txt
	    natt[i] = sv.natts			; # attributes for var i.
	  endfor ; i
	  nspc = max(strlen(vnam))		; Max var name length.
	  tprint,' '
          if keyword_set(vatt) then begin
	    tprint,'     Variables and attributes'
          endif else begin
	    tprint,'     Variables'
          endelse
	  for i=0,sf.nvars-1 do begin		; Loop over variables.
	    tprint,'         '+string(i)+'  '+vnam[i]+':'+spc(nspc,vnam[i])+vdim[i]
	    if keyword_set(vatt) then begin	; List variable attributes.
	      for j=0,natt[i]-1 do begin	; Loop over var atts.
	        nm = ncdf_attname(fid,i,j)	; Att name.
	        ncdf_attget,fid,i,nm,val	; Att value.
	        if datatype(val) eq 'BYT' then val=string(val)
	        tprint,'                '+string(j)+'  '+nm+': '+string(val)
	      endfor ; j
	    endif
	  endfor ; i
	  tprint,' '
	endif ; vars
 
	ncdf_close, fid
	tprint,out=outtxt
	if not keyword_set(quiet) then tprint,/print
 
	end
