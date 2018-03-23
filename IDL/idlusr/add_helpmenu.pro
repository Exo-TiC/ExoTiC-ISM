;-------------------------------------------------------------
;+
; NAME:
;       ADD_HELPMENU
; PURPOSE:
;       Add one or more drop-down menus for help text to given base.
; CATEGORY:
; CALLING SEQUENCE:
;       add_helpmenu, base, file
; INPUTS:
;       base = Widget ID (WID) of base for menus.  in
;       file = Name of menu layout text file.      in
;           This may be a text array instead.
; KEYWORD PARAMETERS:
;       Keywords:
;         /DETAILS displays a commented example layout file.
;         /DEMO Show a demo drop-down menu.  This demo also
;           documents the use of this routine.  May also give
;           the name of a menu layout file to test, or the
;           layout text in an array.
;         CHECK=file Specify a layout file to check.
;           Checks given file for expected format.
;         CMD=cmd String to use as first word in the uval of
;           each menu item (def='UHELP').  This is needed when
;           using several layout files to add several help menus.
;         TEXTOUT=txt The returned text from the layout file.
;           This text can be added to the top level info structure
;           so it is available in the event handler.  It could be
;           saved under a tag with the cmd string in it.
;         ERROR=err Error flag: 0=ok.  Indicates if the requested
;           help menu could not be set up.
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
;       Notes: The menu layout file contains a description
;         of the drop-down menu which may have nested levels.
; MODIFICATION HISTORY:
;       R. Sterner, 2008 Oct 20
;
; Copyright (C) 2008, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
;-----------------------------------------------------------------
;  Event handler
;-----------------------------------------------------------------
	pro add_helpmenu_event, ev
 
	;---------------------------------------------------------
	;  Grab the command from the widget uval
	;---------------------------------------------------------
	widget_control, ev.id, get_uval=uv
	cmd = getwrd(uv)
 
	;---------------------------------------------------------
	;  QUIT
	;---------------------------------------------------------
	if cmd eq 'QUIT' then begin
	  widget_control, ev.top, /destroy
	  return
	endif
 
	;---------------------------------------------------------
	;  Help menu item
	;---------------------------------------------------------
	widget_control, ev.top, get_uval=s	; Top level info structure.
	txt = s.user_help			; Grab the help text array.
	src = s.layout_src			; Grab the text source.
	tag = getwrd(uv,1)			; Grab the help tag from uval.
	atag = '<'+tag+'>'			; Construct the help text
	btag = '</'+tag+'>'			; delimiters.
	txt_keysection,txt,after=atag,before=btag, $ ; Grab the help text.
	  /quiet, err=err
	if err ne 0 then begin			; Deal with an error.
	  xmess,['Error in menu layout text: Could not find matching',$
		 'delimiting tags.  Was looking for', $
		 atag+ ' and '+btag+' in ', $
		 src] 
	  return
	endif
	xhelp,txt,/bottom			; Display the help text.
 
	end
 
;-----------------------------------------------------------------
;  Main routine
;-----------------------------------------------------------------
	pro add_helpmenu, base, file, details=details, demo=demo, $
	  check=check, cmd=cmd, textout=txtout, error=err ,help=hlp
 
	if keyword_set(hlp) then begin
hlp:	  print,' Add one or more drop-down menus for help text to given base.'
	  print,' add_helpmenu, base, file'
	  print,'   base = Widget ID (WID) of base for menus.  in'
	  print,'   file = Name of menu layout text file.      in'
	  print,'       This may be a text array instead.'
	  print,' Keywords:'
	  print,'   /DETAILS displays a commented example layout file.'
	  print,'   /DEMO Show a demo drop-down menu.  This demo also'
	  print,'     documents the use of this routine.  May also give'
	  print,'     the name of a menu layout file to test, or the'
	  print,'     layout text in an array.'
	  print,'   CHECK=file Specify a layout file to check.'
	  print,'     Checks given file for expected format.'
	  print,'   CMD=cmd String to use as first word in the uval of'
	  print,"     each menu item (def='UHELP').  This is needed when"
	  print,'     using several layout files to add several help menus.'
	  print,'   TEXTOUT=txt The returned text from the layout file.'
	  print,'     This text can be added to the top level info structure'
	  print,'     so it is available in the event handler.  It could be'
	  print,'     saved under a tag with the cmd string in it.'
	  print,'   ERROR=err Error flag: 0=ok.  Indicates if the requested'
	  print,'     help menu could not be set up.'
	  print,' Notes: The menu layout file contains a description'
	  print,'   of the drop-down menu which may have nested levels.'
	  return
	endif
 
	;_________________________________________________________
	;=========================================================
	;  Other options
	;_________________________________________________________
	;=========================================================
 
	;---------------------------------------------------------
	;  DETAILS = List example layout file
	;---------------------------------------------------------
	if keyword_set(details) then begin
	  whoami, dir
	  exfile = filename(dir,'add_helpmenu_example.txt',/nosym)
	  txt = getfile(exfile,err=err)
	  if err ne 0 then begin
	    xmess,['Could not find the demo file',$
		   'add_helpmenu_example.txt', $
		   'in '+dir]
	    return
	  endif
	  more,txt
	  return
	endif
 
	;---------------------------------------------------------
	;  DEMO = Display example layout file as a menu
	;---------------------------------------------------------
	if keyword_set(demo) then begin
	  ;---  Use default demo file or given test file  ---
	  if isnumber(demo) then begin		; /DEMO
	    whoami, dir				; Demo file in IDL lib.
	    dfile = filename(dir,'add_helpmenu_example.txt',/nosym)
	    txt = getfile(dfile, error=err)	; Read it if there.
	    if err ne 0 then begin
	      xmess,['Could not find the demo file',$
  		     'add_helpmenu_example.txt', $
		     'in '+dir]
	      return
	    endif
	  endif else begin			; DEMO=test_file
	    if n_elements(demo) eq 1 then begin	; File name given?
	      dfile = demo
	      txt = getfile(dfile, error=err)	; YES, try to read it.
	      if err ne 0 then return		; Could not.
	    endif else begin			; NO, assume text array.
	      dfile = 'given text array'
	      txt = demo			; Copy to text array.
	    endelse
	  endelse
	  ;---  Set up demo widget  ---
	  top = widget_base(/row,title='add_helpmenu demo', $
	    xpad=10,ypad=10,space=10)
	  id = widget_button(top,val='Quit',uval='QUIT')
	  add_helpmenu, top, txt		; Add demo menu(s).
	  widget_control, top, /real		; Realize widget.
	  s = {user_help:txt, layout_src:dfile} ; Info structure.
	  widget_control, top, set_uval=s	; Add info.
	  xmanager,'add_helpmenu',top           ; Manage the widget.
	  return
	endif
 
	;---------------------------------------------------------
	;  CHECK = Check specified layout file or given text array
	;---------------------------------------------------------
	if n_elements(check) gt 0 then begin
 
	  ;---  get text  ---
	  if n_elements(check) eq 1 then begin	; File name.
	    txt = getfile(check, error=err)	; Try to read file.
	    if err ne 0 then begin		; Not read.
	      xmess,'File not found: '+check
	      return
	    endif
	    src = check				; Source was the given file.
	  endif else begin			; Text array.
	    txt = check
	    src = 'the given text array'	; Source was the text array.
	  endelse
 
	  ;---  Get menu section  ---
	  txt = drop_comments(txt,/notrim)	; Ignore comments.
	  txt_keysection, txt, after='<menu>',$	; Grab menu setup.
	    before='</menu>', out=txt1
	  indentation_level, txt1, txt2, lev	; Find indentation levels.
	  txt2 = [txt2,'']			; Add dummy ends.
	  lev = [lev,-1]
 
	  ;---  Check layout file  ---
	  w = where(lev eq 0, nm)		; Find top level buttons.
	  w = [w,n_elements(lev)-1]		; Add dummy end.
	  print,' '
	  print,' Checking '+src
	  print,' '
	  if lev[0] ne 0 then begin		; First item must be top level.
	    print,' The first item in the menu layout must use the'
	    print,' minimum indentation since it must be a top level'
	    print,' button.  Change the layout and check again.'
	    return
	  endif
	  errcnt = 0				; Count total errors.
	  print,' Menu layout defines '+strtrim(nm,2)+ $
	    ' menu button'+plural(nm)+'.'
 
	  ;---  Loop over menu(s)  ---
	  for i=0,nm-1 do begin			; Loop over menus.
	    print,' '
	    print,' Menu # '+strtrim(i+1,2)
	    txt3 = txt2[w[i]:w[i+1]-1]		; Grab i'th menu text.
	    lev3 = lev[w[i]:w[i+1]]		; Levels for i'th menu.
	    n3 = n_elements(txt3)		; # buttons in i'th menu.
 
	    ;---  Loop over menu entries  ---
	    for j=0,n3-1 do begin		; Loop over menu entries.
	      tag = getwrd(txt3[j])		; Get tag.
	      lab = getwrd(txt3[j],1,99)	; Button label.
	      lv = lev3[j]			; Level for item j.
	      lv1 = lev3[j+1]			; Level for next item.
	      if lv1 le lv then begin		; Not a submenu start.
	        atag = '<'+tag+'>'		; Delimiters.
	        btag = '</'+tag+'>'
	        txt_keysection,txt,after=atag,before=btag, $ ; Grab text.
	          /quiet, err=err, out=tt,count=nt
	        if err ne 0 then begin
	          stat = '  Problem finding tags '+atag+' and '+btag+' <===<<<'
	          errcnt += 1
	        endif else begin
                  stat = ' has '+strtrim(nt,2)+' line'+plural(nt)+ $
	            ' of text.'
	          if nt eq 0 then stat=stat+' <===<<< Warning.'
	        endelse
	      endif else begin			; Submenu start.
	        stat = ''			; Ignore tags for menu starts.
	      endelse
	      print,'    '+spc(4*lv)+'['+lab+']'+stat   ; List button.
	    endfor ; j = items in menu i.
	    ;---  End loop over menu entries  ---
 
	  endfor ; i = menus in layout.
	  ;---  End loop over menu(s)  ---
 
	  ;---  Summary  ---
	  print,' '
	  if errcnt eq 0 then begin
	    print,' No layout errors were found.'
	  endif else begin
	    print,' >>>===> Found '+strtrim(errcnt,2)+ $
	      ' error'+plural(errcnt)+'.'
	  endelse
	  print,' '
	  return
	endif
 
	;---  If no options requested show help  ---
	if n_params(0) lt 2 then goto, hlp
 
	;_________________________________________________________
	;=========================================================
	;  Add drop-down help menu button(s)
	;_________________________________________________________
	;=========================================================
	;  TODO:
	;    Consider adding tooltips to the toplevel menu
	;  buttons (only buttosn and draw_widgets can have
	;  tooltips).  Could add a section to the layout file:
	;  <tooltips>
	;  toptag1 Tool tip text for top level button for toptag1.
	;  toptag2 Tool tip text for top level button for toptag2.
	;  ...
	;  </tooltips>
	;  If there are any tooltips could match using the tags
	;  to the level 0 items only.  Null string tooltips are
	;  not displayed.
	;=========================================================
 
	;---------------------------------------------------------
	;  Defaults
	;---------------------------------------------------------
	if n_elements(cmd) eq 0 then cmd='UHELP'
 
	;---------------------------------------------------------
	;  Get layout text
	;
	;  Text may be either from a layout file or a text array.
	;---------------------------------------------------------
	if n_elements(file) eq 1 then begin	; File name.
	  txtout = getfile(file, error=err)
	  if err ne 0 then return
	endif else begin			; Text array.
	  txtout = file
	endelse
 
	;---------------------------------------------------------
	;  Grab menu setup text and find indentation
	;
	;  Find menu setup section and extract.
	;  Determine indentation level for each line.
	;  Set back to top level after last menu item.
	;  Set up a list of widget IDs which will be the
	;    last ID at each level.  Set the first level (0)
	;    to the given base.  Index into this list is
	;    1 + indentation level.
	;---------------------------------------------------------
	txt = drop_comments(txtout,/notrim)	; Ignore comments.
	txt_keysection, txt, after='<menu>', $	; Grab menu setup.
	  before='</menu>', out=txt1
	indentation_level, txt1, txt2, lev	; Find indentation levels.
	n = n_elements(lev)			; Number of menu entries.
	lev = [lev,0]				; Drop back to first level.
	menwid = lonarr(max(lev)+2)		; Last widget list.
	menwid[0] = base			; Root menu at base.
 
	;---------------------------------------------------------
	;  Lay out menu button(s)
	;---------------------------------------------------------
	for i=0,n-1 do begin		; Loop over menu entries.
	  lv = lev[i]			; Current item.
	  lv1 = lev[i+1]		; Next item.
	  if lv1 gt lv then mn=1 else mn=0  ; Does it have a submenu?
	  b = menwid[lv]		; Parent.
	  tag = getwrd(txt2[i])	; Tag = pointer to help.
	  lab = getwrd(txt2[i],1,99)	; Button label.
	  uv = cmd+' '+tag		; Set up uval.
	  id = widget_button(b,val=lab,menu=mn,uval=uv)  ; Add button.
	  menwid[lv+1] = id		; Latest WID.
	endfor
 
	end
