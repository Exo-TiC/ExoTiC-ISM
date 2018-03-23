;------------------------------------------------------------------------------
;  extract_needed.pro = Exatrct list of needed routines in IDLUSR.
;  IDL batch file that returns a list of all IDLUSR routines currently used.
;  Calling syntax:
;	@extract_needed
;  List will be in the variable _idlusr_needed
;  R. Sterner, 2009 Jun 11
;
;  1. Comment out any calls to IDLUSR routines in the IDL_STARTUP file.
;  2. Get into IDL and run main routine.
;  3. Do resolve_all
;  4. Do help,/source,out=txt
;  5. Do strfind,txt,'IDLUSR',out=_idlusr_needed
;
;------------------------------------------------------------------------------

	resolve_all
	help,/source,out=txt0
	strfind,txt0,'IDLUSR',out=txt1, /quiet,count=cnt
	_idlusr_needed = ''
	if cnt eq 0 then stop
	n = n_elements(txt1)
	for i=0,n-1 do txt1[i]=getwrd(txt1[i],1)
	_idlusr_needed = txt1[uniq(txt1)]
