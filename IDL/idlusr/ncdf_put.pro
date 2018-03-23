;-------------------------------------------------------------
;+
; NAME:
;       NCDF_PUT
; PURPOSE:
;       Write given data to a NetCDF file.
; CATEGORY:
; CALLING SEQUENCE:
;       ncdf_put, file
; INPUTS:
;       file = Name of NetCDF file to write or add to.  in
; KEYWORD PARAMETERS:
;       Keywords:
;         GATT=gatt  Global attributes in a hash or structure.
;            Attributes must be scalars or 1-D arrays (no text arrays).
;         VARIABLES=var  Data variables in a hash or structure.
;         /NEW Start a new NetCDF file if file exists.
;         ERROR=err Error flag, 0=ok.
;         ERR_TXT=err_txt Error text.
;         /DETAILS gives details of inputs to this routine:
;           ncdf_put,/details
;         /VERBOSE list processing steps.
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
;       Notes: a fairly simple call can be used with this routine.
;            gatt = {lon:'27.2 W', lat:'13.1 N', hgt:'3.8 km'}
;            var = {azi:'283.4 deg',alt:'-8.9 deg',fl:'300 mm', $
;                   img:bytarr(640,480),time:systime()}
;            ncdf_put,'image.nc',var=var,gatt=gatt
;        Check the created file:
;            ncdf_list,'image.nc',/gatt,/var
;        Read in the data:
;            ncdf_get,'image.nc',['AZI','ALT','IMG','FL','TIME'],gatt=gg,s,/struct
;        See the details using /DETAILS if dimensions or attributes
;        are needed.  In this case the setup will be more complex
;        and will involve nested hashes or structures.
; MODIFICATION HISTORY:
;       R. Sterner, 2012 Jan 03
;       R. Sterner, 2012 Jun 22 --- Changing from structures to hashes.
;       R. Sterner, 2012 Jun 25 --- Renamed from netcdf_write.pro.
;       R. Sterner, 2012 Jun 26 --- Got working.
;       R. Sterner, 2012 Jun 27 --- Handled text strings.
;       R. Sterner, 2012 Aug 07 --- Allowed structures or hashes as inputs.
;       R. Sterner, 2013 Jan 14 --- Forced structure keys to lower case.
;       R. Sterner, 2013 Jan 14 --- Fixed case of existing file with no dims.
;       R. Sterner, 2013 Mar 08 --- Fixed typo in /details text.
;       R. Sterner, 2013 Mar 18 --- Automatically add 1st dim of text array.
;       R. Sterner, 2013 Mar 19 --- Text arrays can have any dimensions now.
;
; Copyright (C) 2012, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
        pro ncdf_put, file, gatt=gatt0, variables=var0, verbose=verb, $
          new=new0, details=details, error=err, err_txt=err_txt, help=hlp
 
        if keyword_set(hlp) then begin
hlp:      print,' Write given data to a NetCDF file.'
          print,' ncdf_put, file'
          print,'   file = Name of NetCDF file to write or add to.  in'
          print,' Keywords:'
          print,'   GATT=gatt  Global attributes in a hash or structure.'
          print,'      Attributes must be scalars or 1-D arrays (no text arrays).'
          print,'   VARIABLES=var  Data variables in a hash or structure.'
          print,'          var = hash(name1, value1, name2, value2, ...)'
          print,'             or {name1:value1, name2:value2, ...}'
          print,'   /NEW Start a new NetCDF file if file exists.'
          print,'   ERROR=err Error flag, 0=ok.'
          print,'   ERR_TXT=err_txt Error text.'
          print,'   /DETAILS gives details of inputs to this routine:'
          print,"     ncdf_put,/details"
          print,'   /VERBOSE list processing steps.'
          print,' Notes: a fairly simple call can be used with this routine.'
          print,"      gatt = {lon:'27.2 W', lat:'13.1 N', hgt:'3.8 km'}"
          print,"      var = {azi:'283.4 deg',alt:'-8.9 deg',fl:'300 mm', $"
          print,'             img:bytarr(640,480),time:systime()}'
          print,"      ncdf_put,'image.nc',var=var,gatt=gatt"
          print,'  Check the created file:'
          print,"      ncdf_list,'image.nc',/gatt,/var"
          print,'  Read in the data:'
          print,"      ncdf_get,'image.nc',['AZI','ALT','IMG','FL','TIME'],gatt=gg,s,/struct"
          print,'  See the details using /DETAILS if dimensions or attributes'
          print,'  are needed.  In this case the setup will be more complex'
          print,'  and will involve nested hashes or structures.'
          return
        endif
 
        ;---------------------------------------------------------
        ;  Give details on input formats
        ;---------------------------------------------------------
        if keyword_set(details) then begin
          text_block, txt
;
;        A NetCDF file contains variables and optional global attributes.
;
;        ncdf_put will create a new NetCDF file if the given file does not
;        exist, or add to it if it does.  Both global attributes and/or
;        new variables may be added to an existing file.
;
;        A NetCDF variable has a name, a value, and some number of attributes.
;          The variable name is case sensitive.
;          The value may be a scalar or an array.  If an array it will have dimensions
;            which have names and sizes.
;          The attributes have names and values.
;
;        Variable Hash or Structure layout
;          NetCDF variable names are case sensitive so a hash is used to contain them.
;          If case does not matter then a structure may be used instead of a hash but
;          all structure tags will be forced lower case.
;
;          variables = hash(name1, value1, name2, value2, ...)
;                    or {name1:value1, name2:value2, ...}
;            name1 is the name of variable 1 (and the hash key to access it).
;            value1 may be just the simple value itself if dimensions or
;              attributes are not needed.  If they are needed then
;            value1 will be a hash or structure with (assumed lower case):
;              value: value_of_variable,
;              dim_names:  String array: [nm1, nm2, ...],
;              dim_sizes:  Long array: [sz1, sz2, ...],
;              attributes: Hash or Structure: hash(att_tag1, att_value1, att_tag2, att_value2, ...)
;                                          or {att_tag1:att_value1, att_tag2:att_value2, ...}
;            Note: dim_names, dim_sizes, and attributes are optional.  If dimensions
;            are not given the dimension names will default to name1_dim1,
;            name1_dim2, ...  and the sizes will be set from the array size.
;            If the value is a scalar the dimension info is not needed and ignored.
;
;         Global Attributes
;               gatt = hash(gatt_tag1, gatt_value1, gatt_tag2, gatt_value2, ...)
;                    or {gatt_tag1:gatt_value1, gatt_tag2:gatt_value2, ...}
;
;       Variables may be multidimensional.
;       Attributes are all either scalars (single-valued) or vectors (a single, fixed dimension).
;       That means an attribute may not be a text array which in NetCDF is 2-D.
;
 
          return
        endif
 
        ;---------------------------------------------------------
        ;  Display help if no args given
        ;---------------------------------------------------------
        flag = 0                                ; Any args given?
        if n_elements(gatt0) ne 0 then flag=1
        if n_elements(var0)  ne 0 then flag=1
        if flag eq 0 then goto, hlp
 
        ;---------------------------------------------------------
        ;  Initialize
        ;---------------------------------------------------------
        err = 0
        err_txt = ''
        if keyword_set(verb) then begin
          print,' '
          print,' Writing to NetCDF file '+file
        endif
 
        ;---------------------------------------------------------
        ;  Check if file exists
        ;---------------------------------------------------------
        f = file_search(file, count=cnt)        ; Look for file.
        if cnt eq 0 then new=1                  ; No such file, new.
        if n_elements(new0) ne 0 then new=new0
 
        ;---------------------------------------------------------
        ;  Open new or existing file
        ;---------------------------------------------------------
        if keyword_set(new) then begin
          if keyword_set(verb) then print,' Create new file.'
          fido = ncdf_create(file,/clobber)     ; Open new file in define mode.
          dimlist = ['']                        ; Existing dimensions.
          ndims = 0                             ; No dimensions yet.
        endif else begin
          if keyword_set(verb) then print,' Add to existing file.'
          fido = ncdf_open(file,/write)         ; Open existing file.
          ss = ncdf_inquire(fido)               ; Grab info for existing file.
          ndims = ss.ndims                      ; # dimensions in the file.
          if keyword_set(verb) then print,'   Dimensions found: ',ndims
          if ndims gt 0 then begin              ; Get existing dimensions.
            dimlist = strarr(ndims)             ; Space for dimensions.
            for i = 0, ndims-1 do begin         ; Loop over dimensions.
              ncdf_diminq,fido,i,nam,sz         ; Get name and size of dim i.
              dimlist[i] = nam                  ; Save dimension name.
            endfor
          endif else begin                      ; No existing dimensions yet.
            dimlist = ['']                      ; Dimensions array.
            ndims = 0                           ; No dimensions yet.
          endelse
          ncdf_control, fido, /redef            ; Get into define mode.
        endelse
 
        ;=========================================================
        ;  Write any given Global Attributes to the file
        ;=========================================================
        if n_elements(gatt0) ne 0 then begin    ; Any Global Attributes given?
          if size(gatt0,/typ) eq 8 then begin   ; gatt0 was a strutcure.
            gatt = hash_from_struct(gatt0,/low) ; Convert structure to hash.
          endif else gatt=gatt0                 ; gatt0 was a hash.
          ng = gatt.count()                     ; Yes, how many?
          gkey = gatt.keys()                    ; Get hash keys.
          if keyword_set(verb) then print,' Writing global attributes: ',ng
          for i=0,ng-1 do begin                 ; Loop over Global Attributes.
            key = gkey[i]                       ; i'th key.
            val = gatt[key]                     ; i'th value.
            ncdf_attput,fido,/global,key,val    ; Write Global Attribute to file.
          endfor
          flag = 1                              ; Processing done.
        endif
        ;=========================================================
        ;  End write any given Global Attributes to the file
        ;=========================================================
 
        ;=========================================================
        ;  Write any given Variables to the file
        ;=========================================================
        if n_elements(var0) ne 0 then begin     ; Any Variables given?
          if size(var0,/typ) eq 8 then begin    ; var0 was a strutcure.
            var = hash_from_struct(var0,/low)   ; Convert structure to hash.
          endif else var=var0                   ; var0 was a hash.
          nv = var.count()                      ; Yes, Number of variables.
          vkey = var.keys()                     ; Variable names (= hash keys).
          if keyword_set(verb) then print,' Variables found: ',nv
 
          ;---------------------------------------------------------
          ;  Loop over variables
          ;---------------------------------------------------------
          for i=0,nv-1 do begin                   ; Loop over Variables.
 
            key = vkey[i]                         ; Variable name (i'th key).
            val = var[key]                        ; i'th value (hash for variable).
            if typename(val) ne 'HASH' then begin ; Not a hash, assume value.
              vval = val                          ; Was just the value.
            endif else begin                      ; Was a hash.
              vval = val['value']                 ; The actual value (array).
            endelse
            typ = datatype(vval)                  ; Data type of variable.
            if typ eq 'STR' then vval=byte(vval)  ; Save text as char array.
            scalar_flag = size(vval,/n_dim) eq 0  ; Scalar variable? 1=yes.
            if keyword_set(verb) then begin
              print,'   Variable name: ',key
              print,'   Variable type: ',typ
              print,'   Scalar_flag: ',scalar_flag
            endif
 
            ;--------------  Scalar Variables  -----------------------
            if scalar_flag eq 1 then begin
              ;---------------------------------------------------------
              ;  Define a scalar variable
              ;
              ;  Dimensions are not needed for scalars and should not
              ;  be given, they are ignored if given.
              ;---------------------------------------------------------
              if keyword_set(verb) then print,'     Defining scalar variable.'
              case typ of                      ; Set variable data type.
'BYT':          vid = ncdf_vardef(fido,key,/byte)
'STR':          vid = ncdf_vardef(fido,key,/char)
'DOU':          vid = ncdf_vardef(fido,key,/double)
'FLO':          vid = ncdf_vardef(fido,key,/float)
'LON':          vid = ncdf_vardef(fido,key,/long)
'INT':          vid = ncdf_vardef(fido,key,/short)
'ULL':          vid = ncdf_vardef(fido,key,/uint64)
'ULO':          vid = ncdf_vardef(fido,key,/ulong)
'UIN':          vid = ncdf_vardef(fido,key,/ushort)
 else:          stop,' Unsupported data type for '+key+': ',typ
              endcase ; typ
 
              if vid eq -1 then begin          ; Could not create variable.
                err_txt = [err_txt,' Could not create variable (skipped): '+key]
                continue
              endif ; vid
 
            ;--------------  End Scalar Variables  -------------------
            endif else begin ; scalar_flag
            ;--------------  Array Variables  ------------------------
              ;---------------------------------------------------------
              ;  Define any new dimensions
              ;
              ;  val is the hash for the i'th variable and contains
              ;    the actual value (array), the dimension names and
              ;    sizes, and any attributes.  If the dimension info
              ;    is not given then add default names along with the
              ;    dimension sizes, to the val hash.
              ;---------------------------------------------------------
              ;---  Look for dimensions info  ---
              if keyword_set(verb) then print,'     Looking for dimensions.'
              if typename(val) eq 'HASH' then begin
                flag_nm = val.haskey('dim_names')     ; Any dimensions given?
                flag_sz = val.haskey('dim_sizes')     ; Any sizes given?
              endif else begin
                flag_nm = 0
                flag_sz = 0
                val = hash('value',vval)              ; Convert val to a hash.
              endelse
              ;---  Dimension info given incorrectly  ---
              if flag_nm ne flag_sz then begin      ; Mismatch.
                txt = [' Error in ncdf_write: Variable '+key+' must have both', $
                       '   dim_names and dim_sizes given and the same length.', $
                       '   Or given no dimension info and use defaults.', $
                       '   Write failed.']
                more,txt
                err_txt = [err_txt, txt]
                err = 1
                return
              endif ; flag_nm
              ;---  If no dimension info then make defaults  ---
              if flag_nm eq 0 then begin
                dim_sz = size(vval,/dim)          ; Array with dimension sizes.
                dim_nm = key + '_dim' + makes(1,size(vval,/n_dim),1,dig=1)
                val = val + hash('dim_names',dim_nm,'dim_sizes',dim_sz)
              endif ; flag_nm
              ;---  Look at dimensions of variable, define any new ones  ---
              dims = val['dim_names']
              sz   = val['dim_sizes']
              ;---  Handle string arrays  ---
              if typ eq 'STR' then begin
                if n_elements(dims) eq size(vval,/n_dim)-1 then begin
                  dim1_nm = key + '_dim1'         ; 1st dim name.
                  dim1_sz = max(strlen(vval))     ; 1st dim size.
                  dims = [dim1_nm,dims] ; Automatically add string max width.
                  sz   = [dim1_sz,  sz]
                endif
              endif
              ;---  Loop over dimensions, define new ones  ---
              for j=0,n_elements(dims)-1 do begin ; Loop over i'th Var dims.
                dm = dims[j]                      ; Next dimension for i'th var.
                w = where(dimlist eq dm, cnt)     ; Is it known?
                if cnt eq 0 then begin            ; No, it is new.
                  id = ncdf_dimdef(fido,dm,sz[j]) ; Define it.
                endif ; cnt
              endfor ; j
 
              ;---------------------------------------------------------
              ;  Define an array variable
              ;
              ;  dims is an array of dimension names for i'th variable.
              ;  Get IDs of each dimension of the variable:
              ;    dim_id = ncdf_dimid(fido,dim_name)   ; Get dim id given name.
              ;  Define variable:
              ;    v_id = ncdf_vardef(fido,vname,[dim_id1,dim_id2,...],</type>)
              ;---------------------------------------------------------
              ndims = n_elements(dims)         ; # dimensions in the i'th var.
              dim_id = lonarr(ndims)           ; Space for dim IDs.
              for j=0,ndims-1 do dim_id[j]=ncdf_dimid(fido,dims[j]) ; Get IDs.
              if keyword_set(verb) then print,'     Defining array variable.'
 
              case typ of                      ; Set variable data type.
'BYT':          vid = ncdf_vardef(fido,key,dim_id,/byte)
'STR':          vid = ncdf_vardef(fido,key,dim_id,/char)
'DOU':          vid = ncdf_vardef(fido,key,dim_id,/double)
'FLO':          vid = ncdf_vardef(fido,key,dim_id,/float)
'LON':          vid = ncdf_vardef(fido,key,dim_id,/long)
'INT':          vid = ncdf_vardef(fido,key,dim_id,/short)
'ULL':          vid = ncdf_vardef(fido,key,dim_id,/uint64)
'ULO':          vid = ncdf_vardef(fido,key,dim_id,/ulong)
'UIN':          vid = ncdf_vardef(fido,key,dim_id,/ushort)
 else:          stop,' Unsupported data type for '+key+': ',typ
              endcase ; typ
 
              if vid eq -1 then begin          ; Could not create variable.
                err_txt = [err_txt,' Could not create variable (skipped): '+key]
                continue
              endif ; vid
            endelse ; scalar_flag
            ;--------------  End Array Variables  --------------------
            
            ;---------------------------------------------------------
            ;  Write any variable attributes
            ;---------------------------------------------------------
            att_flag = 0                                ; Assume no attributes.
            if typename(val) eq 'HASH' then begin       ; Is val a hash?
              if val.haskey('attributes') then att_flag=1 ; Yes, any attributes?
            endif
            if att_flag eq 1 then begin                 ; Any attributes given?
              if keyword_set(verb) then print,'     Writing variable attributes.'
              att = val['attributes']                   ; Grab them.
              na = att.count()                          ; Number of attributes.
              akeys = att.keys()                        ; Get all attribute keys.
              for j=0,na-1 do begin                     ; Loop over attributes.
                aval = att[akeys[j]]                    ; j'th attribute value.
                typ = datatype(aval)                    ; Data type for attr value.
                case typ of                             ; Where is Long64? STR=CHAR?
'BYT':            ncdf_attput,fido,vid,akeys[j],aval,/byte
'STR':            ncdf_attput,fido,vid,akeys[j],aval,/char
'DOU':            ncdf_attput,fido,vid,akeys[j],aval,/double
'FLO':            ncdf_attput,fido,vid,akeys[j],aval,/float
'LON':            ncdf_attput,fido,vid,akeys[j],aval,/long
'INT':            ncdf_attput,fido,vid,akeys[j],aval,/short
'ULL':            ncdf_attput,fido,vid,akeys[j],aval,/uint64
'ULO':            ncdf_attput,fido,vid,akeys[j],aval,/ulong
'UIN':            ncdf_attput,fido,vid,akeys[j],aval,/ushort
else:             stop,' Unsupported attribute type in ncdf_put: '+typ
                endcase ; typ
              endfor ; j
            endif ; Variable attributes.
 
            ;---------------------------------------------------------
            ;  Exit define mode and actually write variables
            ;---------------------------------------------------------
            if keyword_set(verb) then print,'     Writing variable value.'
            ncdf_control, fido, /endef          ; End define mode.
            ncdf_varput, fido, vid, vval        ; Write variable data.
            ncdf_control, fido, /redef          ; Ready for next variable.
 
          endfor ; i (Loop over variables)
          ;---------------------------------------------------------
          ;  End loop over variables
          ;---------------------------------------------------------
 
          flag = 1                              ; Processing done.
        endif ; Any variables?
        ;=========================================================
        ;  End write any given Variables to the file
        ;=========================================================
 
        if flag eq 0 then goto, hlp
 
        ncdf_close, fido                        ; Close file.
 
        if keyword_set(verb) then begin
          print,' NetCDF file complete: '+file
          print,' '
        endif
 
        end
