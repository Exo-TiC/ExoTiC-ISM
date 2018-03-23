;------  mov2gifs.pro = Split out movie frames to gif files  --------
;	R. Sterner, 2000 Mar 10

	pro mov2gifs, file, start=lo, stop=hi, step=st, help=hlp

	if keyword_set(hlp) then begin
	  print,' Split out movie frames to gif files.'
	  print,' mov2gifs, file'
	  print,'   file = res movie file.   in'
	  print,' Keywords:'
	  print,'   START=lo, STOP=hi  Start and stop frame'
	  print,'       numbers (def=1st, last).'
	  print,'   STEP=st   Step in frames (def=1).'
	  print,' Notes: GIF files are named FRAME_0.gif, FRAME_1.gif, ...'
	  print,' If a color table is included in the movie res file it'
	  print,' will be used.  Otherwise the current color table is used.'
	  print,' Press Q to quit extraction before normal termination.'
	  return
	endif

	;-------  Movie file name  ------------
	if n_elements(file) eq 0 then begin
	  file = ''
	  read,' Enter name of res movie file: ',file
	  if file eq '' then return
	endif

	;-------  Open movie file  -------------
	resopen,file,header=hdr,err=err
	if err ne 0 then begin
	  print,' Error in mov2gifs: could not open res movie file.'
	  print,'   File name was: '+file
	  return
	endif

	;--------  Color table  -----------
	resget,'RED',r,error=err
	resget,'GREEN',g,error=err
	resget,'BLUE',b,error=err
	if err ne 0 then begin
	  tvlct,r,g,b,/get
	endif

	;---------  Look at movie file header  ---------
	;------  Grab first and last frame numbers  ----
	w = where(strpos(strupcase(hdr),'FRAME_') ge 0, cnt)
	if cnt le 0 then begin
	  print,' Error in mov2gifs: File not a res movie file: '+file
	  return
	endif
	flo = getwrd(hdr(min(w)),1,del='_')+0L
	fhi = getwrd(hdr(max(w)),1,del='_')+0L

	;--------  Deal with start, stop, step  -----------
	alo = flo
	ahi = fhi
	ast = 1
	if n_elements(lo) ne 0 then alo = flo>lo
	if n_elements(hi) ne 0 then ahi = fhi<hi
	if n_elements(st) ne 0 then ast = st
	in = strtrim(makei(alo,ahi,ast),2)
	frm = 'FRAME_'+in
	out = frm+'.gif'
	n = n_elements(frm)
	print,' Extracting '+strtrim(n,2)+' movie frames ...'

	;--------  Loop through frames  ---------------
	for i=0,n-1 do begin
	  k = get_kbrd(0)
	  if k eq 'Q' then begin
	    print,' mov2gifs: Extraction terminated by Q command.'
	    return
	  endif
	  resget,frm(i),a,error=err
	  if err ne 0 then begin
	    print,' Error in mov2gifs: frame not found: '+frm(i)
	    print,'   Processing aborted.'
	    return
	  endif
	  write_gif,out(i),a,r,g,b
	  print,i,':  ',out(i)
	endfor

	bell
	print,' '
	print,' mov2gifs: extraction complete from movie file '+file

	end
