;-------------------------------------------------------------
;+
; NAME:
;       AGE_CHECK
; PURPOSE:
;       Check if files in two directories match.
; CATEGORY:
; CALLING SEQUENCE:
;       age_check, wild
; INPUTS:
;       wild = File wildcard.   in
; KEYWORD PARAMETERS:
;       Keywords:
;         DIR1=d1  Directory 1.  Required.
;         DIR2=d2  Directory 2. Default=current.
;         /TIMES   List file times also.
;         OUT=out  Return listing in a text array.
;         /QUIET   Do not list to screen.
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
;       Notes: Lists files in two columns indicating
;         how they compare in age.  If they differ in
;         age the symbol points to the older one.
; MODIFICATION HISTORY:
;       R. Sterner, 2008 Nov 14
;
; Copyright (C) 2008, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro age_check, wild, dir1=d1, dir2=d2, times=times, out=out, $
	  quiet=quiet, help=hlp
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
hlp:	  print,' Check if files in two directories match.'
	  print,' age_check, wild'
	  print,'   wild = File wildcard.   in'
	  print,' Keywords:'
	  print,'   DIR1=d1  Directory 1.  Required.'
	  print,'   DIR2=d2  Directory 2. Default=current.'
	  print,'   /TIMES   List file times also.'
	  print,'   OUT=out  Return listing in a text array.'
	  print,'   /QUIET   Do not list to screen.'
	  print,' Notes: Lists files in two columns indicating'
	  print,'   how they compare in age.  If they differ in'
	  print,'   age the symbol points to the older one.'
	  return
	endif
 
	;----------------------------------------
	;  Initialize
	;----------------------------------------
	if n_elements(d1) eq 0 then goto, hlp	; Must give DIR1.
	if n_elements(d2) eq 0 then cd,curr=d2	; DIR2 defaults to current.
	f1 = filename(d1,wild,/nosym)		; Make complete paths.
	f2 = filename(d2,wild,/nosym)
 
	;----------------------------------------
	;  Get file lists and info
	;----------------------------------------
	ff1 = file_search(f1,count=n1)		; Look for files.
	ff2 = file_search(f2,count=n2)
	if n1 eq 0 then begin			; None in DIR1.
	  print,' No files found in '+d1
	  return
	endif
	if n2 eq 0 then begin			; None in DIR2.
	  print,' No files found in '+d2
	  return
	endif
	;---  Get names  ---
	filebreak,ff1,nvfile=nam1		; Grab just file names.
	filebreak,ff2,nvfile=nam2
	;---  Get ages  ---
	js1970 = dt_tm_tojs('1970 Jan 1 0:00:00')
	off = gmt_offsec()
	js1 = dblarr(n1)
	js2 = dblarr(n2)
	get_lun, lun
	for i=0,n1-1 do begin			; Look at DIR1 files.
	  openr,lun,ff1[i]			; Open i'th file.
	  f = fstat(lun)			; Get file stats.
	  close,lun				; Close file.
	  js1[i] = f.mtime + js1970 - off	; Grab modification time.
	endfor
	for i=0,n2-1 do begin			; Look at DIR2 files.
	  openr,lun,ff2[i]
	  f = fstat(lun)
	  close,lun
	  js2[i] = f.mtime + js1970 - off
	endfor
	free_lun, lun
	tim1 = dt_tm_fromjs(js1)		; Times to date/time astrings.
	tim2 = dt_tm_fromjs(js2)	
	;---  Pad names with spaces  ---
	b = byte(nam1+' ')			; File names to bytes.
	im = strlen(nam1)			; Name lengths.
	for i=0,dimsz(b,2)-1 do b[0,i]=shift(b[*,i],-im[i]) ; Right justify.
	w = where(b eq 0,c)			; Find 0s.
	if c gt 0 then b[w]=32B			; Replace by spaces to pad.
	pnam1 = strmid(string(b[1:*,*]),0,dimsz(b,1)) ; Trim added spc, -> str.
	if keyword_set(times) then pnam1 = pnam1+' '+tim1  ; Tack on time.
	pnam2 = nam2
	if keyword_set(times) then pnam2 = tim2+' '+pnam2
	dsh1 = spc(strlen(pnam1[0]),ch='-')	; For files with no match.
	dsh2 = spc(max(strlen(nam2[0])),ch='-')
	dtxt1 = 'Dir 1'+spc(strlen(pnam1[0]),'Dir 1')  ; Header.
	dtxt2 = 'Dir 2'+spc(strlen(dsh2),'Dir 2')
 
	;----------------------------------------
	;  List files
	;----------------------------------------
	tprint,/init
	tprint,' '
	tprint,' Age Check'
	tprint,'   = Dir 1 file is the same age as dir 2 file.'
	tprint,'   < Dir 1 file is older than dir 2 file.'
	tprint,'   > Dir 1 file is younger than dir 2 file.'
	tprint,' '
	tprint,' Dir 1 = '+d1
	tprint,' Dir 2 = '+d2
	tprint,' '
	tprint,' '+dtxt1+'         '+dtxt2
	tprint,' '
	i1 = 0						; List 1 index.
	i2 = 0						; List 2 index.
loop:   if i1 gt (n1-1) then goto, trm1			; Done with DIR1?
	if i2 gt (n2-1) then goto, trm2			; Done with DIR2?
	nm1 = nam1[i1]					; Next DIR1 file name.
	nm2 = nam2[i2]					; Next DIR2 file name.
	pnm1 = pnam1[i1]				; Padded names.
	pnm2 = pnam2[i2]
	;---  Name1 EQ Name2  ---
	if nm1 eq nm2 then begin
	  if js1[i1] eq js2[i2] then sym='    =    '	; F1 same age as F2.
	  if js1[i1] gt js2[i2] then sym='    >    '	; F1 older than F2.
	  if js1[i1] lt js2[i2] then sym='    <    '	; F1 younger than F2.
	  tprint,' ' + pnm1 + sym + pnm2
	  i1 += 1
	  i2 += 1
	  goto, loop
	endif
	;---  Name1 GT Name2  ---
	if nm1 gt nm2 then begin
	  tprint,' '+dsh1+'         '+pnm2
	  i2 += 1
	  goto, loop
	endif
	;---  Name1 LT Name2  ---
	if nm1 lt nm2 then begin
	  tprint,' '+pnm1+'         '+dsh2
	  i1 += 1
	  goto, loop
	endif
 
 
	;----------------------------------------
	;  List the rest of dir2 files
	;----------------------------------------
trm1: 	if i2 gt (n2-1) then goto, done
	tprint,' '+dsh1+'         '+pnm2
	i2 += 1
	goto, trm1
 
	;----------------------------------------
	;  List the rest of dir1 files
	;----------------------------------------
trm2: 	if i1 gt (n1-1) then goto, done
	tprint,' '+pnm1+'         '+dsh2
	i1 += 1
	goto, trm2
 
done:	tprint,' '
	tprint,out=txt
	strfind,txt[11:*],/quiet,out=tt,'=',/inverse
	tt = [' ',' Non-matching files:',' ',tt]
	tprint,add=tt
	tprint,out=out
	if not keyword_set(quiet) then tprint,/print
 
	end
