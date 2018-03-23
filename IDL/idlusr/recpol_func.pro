;-------------------------------------------------------------
;+
; NAME:
;       RECPOL_FUNC
; PURPOSE:
;       2-D rectangular coordinates to polar as a function.
; CATEGORY:
; CALLING SEQUENCE:
;       out = recpol_func(x,y)
; INPUTS:
;       x,y = Input x and y components.     in
;         Scalars or arrays.
; KEYWORD PARAMETERS:
;       Keywords:
;         /DEGREES Reurn directions in degrees, else radians.
;           Directions are angle from +X axis in CCW direction.
;         /MAG  Return magnitude.
;         /DIR  Return direction.
;           If only one of the above is used then the single
;           requested value is returned (may be a scalar or array).
;           If neither or both are given both values are returned
;           in a structure (def) or hash.  These keywords are used
;           to make this function return a single component for each
;           call.
;         /STRUCTURE  Return the requested values in a structure.
;           The tags will be MAG and DIR.
;         /HASH  Return the requested values in a hash.
;           The keys will be MAG and DIR.
; OUTPUTS:
;       out = Returned result.              out
;         May be a scalar, array, structure, or hash.
; COMMON BLOCKS:
; NOTES:
;       Notes: This function is similar to the recpol procedure
;       but can be used where a function is needed, such as in an
;       expression.  For such calls only one of /MAG or /DIR would
;       be used.
; MODIFICATION HISTORY:
;       R. Sterner, 2012 Sep 25
;
; Copyright (C) 2012, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
        function recpol_func, x, y, degrees=deg, mag=mag, dir=dir, $
          struct=struct, hash=hash, help=hlp
 
        if (n_params(0) lt 2) or keyword_set(hlp) then begin
          print,' 2-D rectangular coordinates to polar as a function.'
          print,' out = recpol_func(x,y)'
          print,'   x,y = Input x and y components.     in'
          print,'     Scalars or arrays.'
          print,'   out = Returned result.              out'
          print,'     May be a scalar, array, structure, or hash.'
          print,' Keywords:'
          print,'   /DEGREES Reurn directions in degrees, else radians.'
          print,'     Directions are angle from +X axis in CCW direction.'
          print,'   /MAG  Return magnitude.'
          print,'   /DIR  Return direction.'
          print,'     If only one of the above is used then the single'
          print,'     requested value is returned (may be a scalar or array).'
          print,'     If neither or both are given both values are returned'
          print,'     in a structure (def) or hash.  These keywords are used'
          print,'     to make this function return a single component for each'
          print,'     call.'
          print,'   /STRUCTURE  Return the requested values in a structure.'
          print,'     The tags will be MAG and DIR.'
          print,'   /HASH  Return the requested values in a hash.'
          print,'     The keys will be MAG and DIR.'
          print,'   Notes: This function is similar to the recpol procedure'
          print,'   but can be used where a function is needed, such as in an'
          print,'   expression.  For such calls only one of /MAG or /DIR would'
          print,'   be used.'
          return,''
        endif
 
        compile_opt idl2        ; hash(...) gives error without this.
 
        ;------------------------------------------------------
        ;  Determine what values to compute
        ;------------------------------------------------------
        flag_mag = keyword_set(mag)     ; 1 if /mag, else 0.
        flag_dir = keyword_set(dir)     ; 1 if /dir, else 0.
        if (flag_mag + flag_dir) eq 0 then begin
          flag_mag = 1                  ; Neither set, do both.
          flag_dir = 1
        endif
 
        ;------------------------------------------------------
        ;  Magnitude if requested
        ;------------------------------------------------------
        if flag_mag then begin
          r = sqrt(x^2 + y^2)
        endif
 
        ;------------------------------------------------------
        ;  Direction if requested
        ;
        ;  Direction is complicated because atan will not take
        ;  (0,0) and also want to keep direction in the range
        ;  0 to 360 (0 to 2*pi).
        ;------------------------------------------------------
        if flag_dir then begin
          if size(x,/type) eq 5 then pi=!dpi else pi=!pi ; Double or float?
          w = where((x ne 0) or (y ne 0), cnt)  ; Where not both x,y eq 0.
          a = x*0.                              ; Output direction array.
          if cnt gt 0 then a[w]=atan(y[w],x[w]) ; Find directions.
          w = where(a lt 0,cnt)                 ; Find a LT 0.
          if cnt gt 0 then a[w]=a[w]+2*pi       ; Keep in positive range.
          if keyword_set(deg) then a=a*180/pi   ; Convert to degrees.
        endif
 
        ;------------------------------------------------------
        ;  Determine return type
        ;------------------------------------------------------
        typ = 1                                 ; Assume single function value.
        if keyword_set(struct) then typ=2       ; Return in a structure.
        if keyword_set(hash)   then typ=3       ; Return in a hash.
        if (typ eq 1) and ((flag_mag+flag_dir) eq 2) then typ=2  ; Struct.
 
        ;------------------------------------------------------
        ;  Return value(s)
        ;------------------------------------------------------
        case typ of
        ;---  Single function value  ---
1:      begin
          if flag_mag then return, r
          if flag_dir then return, a
        end
        ;---  Structure  ---
2:      begin
          out = {count:n_elements(x)}
          if flag_mag then out=create_struct(out,'MAG',r)
          if flag_dir then out=create_struct(out,'DIR',a)
          return, out
        end
        ;---  Hash  ---
3:      begin
          out = hash('count',n_elements(x))     ; Start hash.
          if flag_mag then out['MAG']=r
          if flag_dir then out['DIR']=a
          return, out
        end
        endcase
 
        end
