;--- html_idl_lib.pro = For a given IDL libray display routines with links.
;  R. Sterner, 2009 Oct 28
;------------------------------------------------------------------------------
;  To do:
;	[O] Allow routine list to be given and only work with those.
;	[O] Allow a list of routines to highlight, list at top in a
;	    special area, maybe put their one line descriptions with them.
;	[O] Allow a list to exclude or at least put in an area at end.
;	[ ] All the above replaced by a layout file that will allow
;	    routine groups.  Always include a complete alphabetical list
;	    at end of page unless some future flag to not do this is added.
;	[ ] Add a count of total routines in alphabetical list.
;	[ ] Label alphabetical list as alphabetical list of all routines.
;	[ ] Allow a title section in layout file.  Maybe use bigger font.
;	[ ] Allow section trailer?  Any layout section allows html code.
;------------------------------------------------------------------------------

	;============================================================
	;  html_idl_lib_parse_layout = Parse layout file.
	;============================================================
	pro html_idl_lib_parse_layout, dir_lib, s

	;----------------------------------------------------------
	;  Try to read a layout file
	;----------------------------------------------------------
	layfile = filename(dir_lib,/nosym,'html_idl_lib_layout.txt')
	t = getfile(layfile, err=err, /quiet)

	;----------------------------------------------------------
	;  If not read return an error indicator
	;----------------------------------------------------------
	if err ne 0 then begin
none:	  s = {flag:1}
	  return
	endif

	;----------------------------------------------------------
	;  Drop comments
	;----------------------------------------------------------
	t = drop_comments(t)

	;----------------------------------------------------------
	;  Get tag
	;----------------------------------------------------------
	strfind,t,'<desc',index=in,count=cnt,/quiet
	if cnt eq 0 then goto, none
	tags = strmid(t[in],6)
	len = strlen(tags)
	tags = strmid(tags,0,transpose(len-1))

	;----------------------------------------------------------
	;  Build and return structure
	;----------------------------------------------------------
	nkeys = cnt
	dkey1 = '<desc_'+tags+'>'
	dkey2 = '</desc_'+tags+'>'
	lkey1 = '<list_'+tags+'>'
	lkey2 = '</list_'+tags+'>'
	txt = t
	s = {flag:0, nkeys:nkeys, txt:txt, tags:tags, $
	     dkey1:dkey1, dkey2:dkey2, lkey1:lkey1, lkey2:lkey2 }

	return

	end


	;============================================================
	;  html_idl_lib = Main Routine
	;============================================================
	pro html_idl_lib, dir_lib, nocheck=nocheck, help=hlp

	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Display library routines with links to any routine in lib.'
	  print,' html_idl_lib, dir_lib'
	  print,'   dir_lib = Full path to target IDL library.  in'
	  print,' Notes: The results will be made in the current directory.'
	  return
	endif

	;==========================================================
	;  PASS 1: Generate html files with hyperlinks
	;          for each routine
	;==========================================================
	;----------------------------------------------------------
	;  Find library routines
	;----------------------------------------------------------
	wld = filename(dir_lib,'*.pro',/nosym)	; Wild card for IDL lib.
	list_pro = file_search(wld,count=n)	; Find all routines there.
	filebreak,list_pro,name=r		; Routine names (alphabetical).
	sz = strlen(r)				; Length of names.
	rr = r[reverse(sort(sz))]		; Longest names first list.
	filebreak,dir_lib,name=lib		; Library name.

	;----------------------------------------------------------
	;  Set up reverse lookup table
	;
	;  Initialize here.  Used to add in a second pass a list
	;  of routines that call a given routine.
	;----------------------------------------------------------
	rlow = strlowcase(r)
	for i=0,n-1 do dict=aarr(dict,rlow[i],value='',/add)

	;----------------------------------------------------------
	;  Double check if should copy
	;----------------------------------------------------------
	if not keyword_set(nocheck) then begin
	  cd,curr=dir0
	  print,' Are you sure you want to copy '+strtrim(n,2)+ $
	    ' *.pro to *.html files'
	  print,' from '+dir_lib
	  print,'   to '+dir0+'?'
	  txt = ''
	  read,' Y or N: ',txt
	  if strupcase(txt) ne 'Y' then return
	endif

	;----------------------------------------------------------
	;  Set up front and tail
	;----------------------------------------------------------
	fr = ['<html>',' ','<head>', $
              '<title>IDL Library: '+lib+'</title>', $
	      '</head>',' ', $
	      '<body link="red" alink="#ff00ff" vlink="#ee6600" ' + $
	      'bgcolor="white" >',$
	      ' ','<a href="index.html">Back to list of routines</a>']
	fr2 = ['<p>Routines called: ', '<p>','$$$$$','<pre>']
	tl = [' ','</pre>','<a href="index.html">Back to list of ' + $
	      'routines</a>', '</body>','</html>']

	;----------------------------------------------------------
	;  process library routines
	;
	;  Loop over each routine in this library and check
	;  each for calls to other routines in this library.
	;  Processing will increase with the square of the number
	;  of routines in the library.  If a library routine
	;  reference is found check if it is in a comment.
	;  Ignore those in comments, print strings, pro or
	;  function lines, and convert the others to hyperlinks.
	;----------------------------------------------------------
	all = ['']
	all_fr = ['<html>',' ','<head>', $
              '<title>IDL Library: '+dir_lib+'</title>', $
	      '</head>',' ', $
	      '<body link="red" alink="#ff00ff" vlink="#ee6600" ' + $
	      'bgcolor="white" >', ' ','<blockquote>','<blockquote>',' ',$
	      '<h2>Routines in IDL library '+lib+'</h2>',' ','<ul>']
	;---  Loop over each routine in this library  ---
	;iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
	for i=0, n-1 do begin			; Loop over library routines.
	  print,' Pass 1: ',i,n
	  ri = strlowcase(r[i])			; Routine ri to process.
	  out = ri + '.html'			; Output html file name.
	  t = getfile(list_pro[i],err=err)	; Read in the routine.
	  t = detab(t)				; Detab.
	  ;---  Check the ith routine for calls to other routines  ---
	  cntj = 0				; Count # of routines called.
	  ;jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
	  for j=0, n-1 do begin			; Check against each lib routn.
	    rj = strlowcase(rr[j])		; Routine rj to check.
	    if ri eq rj then begin		; Ignore self.
	      continue
	    endif
	    strfind,t,rj,/quiet,index=in,count=cnt  ; Look for calls to rj.
	    if cnt eq 0 then begin		; rj not called, check next.
	      continue
	    endif
	    ;--- The ith routine calls the jth routine  ---
	    kflag = 0				; rj not counted yet.
	    ;kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk
	    for k=0,cnt-1 do begin		; Loop over occurances.
	      tk = t[in[k]]			; Pull out the k'th occurance.
	      tkl = strlowcase(tk)		; Lower case copy.
	      pr = strpos(tkl,rj)		; Where is routine rj?
	      ;---  Check and ignore if in a comment  -----
	      pc = strpos(tk,';')		; Loop for a comment.
	      if pc lt 0 then pc=9999		; Not a comment.
	      if pc lt pr then begin		; Routine occurs comment, skip.
		continue
	      endif
	      ;---  Check and ignore if in a hyperlink  ---
	      p1 = strpos(tk,'<a href=',pr-1,/reverse_search)
	      p2 = strpos(tk,'</a>', pr+1)
	      if (p1 lt pr) and (pr lt p2) then begin
		continue
	      endif
	      ;---  Check and ignore pro lines  ---
	      p1 = strpos(tk,'pro ',pr-1,/reverse_search)
	      if p1 lt 0 then p1=9999		; Not a pro line.
	      if p1 lt pr then begin		; Routine in pro line, skip.
		continue
	      endif
	      ;---  Check and ignore function lines  ---
	      p1 = strpos(tk,'function ',pr-1,/reverse_search)
	      if p1 lt 0 then p1=9999		; Not a function line.
	      if p1 lt pr then begin		; Routn in function line, skip.
		continue
	      endif
	      ;---  Check and ignore text strings  ---
	      ;  If this line contains any text strings then
	      ;  check if routine rj is inside any of them.
	      ;  If it is inside then break from the string search loop.
	      ;  If the loop does all iterations then the routine
	      ;  was not found in any string and thre loop index ii will
	      ;  equal the # of strings, nch, else it will be less.
	      ;  So if ii lt nch the routine was in a string, so skip
	      ;  to next k using continue.
	      ;---------------------------------------
	      s = getstr(tk,ch1=ch1,ch2=ch2)	; Locate any strings.
	      if ch1[0] ge 0 then begin		; Line has text string(s).
		nch = n_elements(ch1)		; # strings in line.
		;-ii-ii-ii-ii-ii-ii-ii-ii-ii-ii-ii-ii-ii-ii-ii-ii-ii-ii
	        for ii=0,nch-1 do begin		; Loop over strings.
	          if (ch1[ii] le pr) and $
		    (pr le ch2[ii]) then break	; In a string, break loop.
	        endfor ; ii: Go see if rj is inside next string.
		;-ii-ii-ii-ii-ii-ii-ii-ii-ii-ii-ii-ii-ii-ii-ii-ii-ii-ii
	        if ii lt nch then begin		; Ignore rj in string.
		  continue
		endif
	      endif
	      ;###############################################################
	      ;---  Count call to routine one time  ---
	      if kflag eq 0 then begin		; Routine rj not counted yet.
	        kflag = 1			; Don't count rj again.
	        cntj = cntj + 1
	        ;---  Build the who calls me list  ---
	        val = aarr(dict,rj)		; List of known callers of rj.
		wordarray, val, txt		; List as array.
	        w = where(txt eq ri,cnt)	; Is ri already in list?
		if cnt eq 0 then begin		; No, then add it.
		  dict = aarr(dict,rj,val=val+' '+ri,/add) ; Add ri.
		endif
	      endif ; kflag.
	      ;---  Process a real call to routine: ri calls rj ---
	      len = strlen(rj)			; Length of routine name.
	      tkr = strmid(tk,pr,len)		; Grab in original case.
	      tkr2 = '<a href="'+rj+'.html"><b>'+tkr+'</b></a>' ; Link text.
	      tk = stress(tk,'R',0,tkr,tkr2)	; Replace string with link.
	      t[in[k]] = tk			; Replace edited line.
	      ;###############################################################
	    endfor ; k: Process next call to rj from ri.
	    ;kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk
	  endfor ; j: Go see if ri calls another routine, rj.
	  ;jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
	  if cntj gt 0 then txt=' '+strtrim(cntj,2) else txt='' ; # called.
	  if cntj gt 0 then txt2='<p>Routines called: '+ $
	    strtrim(cntj,2)+'</font>' $
	   else txt2='' ; # called.
	  fr2[0] = txt2
	  putfile,out,[fr,fr2,t,tl]
	  all = [all,'<li><a href="'+out+'">'+ri+'</a>'+txt]    ; Routine lnks.
	endfor ; i: Process next routine ri.
	;iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii

	;---  Put routine list in alphabetical order and save  ---
	all = [all_fr,all,'</ul>',' ','</blockquote>','</blockquote>', $
	       '<font size=-2>',created(),'<br>',created(/by),'</font>', $
	       '<hr size=5 color="red">', '</body>','</html>']
	putfile,'index.html',all

	;==========================================================
	;  PASS 2: Go back through each html file and add
	;  who calls me links.
	;==========================================================
	print,' ======================================'

	hfile = r + '.html'		; List of html files for each routine.

	for i=0,n-1 do begin			; Loop over files.
	  print,' Pass 2: ',i,n
	  ri = r[i]
	  txt = getfile(hfile[i])		; Read in file.
	  strfind,txt,'\$\$\$\$\$',index=in,/quiet,count=cnt ; Insertion point.
	  in = in[0]
	  if cnt eq 0 then stop,' STOP: in html_idl_lib: Internal error in PASS 2.'
	  val = aarr(dict,ri)			; Grab list of callers (if any).
	  if val eq '' then begin		; If no callers
	    txt2 = ' '				; then replace with null.
	  endif else begin			; If callers
	    wordarray,val,list			; then list them as hyperlinks.
	    txt2 = '<li><a href="'+list+'.html">'+list+'</a>'
	    txt2 = ['Called by:','<ul>',txt2,'</ul>','<hr size=5 color="red">',' ']
	  endelse
	  txt = [txt[0:in-1],txt2,txt[in+1:*]]	; Replace marker with list.
	  putfile,hfile[i],txt			; Update file.
	endfor ; i

stop

	end
