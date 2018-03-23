;-----  img_process.pro = Process a list of images  ------
;	R. Sterner, 2006 Jul 17

	;==========================================================
	;  img_process_apply = Apply a processing command
	;==========================================================
	pro img_process_apply, img, cmd, debug=debug
	  c = repchr(cmd,',')				; Drop any commas.
	  w1 = strupcase(getwrd(c,0))			; Command name.
	  case w1 of					; Apply command.
'STOP':	    begin
	      stop
	    end
'DISPLAY':  begin
	      img_disp,img,/curr
	    end
'COPY':	    begin	; copy ix1,iy1,dx,dy to ix,iy rot n
	      ix1 = getwrd(c,1)+0
	      iy1 = getwrd(c,2)+0
	      dx  = getwrd(c,3)+0
	      dy  = getwrd(c,4)+0
	      ix  = getwrd(c,6)+0
	      iy  = getwrd(c,7)+0
	      ir  = getwrd(c,9)+0
	      sub = img_subimg(img,ix1,iy1,dx,dy)
	      if ir ne 0 then sub=img_rotate(sub,ir)
	      img = img_insimg(img,sub,xstart=ix,ystart=iy)
	    end
'COPY2':    begin	; copy2 ix1,iy1,ix2,iy2 to ix,iy rot n
	      ix1 = getwrd(c,1)+0
	      iy1 = getwrd(c,2)+0
	      ix2 = getwrd(c,3)+0
	      iy2 = getwrd(c,4)+0
	      ix  = getwrd(c,6)+0
	      iy  = getwrd(c,7)+0
	      ir  = getwrd(c,9)+0
	      dx = ix2-ix1+1
	      dy = iy2-iy1+1
	      sub = img_subimg(img,ix1,iy1,dx,dy)
	      if ir ne 0 then sub=img_rotate(sub,ir)
	      img = img_insimg(img,sub,xstart=ix,ystart=iy)
	    end
'CROP':	    begin	; crop ix1,iy1,dx,dy
	      ix1 = getwrd(c,1)+0
	      iy1 = getwrd(c,2)+0
	      dx  = getwrd(c,3)+0
	      dy  = getwrd(c,4)+0
	      img = img_subimg(img,ix1,iy1,dx,dy)
	    end
'CROP2':    begin	; crop2 ix1,iy1,ix2,iy2
	      ix1 = getwrd(c,1)+0
	      iy1 = getwrd(c,2)+0
	      ix2 = getwrd(c,3)+0
	      iy2 = getwrd(c,4)+0
	      dx = ix2-ix1+1
	      dy = iy2-iy1+1
	      img = img_subimg(img,ix1,iy1,dx,dy)
	    end
'ROT':	    begin	; rot deg
	      deg = getwrd(c,1)+0.0
	      img = img_rot(img,deg)
	    end
'ROTATE':   begin	; rotate n
	      n = getwrd(c,1)+0
	      img = img_rotate(img,n)
	    end
'RESIZE':   begin	; resize magx, magy, /rebin (may just give mag).
	      p1 = getwrd(c,1)		; Possible allowed parameters.
	      p2 = getwrd(c,2)
	      p3 = getwrd(c,3)
	      p = [p1,p2,p3]		; Pack into an array.
	      w = where(strupcase(strmid(p,0,4)) eq '/REB',cnt, comp=wc)
	      rebin = 0			; Assume no /rebin.
	      if cnt gt 0 then begin	; Found /rebin.
	        rebin = 1		; Set flag.
		p = p(wc)		; Drop from parameter array.
	      endif
	      magx = p(0) + 0.0		; X mag factor.
	      magy = p(1) + 0.0		; Y mag factor.
	      if magy eq 0 then magy=magx
	      img = img_resize(img,mag=[magx,magy],rebin=rebin)
	    end
'SHIFT':   begin	; shift dx, dy
	      dx = getwrd(c,1)+0
	      dy = getwrd(c,2)+0
	      img = img_shift(img,dx,dy)
	    end
'SMOOTH':   begin	; smooth w
	      w = getwrd(c,1)+0
	      img = img_smooth(img,w)
	    end
else:	    begin
	      print,' Error in img_process: Unkown command:'
	      print,'    '+cmd
	      print,' Ignored.'
	    end
	  endcase
	end


	;==========================================================
	;  Main routine
	;==========================================================
	pro img_process, list, cfile, outdir=outdir0, prefix=prefix0, $
	  postfix=postfix0, type=typ0, $
	  error=err, debug=debug, nosave=nosave, help=hlp

	if (n_params(0) lt 2) or keyword_set(hlp) then begin
	  print,' Process a list of images.'
	  print,' img_process, list, cfile'
	  print,'   list = List of images to process.       in'
	  print,'     May be a full path to the images.'
	  print,'   cfile = Name of process control file.   in'
	  print,'     This file contains the processing'
	  print,'     commands. May be instead a text array'
	  print,'     with the commands.  Null lines and comments'
	  print,'     (* or ; as first character) are allowed.'
	  print,' Keywords:'
	  print,'   OUTDIR=dir  Name of output directory (def=current).'
	  print,'   PREFIX=prefix  Text to add the front of each output'
	  print,'     file name (def=none).'
	  print,'   POSTFIX=postfix  Text to add to the end of each output'
	  print,'     file name (def=none).'
	  print,'     By default to output names will be the same as the'
	  print,'     input names so they may be overwritten.'
	  print,'   TYPE=typ Type of image for result:'
	  print,"     typ must be 'png', or 'jpg'."
	  print,'   Any of the above keywords may be in the control file.'
	  print,'   /DEBUG show debugging messages.'
	  print,'   /NOSAVE do not save results.'
	  print,'   ERROR=err Error: 0=ok.'
	  print,'   /COMMANDS list allowed processing commands.'
	  return
	endif

	;----------------------------------------------------------
	;  Number of images to process
	;----------------------------------------------------------
	n = n_elements(list)

	;----------------------------------------------------------
	;  Get processing commands
	;----------------------------------------------------------
	if n_elements(cfile) ne 1 then begin
	  ctxt = cfile
	endif else begin
	  ctxt = getfile(cfile,err=err)
	  if err ne 0 then return
	endelse
	ctxt = drop_comments(ctxt,err=err)

	;----------------------------------------------------------
	;  Set up working values
	;----------------------------------------------------------
	if n_elements(outdir0) eq 0 then cd,curr=outdir else outdir=outdir0
	if n_elements(prefix0) eq 0 then prefix='' else prefix=prefix0
	if n_elements(postfix0) eq 0 then postfix='' else postfix=postfix0
	if n_elements(typ0) eq 0 then typ='png' else typ=typ0

	;----------------------------------------------------------
	;  From command list pull out commands and set any values
	;----------------------------------------------------------
	strfind,ctxt,'=',index=in2,count=ncmd,/quiet,/inverse
	if ncmd eq 0 then begin
	  err = 2
	  print,' Error in img_process: No processing commands given.'
	  return
	endif
	cmd = ctxt(in2)
	if keyword_set(debug) then begin
	  print,' Commands:'
	  more,cmd,lines=100
	endif
	strfind,ctxt,'=',index=in1,count=nset,/quiet
	set = ctxt(in1)
	if keyword_set(debug) then begin
	  print,' Settings:'
	  more,set,lines=100
	endif
	set = repchr(set,"=")
	set = repchr(set,"'")
	w1 = strarr(nset)
	for i=0,nset-1 do w1(i) = strupcase(strmid(getwrd(set(i),0),0,3))
	w = where(w1 eq 'OUT',cnt)
	if cnt gt 0 then outdir=getwrd(set(w),1)
	w = where(w1 eq 'PRE',cnt)
	if cnt gt 0 then prefix=getwrd(set(w),1)
	w = where(w1 eq 'POS',cnt)
	if cnt gt 0 then postfix=getwrd(set(w),1)
	w = where(w1 eq 'TYP',cnt)
	if cnt gt 0 then typ=getwrd(set(w),1)

	;----------------------------------------------------------
	;  Set up output image names
	;----------------------------------------------------------
	filebreak,list,name=nam
	outlist = filename(outdir,prefix+nam+postfix+'.'+typ,/nosym)


	;==========================================================
	;  Loop through images
	;==========================================================
	for i=0, n-1 do begin
	  ;--------------------------------------------------------
	  ;  Read input image
	  ;--------------------------------------------------------
	  f = list(i)
	  filebreak,f,ext=ext
	  if strupcase(ext) eq 'PNG' then begin
	    read_png, f, img
	  endif
	  if strupcase(ext) eq 'JPG' then begin
	    read_jpeg, f, img
	  endif
	  if strupcase(ext) eq 'BMP' then begin
	    img = read_bmp(f)
	  endif
	
	  ;--------------------------------------------------------
	  ;  Apply all commands to image
	  ;--------------------------------------------------------
	  for j=0,ncmd-1 do begin
	    if keyword_set(debug) then print,' File, command: ',f,'  ',cmd(j)
	    img_process_apply, img, cmd(j), debug=debug
	  endfor  ; j

	  ;--------------------------------------------------------
	  ;  Save result
	  ;--------------------------------------------------------
	  if not keyword_set(nosiave) then begin
	    case typ of
	  endif
	endfor ; i
	;==========================================================
	;  End of loop through images.
	;==========================================================


	end
