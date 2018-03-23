;-------------------------------------------------------------
;+
; NAME:
;       IMG_SHAPE
; PURPOSE:
;       Returns the shape of a 2-D or 3-D image array.
; CATEGORY:
; CALLING SEQUENCE:
;       img_shape, img
; INPUTS:
;       img = Input image.    in
; KEYWORD PARAMETERS:
;       Keywords:
;         TRUE=tr Interleave dimension for true color:
;           0 = 2-D image, else dimension (1, 2, or 3).
;           Use to display image: tv,img,true=tr
;         NX=nx, NY=ny returned image size in x and y.
;         ERROR=err error flag: 0=ok, 1=not 2-D or 3-D,
;           2=wrong number of color channels for 3-D array.
;         /QUIET do not display an error message.
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
;       Note: deals with 2-D or 3-D image arrays.
; MODIFICATION HISTORY:
;       R. Sterner, 2001 Mar 26
;       R. Sterner, 2007 Mar 01 --- Added /QUIET keyword.
;       R. Sterner, 2010 May 04 --- Converted arrays from () to [].
;       R. Sterner, 2010 Sep 06 --- Now allows 1-d arrays.
;       R. Sterner, 2011 May 12 --- Allowed for Alpha channel.
;
; Copyright (C) 2001, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro img_shape, img, true=true, nx=nx, ny=ny, error=err, $
	  quiet=quiet, aflag=aflag, help=hlp
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Returns the shape of a 2-D or 3-D image array.'
	  print,' img_shape, img'
	  print,'   img = Input image.    in'
	  print,' Keywords:'
	  print,'   TRUE=tr Interleave dimension for true color:'
	  print,'     0 = 2-D image, else dimension (1, 2, or 3).'
	  print,'     Use to display image: tv,img,true=tr'
	  print,'   NX=nx, NY=ny returned image size in x and y.'
          print,'   AFLAG=aflag Alpha channel?: 0=no, 1=yes.'
	  print,'   ERROR=err error flag: 0=ok, 1=not 2-D or 3-D,'
	  print,'     2=wrong number of color channels for 3-D array.'
	  print,'   /QUIET do not display an error message.'
	  print,' Note: deals with 2-D or 3-D image arrays.'
	  return
	endif
 
	err = 0
 
	;--------  Find image dimensions  --------------
	sz = size(img)
	ndim = sz[0]
        if ndim eq 0 then begin
          err = 1
          if not keyword_set(quiet) then $
	    print,' Error in img_shape: given array was undefined.'
	  return
	endif
	if ndim gt 3 then begin
	  err = 1
	  if not keyword_set(quiet) then $
	    print,' Error in img_shape: given array must be 3-D or less.'
	  return
	endif
 
	;--------  1-D image = nx x 1  -----------------
	if ndim eq 1 then begin
	  true = 0
	  nx = sz[1]
	  ny = 1
	  return
	endif
 
	;--------  2-D image  --------------------------
	if ndim eq 2 then begin
	  true = 0
	  nx = sz[1]
	  ny = sz[2]
	  return
	endif
 
	;--------  3-D image  --------------------------
        nch = min(size(img,/dim))
	if (nch lt 3) or (nch gt 4) then begin
	  err = 2
	  if not keyword_set(quiet) then $
	    print,' Error in img_shape: given array must have a dimension of 3 or 4.'
	  return
	endif
        aflag = nch eq 4
	if sz[1] eq nch then typ=1
	if sz[2] eq nch then typ=2
	if sz[3] eq nch then typ=3
 
	case typ of
1:	begin
	  true = typ
	  nx = sz[2]
	  ny = sz[3]
	end
2:	begin
	  true = typ
	  nx = sz[1]
	  ny = sz[3]
	end
3:	begin
	  true = typ
	  nx = sz[1]
	  ny = sz[2]
	end
	endcase
 
	return
 
	end
