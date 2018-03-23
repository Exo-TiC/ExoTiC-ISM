;-------------------------------------------------------------
;+
; NAME:
;       IMG_MERGE
; PURPOSE:
;       Merge color components into a 24-bit color image.
; CATEGORY:
; CALLING SEQUENCE:
;       img = img_merge(c1, c2, c3)
; INPUTS:
;       c1 = color component 1.   in
;       c2 = color component 2.   in
;       c3 = color component 3.   in
; KEYWORD PARAMETERS:
;       Keywords:
;         /HSV means color components are HSV (def RGB).
;         TRUE=tr Specify dimension to interleave (1, 2, or 3=def).
;           For tr=0 the first component is returned (avoid /HSV).
;         NX=nx, NY=ny Returned image dimensions.
;         ALPHA=a Give an alpha channel (def=none).
;           0 is full transparency, 255 is no transparency.
;         ERROR=err error flag: 0=ok, 1=input not 2-D, 3=# dimension vary.
; OUTPUTS:
;       img = Output image.       out
;          By default c1,c2,c3 = Red, Green, Blue.
;          /HSV means c1, c2, c3 =  Hue, Saturation, Value.
; COMMON BLOCKS:
; NOTES:
;       Note: input color components are 2-D.
;         1-D arrays are treated like a NX x 1 arrays.
;         1-D color arrays may require a trailing dimension of 1.
;       
;         The alpha channel is a byte array with the same dimensions
;         as the image components.  It may be used to control the
;         image transparency and may be set from 0 (image is
;         completely transparent at that point so not visible) to 255
;         (image is not transparent at that point so completely
;         visible) or anywhere in between.  To save the result as a
;         PNG image make sure to use TRUE=1 (default if an alpha is
;         given).  The result will be bytarr[4,nx,ny] and may be
;         saved using the IDL routine write_png:
;             write_png, filename, img
; MODIFICATION HISTORY:
;       R. Sterner, 2001 Jun 21
;       R. Sterner, 2009 Jul 15 --- Handled true=0 case.
;       R. Sterner, 2010 May 04 --- Converted arrays from () to [].
;       R. Sterner, 2010 Sep 08 --- Now allows 1-D arrays.
;       R. Sterner, 2011 May 12 --- Handled Alpha channel.
;
; Copyright (C) 2001, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	function img_merge, c1, c2, c3, true=typ, nx=nx, ny=ny, $
	  hsv=hsv, alpha=a, error=err, help=hlp
 
	if (n_params(0) lt 3) or keyword_set(hlp) then begin
	  print,' Merge color components into a 24-bit color image.'
	  print,' img = img_merge(c1, c2, c3)'
	  print,'   c1 = color component 1.   in'
	  print,'   c2 = color component 2.   in'
	  print,'   c3 = color component 3.   in'
	  print,'   img = Output image.       out'
	  print,'      By default c1,c2,c3 = Red, Green, Blue.'
	  print,'      /HSV means c1, c2, c3 =  Hue, Saturation, Value.'
	  print,' Keywords:'
	  print,'   /HSV means color components are HSV (def RGB).'
	  print,'   TRUE=tr Specify dimension to interleave (1, 2, or 3=def).'
	  print,'     For tr=0 the first component is returned (avoid /HSV).'
	  print,'   NX=nx, NY=ny Returned image dimensions.'
          print,'   ALPHA=a Give an alpha channel (def=none).'
          print,'     0 is full transparency, 255 is no transparency.'
	  print,'   ERROR=err error flag: 0=ok, 1=input not 2-D, 3=# dimension vary.'
	  print,' Note: input color components are 2-D.'
          print,'   1-D arrays are treated like a NX x 1 arrays.'
          print,'   1-D color arrays may require a trailing dimension of 1.'
          print,' '
          print,'   The alpha channel is a byte array with the same dimensions'
          print,'   as the image components.  It may be used to control the'
          print,'   image transparency and may be set from 0 (image is'
          print,'   completely transparent at that point so not visible) to 255'
          print,'   (image is not transparent at that point so completely'
          print,'   visible) or anywhere in between.  To save the result as a'
          print,'   PNG image make sure to use TRUE=1 (default if an alpha is'
          print,'   given).  The result will be bytarr[4,nx,ny] and may be'
          print,'   saved using the IDL routine write_png:'
          print,'       write_png, filename, img'
	  return,''
	endif
 
	err = 0
 
	;--------  Find image dimensions  --------------
	nd1 = (size(c1))[0]
	nd2 = (size(c2))[0]
	nd3 = (size(c3))[0]
	nd = [nd1,nd2,nd3]
	if (min(nd) ne max(nd)) then begin
          err = 3
	  print,' Error in img_merge: input arrays must have same # dimensions.'
	  return,''
        endif
	if (min(nd) lt 1) or (max(nd) gt 2) then begin
	  err = 1
	  print,' Error in img_merge: input color arrays must be 2-D.'
	  return,''
	endif
        nd = min(nd)            ; # dimensions.
	sz = size(c1)
	nx = sz[1]		; Image dimensions.
        if nd eq 1 then ny=1 else ny=sz[2]
	dtyp = sz[sz[0]+1]	; Incoming data type.
 
	if keyword_set(hsv) then begin
	  color_convert,c1,c2,c3,r,g,b,/hsv_rgb
	endif else begin
	  r = c1
	  g = c2
	  b = c3
	endelse
 
        if n_elements(a) gt 0 then nch=4 else nch=3     ; # channels.
	if n_elements(typ) eq 0 then begin              ; Default interleaving.
          if nch eq 4 then typ=1 else typ=3
        endif
 
	;-------  Recombine as requested  --------------
	case typ of
0:	out = r
1:	begin
	  out = make_array(nch,nx,ny,type=dtyp)
	  out[0,*,*] = r
	  out[1,*,*] = g
	  out[2,*,*] = b
	  if nch eq 4 then out[3,*,*]=a
          out=reform(out,nch,nx,ny)
	end
2:	begin
	  out = make_array(nx,nch,ny,type=dtyp)
	  out[*,0,*] = r
	  out[*,1,*] = g
	  out[*,2,*] = b
	  if nch eq 4 then out[*,3,*]=a
          out=reform(out,nx,nch,ny)
	end
3:	begin
	  out = make_array(nx,ny,nch,type=dtyp)
	  out[*,*,0] = r
	  out[*,*,1] = g
	  out[*,*,2] = b
	  if nch eq 4 then out[*,*,3]=a
          out=reform(out,nx,ny,nch)
	end
else: 	begin
	  out = make_array(nx,ny,nch,type=dtyp)
	  out[*,*,0] = r
	  out[*,*,1] = g
	  out[*,*,2] = b
	  if nch eq 4 then out[*,*,3]=a
          out=reform(out,nx,ny,nch)
	end
	endcase
 
	return, out
 
	end
