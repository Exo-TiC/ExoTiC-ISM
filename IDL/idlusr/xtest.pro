;---  xtest.pro = Test text widget  ---
;	R. Sterner, 2008 Aug 07
;       R. Sterner, 2010 Jun 04 --- Converted arrays from () to [].

	pro xtest_event, ev

	widget_control, ev.id, get_uval=cmd

	;------  Date selected?  -------
	if cmd eq 'TEXT' then begin
	  off = ev.offset
	  print,' OFFSET = ',off
	  return
	endif
 
	;------  Dismiss text display widget  ---------
	if cmd eq 'DONE' then begin
	  widget_control, /dest, ev.top
	  return
	endif
 
	widget_control, ev.top, get_uval=s	; Info structure.
 
	;------  Save text in a file  ------------------
	if cmd eq 'SAVE' then begin
	  file = ''
	  xtxtin, file, def=s.file, title=['Save this text',' ',$
	    'Filename:']
	  if file eq '' then return
	  widget_control, s.tid, get_val=txt
	  putfile, file, txt	
	  xmess,'Text saved in '+file
	  return
	endif
 
	;------  Display text2  -----------------
	if cmd eq 'TEXT2' then begin
	  if s.state then txt=s.txt1 else txt=s.txt2	; Display text 1 or 2.
	  s.state = 1 - s.state				; Reverse state flag.
	  nx = max(strlen(txt))<s.xsize			; Text area size.
	  ny = n_elements(txt)
	  if ny gt s.lines then begin
	    ny = s.lines
	    scroll = 1
	  endif else scroll=0
	  if s.scroll0 eq 1 then scroll=1		; Force scroll bars.
 
	  widget_control, s.tid, /destroy
	  tid = widget_text(ev.top,value=txt,xsize=nx,ysize=ny,scroll=scroll)
	  s.tid = tid
	  widget_control, ev.top,set_uval=s		; Save state flag.
	  return
	endif
 
	end
 
;=============================================================
 
	pro xtest, txt, title=title, lines=lines, exit_text=texit, $
	  wid=top, group_leader=grp, help=hlp, nowait=nowait, wait=wait, $
	  save=fsave, xoffset=xoff, yoffset=yoff, tid=tid, $
	  scroll=scroll0, ttid=ttid, xsize=xsize, text2=txt2, $
	  t2label=t2lab, bottom=bot
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Widget to display given help text.'
	  print,' xtest, txt'
	  print,'   txt = String array with help text to display.  in'
	  print,' Keywords:'
          print,'   TITLE=txt  title text or text array (def=none).'
	  print,'   LINES=lns maximum number of lines to display'
	  print,'     before added a scroll bar (def=30).'
	  print,'   XSIZE=xs Width of text area in characters (def=max needed).'
	  print,'   /SCROLL force scroll bars.  Useful if new text will'
	  print,'     displayed later.'
	  print,'   /BOTTOM Put buttons at the bottom instead of top.'
	  print,'   EXIT_TEXT=txt Exit button text (def=Quit help).'
	  print,'   SAVE=file  If a file name is given a SAVE button is'
	  print,'     added and the contents may be saved.  Given name is'
	  print,'     used as the default.'
	  print,'   TEXT2=txt2 A text array to display when the text2 button is clicked.'
	  print,'   T2LABEL=t2lab Label for the text2 button (def=text2).'
	  print,'     Clicking this button will replace the displayed text with the text'
	  print,'     in the array txt2.  txt2 must be given for this button to appear.'
	  print,'   WID=id  returned widget ID of help widget.  This'
	  print,'     allows the help widget to be automatically'
	  print,'     destroyed after action occurs.'
	  print,'   TID=tid returned widget ID of text area.  This'
	  print,'     allows text to be updated from outside this routine.'
	  print,'     widget_control,tid,set_val=new_text,xsize=xs,ysize=ys'
	  print,'     New x and y sizes may optionally be set.'
	  print,'   TTID=ttid returned widget ID of the title (-1 if no title).'
	  print,'     Title may be changed: widget_control,ttid,set_val=new'
	  print,'   /NOWAIT  means do not wait for exit button to be'
	  print,'     pressed.  Use with WID for to display help.'
          print,'   /WAIT  means wait for OK button without using xmanager'
          print,'     to register xtest.  Will not drop through if button'
          print,'     is not pressed as in default case.'
	  print,'   GROUP_LEADER=grp  Assign a group leader to this'
	  print,'     widget.  When the widget with ID group is destroyed'
	  print,'     this widget is also.'
	  print,'   XOFFSET=xoff, YOFFSET=yoff Widget position.'
	  return
	endif
 
	if n_elements(texit) eq 0 then texit = 'Quit help'
	if n_elements(xsize) eq 0 then xsize=999
 
	;-------  Set up and display widget  --------
	if n_elements(lines) eq 0 then lines = 30
 
	top = widget_base(title='  ',/column,xoff=xoff,yoff=yoff)
 
	if n_elements(grp) ne 0 then widget_control, top, group=grp
 
	nx = max(strlen(txt))<xsize
	ny = n_elements(txt)
	if ny gt lines then begin
	  ny = lines
	  scroll = 1
	endif else scroll=0
	if n_elements(scroll0) eq 0 then scroll0=0
	if scroll0 eq 1 then scroll=1		; Force scroll bars.
 
	if n_elements(title) ne 0 then begin
          for i=0, n_elements(title)-1 do ttid = widget_label(top,val=title[i],/dynamic)
	endif else ttid=-1
 
	if keyword_set(bot) then begin
	  tid = widget_text(top,value=txt,xsize=nx,ysize=ny,scroll=scroll, $
	    /all_events,uval='TEXT')
	endif
 
	;-----  Control buttons  -------------
	if not keyword_set(nowait) then begin
	  b1 = widget_base(top,/row)
	  ;--------  Done  ------------
	  b11 = widget_button(b1,value=texit, uval='DONE')
	  ;--------  Save text  -------
	  if n_elements(fsave) eq 0 then fsave=''
	  if fsave ne '' then $
	    id_sv=widget_button(b1,value='Save text',uval='SAVE')
	  ;--------  Text2 button  -------
	  if n_elements(txt2) gt 0 then begin
	    if n_elements(t2lab) eq 0 then t2lab='Text 2'
	    id_t2=widget_button(b1,value=t2lab,uval='TEXT2')
	  endif else txt2 = ''
	endif else begin
	  txt2 = ''
	  fsave = ''
	endelse
 
	if not keyword_set(bot) then begin
	  tid = widget_text(top,value=txt,xsize=nx,ysize=ny,scroll=scroll, $
	    /all_events,uval='TEXT')
	endif
;	tid = widget_text(top,value=txt,xsize=nx,ysize=ny,scroll=scroll)
 
	s = {txt1:txt,txt2:txt2,state:0,xsize:xsize,lines:lines, $
	     file:fsave,scroll0:scroll0,tid:tid}
	widget_control,/real,top, set_uval=s
 
        ;-------  Forced wait  ----------
        if keyword_set(wait) then begin
          widget_control, b11, /input_focus
          tmp = widget_event(top)
          widget_control, /dest, top
          return
        endif
 
	;--------  No wait  -----------
	if keyword_set(nowait) then return
 
        widget_control, b11, /input_focus
 
	xmanager, 'xtest', top, /no_block
 
	return
	end
