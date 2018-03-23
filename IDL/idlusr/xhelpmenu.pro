;------------------------------------------------------------------------------
;  xhelpmenu.pro = Give a drop down help menu set up by add_helpmenu.
;  R. Sterner, 2010 Aug 16
;------------------------------------------------------------------------------

        ;=========================================================
        ;  Event handler
        ;=========================================================
	pro xhelpmenu_event, ev

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
	xhelp,txt,/bottom,/nowait,group=s.grp   ; Display the help text.

	end


        ;=========================================================
        ;  xhelpmenu = Help in a drop down menu button
        ;=========================================================
        pro xhelpmenu, file, title=ttl, help=hlp, wait=wait, group_leader=grp

        if (n_params(0) lt 1) or keyword_set(hlp) then begin
          print,' Give a drop-down help menu from text in a file.'
          print,' xhelpmenu, file'
          print,'   file = Name of text file with menu.   in'
          print,' Keywords:'
          print,'   TITLE=ttl Title for help widget (def=none).'
          print,'   /WAIT wait until help is exited.'
          print,'   GROUP_LEADER=grp  Assign a group leader.'
          print,' Notes: Can use this routine to drop in a fairly large'
          print,' amount of help in an organized way.  For details on'
          print,' how to layout the help text file see:'
          print,'     add_helpmenu,/details'
          print,' Can use this in another routine or see how to add'
          print,' a drop-down menu help button in a widget using this'
          print,' routine as an example.'
          return
        endif

        ;---  Defaults  ---
        if n_elements(ttl) eq 0 then ttl=''
        if n_elements(grp) eq 0 then grp=0

        ;---  Get text from file or text array  ---
        if n_elements(file) eq 1 then begin     ; File name.
          txt = getfile(file, error=err)
          if err ne 0 then return
          dfile = file
        endif else begin                        ; Text array.
          txt = file
          dfile = 'Text array'
        endelse

        ;---  Set up help text widget  ---
        top = widget_base(/row,title=ttl, xpad=10,ypad=10,space=10)
	add_helpmenu, top, txt	        	; Add menu.
	id = widget_button(top,val='Quit Help',uval='QUIT')
	widget_control, top, /real		; Realize widget.
	s = {user_help:txt, layout_src:dfile, grp:grp}   ; Info structure.
	widget_control, top, set_uval=s         ; Add info.
        noblk = 1
        if keyword_set(wait) then noblk=0
	xmanager,'xhelpmenu',top,no_block=noblk ; Manage the widget.

        end
