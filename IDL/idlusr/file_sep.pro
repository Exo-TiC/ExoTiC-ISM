;------------------------------------------------------------------------------
;  file_sep.pro = File separator widget.
;  R. Sterner, 2013 Feb 17
;
;  Given a list of text files, allow them to be moved or copied to other lists.
;  May also dispay the contents of a file.
;------------------------------------------------------------------------------

        ;----------------------------------------------------------------------
        ;  Event handler
        ;----------------------------------------------------------------------
        pro file_sep_event, ev

        widget_control, ev.id, get_uval=uval
        widget_control, ev.top, get_uval=s

        ;------------------------------------------------------------
        ;  Dropdown menus above columns
        ;
        ;  UVAL is LIST_D_xx where xx is the 2 digit list number.
        ;  The dropdown menu index is the flag value for that
        ;  column.  Just save the current value.
        ;------------------------------------------------------------
        cmd = strmid(uval,0,6)
        if cmd eq 'LIST_D' then begin
          nn = getwrd(uval,del='_',2) + 0       ; List number.
          flag_nn = ev.index                    ; New flag value.
          s.list_flags[nn] = flag_nn            ; Save new flag.
          widget_control, ev.top, set_uval=s    ; Save updated values.
          return
        endif

        ;------------------------------------------------------------
        ;  Click on item in a list
        ;
        ;  UVAL is LIST_xx where xx is the 2 digit list number.
        ;
        ;  A click in the left column (the main list) will move,
        ;  copy, or list the selected item, depending on the action
        ;  flag from the dropdown menu above the list.
        ;
        ;  A click on another column will send the selected item
        ;  back to the main column on the left.
        ;------------------------------------------------------------
        cmd = strmid(uval,0,5)
        if cmd eq 'LIST_' then begin

          nn = getwrd(uval,del='_',1) + 0       ; List number.
          in_sel = widget_info( (s.id_list)[nn], /list_select)
          list_0 = (s.list_list)[0]             ; Main list as list type.

          ;---  Main list click  ---
          if nn eq 0 then begin

            ;---  Get item name  ---
            if list_0.isempty() then return     ; Nothing to do.
            txt = list_0.toarray()              ; String array from main list.
            item = txt[in_sel]                  ; Selected item.
            ;--- Action flag  ---
            flag = s.list_flags[0]              ; Action flag for main list.

            ;---  Action = List: Try to display contents of item  ---
            if flag eq 2 then begin
              f = filename(/nosym,s.dir,item)   ; Add path to file name.
              txt = getfile(f,err=err)          ; Try to read it.
              if err ne 0 then return           ; Not found.
              xhelp,txt,title=item,exit_text='Dismiss'  ; Display contents.
              return
            endif

            ;---  Action = Move or Copy: Handle item transfer  ---
            flgs = s.list_flags[1:*]            ; Flags for right lists.
            w = where(flgs eq 0,ntarg)          ; Find target lists.
            tlsts = s.list_num[w]               ; Target list numbers.
            for i=0,ntarg-1 do begin            ; Loop over target lists.
              j = tlsts[i]                      ; Actual target list number.
              list_i = (s.list_list)[j]         ; Get list.
              list_i.add, item                  ; Add item to list.
              txt = list_i.toarray()            ; Convert to string array.
              is = sort(txt)                    ; Sort.
              txt = txt[is]
              list_i = list(txt,/extract)       ; Convert back to list.
              (s.list_list)[j] = list_i         ; Replace with updated list.
              wid = s.id_list[j]                ; Widget ID of target list.
              widget_control,wid,set_value=txt  ; Display updated list.
            endfor ; i

            ;---  Remove item from main list  ---
            if (flag eq 0) and (ntarg ne 0) then begin ; Move from main list.
              list_0.remove, in_sel             ; Remove item from main list.
              txt = list_0.toarray()            ; String array from main list.
              if txt eq !NULL then txt=''
              wid = s.id_list[0]                ; Widget ID of main list.
              widget_control,wid,set_value=txt  ; Display main list.
              (s.list_list)[0] = list_0         ; Replace with updated list.
            endif

            widget_control, ev.top, set_uval=s  ; Save updated info.
            return

          ;---  Right list click  ---
          endif else begin
            list_i = (s.list_list)[nn]          ; Get the target list.
            if n_elements(list_i) eq 0 then return ; If empty ignore click.
            ;---  Remove from target list and display updated  ---
            item = list_i.remove(in_sel)        ; Remove selected item.
            txt = list_i.toarray()              ; Convert to string array.
            if txt eq !NULL then txt=''
            wid = s.id_list[nn]                 ; Widget ID of target list.
            widget_control,wid,set_value=txt    ; Display updated list.
            (s.list_list)[nn] = list_i          ; Replace with updated list.
            ;---  Add to main list and display updated  ---
            txt = list_0.toarray()              ; String array from main list.
            w = where(txt eq item,cnt)          ; Check if item already there.
            if cnt eq 0 then begin              ; Item was not in main.
              txt = [txt,item]                  ; Add item.
              is = sort(txt)                    ; Sort.
              txt = txt[is]
              wid = s.id_list[0]                ; Widget ID of main list.
              widget_control,wid,set_value=txt  ; Display main list.
              list_0 = list(txt,/extract)       ; Convert back to list.
              (s.list_list)[0] = list_0         ; Replace with updated list.
            endif
            
            widget_control, ev.top, set_uval=s  ; Save updated info.
            return
          endelse

        endif


        ;------------------------------------------------------------
        ;  Quit file_sep
        ;------------------------------------------------------------
        if uval eq 'QUIT' then begin
          for i=0,s.nsplit do begin
            list_i = (s.list_list)[i]           ; Grab next list.
            txt = list_i.toarray()              ; Convert to string array.
            if txt eq !null then txt=''         ; Handle null.
            out = numname('LIST_#.txt',i,dig=2) ; Output file name.
            putfile, out, txt                   ; Save list.
            print,' List ',i,' saved in ',out
          endfor ; i
stop
;##########################################
;  Prompt to save lists here.
;  Will save as LIST_xx.xt where xx is the
;  2 digit list number (00 for main list).
;  Use numname.  For list i:
;    out = numname('LIST_#.txt',i,dig=2)
;##########################################
          widget_control, ev.top, /destroy
          return
        endif

        ;------------------------------------------------------------
        ;  Help
        ;------------------------------------------------------------
        if uval eq 'HELP' then begin
          text_block, txt, /widget
; Separate a list of text file names into two or more lists.
;
; File names start in the main list in the left column and
; may be moved or copied to one or more lists on the right.
; A file may also have its contents listed.
;
; Use the dropdown list over the left column to control
; Move, Copy, or List when a file is clicked in that column.
;
; The dropdown list over the right columns controls which
; will receive transfered file names.
;
; Click on a file name in a right column to send it back to
; the main list in the left column.
; 

          return
        endif

        ;------------------------------------------------------------
        ;  Unhandled Event
        ;------------------------------------------------------------
        print,' '
        print,' Unhandled Event'
        print,' '
        help,ev
        print,' '
        print,' UVL = ',uval

        return


        end



        ;----------------------------------------------------------------------
        ;  Main routine
        ;
        ;  This routine allows a list of text files to be separated into
        ;  other lists.  File may be moved or copied from the main list.
        ;
        ;  Main list is split into nsplit other lists.
        ;----------------------------------------------------------------------

        pro file_sep, list00, nsplit=nsplit, directory=dir0, help=hlp

        if keyword_set(hlp) then begin
          print,' Separate a given list of text file names into multiple lists.'
          print,' file_sep, list'
          print,'   list = Text array of file names.      in'
          print,' Keywords:'
          print,'   NSPLIT=ns  Number of new lists to make (def=1).'
          print,'   DIRECTORY=dir Directory of given files (def=current).'
          print,' Notes: If given list of items are not files then the List'
          print,'   action will not do anything.'
          return
        endif

        ;------------------------------------------------------------
        ;  Set defaults
        ;------------------------------------------------------------
        if n_elements(list00) eq 0 then list00=animals()
        if n_elements(nsplit) eq 0 then nsplit=2
        if n_elements(dir0) eq 0 then cd,curr=dir0

        ;------------------------------------------------------------
        ;  Sort incoming list
        ;
        ;  The incoming string array is list00.
        ;  This sorted into txt_list_0.
        ;  This concerted to a list data type, list_0.
        ;  This is used to start a list of lists.
        ;------------------------------------------------------------
        is = sort(list00)                       ; Sort input array.
        txt_list_0 = list00[is]
        list_0 = list(txt_list_0,/extract)      ; Convert to list type.
        list_list = list(list_0)                ; List of lists.

        ;------------------------------------------------------------
        ;  Layout widget
        ;
        ;  A Quit and Help button on top and a short label.
        ;  A main column on the left where items start, and one
        ;  or more columns on the right where items are moved or
        ;  copied.
        ;
        ;  An action (left click) is controlled by the dropdown
        ;  menus above the columns.
        ;------------------------------------------------------------
        top = widget_base(/col, title='File Separator')

        ;---  Control buttons  ---
        b = widget_base(top,/row)
        id = widget_button(b,val='QUIT',uval='QUIT')
        id = widget_label(b,val='      Click on an item      ')
        id = widget_button(b,val='HELP',uval='HELP')

        ;---  Set up columns of lists  ---
        main_dmenu = ['Move','Copy','List']             ; Main list modes.
        targ_dmenu = ['Transfer to here','Inactive']    ; Target lists modes.

        b = widget_base(top,/row)               ; Row of columns.

        ;---  Store list parameters  ---
        list_flags = bytarr(nsplit+1)           ; Action control flags.
        id_list = lonarr(nsplit+1)              ; List widget IDs.

        ;---  Main list  ---
        b2 = widget_base(b,/col)                ; For dropdown menu and list.
        list_flags[0] = 0                       ; 0=Move, 1=Copy, 2=List.
        id = widget_droplist(b2,val=main_dmenu,uval='LIST_D_00')
        id_list[0] = widget_list(b2, $
          xsize=20,ysize=20, $
          val=txt_list_0,uval='LIST_00')

        ;---  Split lists  ---
        for i=1, nsplit do begin                ; Loop over lists.
          nn = string(i,form='(I2.2)')          ; List number (2 digit).
          b2 = widget_base(b,/col)              ; For dropdown menu and list.
          if i eq 1 then flag=0 else flag=1     ; 0=Transfer to here, 1=Inactive
          id = widget_droplist(b2,val=targ_dmenu,uval='LIST_D_'+nn)
          widget_control, id, set_droplist_select=flag ; Set action.
          list_flags[i] = flag                  ; Save action flag.
          id_list[i] = widget_list(b2, $        ; List i on right.
            xsize=20,ysize=20, $
            uval='LIST_'+nn,val='')
          list_list.add, list()                 ; Add an empty list.
        endfor ; i

        ;------------------------------------------------------------
        ;  Pack up info structure and activate widget
        ;
        ;  list_flags = Action flags for each column.
        ;  id_list = List widget IDs.  Needed to update lists.
        ;  id_list = Each list in a list of lists.
        ;  dir = Directory (if any) containing given files.
        ;  nsplit = Number of columns on the right.
        ;  list_num: Number of each list on the right.
        ;------------------------------------------------------------
        s = {list_flags:list_flags, id_list:id_list, $
             list_list:list_list, dir:dir0, nsplit:nsplit, $
             list_num:indgen(nsplit)+1, $
             dum:0}

        widget_control, top, /real, set_uval=s
 
        xmanager, 'file_sep', top, /no_block

        end
