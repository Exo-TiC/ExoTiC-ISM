;-------------------------------------------------------------
;+
; NAME:
;       NCDF_GET
; PURPOSE:
;       Get a set of variables from a NetCDF file.
; CATEGORY:
; CALLING SEQUENCE:
;       ncdf_get, file, list, out
; INPUTS:
;       file = Name of NetCDF file.                       in
;       list = Array of variable names.                   in
;         May contain regular expressions.
;         May also contain aliases, other names the
;         variable may go by.  Give as a string with the
;         names separated by spaces.  The first name will
;         be the output name.  Example:
;         'U_10m UGRD_10maboveground U_GRD_3_MWSL_10'
;         where either UGRD_10maboveground or
;         U_GRD_3_MWSL_10 will be returned as U_10m,
;         whichever is found first in the file.
;         If neither is found then U_10m is added to the
;         array of missing variables.
; KEYWORD PARAMETERS:
;       Keywords:
;         GATT=gatt Return Global Attributes in hash gatt.
;           !NULL if none.
;         /STRUCT Convert outputs to structures instead of hashes.
;         /QUIET inhibit some messages.
;         ERROR=err  Error flag: 0=ok.
;           If err GT 0 then it is the number of missing variables.
;           Some NC errors:
;             -31: File not found.
;             -51: File not NetCDF.
;         MISSING=miss Return an array of missing variables
;           names (requested but not found).
;         FOUND=fnd Return an array of found variables.
; OUTPUTS:
;       out = Returned a hash of requested items.         out
;         !NULL if none.
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 2012 Jun 11 from wrf_varget.pro in IDLWRF.
;       R. Sterner, 2012 Jun 27 --- Renamed from ncdf_getvar.pro and used hashes.
;       R. Sterner, 2012 Jun 29 --- Added GATT=gatt, /STRUCT.
;       R. Sterner, 2012 Aug 15 --- Allowed regular expressions in list.
;       R. Sterner, 2012 Oct 01 --- Added an error handler.
;       R. Sterner, 2012 Oct 01 --- Counted # missing vars in err.
;       R. Sterner, 2012 Oct 08 --- Allowed multi-possible var names (aliases).
;       R. Sterner, 2012 Oct 24 --- Returned an array of found variables.
;
; Copyright (C) 2012, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro ncdf_get, file, list0, out, quiet=quiet, gatt=gatt, $
            missing=miss, found=fnd, error=err, struct=struct, help=hlp
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
hlp:	  print,' Get a set of variables from a NetCDF file.'
	  print,' ncdf_get, file, list, out'
	  print,'   file = Name of NetCDF file.                       in'
	  print,'   list = Array of variable names.                   in'
          print,'     May contain regular expressions.'
          print,'     May also contain aliases, other names the'
          print,'     variable may go by.  Give as a string with the'
          print,'     names separated by spaces.  The first name will'
          print,'     be the output name.  Example:'
          print,"     'U_10m UGRD_10maboveground U_GRD_3_MWSL_10'"
          print,'     where either UGRD_10maboveground or'
          print,'     U_GRD_3_MWSL_10 will be returned as U_10m,'
          print,'     whichever is found first in the file.'
          print,'     If neither is found then U_10m is added to the'
          print,'     array of missing variables.'
	  print,'   out = Returned a hash of requested items.         out'
          print,'     !NULL if none.'
	  print,' Keywords:'
          print,'   GATT=gatt Return Global Attributes in hash gatt.'
          print,'     !NULL if none.'
          print,'   /STRUCT Convert outputs to structures instead of hashes.'
	  print,'   /QUIET inhibit some messages.'
	  print,'   ERROR=err  Error flag: 0=ok.'
          print,'     If err GT 0 then it is the number of missing variables.'
          print,'     Some NC errors:'
          print,'       -31: File not found.'
          print,'       -51: File not NetCDF.'
	  print,'   MISSING=miss Return an array of missing variables'
	  print,'     names (requested but not found).'
	  print,'   FOUND=fnd Return an array of found variables.'
	  return
	endif
 
	;------------------------------------------------------------------
        ;  Set up an error handler
	;------------------------------------------------------------------
        catch, error_status             ; error_status set to 0 here.
 
        if error_status ne 0 then begin ; Any error below jumps here.
          err = (getwrd(!error_state.msg,del='=',1)+0)<(-1)
          if keyword_set(quiet) then return
          print,' Error in ncdf_get: '+!error_state.msg
          if err eq -31 then print,'   File not found: '+file
          if err eq -51 then print,'   File not NetCDF: '+file
          return
        endif
 
	;------------------------------------------------------------------
        ;  Open NetCDF file
	;------------------------------------------------------------------
	fid = ncdf_open(file)		; Open ncdf file.        
	sf = ncdf_inquire(fid)		; Get file info.
        err = 0
        out = !null
        gatt = !null
        miss = ''
        fnd = ''
 
	;------------------------------------------------------------------
        ;  Deal with global attributes
	;------------------------------------------------------------------
        if arg_present(gatt) then begin                 ; Global atts requested?
 
          if sf.ngatts eq 0 then $
              if not keyword_set(quiet) then print,' No Global Attributes.'
 
          for i=0,sf.ngatts-1 do begin                  ; Yes, loop over them.
 
            attnam = ncdf_attname(fid,i,/global)        ; Get global att name.
            ncdf_attget,fid,/global,attnam,attval       ; Get value.
            sa = ncdf_attinq(fid,attnam,/global)        ; Get type.
            if sa.datatype eq 'CHAR' then attval=string(attval)
 
            if i eq 0 then begin                        ; If first
              gatt = hash(attnam,attval)                ;   Start hash.
            endif else begin
              gatt = gatt + hash(attnam,attval)         ; else just add it.
            endelse
 
          endfor ; i
 
          ;---  Convert to struct here if requested  ---
          if keyword_set(struct) then gatt=hash_to_struct(gatt)
 
        endif
 
        if n_elements(list0) eq 0 then goto, done
 
	;------------------------------------------------------------------
	;  Get dimensions
	;------------------------------------------------------------------
	dim_sz = lonarr(sf.ndims)	; For dimension sizes.
	dim_nm = strarr(sf.ndims)	; For dimension names.
	for i=0,sf.ndims-1 do begin
	  ncdf_diminq, fid, i, nam, sz
	  dim_sz[i] = sz
	  dim_nm[i] = nam
	endfor
 
	;------------------------------------------------------------------
        ;  Preprocess list of variables if regular expressions used
	;------------------------------------------------------------------
        r = stregex(list0,'[]*.+()\?{^$[]')     ; Look for regular expressions.
        if max(r) ge 0 then begin               ; Any regular expressions?
          ncdf_list,file,/var,/q,vname=vnam     ; Get all variable names.
          for i=0,n_elements(list0)-1 do begin  ; Yes.
            strfind,vnam,list0[i],out=t,/q      ; Expand regular expression.
            if i eq 0 then list=t else list=[list,t]
          endfor ; i
        endif else list=list0                   ; No.
 
	;------------------------------------------------------------------
	;  Loop over requested variables
	;------------------------------------------------------------------
	out = hash('created',created())  ; Initialize output structure.
 
	;========  Start of loop over requested variables  ========
	for ivar=0,n_elements(list)-1 do begin	; Loop over requested vars.
 
	  nams = list[ivar]			; Variable name.

;;###########################################################
;	  ;------------------------------------------------
;          ;  Deal with an External Virtual Variable
;          ;
;          ;  Name will start with *, like *wind10m.
;          ;  Will call a routine to get the external
;          ;  virtual variable, the routine call will be:
;          ;    ncdf_get_xvv_wind10m, file, out
;          ;  with the wind10m variable or variables returned
;          ;  in out.  For each variable returned include:
;          ;    value: value_of_variable
;          ;    dim_names: text array of dimension names.
;          ;    dim_sizes: text array of dimension sizes.
;          ;    attributes: hash with attributes of var:
;          ;      att_name1: att_value1
;          ;      att_name2: att_value2
;          ;      ...
;	  ;------------------------------------------------
;          if strmid(nams,0,1) eq '*' then begin
;            rtn = 'ncdf_get_xvv_' + strmid(nams,1)  ; Build routine name.
;            ;####  Set up a catch error handler here  ####
;            ;####  to catch if no such routine.       ####
;            call_procedure,rtn,file,s2, $           ; Call external vv routine
;              error=err, quiet=quiet
;	    if err ne 0 then begin                  ; No such variale.
;	      if miss[0] eq '' then miss=[nams] else miss=[miss,nams]
;	      if not keyword_set(quiet) then $
;	        print,' Error in ncdf_get: No such variable: '+nams
;	      continue
;	    endif
;            ;---  Add to output hash  ---
;            out = out + hash(strmid(nams,1),val)
;            continue
;          endif
;;###########################################################


	  ;------------------------------------------------
          ;  Deal with aliases
	  ;------------------------------------------------
          if nwrds(nams) gt 1 then begin        ; Split first word from rest.
            nam0 = getwrd(nams)                 ; First word = output name.
            nam1 = getwrd(nams,1,99)            ; Rest of words = aliases.
          endif else begin                      ; Only one word, use it.
            nam0 = nams
            nam1 = nams
          endelse
 
	  ;------------------------------------------------
	  ;  Check if already in output structure
          ;    Ignores accidental repeats
	  ;------------------------------------------------
          if out.haskey(nam0) then continue     ; If variable there skip to next.
 
	  ;------------------------------------------------
	  ;  Get variable
          ;
          ;  Get dimension names, dimension sizes,
          ;  variable value, and variable attributes.
          ;
          ;  Variable attributes are packed in a hash.
          ;  Variable value is a hash with
          ;     Value, dimension_names, dimension_sizes,
          ;     Attributes_hash
          ;  All requested variables are returned in a
          ;     hash with each variable name and the
          ;     value hash.
	  ;------------------------------------------------
	  ;---  Check if exists  ---
          for in=0, nwrds(nam1)-1 do begin      ; Loop over aliases (if any).
            nam = getwrd(nam1,in)               ; Grab next alias.
	    vid = ncdf_varid(fid,nam)		; Get var id from name.
;            if vid ge 0 then break
            if vid ge 0 then begin              ; Good ID, break search loop.
	      if fnd[0] eq '' then fnd=[nam0] else fnd=[fnd,nam0]
              break
            endif
          endfor ; in
 
	  if vid eq -1 then begin		; No such variable.
	    if miss[0] eq '' then miss=[nam0] else miss=[miss,nam0]
            err = err + 1                       ; Count missing variable.
	    if not keyword_set(quiet) then $
	      print,' Error in ncdf_get: No such variable: '+nam0
	    continue
	  endif
 
	  ;---  Get variable info  ---
	  sv = ncdf_varinq(fid,nam)		; Get var info.
	  dim_names = dim_nm[sv.dim]		; Array dimension names.
          dim_sizes = dim_sz[sv.dim]            ; Array dimension sizes.
	  dmsz = '('+commalist(dim_sizes)+')'   ; Dimensions.
          if sv.ndims gt 0 then begin
	    txt = ': '+sv.datatype+dmsz		; Dimensions.
          endif else begin
	    txt = ': '+sv.datatype
          endelse
	  ;---  Read variable  ---
	  if not keyword_set(quiet) then print,' Reading '+nam+txt+' . . .'
	  ncdf_varget, fid, vid, val		; Read variable from file.
          if sv.datatype eq 'CHAR' then val=string(val)
 
	  ;---  Get variable attributes  ---
          att_hash = hash('var_name',nam)       ; Save variable name used.
 
          for j=0,sv.natts-1 do begin
            attnam = ncdf_attname(fid,vid,j)
            ncdf_attget,fid,vid,attnam,attval
            att = ncdf_attinq(fid,vid,attnam)
            if att.datatype eq 'CHAR' then attval=string(attval)
            att_hash = att_hash + hash(attnam,attval)
          endfor
 
          ;---  Pack items for the variable into a hash  ---
          val = hash('value',val,'dim_names',dim_names,'dim_sizes',dim_sizes, $
                     'attributes',att_hash)
 
	  ;---  Pack into output hash  ---
          out = out + hash(nam0,val)
 
	endfor ; ivar
	;========  End of loop over requested variables  ========
 
 
	;------------------------------------------------------------------
        ;  Finish
	;------------------------------------------------------------------
done:
	ncdf_close, fid				; Close NetCDF file.
 
        if out eq !null then return
 
	if out.count() le 1 then begin          ; Hash has only 1 item.
          out = !null
	endif else begin
          ;---  Convert to stucture here if requested  ---
          if keyword_set(struct) then out=hash_to_struct(out)
        endelse
 
	end
