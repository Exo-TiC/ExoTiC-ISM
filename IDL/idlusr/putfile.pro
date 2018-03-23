;-------------------------------------------------------------
;+
; NAME:
;       PUTFILE
; PURPOSE:
;       Write a text file from a string array.
; CATEGORY:
; CALLING SEQUENCE:
;       putfile, f, s
; INPUTS:
;       f = text file name.      in
;       s = string array.        in
; KEYWORD PARAMETERS:
;       Keywords:
;         ERROR=err  error flag: 0=ok, 1=invalid string array.
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 20 Mar, 1990
;       R. Sterner,  4 Nov, 1992 --- allowed scalar strings.
;       R. Sterner, 2007 Jun 14 --- Fixed loop limit.
;       R. Sterner, 2010 May 07 --- Converted arrays from () to [].
;       R. Sterner, 2014 Jan 20 --- Added the new keyword /append.
;
; Copyright (C) 1990, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
	pro putfile, file, s, append=append, error=err, help=hlp
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Write a text file from a string array.'
	  print,' putfile, f, s'
	  print,'   f = text file name.      in'
	  print,'   s = string array.        in'
	  print,' Keywords:'
          print,'   /APPEND append text to an existing file.'
          print,'     If this keyword is not given the text replaces the'
          print,'     contents of the file if it exists.'
          print,'     If the file does not exist it is created in either case.'
	  print,'   ERROR=err  error flag: 0=ok, 1=invalid string array.'
	  return
	endif
 
	if datatype(s) ne 'STR' then begin
	  print,' Error in putfile: argument must be a string array.'
	  err = 1
	  return
	endif
 
	get_lun, lun
	openw, lun, file, append=append
 
	for i = 0L, n_elements(s)-1 do begin
	  t = s[i]
	  if t eq '' then t = ' '
	  printf, lun, t
	endfor
 
	close, lun
	free_lun, lun
	err = 0
	return
 
	end
