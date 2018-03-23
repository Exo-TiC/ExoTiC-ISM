;-------------------------------------------------------------
;+
; NAME:
;       CLRNAME
; PURPOSE:
;       Return a 24 bit color given a color name.
; CATEGORY:
; CALLING SEQUENCE:
;       clr = clrname(name)
; INPUTS:
;       name = Name of a color.        in
; KEYWORD PARAMETERS:
;       Keywords:
;         /LIST  List known color names.
;             help,clrname(0,/list)
; OUTPUTS:
;       clr = Returned 24-bit color.   out
; COMMON BLOCKS:
; NOTES:
;       Note: if name is unkown then middle gray is returned.
; MODIFICATION HISTORY:
;       R. Sterner, 2011 Jul 01
;
; Copyright (C) 2011, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
        function clrname, name0, list=lst, help=hlp
 
        if (n_params(0) eq 0 ) or keyword_set(hlp) then begin
          print,' Return a 24 bit color given a color name.'
          print,' clr = clrname(name)'
          print,'   name = Name of a color.        in'
          print,'   clr = Returned 24-bit color.   out'
          print,' Keywords:'
          print,'   /LIST  List known color names.'
          print,'       help,clrname(0,/list)'
          print,' Note: if name is unkown then middle gray is returned.'
          return,''
        endif
 
        ;---------------------------------------------------
        ;  Read in colors
        ;---------------------------------------------------
        whoami, dir
        f = filename(/nosym,dir,'colors.txt')
        txt = getfile(f,err=err)
        if err ne 0 then begin
          print,' Internal error in clrname: file not found: '+f
          return,tarclr(128,128,128)
        endif
        fr = ['  R   G   B   NAME',$
              '  B   B   B   S',$
              ' --- --- --- -------------------------------']
        txt = [fr,txt]          ; Add front end to text.
        s = txtdb_rd(txt)
 
        ;---------------------------------------------------
        ;  List colors
        ;---------------------------------------------------
        if keyword_set(lst) then begin
          more,txt
          return,''
        endif
 
        ;---------------------------------------------------
        ;  Process input color name
        ;---------------------------------------------------
        name = strlowcase(name0)              ; Force lower case.                              
        lo = 0                                ; Name starts at word 0.                 
        vflag = 0                             ; No verys.                                      
        sfact = 1.                            ; Saturation factor.                     
        vfact = 1.                            ; Value factor.                          
        vpos = wordpos(name,'very')           ; Look for very.                         
        if vpos ge 0 then lo = lo + 1         ;  Ignore very in color name.            
        if vpos lt 0 then vpos = 99                                                        
        dkpos = wordpos(name,'dark')          ; Look for dark.                         
        if dkpos ge 0 then begin              ; Process dark.                                  
          lo = lo + 1                         ; Ignore dark in color name.             
          vfact = .7                          ; Value factor for dark.                 
          if vpos eq (dkpos-1) then vfact=.3  ; Value factor for very dark.            
        endif                                                                          
        dlpos = wordpos(name,'pale')          ; Look for pale.                         
        if dlpos ge 0 then begin              ; Process dull.                                  
          lo = lo + 1                         ; Ignore pale in color name.             
          sfact = .5                          ; Saturation factor for pale.            
          if vpos eq (dlpos-1) then sfact=.3  ; Sat. fact. for very pale.              
        endif                                                                          
        name = getwrd(name,lo,9)              ; Ignore modifiers.                              
 
        ;---------------------------------------------------
        ;  Find color in list
        ;---------------------------------------------------
        w = where(s.name eq name, count)      ; Look up desired color.
        if count gt 0 then begin              ; Found it.
          rc = s.r[w[0]]                      ; Grab color rgb values.
          gc = s.g[w[0]]                                                                  
          bc = s.b[w[0]]                                                                  
          color_convert,/rgb_hsv, rc,gc,bc,h,s,v  ; Convert to H,S,V       
          s = s*sfact                         ; Handle dark and pale.                  
          v = v*vfact                                                                    
        endif else begin                      ; Color not found.
          print,' Error in clrname: Given color not found: '+name0
          print,'     Returning medium gray.'
          h = 0.0                             ; Return medium gray.
          s = 0.0
          v = 0.5
        endelse
 
        clr = tarclr(/hsv,h,s,v)
 
        return, clr
 
        end
