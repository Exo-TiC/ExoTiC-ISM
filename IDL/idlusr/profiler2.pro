;---  profiler2.pro = Wrapper for profiler  ----
;	R.       Sterner, 2008 Nov 20

	pro profiler2, modl, _extra=extra, output=txt, file=file, $
	  data=ss, sort=ktag, reverse=rev, list=list, average=ave, $
	  error=err, help=hlp

	if keyword_set(hlp) then begin
	  print,' Timing for called routines. Allows sorts. Wrapper for profiler.'
	  print,' profiler2, module'
	  print,'   module = Start profiling given module, or with /CLEAR'
	  print,'     disable profiling of given module (default=all modules).'
	  print,' Keywords:'
	  print,'   ----------------------'
	  print,'   Control Mode Keywords:'
	  print,'     These keywords, along with the module arg, control'
	  print,'     how profiler is done or stops profiling.'
	  print,'   /RESET Restarts profiling.  Any other keywords ignored.'
	  print,'   /START start profiling all user modules when a module'
	  print,'     name is not given.'
	  print,'   /CLEAR disable profiling of specified module'
	  print,'     or all if none given.'
	  print,'   /SYSTEM Start profiling system routines, or with /CLEAR'
	  print,'     stop profiling system routines.'
	  print,'   ----------------------'
	  print,'   Output Mode Keywords:'
	  print,'     These keywords control how the profiling results are'
	  print,'     handled or displayed.'
	  print,'   /AVERAGE also display average times.'
	  print,'   SORT=tag Tag to sort on for output.  The options are:'
	  print,'     NAME = Module name.  This is the default sort tag.'
	  print,'     COUNT = # times module was called.'
	  print,'     SEC_1 = Total seconds in the listed module only.'
	  print,'     SEC_A = Total seconds in the listed module plus'
	  print,'       any submodules called by it.'
	  print,'     SYSTEM = System module flag (0: user module,'
	  print,'       1: system module).  Not a very useful sort tag.'
	  print,'     The following two tags are available if /AVERAGE used:'
	  print,'     SEC_1_AV = Average seconds in the listed module only'
	  print,'       = SEC_1 / COUNT'
	  print,'     SEC_A_AV = Average seconds in the listed module plus'
	  print,'       any submodules called by it = SEC_A / COUNT.'
	  print,'   /REVERSE Sort from high to low instead of low to high.'
	  print,'   OUTPUT=txt Return results in a text array.'
	  print,'   DATA=d Return the results in a structure.'
	  print,'   FILE=file Save results in a file.'
	  print,'   /LIST list results on screen.  Needed with OUTPUT, DATA,'
	  print,'     and FILE since those options do not list to the screen.'
	  print,'   ERROR=err Error flag: 0=ok.'
	  return
	end

	;-------------------------------------------------------------
	;  Determine type of call: Control or output
	;-------------------------------------------------------------
	flag = 0
	if n_elements(extra) gt 0 then flag=1 ; Expected: /CLEAR,/RESET,/SYSTEM.
	if n_elements(modl) gt 0 then flag=1  ; Module name.
	if n_elements(txt) gt 0 then flag=2   ; For OUTPUT=txt
	if n_elements(file) gt 0 then flag=2  ; For FILE=file
	if n_elements(ktag) gt 0 then flag=2  ; For SORT=ktag
	if n_elements(rev) gt 0 then flag=2   ; /REVERSE
	if n_elements(list) gt 0 then flag=2  ; /LIST
	if n_elements(ave) gt 0 then flag=2   ; /AVERAGE
	if flag eq 0 then flag=2	      ; if not control assume output.
	if n_elements(ktag) eq 0 then ktag='NAME'    ; Default sort tag.
	if arg_present(ss) then dflag=1 else dflag=0 ; DATA=d?
	err = 0

	;-------------------------------------------------------------
	;  Control Mode
	;-------------------------------------------------------------
	if flag eq 1 then begin
	  if n_elements(modl) gt 0 then begin	; Specified a module name.
	    profiler,modl, _extra=extra
	  endif else begin
	    profiler, _extra=extra		; Do all modules.
	  endelse
	  return
	endif

	;-------------------------------------------------------------
	;  Output mode
	;-------------------------------------------------------------
	;---  Get report info in structure and pad names to same length.
	profiler, /report, data=s		; Grab report in a structure.
	tag_add, s, 'NAME', txtpad(s.name)	; Pad names.

	;---  Build header  ---
	stxt = '  Sorted on '+strupcase(ktag)+' from '+ $
	  (['low to high','high to low'])[keyword_set(rev)]+'.'
	;---  Add averages  ---
	if keyword_set(ave) then begin
	  hd = ['  Timing since last profiler2,/reset', $
	    ' '+created(), ' '+created(/by), ' ', $
	    '  NAME:     Module name.', $
	    '  COUNT:    # calls to module.', $
	    '  SEC_1:    Total time in module only.', $
	    '  SEC_1_AV: Average time in module only.', $
	    '  SEC_A:    Total time for module and all submodules.', $
	    '  SEC_A_AV: Average time for module and all submodules.', $
	    '  SYS:      System module? 0=no, 1=yes.',' ',stxt,' ']
	  t = s.only_time/s.count			; Total time, mod only.
	  tag_add, s, 'SEC_1_AV', t, after='only_time'  ; Add average.
	  t = s.time/s.count				; Total time, mod+subs.
	  tag_add, s, 'SEC_A_AV', t, after='time'	; Add average.
	  new = ['NAME','COUNT','SEC_1','SEC_1_AV', $   ; New names for items.
	    'SEC_A','SEC_A_AV','SYS']
	  s2 = tag_sort(s,key=ktag,rev=rev,alias=new,err=err) ; Sort and rename.
	  if err ne 0 then return	; Quit if error (unknown tag?).
	  len = strlen(s2.name[0])	; Name length.
	  maxlen = 150 + (len-12)	; Needed length depends on module names.
	;---  No averages  ---
	endif else begin
	  hd = ['  Timing since last profiler2,/reset', $
	    ' '+created(), ' '+created(/by), ' ', $
	    '  NAME:  Module name.', $
	    '  COUNT: # calls to module.', $
	    '  SEC_1: Total time in module only.', $
	    '  SEC_A: Total time for module and all submodules.', $
	    '  SYS:   System module? 0=no, 1=yes.',' ',stxt,' ']
	  new = ['NAME','COUNT','SEC_1','SEC_A','SYS'] ; New names for items.
	  s2 = tag_sort(s,key=ktag,rev=rev,alias=new,err=err) ; Sort and rename.
	  if err ne 0 then return	; Quit if error (unknown tag?).
	  len = strlen(s2.name[0])	; Name length.
	  maxlen = 94 + (len-12)	; Needed length depends on module names.
	endelse

	;---  Write structure to a text array adding header  ---
	txtdb_wr,'',s2,header=hd,out=txt,max=maxlen

	;---  Output  ---
	;---    To a file  ---
	if n_elements(file) ne 0 then begin
	  putfile, file, txt
	  if keyword_set(list) then more,txt
	  return
	endif
	;---    To a text array  ---
	if arg_present(txt) then begin
	  if keyword_set(list) then more,txt
	  return
	endif
	;---    To a structure  ---
	if dflag then begin
	  ss = create_struct('HEADER',hd,ss)
	  if keyword_set(list) then more,txt
	  return
	endif
	;---    To the screen  ---
	more,txt

	end
