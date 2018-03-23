;-------------------------------------------------------------
;+
; NAME:
;       ARCHIVE_NDIR
; PURPOSE:
;       Archive N levels of a directory.
; CATEGORY:
; CALLING SEQUENCE:
;       archive_ndir
; INPUTS:
; KEYWORD PARAMETERS:
;       Keywords:
;         NK=nk Number of extra copies to keep.
;         CURR=curr Name of current data directory.
;         BASE=base Base name of archive copies.
;         /QUIET give less feedback.
;         /VERBOSE give more feedback.
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
;       Notes: Current directory, curr, will be copied to the
;       base_0 archive directory.  Example:
;         If nk=3, curr='data', and base='data_' and
;         there are 3 archive directories (the max number), then
;           data_3 will be deleted,
;           data_2 will move to data_3
;           data_1 will move to data_2
;           data_0 will move to data_1
;           data   will copy to data_0
;       This routine could be called after new content is created
;       in the current directory.
; MODIFICATION HISTORY:
;       R. Sterner, 2009 Jun 03
;       R. Sterner, 2013 Oct 29 --- Allowed nk to be a string.
;
; Copyright (C) 2009, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro archive_ndir, nk=nk, curr=curr, base=base, $
	  verbose=verb, quiet=quiet, help=hlp
 
	if keyword_set(hlp) then begin
	  print,' Archive N levels of a directory.'
	  print,' archive_ndir'
	  print,'   All args are input keywords (no defaults).'
	  print,' Keywords:'
	  print,'   NK=nk Number of extra copies to keep.'
          print,'     The number of digits in the postfix is the number of'
          print,'     digits in nk, unless nk is a string and then it is the'
          print,'     string length.  So 7 will give 1 digit postfixes, but'
          print,"     '07' will give 2 digits, '007' three digits, and so on."
          print,'     This allows for future expansion, like 7 now, 14 later.'
	  print,'   CURR=curr Name of current data directory.'
	  print,'   BASE=base Base name of archive copies.'
          print,'     curr and base may be full paths (not needed locally).'
	  print,'   /QUIET give less feedback.'
	  print,'   /VERBOSE give more feedback.'
	  print,' Notes: Current directory, curr, will be copied to the'
	  print,' base_0 archive directory.  Example:'
	  print,"   If nk=3, curr='data', and base='data_' and"
	  print,'   there are 3 archive directories (the max number), then'
	  print,'     data_3 will be deleted,'
	  print,'     data_2 will move to data_3'
	  print,'     data_1 will move to data_2'
	  print,'     data_0 will move to data_1'
	  print,'     data   will copy to data_0'
	  print,' This routine could be called after new content is created'
	  print,' in the current directory.'
	  return
	endif
 
	;------------------------------------------------------
	;  Check for all inputs
	;------------------------------------------------------
	if n_elements(nk) eq 0 then begin
	  print,' Error in archive_ndir: nk not given (number to keep).'
	  print,'   No archiving done.'
	  return
	endif
	if n_elements(curr) eq 0 then begin
	  print,' Error in archive_ndir: curr not given (Current dir).'
	  print,'   No archiving done.'
	  return
	endif
	if n_elements(base) eq 0 then begin
	  print,' Error in archive_ndir: base not given (archive base name).'
	  print,'   No archiving done.'
	  return
	endif
 
	;------------------------------------------------------
	;  Initialize
	;
        ;  The number of digits is either the number of digits
        ;  in nk or the number of characters if it is given as
        ;  a string like '07'. This allows for future expansion.
        ;
	;  Find number of digits in max number to keep
	;  and make archive numbers and then archive directory
	;  names.  Starting at the max and working down find
	;  the last existing archive directory (will be i).
	;  Add one more after that, if any, for the new
	;  directory and add the current data directory to
	;  front of list.  Get last index into that list.
	;------------------------------------------------------
        if datatype(nk) eq 'STR' then begin
          ndig = strlen(nk)
        endif else begin
	  ndig = ceil(alog10(1+nk))	; Number of digits needed.
        endelse
	d = makes(0,nk,1,dig=ndig)	; Archive digits.
	adir = base + d			; Archive dir list.
	for i=nk+0,0,-1 do begin $	; Find last existing archive. The 
	  flag = file_test(adir[i]) &$	; index of it will be i when the
	  if flag eq 1 then break &$	; loop exits, -1 means none.
	endfor
	f = [curr,adir[0:(i+1)<nk]]	; Complete dir list.
	n = n_elements(f) - 1		; Last index into f.
 
	;------------------------------------------------------
	;  Do archiving
	;
	;  Must delete the last directory or the one before
	;  it will be moved into it.  The last directory will
	;  only exist if it is the max one (else it is the
	;  newly added but yet nonexistent one).
	;  Starting from the highest existing directory move
	;  each to the next one after it.  Each move will be
	;  to a nonexisting directory (the last one was
	;  deleted or moved upward).
	;  Finally copy the current directory to the first
	;  archive directory (*_0).
	;------------------------------------------------------
	;---  Delete last dir  ---
	file_delete, f[n], /allow_nonexistent,/recursive
	;---  Move  ---
	for i=n-1,1,-1 do begin
	  if not keyword_set(quiet) then print,' Move '+f[i]+' to '+f[i+1]
	  file_move,f[i],f[i+1],/overwrite,verb=verb
	endfor
	;---  Copy  ---
	if not keyword_set(quiet) then print,' Copy '+f[0]+' to '+f[1]
	file_copy,f[0],f[1],/overwrite,/recursive,verb=verb
 
	end
