;------  pickfile2.pro = Portable version of pickfile  -------
;	R. Sterner, 1997 Oct 13

	function pickfile2, get_path=get_path, _extra=extra, help=hlp

	if keyword_set(hlp) then begin
	  print,' Portable version of pickfile.'
	  print,'   Call just like the IDL function pickfile.'
	  print,'   Interface will differ on different machines but'
	  print,'   the operation is the same.'
	  return,''
	endif

	out = pickfile(get_path=get_path, _extra=extra)

	;-----  Use pickfile if IDL 4 and before  ----------
	if (!version.release + 0) le 4 then begin
print,' IDL 4'
	  out = pickfile(get_path=get_path, _extra=extra)
	;-----  Use dialog_pickfile if IDL 5 and after  ----------
	endif else begin
print,' IDL 5'
	  out = dialog_pickfile(get_path=get_path, _extra=extra)

	endelse

help,out,get_path

	return, out

	end
