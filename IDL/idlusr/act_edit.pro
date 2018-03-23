;------------------------------------------------------------------------------
;+
; NAME:
;       ACT_EDIT
; PURPOSE:
;       Build and/or Edit an absolute color table.
; CATEGORY:
; CALLING SEQUENCE:
;       act_edit
; INPUTS:
; KEYWORD PARAMETERS:
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
;       Notes: An absolute color table is used to map data
;       values to specified colors, always the same color for the
;       same value.  A color table is built by defining colors at
;       specified points called tiepoints.  The table starts
;       with two tiepoints, the start and end.  Each tiepoint
;       has a value entry area and a color patch.  The value may
;       be changed to move the tiepoint.  The color may be changed
;       by clicking on the color patch and using the color picker
;       to change the color.  Tiepoints may be added or dropped.
;       Colors between tiepoints are interpolated, either in RGB
;       color space, or HSV color space.  The table may also be
;       stepped into descrete color steps of a specified size.
;       The color table may be saved in a text file and read
;       back in.  The tiepoints LO and HI are the table endpoints
;       and define the range of the table.  The range may be
;       changed by changing the values of these points.  The Bar
;       min and max just set how much of the table is displayed,
;       not the actual range covered by the table.  When the table
;       is applied to data using act_apply then data is clipped to
;       the range of the table (which may be freely changed in that
;       routine). The tiepoints positions are displayed above the
;       color bar.
;       
;       To apply a color table to data:
;         img = act_apply(data,file=color_table)
;         (see the built-in help for more options).
;       
;       To display a color bar:
;          act_cbar, vmin, vmax
;         (see the built-in help for more options).
; MODIFICATION HISTORY:
;       R. Sterner, 2007 Dec 17
;       R. Sterner, 2007 Dec 30 --- Fixed some minor problems.
;                                  Tried wheel events.
;       R. Sterner, 2008 Jan 08 --- Added a 2nd color picker option.
;       R. Sterner, 2008 May 21 --- Saved and read barmin, barmax.
;       R. Sterner, 2009 Mar 10 --- Now uses dialog_pickfile to open a file.
;       R. Sterner, 2010 Mar 22 --- Allowed extra items in file.
;       R. Sterner, 2010 Apr 08 --- Minor cleanup.
;       R. Sterner, 2010 Apr 12 --- Fixed problem writing out act_x.
;       R. Sterner, 2010 Nov 15 --- Added log flag. Log tables not yet ready.
;       R. Sterner, 2010 Nov 29 --- Making log color table work.
;       R. Sterner, 2010 Nov 29 --- Also adjusted tiepoint Y scroll size,
;                                   added file name.
;       R. Sterner, 2010 Nov 30 --- Rearranged layout a bit.  Animated text input.
;       R. Sterner, 2010 Dec 01 --- Minor tweaks.
;       R. Sterner, 2010 Dec 30 --- Handled units conversion.
;       R. Sterner, 2010 Dec 31 --- Increased save file name entry area.
;       R. Sterner, 2011 Jan 02 --- Included act_edit_ucon_d internally.
;
; Copyright (C) 2007, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
;______________________________________________________________________________
;
;  Known issues in this routine  (nothing too serious known).
;
;    When typing the Enter key for a tiepoint value (in the text entry area)
;      things flash more than they should.  This is for tiepoints other than
;      LO or HI.  It seems that focus goes to HI and then gets set back.
;      Don't know why HI gets focus.
;
;    When entering a new value for a tiepoint, check if same as old and
;      do nothing if so (except maybe animate).
;
;    When the tiepoint list gets refreshed (like in the above item) some
;      excess blank space appears at the bottom of the list when it is not
;      a scrolling list.  Not sure where that comes from.
;
;    When updating a tiepoint in the lower section (out of view before
;      scrolling) of the list it jumps back out of view.
;
;    Can click on a tiepoint marker in above the color bar but so far
;      nothing has been made to happen.  It knows which tiepoint was clicked.
;______________________________________________________________________________

        ;==================================================================
        ;==================================================================
        ;  act_edit_ucon_d = Units conversion dialog widget
        ;
        ;    act_edit_ucon_d, s, count
        ;      s = Absolute color table structure.
        ;
        ;    Looks for:
        ;      units = Default units for colort table.
        ;      new_units = Allowed new units (like deg F).
        ;      slope = Slope.  new_units = default_units*m + b
        ;      offset = Offset.
        ;==================================================================
        ;==================================================================

        ;------------------------------------------------------------------
        ;  Event handler for units conversion widget dialog
        ;------------------------------------------------------------------
        pro act_edit_ucon_d_event, ev

        common act_edit_ucon_d_event_com, list  ; List of test values.

        widget_control, ev.id, get_uval=uval
        widget_control, ev.top, get_uval=info

        ;---------------------------------------
        ;  OK
        ;---------------------------------------
        if uval eq 'OK' then begin
          widget_control, info.id_tab, get_val=tbl      ; Grab conversion table.
          new_unt = strtrim(tbl[0,*],2)                 ; Check new units.
          new_slp = tbl[1,*]                            ; Slope.
          new_off = tbl[2,*]                            ; Offset.
          w = where(new_unt ne '',cnt)                  ; How many?
          if cnt ne 0 then begin                        ; If some then grab ...
            new_unt = new_unt[w]                        ;   new units,
            new_slp = new_slp[w]                        ;   new slope,
            new_off = new_off[w]                        ;   new ofset.
            s = info.s                                  ; Grab color table.
            tag_add,s,'new_units',new_unt               ; Add units conversion.
            tag_add,s,'slope',new_slp
            tag_add,s,'offset',new_off
          endif
          widget_control, info.res,set_uval=s           ; Save updated table.
          widget_control, ev.top, /destroy              ; Destroy widget.
          return
        endif

        ;---------------------------------------
        ;  Cancel
        ;---------------------------------------
        if uval eq 'CAN' then begin
          s = info.s                                    ; Grab color table.
          widget_control, info.res,set_uval=s           ; Save updated table.
          widget_control, ev.top, /destroy
          return
        endif

        ;---------------------------------------
        ;  DUN  Conversion table entry.
        ;---------------------------------------
        if uval eq 'DUN' then begin
          widget_control, info.id_dun, get_val=units    ; Def units required.
          if units eq '' then return                    ; Was none.
          s = info.s                                    ; Get colort table.
          tag_add, s, 'units', units[0]                 ; Add units to it.
          tag_add, info, 's', s                         ; Put tbl back in info.
          widget_control, info.b_u, sensitive=1         ; Now allow conversion.
          widget_control, ev.top, set_uval=info         ; Save info.
          return
        end

        ;---------------------------------------
        ;  Debug
        ;---------------------------------------
        if uval eq 'BUG' then begin
          stop,'STOP: .con to continue'
          return
        endif

        ;---------------------------------------
        ;  Help
        ;---------------------------------------
        if uval eq 'HELP' then begin
          text_block,/widget,/wait,group=ev.top
; An absolute color table has some default units.
; For example, a color table for temperature may be in
; deg K.  Values to display with this color table must
; also be in deg K by default.  Units conversion may be
; added to the absolute color table to allow it to be
; used with other units.  For example the deg K color
; table may have conversions for deg C and deg F.
;
; The default units are required before units conversions
; may be added.  In the example above that would be deg K
; (or perhaps just K for some purposes).  If the default
; units is blank it must be entered first.  If the default
; units are picked up by software from some data set then use
; use the same exact units as the software will pick up.
; For example, WRF data sets use K for deg K, so the default
; units should be set to just K.  Make sure to use the "Enter"
; key when giving the default units.
;
; Then conversions to other units may be entered in the
; units conversion table.  Only linear converions are handled,
; they must be of the form:
;      new_units = default_units*slope + offset
; In the above example the default units are deg K.
; To add units conversions for deg C and deg F enter into
; to correct columns of the table the following:
;
; +------------+---------+----------+
; | New units  |  Slope  |  Offset  |
; +------------+---------+----------+
; | deg C      | 1       | -273.15  |
; | deg F      | 1.8     | -459.67  |
; +------------+---------+----------+
;
; The units conversion may be tested using the Test button. It
; will request a list of values which should be entered in the
; default units.  These values will be converted to the other
; units given in the table to check if the conversions are working
; correctly.  For example, the above example might be tested
; using the values: 273.15 323.15 373.15
; Click the "Accept entry" button and the following is displayed:
; Test conversions:
;     From K to deg C:
;       273.15 K = 0.00000 deg C
;       323.15 K = 50.0000 deg C
;       373.15 K = 100.000 deg C
;     From K to deg F:
;       273.15 K = 32.0000 deg F
;       323.15 K = 122.000 deg F
;       373.15 K = 212.000 deg F
;
; Make sure to use the "Enter" key for the units conversion table
; values, at least for the last value entered (tabs will jump to
; next column, but not down).
;
; The "OK" button will accept any changes, "Cancel" will ignore them.
;
; To use the color table with units conversion do:
;
;    img = act_apply(z,...,units='deg F')
;
; where z must be in deg F.
;

          return
        endif

        ;---------------------------------------
        ;  Test  Units conversion.
        ;---------------------------------------
        if uval eq 'TEST' then begin
          widget_control, info.id_dun, get_val=units
          if units eq '' then begin                     ; Must have def units.
            xmess,['Must enter a value for default units.',$
                   'Also must have at least one units conversion',$
                   'entered into table.']
            return
          endif
          widget_control, info.id_tab, get_val=tbl      ; Get conversions.
          if tbl[0,0] eq '' then begin                  ; Any?
            xmess,'Must have at least one units conversion entered into table.'
            return
          endif
          if n_elements(list) eq 0 then list=''
          xtxtin, out, title='Enter a few test values in units of '+ $
            info.s.units, def=list                      ; Get some test values.
          if out eq '' then return                      ; None entered.
          list = out                                    ; Remember them.
          wordarray,out,list0,number=nlist              ; Break into a list.
          new_unt = tbl[0,*]                            ; Grab conversion items.
          new_slp = tbl[1,*]
          new_off = tbl[2,*]
          w = where(new_unt ne '',cnt)                  ; Ingore blank lines.
          new_unt = new_unt[w]                          ; Units.
          new_slp = new_slp[w] + 0.                     ; Slope.
          new_off = new_off[w] + 0.                     ; Offset.

          print,' Test conversions:'
          for i=0,cnt-1 do begin                        ; Loop over new units.
            print,'     From '+units+' to '+new_unt[i]+':'
            for j=0,nlist-1 do begin                    ; Loop over test values.
              print,'       '+list0[j]+' '+units+' = ' + $
                strtrim(list0[j]*new_slp[i] + new_off[i],2) + ' ' + new_unt[i]
            endfor ; j
          endfor ; i
          return
        endif

        end


        ;------------------------------------------------------------------
        ;  Units conversion widget dialog
        ;
        ;  R. Sterner, 2010 Dec 24
        ;------------------------------------------------------------------
        pro act_edit_ucon_d, s
 
        top = widget_base(/col,title='Units Conversion')

        ;---  Text at top  ---
        text_block, t, /quiet
; Units Conversions allow the color table to be converted
; from the default units to new units.
;     new_units = default_units*slope + offset
; To use: img = act_apply(z,...,units='deg F')

        id = widget_text(top,ysize=n_elements(t),val=t)

        ;---  Default units  ---
        if tag_test(s,'units') eq 0 then begin
          utxt = ''
          uflag = 0
        endif else begin
          utxt = s.units
          uflag = 1
        endelse
        b = widget_base(top,/row)
        id = widget_label(b,val='Default units: ')
        id_dun = widget_text(b,xsize=10,/edit, val=utxt, uval='DUN')

        ;---  New units area  ---
        ;      new_units = Allowed new units (like deg F).
        ;      slope = Slope.  new_units = default_units*m + b
        ;      offset = Offset.
        if tag_test(s,'new_units') eq 1 then begin
          if tag_test(s,'slope') eq 0 then stop,' ERROR: no slope.'
          if tag_test(s,'offset') eq 0 then stop,' ERROR: no offset.'
          n_units = n_elements(s.new_units)
          utable = strarr(3,n_units+4)
          for i=0,n_units-1 do begin
            utable[0,i] = s.new_units[i]
            utable[1,i] = s.slope[i]
            utable[2,i] = s.offset[i]
          endfor
        endif else begin
          utable = strarr(3,4)
        endelse
        b_u = widget_base(top,/col,/frame)
        id = widget_label(b_u,val='Units conversions')
        tlab = ['New units','Slope','Offset']
        id_tab = widget_table(b_u, val=utable,/edit,$
          column_labels=tlab, uval='TAB')
        widget_control, b_u, sensitive=uflag

        ;---  Buttons  ---
        b = widget_base(top,/row)
        id = widget_button(b, val='OK',uval='OK')
        id = widget_button(b, val='Cancel',uval='CAN')
        id = widget_label(b,val='  ')
        id = widget_button(b, val='Test',uval='TEST')
        id = widget_label(b,val='  ')
        id = widget_button(b, val='Help',uval='HELP')
;       id = widget_button(b, val='Debug',uval='BUG')

        ;---  Unused base for return value  ---
        res = widget_base()

        ;---  Pack up info  ---
        if n_elements(s) eq 0 then s=''
        info = {s:s, res:res, b_u:b_u, id_dun:id_dun,id_tab:id_tab}

        ;--- Activate widget  ---
        widget_control, top, /real, set_uval=info
        xmanager, 'act_edit_ucon_d', top

        ;---  Return updated color table structure  ---
        widget_control, res, get_uval=s
        
        end


	;==================================================================
	;==================================================================
	;  act_edit_animate = animate entered text
	;==================================================================
	;==================================================================
	pro act_edit_animate, wid, val

        n = 3
        d = 0.04

        for i = -n, n do begin
          s = spc(n-abs(i))
          widget_control, wid, set_val=s+val
          wait,d
        endfor

        end


	;==================================================================
	;==================================================================
	;  act_edit_refresh_bar = Refresh color bar
	;==================================================================
	;==================================================================
	pro act_edit_refresh_bar, s
 
	wset, s.winbar					; Set to bar window.
	win_redirect					; Hold display update.
	erase, -1					; Fill with white.
        
	ihi = s.tp_num - 1				; Index of HI.
	bmin = s.barmin					; Bar minimum.
	bmax = s.barmax					; Bar maximum.
	val = s.tp_val_list				; Tiepoint values.
	rgb = s.rgb					; Interp mode.
	log = s.log					; Log flag.
	hsv = s.tp_hsv					; Colors.
	sact = {z:val,h:hsv[0,*],s:hsv[1,*], $		; Pack into structure.
	  v:hsv[2,*],rgb:rgb, log:log, $
	  step_flag:s.step_flag, step:s.step, $
	  step_offset:s.step_offset}
	img = act_apply(str=sact)			; Set color table.
        act_cbar, bmin,bmax,col=0,xticklen=-.08,$
          chars=1.5,pos=s.bpos,/keep_scaling
        put_scale                                       ; Color bar plot scaling.

        vpt = val
        if log then vpt = alog10(vpt)
	ver,vpt,col=0,pointer=[.3,.02],/out,/top	; Mark tiepoints.
	win_copy					; Update display.
 
	end
 
 
	;==================================================================
	;==================================================================
	;  act_edit_refresh_tp = Refresh tiepoint list
	;
	;  Can take an optional old info structure.  If given it will be
	;  used to erase old tiepoints.
	;==================================================================
	;==================================================================
	pro act_edit_refresh_tp, s, s_old
 
	;---  If old info given use to erase tiepoints  ---
	if n_elements(s_old) gt 0 then s2=s_old else s2=s
	ihi = s2.tp_num-1			; Old index for HI.
	for i=1,ihi-1 do begin			; Erase tiepts.
	  widget_control, s2.tp_bas_list[i], /destroy
	endfor
	;---  Set up tiepoint area  ---
	ihi = s.tp_num - 1
        if ihi gt 1 then begin
	  ysz = (ihi*s.tpdy+10)<s.max_y_scr
	  widget_control,s.id_tp,scr_ysize=ysz	; Scroll size.
        endif else begin
	  widget_control,s.id_tp,scr_ysize=1	; Scroll size.
        endelse
	;---  Get ready to update info structure  ---
	blo = s.tp_bas_list[0]
	bhi = s.tp_bas_list[ihi]
	val = s.tp_val_list			; List of vals.
	is = sort(val)				; Sort on vals.
	tag_add, s, 'tp_hsv', s.tp_hsv[*,is]	; Sort colors.
	tag_add, s, 'tp_val_list', s.tp_val_list[is]		; Sort Values.
	tag_add, s, 'tp_ind_list', makes(0,s.tp_num-1,1,dig=3)	; Update indics.
        tp_bas_list = [blo]
        if s.tp_num gt 2 then tp_bas_list = [tp_bas_list,lonarr(s.tp_num-2)]
        tp_bas_list = [tp_bas_list,bhi]
	tag_add, s, 'tp_bas_list', tp_bas_list	; Space for Base WIDs.
        txt_lo = s.tp_txt_list[0]               ; Grab LO and HI text WIDs.
        txt_hi = s.tp_txt_list[n_elements(s.tp_txt_list)-1]
        tp_txt_list = tp_bas_list               ; Copy to get correct number.
        tp_txt_list[0] = txt_lo                 ; Preseve LO and HI text WIDs.
        tp_txt_list[ihi] = txt_hi
	tag_add, s, 'tp_txt_list', tp_txt_list	; Space for Text WIDs.
	;---  Create new tiepoint controls  ---
	for i=1,ihi-1 do begin			; Display tiepts.
	  id_tp1 = widget_base(s.id_tp,/row)	; Base for tiept controls.
	  s.tp_bas_list[i] = id_tp1
	  id = widget_label(id_tp1,val='   ')	; Spacer for layout.
	  id = widget_label(id_tp1,val=s.tp_ind_list[i]) ; Tiept label (index).
	  id = widget_text(id_tp1,val=strtrim(s.tp_val_list[i],2), $
	    uval='VAL '+s.tp_ind_list[i],/edit,xsize=15) ; Tiept val text area.
          s.tp_txt_list[i] = id                 ; Save new text area WID.
	  id = widget_label(id_tp1,val='   ')	; Spacer for layout.
	  id = widget_draw(id_tp1,xs=s.psz,ys=s.psz, $
	    uval='DRW '+s.tp_ind_list[i],$
	    /button_events, /align_bottom)	; Color at tiepoint.
	  widget_control, id, get_val=win	; Get draw widget win indx.
	  wset, win				; Make current window.
	  erase, tarclr(/hsv,s.tp_hsv[*,i])	; Fill new color patch.
	endfor
	;---  Show updated color bar  ---
	act_edit_refresh_bar, s			; Update color bar.
 
	end
 
 
	;==================================================================
	;==================================================================
	;  act_edit_event = Event handler
	;==================================================================
	;==================================================================
	pro act_edit_event, ev
 
	widget_control, ev.id, get_uval=uval	; Get command (= UVAL).
	uval1 = getwrd(uval,0)			; First word in UVAL.
	
	;-----------------------------------------------------------
	;  DONE: Clean up and exit
	;-----------------------------------------------------------
	if uval eq 'DONE' then begin
	  widget_control, ev.top, /destroy
	  return
	endif
 
	;-----------------------------------------------------------
	;  ADD: Add a new tiepoint to color table
	;    New tiepoint will appear after last tiepoint.
	;    Edit the value to rearrange tiepoints.
	;-----------------------------------------------------------
	if uval eq 'ADD' then begin
	  widget_control, ev.top, get_uval=s		; Get info.
	  ihi = s.tp_num-1				; Index of HI.
	  val_lo = s.tp_val_list[0]			; LO value.
	  val_hi = s.tp_val_list[ihi]			; HI value.
	  if s.tp_num eq 2 then begin			; First tiepoint.
            if s.log then begin
	      tp_val = midv_log_fr([val_lo,val_hi])	; Tiepoint value for log.
            endif else begin
	      tp_val = midv([val_lo,val_hi])		; Tiepoint value for linear.
            endelse
	    tp_ind = '001'				; Tiepoint index.
	  endif else begin				; Added tiepoint.
	    val_last = s.tp_val_list[ihi-1]		; Last tiepoint val.
            if s.log then begin
	      tp_val = midv_log_fr([val_last,val_hi])	; Tiepoint value for log.
            endif else begin
	      tp_val = midv([val_last,val_hi])		; Tiepoint value for linear.
            endelse
	    last_ind = s.tp_ind_list[ihi-1]		; Last tiepoint index.
	    tp_ind = string(last_ind+1,form='(I3.3)')	; Tiepoint index.
	  endelse
	  ysz = (ihi*s.tpdy+10)<s.max_y_scr		; Y scroll size.
	  widget_control,s.id_tp,scr_ysize=ysz		; Scroll size.
	  id_tp = s.id_tp				; Main base.
	  id_tp1 = widget_base(id_tp,/row)		; Base for tiept cntrls.
	  id = widget_label(id_tp1,val='   ')		; Spacer for layout.
	    id = widget_label(id_tp1,val=tp_ind)	; Tiepoint label (indx).
	  id_txt = widget_text(id_tp1,val=strtrim(tp_val,2),uval='VAL '+tp_ind, $
	    /edit,xsize=15)				; Tiepoint val txt area.
	  id = widget_label(id_tp1,val='   ')		; Spacer for layout.
	  id = widget_draw(id_tp1,xs=s.psz,ys=s.psz,uval='DRW '+tp_ind, $
	    /button_events, /align_bottom)		; Color at tiepoint.
	  widget_control, id, get_val=win		; Get tiepoint clr win.
	  v = (tp_val-val_lo)/(val_hi-val_lo)		; Make default color.
	  hsv = [0.,0.,v]				; HSV format.
	  clr = tarclr(/hsv,hsv)			; Actual color.
	  wset, win					; Set to cclr patch win.
	  erase, clr					; Fill with clr.
	  ;---  Update info structure  ---
	  bt_bas = s.tp_bas_list[0:ihi-1]		; Grab all but HI,
	  hi_bas = s.tp_bas_list[ihi]			; then HI itself,
	  bt_txt = s.tp_txt_list[0:ihi-1]		; for the needed parts.
	  hi_txt = s.tp_txt_list[ihi]
	  bt_ind = s.tp_ind_list[0:ihi-1]
	  hi_ind = string(s.tp_ind_list[ihi]+1,form='(I3.3)')
	  bt_val = s.tp_val_list[0:ihi-1]
	  hi_val = s.tp_val_list[ihi]
	  bt_hsv = s.tp_hsv[*,0:ihi-1]
	  hi_hsv = s.tp_hsv[*,ihi]
	  ;---  Insert new tiepoint values into info structure  ---
	  tag_add, s, 'tp_bas_list',[bt_bas,id_tp1,hi_bas] ; Add base WID.
	  tag_add, s, 'tp_txt_list',[bt_txt,id_txt,hi_txt] ; Add text WID.
	  tag_add, s, 'tp_ind_list',[bt_ind,tp_ind,hi_ind] ; Add index.
	  tag_add, s, 'tp_val_list',[bt_val,tp_val,hi_val] ; Add tiept value.
	  tag_add, s, 'tp_hsv',[[bt_hsv],[hsv],[hi_hsv]]   ; Add new clr (blck).
	  s.tp_num += 1					; Increment count.
	  s.modflag = 1					; Set modified flag.
	  widget_control, ev.top, set_uval=s		; Save updated info.
	  act_edit_refresh_bar, s			; Update color bar.
	  return
	endif
 
	;-----------------------------------------------------------
	;  DROP: Drop a tiepoint.
	;
	;  Drop a tiepoint by keeping compliment.
	;  Use the update keyword to avoid flicker.
	;-----------------------------------------------------------
	if uval eq 'DROP' then begin
	  widget_control, ev.top, get_uval=s
	  ihi = s.tp_num - 1				; Index of HI.
	  if s.tp_num lt 3 then return			; No tiepoints.
	  if s.tp_num gt 3 then begin
	    itm = xlist(s.tp_ind_list[1:ihi-1], $	; Select tiept to drop.
	      /wait,index=in)
	  endif else begin				; Only one to drop.
	    in = 0
	    itm = '001'
	  endelse
	  if in lt 0 then return			; Canceled.
	  w = where(itm eq s.tp_ind_list, cnt, comp=wc, ncomp=cntc)
	  widget_control, s.top, update=0		; Don't update til done.
	  s.modflag = 1					; Set modified flag.
	  widget_control, s.tp_bas_list[w],/destroy	; Drop tiepoint.
	  s.tp_num -= 1			        	; Decrement tiepoints.
	  n = s.tp_num - 2
	  ysz = (n*s.tpdy+10)<s.max_y_scr
	  if ysz eq 10 then ysz=1
	  widget_control,s.id_tp,scr_ysize=ysz		; Scroll size.
	  if cntc eq 2 then begin			; Dropped last tiepoint.
	    tag_add, s, 'tp_ind_list',['000','001']	; Just LO and HI.
	  endif else begin				; Some tiepoints left.
	    tag_add, s, 'tp_ind_list',s.tp_ind_list[wc] ; Drop index.
	  endelse
	  tag_add, s, 'tp_hsv', s.tp_hsv[*,wc]		; Drop color.
	  tag_add, s, 'tp_bas_list',s.tp_bas_list[wc]	; Drop base WID.
	  tag_add, s, 'tp_txt_list',s.tp_txt_list[wc]	; Drop text WID.
	  tag_add, s, 'tp_val_list',s.tp_val_list[wc]	; Drop tiept value.
	  if s.tp_num gt 2 then act_edit_refresh_tp, s
	  widget_control, s.top, update=1		; Update changes.
	  widget_control, ev.top, set_uval=s		; Save updated info.
	  act_edit_refresh_bar, s			; Update color bar.
	  return
	endif
 
	;-----------------------------------------------------------
	;  VAL iii: Reorder a tiepoint by changing it's value.
	;-----------------------------------------------------------
	if uval1 eq 'VAL' then begin
 
	  widget_control, ev.top, get_uval=s		; Get info.
	  w1 = getwrd(uval,1)				; Get 2nd part of UVAL.
	  ihi = s.tp_num - 1				; Index of HI.
	  LO = '000'					; Index text for LO.
	  HI = string(ihi,form='(I3.3)')		; Index text for HI.
	  if w1 eq 'LO' then w1=LO			; Convert to numeric.
	  if w1 eq 'HI' then w1=HI
	  val = s.tp_val_list				; Get tiepoint values.
 
	  ;---  Handle LO and HI value changes ---
	  s.modflag = 1					; Set modified flag.
	  if (w1 eq LO) or (w1 eq HI) then begin	; Specl case: Lo or HI.
	    widget_control, ev.id, get_val=newval	; Get entered value.
            act_edit_animate, ev.id, newval             ; Animate it.
	    newval = newval[0]*1.			; Convert to numeric.
	    if w1 eq LO then begin			; Make sure LO is lowst.
	      if newval ge min(val[1:ihi]) then begin	; Is new LO too high?
	        xmess,'LO must be < lowest tiepoint value.'
	        widget_control, ev.id, set_val=string(val[0]) ; Restore orignal.
	        return
	      endif
	      s.tp_val_list[0] = newval			; New LO OK, save it.
	    endif
	    if w1 eq HI then begin			; make sure HI highest.
	      if newval le max(val[0:ihi-1]) then begin	; Is new HI too low?
	        xmess,'HI must be > highest tiepoint value.'
	        widget_control, ev.id, set_val=string(val[ihi]) ; Restore orig.
	        return
	      endif
	      s.tp_val_list[ihi] = newval		; New HI OK, save it.
	    endif
	    widget_control, ev.top, set_uval=s		; Save updated info.
	    act_edit_refresh_bar, s			; Update color bar.
	    return
	  endif
	  ;---  handle tiepoint value change  ---
	  in = w1 + 0					; Index of tiepoint.
	  widget_control, ev.id, get_val=newval		; Entered value.
          act_edit_animate, ev.id, newval               ; Animate it.
	  newval = newval[0]*1.				; Convert to numeric.
	  oldval = s.tp_val_list[in]			; Old value.
	  if newval le val[0] then begin		; Cannot go below LO.
	    xmess,'Entered value must be > LO'
	    widget_control,ev.id,set_val=string(oldval)	; Restore old.
	    return
	  endif
	  if newval ge val[ihi] then begin		; Cannot go above HI.
	    xmess,'Entered value must be < HI'
	    widget_control,ev.id,set_val=string(oldval)	; Restore old.
	    return
	  endif
	  s.tp_val_list[in] = newval			; Update value with new.
	  widget_control, s.top, update=0		; Don't update til done.
	  if s.tp_num gt 0 then act_edit_refresh_tp,s	; Sort order.
	  widget_control, s.top, update=1		; Update changes.
	  widget_control, ev.top, set_uval=s		; Save updated info.
	  act_edit_refresh_bar, s			; Update color bar.
          w = where(newval eq s.tp_val_list)            ; Follow tp if moved.
          wid = s.tp_txt_list[w[0]]                     ; Widget ID of tiepoint.
          widget_control, wid, /input_focus             ; Jumped to HI, set back.
	  return
	endif
 
	;-----------------------------------------------------------
	;  DRW iii: Change color
	;-----------------------------------------------------------
	if uval1 eq 'DRW' then begin
	  if ev.release eq 0 then return		; Trigger on release.
	  widget_control, ev.top, get_uval=s		; Get info.
	  if (ev.x lt 0)     or (ev.y lt 0)     then return ; Outside box.
	  if (ev.x ge s.psz) or (ev.y ge s.psz) then return ; Outside box.
 
	  w1 = getwrd(uval,1)				; Get 2nd part of UVAL.
	  ihi = s.tp_num - 1				; Index of HI.
	  LO = '000'					; Index text for LO.
	  HI = string(ihi,form='(I3.3)')		; Index text for HI.
	  if w1 eq 'LO' then w1=LO			; Convert to numeric.
	  if w1 eq 'HI' then w1=HI
	  hsvarr = s.tp_hsv
 
	  if (w1 eq LO) or (w1 eq HI) then begin	; Spec case: Lo or HI.
	    if (w1 eq LO) then hsv = hsvarr[*,0]	; LO HSV.
	    if (w1 eq HI) then hsv = hsvarr[*,ihi]	; HI HSV.
	  endif else begin				; Tiepoint.
	    in = w1 + 0					; Tiepoint index.
	    hsv = hsvarr[*,in]				; Tiepoint HSV.
	  endelse
	  clr1 = tarclr(/hsv,hsv)			; Current color.
	  if s.cpick eq 1 then begin			; Get new color.
	    color_pick, clr2, clr1			; Using wheel and bar.
	  endif else begin
	    color_pick2, clr2, clr1			; Using RGB/HSV sliders.
	  endelse
	  if clr2 eq -1 then return			; Canceled.
	  widget_control, ev.id, get_val=win		; Get draw WID.
	  wset, win					; Set as current window.
	  erase, clr2					; Fill with new color.
	  c2hsv, clr2, hh, ss, vv			; New color to HSV.
	  hsv = [hh,ss,vv]				; Pack in array.
	  if (w1 eq LO) or (w1 eq HI) then begin	; Spec case: Lo or HI.
	    if (w1 eq LO) then s.tp_hsv[*,0]=hsv	; LO HSV.
	    if (w1 eq HI) then s.tp_hsv[*,ihi]=hsv	; HI HSV.
	  endif else begin				; Tiepoint.
	    s.tp_hsv[*,in]=hsv				; Tiepoint HSV.
	  endelse
	  widget_control, ev.top, set_uval=s		; Save updated info.
	  act_edit_refresh_bar, s			; Update color bar.
	  return
	endif
 
	;-----------------------------------------------------------
	;  OPEN: Read color table
	;-----------------------------------------------------------
	if uval eq 'OPEN' then begin
	  widget_control, ev.top, get_uval=s		; Get info.
	  s2 = s					; Copy before changing.
	  ihi = s2.tp_num - 1				; Old HI index.
	  bas_lo = s2.tp_bas_list[0]			; LO base (keep).
	  bas_hi = s2.tp_bas_list[ihi]			; HI base (keep).
	  def = s.svdef					; Default input name.
	  ;------------------------------------
	  f = file_search('act_*.txt',count=cnt)	; Look for act_*.txt files.
	  if cnt gt 1 then begin			; Found more than 1.
	    r = dialog_pickfile(filter='act_*.txt',file=def) ; Let user pick one.
	    sname = r[0]
	  endif else begin				; Found just 1.  Open it.
	    sname = f[0]
	  endelse
	  if sname eq '' then return			; Cancelled.
	  ;------------------------------------
	  s.svdef = sname				; Remember name as def.
	  act = txtdb_rd(sname,error=err)		; Read color table.
	  if err ne 0 then begin
	    xmess,'Could not open '+sname
	    return
	  endif
          widget_control, s.id_name,set_val=sname
          if tag_test(act,'log') eq 1 then log=act.log else log=0
          if tag_test(act,'abs_flag') eq 1 then $
            abs_flag=act.abs_flag else abs_flag=0
          if tag_test(act,'desc') eq 1 then $
            desc=act.desc else desc=''
	  rgb = act.rgb					; Extract parts.
	  val = act.z					; Val list from clr tbl.
	  if tag_test(act,'BARMIN') eq 0 then begin	; Not in color table.
	    barmin = min(val)				; Use max range for
	    barmax = max(val)				; bar display.
	  endif else begin
	    barmin = act.barmin
	    barmax = act.barmax
	  endelse
	  lo = string(min(val))				; LO and HI.
	  hi = string(max(val))
	  hh = transpose(act.h)				; Build HSV table from
	  ss = transpose(act.s)				; color table.
	  vv = transpose(act.v)
	  hsv = [hh,ss,vv]
	  ;---  Update structure  ---
          s.desc = desc
	  s.tp_num = n_elements(val)			; Number of colors.
	  ihi = s.tp_num - 1				; New HI index.
	  s.barmin = barmin				; Bar display range.
	  s.barmax = barmax
          s.rgb = rgb                                   ; rgb flag.
          s.log = log                                   ; log flag.
          s.abs_flag = abs_flag
	  s.step_flag = act.step_flag
	  s.step = act.step
	  s.step_offset = act.step_offset
	  tag_add, s, 'tp_hsv', hsv			; Colors.
	  tag_add, s, 'tp_val_list', val		; Tiept values.
          tp_bas_list = [bas_lo]
          if ihi gt 1 then tp_bas_list = [tp_bas_list,lonarr(ihi-1)]
          tp_bas_list = [tp_bas_list,bas_hi]
	  tag_add, s, 'tp_bas_list', tp_bas_list        ; TP bases.
          ;---  Units conversion if any  ---
          if tag_test(act,'units') then tag_add,s,'units',act.units
          if tag_test(act,'new_units') then tag_add,s,'new_units',act.new_units
          if tag_test(act,'slope') then tag_add,s,'slope',act.slope
          if tag_test(act,'offset') then tag_add,s,'offset',act.offset
	  ;---  Update widget  ---
	  widget_control, s.id_desc, set_val=desc
	  widget_control, s.id_abs, set_button=s.abs_flag
	  stat = (['NO','YES'])[s.abs_flag]
	  widget_control, s.id_absstat, set_val=stat
	  widget_control, s.id_sflag, set_button=s.step_flag
	  stat = (['NO','YES'])[s.step_flag]
	  widget_control, s.id_stepstat, set_val=stat
	  widget_control, s.id_bstep2, sensitive=s.step_flag
	  widget_control, s.id_step, set_val=string(s.step)
	  case float(s.step_offset) of
-0.5:	    widget_control, s.id_stepm, /set_button
 0.0:	    widget_control, s.id_stepz, /set_button
 0.5:	    widget_control, s.id_stepp, /set_button
	  endcase
	  widget_control, s.id_bmin, set_val=string(barmin) ; Bar display range.
	  widget_control, s.id_bmax, set_val=string(barmax)
	  widget_control, s.id_rgb, set_button=rgb	; Interp mode button.
	  widget_control, s.id_hsv, set_button=1-rgb	; Interp mode button.
	  widget_control, s.id_log, set_button=log	; Type button (linear/log).
	  widget_control, s.id_lin, set_button=1-log	; Type button (linear/log).
	  widget_control, s.id_val_lo, set_val=lo	; Update LO.
	  widget_control, s.id_val_hi, set_val=hi	; Update HI.
	  wset, s.winlo					; Set LO clr window.
	  erase, tarclr(/hsv,hsv[*,0])			; Fill LO color.
	  wset, s.winhi					; Set HI clr window.
	  ihi = s.tp_num - 1				; HI index.
	  erase, tarclr(/hsv,hsv[*,ihi])		; Fill HI color.
	  ;---  Update tiepoints on widget  ---
	  act_edit_refresh_tp, s, s2			; Update Tiept display.
          ;---  Save any extra items from act file  ---
          act_x = act                           ; Copy of act file in structure.
          tag_move,['__text000','rgb','log','z','h','s','v','barmin','barmax', $
            'abs_flag','desc','step_flag','step','step_offset', $
            'units','new_units','slope','offset','__text001'],$
            act_x,tmp                                   ; Move all known items out.
          ;---  Save in s  ---
          ;  Any extra items that were in the structure act that are not the
          ;  standard known items (as listed in the tag_move above) are copied
          ;  to structure s as a member structure named act_x.  If no extra
          ;  items than act_x will be a null string in structure s.
          tag_add, s, 'act_x', act_x                    ; Move extra to act_x substruct.
	  widget_control, ev.top, set_uval=s		; Save updated info.
	  return
	endif
 
	;-----------------------------------------------------------
	;  SAVE: Save color table
	;-----------------------------------------------------------
	if uval eq 'SAVE' then begin
	  widget_control, ev.top, get_uval=s	        ; Get info.
	  def = s.svdef					; Default output name.
	  xtxtin, sname, title='Enter color table name to SAVE', $
	    def=def,xsize=80				; Get new name.
	  if sname eq '' then return			; Cancelled.
	  s.svdef = sname				; Remember name as def.
	  widget_control, ev.top, set_uval=s	        ; Save default.
	  openw,lun,sname,/get_lun	 		; Open output file.
          ;---  Write out file name  ---
	  printf,lun,' Absolute color table: '+sname
	  printf,lun,' '
	  printf,lun,' desc = ',s.desc
          ;---  Write out extra items if any  ---
          if tag_test(s,'act_x') then begin
            if datatype(s.act_x) eq 'STC' then begin
              xtags = strlowcase(tag_names(s.act_x)) + ' = '
              printf,lun,' '
              for ix=0,n_elements(xtags)-1 do begin
                printf,lun,' '+xtags[ix]+string(s.act_x.(ix))
              endfor ; ix
            endif ; datatype
          endif ; tag_test
          ;---  Write out standard items  ---
	  printf,lun,' '
	  printf,lun,' step_flag = ',s.step_flag
	  printf,lun,' step = ',s.step
	  printf,lun,' step_offset = ',s.step_offset
	  printf,lun,' log = '+strtrim(s.log,2)
	  printf,lun,' rgb = '+strtrim(s.rgb,2)
	  printf,lun,' abs_flag = '+strtrim(s.abs_flag,2)
	  printf,lun,' barmin = ',s.barmin
	  printf,lun,' barmax = ',s.barmax
          if tag_test(s,'units') then printf,lun,' units = ',s.units
          if tag_test(s,'new_units') then begin
	    printf,lun,' '
	    printf,lun,' Units Conversion: new_units = old_units*slope + offset'
	    printf,lun,' '
	    printf,lun,' NEW_UNITS             SLOPE             OFFSET'
	    printf,lun,'      S                  S                  S'
	    printf,lun,'----------------   ---------------   ---------------'
            for i=0,n_elements(s.new_units)-1 do begin
              printf,lun,s.new_units[i],s.slope[i],s.offset[i], $
                format='(A15,3X,A15,3X,A15)'
            endfor
          endif
	  printf,lun,' '
	  printf,lun,' Color table: Z=Independent Variable, H=Hue, S=Stauration, V=Value.'
	  printf,lun,' '
	  printf,lun,'      Z               H            S            V'
	  printf,lun,'      F               F            F            F'
	  printf,lun,'-------------      -------     --------     --------'
	  for i=0,s.tp_num-1 do printf,lun,s.tp_val_list[i],s.tp_hsv[*,i]
	  printf,lun,' '
	  free_lun, lun
	  print,' Color table saved in txtdb file '+sname
	  return
	endif
 
	;-----------------------------------------------------------
	;  BARMIN: Change bar minimum
	;-----------------------------------------------------------
	if uval eq 'BARMIN' then begin
	  widget_control, ev.top, get_uval=s		; Get info.
	  widget_control, ev.id, get_val=val		; Get new value.
          act_edit_animate, ev.id, val                  ; Animate it.
	  s.barmin = val + 0.0				; Save in info.
	  widget_control, ev.top, set_uval=s		; Save updated info.
	  act_edit_refresh_bar, s			; Update color bar.
	  return
	endif
 
	;-----------------------------------------------------------
	;  BARMAX: Change bar maximum
	;-----------------------------------------------------------
	if uval eq 'BARMAX' then begin
	  widget_control, ev.top, get_uval=s		; Get info.
	  widget_control, ev.id, get_val=val		; Get new value.
          act_edit_animate, ev.id, val                  ; Animate it.
	  s.barmax = val + 0.0				; Save in info.
	  widget_control, ev.top, set_uval=s		; Save updated info.
	  act_edit_refresh_bar, s			; Update color bar.
	  return
	endif
 
	;-----------------------------------------------------------
	;  INT_RGB: Set or unset RGB interpolation
        ;    Exclusive buttons always trigger both events so
        ;    only need to checkone.
	;-----------------------------------------------------------
	if uval eq 'INT_RGB' then begin
	  widget_control, ev.top, get_uval=s		; Get info.
	  s.rgb = ev.select				; Set RGB status.
	  widget_control, ev.top, set_uval=s		; Save updated info.
	  act_edit_refresh_bar, s			; Update color bar.
	  return
	endif
 
	;-----------------------------------------------------------
	;  TYP_LOG: Set or unset LOG color table.
        ;    Exclusive buttons always trigger both events so
        ;    only need to check one.
	;-----------------------------------------------------------
	if uval eq 'TYP_LOG' then begin
	  widget_control, ev.top, get_uval=s		; Get info.
	  s.log = ev.select				; Set LOG status.
          if s.log then begin                           ; If switching to log mode ...
            err = 0
            if s.barmin le 0 then err=1                 ; Check for invalid values.
            if s.barmax le 0 then err=1
            if min(s.tp_val_list) le 0 then err=1
            if err then begin                           ; Found invalid values.
              widget_control, s.id_lin, set_button=1    ; Set linear button.
              xmess,'Bar min or LO must be GT 0 for Log'
              return
            endif
          endif
          widget_control, s.id_stepz, set_button=1      ; Offset must be 0.
          widget_control, s.id_sflag, set_button=0      ; Turn off step.
          widget_control, s.id_stepstat, set_val='NO'
	  widget_control, s.id_bstep2, sensitive=0      ; Gray/ungray contrls.
	  widget_control, ev.top, set_uval=s		; Save updated info.
	  act_edit_refresh_bar, s			; Update color bar.
	  return
	endif
 
	;-----------------------------------------------------------
	;  BAR: deal with bar events.
	;
	;  Does nothing much so far except determine
	;  which button clicked on which tiepoint (if any).
	;  Could use to Add, Move, or Delete a tiepoint.
	;-----------------------------------------------------------
	if uval eq 'BAR' then begin
	  if ev.release eq 0 then return		; Only release counts.
	  widget_control, ev.top, get_uval=s
	  wset,s.winbar
	  set_scale
	  ix = ev.x
	  iy = ev.y
	  tmp = convert_coord(ev.x,ev.y,/dev, /to_data)
	  x = tmp[0]
	  y = tmp[1]
	  n = s.tp_num
	  xv = s.tp_val_list
	  yv = fltarr(n) + 1.
	  tmp = convert_coord(xv,yv,/to_dev, /data)
	  ixv = round(tmp[0,*])
	  iyv = round(tmp[1,*])
	  if y gt 1. then begin
	    id = abs(ixv - ix)
	    d = abs(xv - x)
	    w = where(d eq min(d))
	    in = w[0]
	    dmin = id[in]
	    if dmin le 5 then begin
	      btt = (['','Left','Middle','','Right'])[ev.release]+' button'
	      ind = string(in,form='(I3.3)')
	      print,btt + ' on tiepoint # ',ind,' ('+strtrim(xv[in],2)+')'
	    endif
	  endif
help,/st,ev
	  return
	endif
 
	;-----------------------------------------------------------
        ;  Description
	;-----------------------------------------------------------
        if uval eq 'DESC' then begin
          widget_control, ev.id, get_val=desc           ; Grab description text.
	  widget_control, ev.top, get_uval=s		; Get info.
          s.desc = desc                                 ; Store it.
	  widget_control, ev.top, set_uval=s		; Save info.
          act_edit_animate, ev.id, desc                 ; Animate it.
	  return
	endif

	;-----------------------------------------------------------
        ;  Absolute flag
	;-----------------------------------------------------------
        if uval eq 'ABS_FLAG' then begin
	  abs_flag = ev.select				; Get flag value.
	  stat = (['NO','YES'])[abs_flag]		; Translate to yes/no.
	  widget_control, ev.top, get_uval=s		; Get info.
	  widget_control, s.id_absstat, set_val=stat	; Display yes/no.
	  s.abs_flag = abs_flag 			; Save step flag.
	  widget_control, ev.top, set_uval=s		; Save info.
	  return
	endif

	;-----------------------------------------------------------
	;  STEP_FLAG = Turn stepping on/off
	;-----------------------------------------------------------
	if uval eq 'STEP_FLAG' then begin
	  step_flag = ev.select				; Get flag value.
	  stat = (['NO','YES'])[step_flag]		; Translate to yes/no.
	  widget_control, ev.top, get_uval=s		; Get info.
          if s.log eq 0 then begin
	    widget_control, s.id_bstep2, sensitive=step_flag ; Gray/ungray contrls.
          endif else begin
            widget_control, s.id_stepz, set_button=1
	    widget_control, s.id_bstep2, sensitive=0    ; Gray/ungray contrls.
          endelse
	  widget_control, s.id_stepstat, set_val=stat	; Display yes/no.
	  s.step_flag = step_flag			; Save step flag.
	  widget_control, ev.top, set_uval=s		; Save info.
	  act_edit_refresh_bar, s			; Update color bar.
	  return
	endif
 
	;-----------------------------------------------------------
	;  STEP = Set step size
	;-----------------------------------------------------------
	if uval eq 'STEP' then begin
	  widget_control, ev.top, get_uval=s		; Get info.
	  widget_control, ev.id, get_val=val		; Get new step.
          act_edit_animate, ev.id, val                  ; Animate it.
	  s.step = val+0.0				; Float and save it.
	  widget_control, ev.top, set_uval=s		; Save info.
	  act_edit_refresh_bar, s			; Update color bar.
	  return
	endif
 
	;-----------------------------------------------------------
	;  STEP-/STEP0/STEP+ = Step Offset
	;-----------------------------------------------------------
	if uval eq 'STEP-' then begin
	  if ev.select eq 0 then return			; Ignore release.
	  widget_control, ev.top, get_uval=s		; Get info.
	  s.step_offset = -0.5				; Set offset.
	  widget_control, ev.top, set_uval=s		; Save info.
	  act_edit_refresh_bar, s			; Update color bar.
	  return
	endif
	if uval eq 'STEP0' then begin
	  if ev.select eq 0 then return			; Ignore release.
	  widget_control, ev.top, get_uval=s		; Get info.
	  s.step_offset = 0.0				; Set offset.
	  widget_control, ev.top, set_uval=s		; Save info.
	  act_edit_refresh_bar, s			; Update color bar.
	  return
	endif
	if uval eq 'STEP+' then begin
	  if ev.select eq 0 then return			; Ignore release.
	  widget_control, ev.top, get_uval=s		; Get info.
	  s.step_offset = 0.5				; Set offset.
	  widget_control, ev.top, set_uval=s		; Save info.
	  act_edit_refresh_bar, s			; Update color bar.
	  return
	endif
 
	;-----------------------------------------------------------
	;  Color picker
	;-----------------------------------------------------------
	if uval eq 'CWHEEL' then begin
	  if ev.select eq 0 then return			; Ignore release.
	  widget_control, ev.top, get_uval=s		; Get info.
	  s.cpick = 1
	  widget_control, ev.top, set_uval=s		; Save info.
	  return
	endif
	if uval eq 'CSLIDE' then begin
	  if ev.select eq 0 then return			; Ignore release.
	  widget_control, ev.top, get_uval=s		; Get info.
	  s.cpick = 2
	  widget_control, ev.top, set_uval=s		; Save info.
	  return
	endif
 
	;-----------------------------------------------------------
	;  Units Conversion
	;-----------------------------------------------------------
	if uval eq 'UNITS' then begin
	  widget_control, ev.top, get_uval=s
          ;################################
          act_edit_ucon_d, s 
          ;################################
	  widget_control, ev.top, set_uval=s		; Save info.
	  return
	endif
 
	;-----------------------------------------------------------
	;  DEBUG: Do a debug stop.
	;-----------------------------------------------------------
	if uval eq 'DEBUG' then begin
	  widget_control, ev.top, get_uval=s
          stop
	  return
	endif
 
help,/st,ev
help,uval
 
	end
 
 
 
	;==================================================================
	;==================================================================
	;  act_edit.pro = Main routine = Layout
	;==================================================================
	;==================================================================
	pro act_edit, help=hlp
 
	if keyword_set(hlp) then begin
	  print,' Build and/or Edit an absolute color table.'
	  print,' act_edit'
	  print,'   No args.'
	  print,' Notes: An absolute color table is used to map data'
	  print,' values to specified colors, always the same color for the'
	  print,' same value.  A color table is built by defining colors at'
	  print,' specified points called tiepoints.  The table starts'
	  print,' with two tiepoints, the start and end.  Each tiepoint'
	  print,' has a value entry area and a color patch.  The value may'
	  print,' be changed to move the tiepoint.  The color may be changed'
	  print,' by clicking on the color patch and using the color picker'
	  print,' to change the color.  Tiepoints may be added or dropped.'
	  print,' Colors between tiepoints are interpolated, either in RGB'
	  print,' color space, or HSV color space.  The table may also be'
	  print,' stepped into descrete color steps of a specified size.'
	  print,' The color table may be saved in a text file and read'
	  print,' back in.  The tiepoints LO and HI are the table endpoints'
	  print,' and define the range of the table.  The range may be'
	  print,' changed by changing the values of these points.  The Bar'
	  print,' min and max just set how much of the table is displayed,'
	  print,' not the actual range covered by the table.  When the table'
	  print,' is applied to data using act_apply then data is clipped to'
	  print,' the range of the table (which may be freely changed in that'
	  print,' routine). The tiepoints positions are displayed above the'
	  print,' color bar.'
	  print,' '
	  print,' To apply a color table to data:'
	  print,'   img = act_apply(data,file=color_table)'
	  print,'   (see the built-in help for more options).'
	  print,' '
	  print,' To display a color bar:'
	  print,'    act_cbar, vmin, vmax'
	  print,'   (see the built-in help for more options).'
	  return
	endif 
 
	;-----------------------------------------------------------
	;  Set up values
	;-----------------------------------------------------------
	barmin =   0.0		; Color bar display min.
	barmax = 100.0		; Color bar display max.
	lo_val =   0.0		; Color table min.
	lo_hsv = [0.,0.,0.]	; Color at table min.
	hi_val = 100.0		; Color table max.
	hi_hsv = [0.,0.,1.]	; Color at table max.
	psz = 25		; Color patch size.
	barx = 800		; Bar window size.
	bary = 100
	bpos = [0.07,0.30,0.95,0.75]  ; Color bar position.
	tpdy = 40		; Y size per tie point.
	svdef ='act_def000.txt'	; Default save file name.
	step_flag = 0		; Default is non-stepped color table.
	step = 10.		; Step size.
	step_offset = 0.	; Step offset.
	device,get_screen_size=sxy ; Get screen size.
	max_y_scr = sxy[1]-550	; Max scroll size for tiepoints.
 
	;-----------------------------------------------------------
	;  Top level base
	;-----------------------------------------------------------
	top = widget_base(/column)
 
	;-----------------------------------------------------------
	;  Color bar area
	;-----------------------------------------------------------
	b = widget_base(top,/column)
	b1 = widget_base(b,/row)
	id_drw_bar = widget_draw(b1,xs=barx,ys=bary, $
	  /button_events, /wheel_events, uval='BAR')
 
	;-----------------------------------------------------------
	;  Color table file name
	;-----------------------------------------------------------
	id_nam0 = widget_base(b,/row)
	id = widget_label(id_nam0,val='Name')
        id_name =  widget_text(id_nam0,val=' ',xsize=125)

	;-----------------------------------------------------------
	;  Color bar range control (what range to display)
	;-----------------------------------------------------------
	b2 = widget_base(b,/row)
	  b3 = widget_base(b2,/col)
	    b4 = widget_base(b3,/row)
	      id = widget_label(b4,val='Bar min')
	      id_bmin =widget_text(b4,xsize=15,val=strtrim(barmin,2), $
	        uval='BARMIN',/edit)
	    b4 = widget_base(b3,/row)
	      id = widget_label(b4,val='Bar max')
	      id_bmax =widget_text(b4,xsize=15,val=strtrim(barmax,2), $
	        uval='BARMAX',/edit)
	  id = widget_label(b2,val='Bar display range.')

	  ;---------------------------------------------------------
          ;  Description and Absolute flag
	  ;---------------------------------------------------------
	  id = widget_label(b2,val=' ')                 ; Spacer.
	  b3 = widget_base(b2,/col)
	    b4 = widget_base(b3,/row)
	      id = widget_label(b4,val='Short Description:')
              desc = ''
	      id_desc = widget_text(b4,val=desc,uval='DESC', $
	        /edit,xsize=60)
            b4  = widget_base(b3,/row)
	    bnx = widget_base(b4,/row,/nonexclusive)
	      id_abs = widget_button(bnx,val='Absolute?',uval='ABS_FLAG', $
	        tooltip='Flag that this table should be used as an absolute table.')
	      id_absstat = widget_label(b4,value='YES',/dynamic)
              abs_flag = 1                              ; Def is absolute table.
	      widget_control, id_abs, set_button=abs_flag


	;-----------------------------------------------------------
	;  Bases for instructions, LO, and Step control
	;-----------------------------------------------------------
	top2 = widget_base(top,/row)
	toplft = widget_base(top2,/col)
	id = widget_label(top2,/align_left, val='        ')
	toprgt = widget_base(top2,/col)
 
	;-----------------------------------------------------------
	;  Tiepoint instructions
	;-----------------------------------------------------------
	id_ct = widget_label(toplft,/dynamic, /align_left, $
	  val='The color table tiepoint values and colors may be edited below')
 
	;-----------------------------------------------------------
	;  LO = Color table bottom.  Value and color may be changed.
	;-----------------------------------------------------------
	id_lo = widget_base(toplft,/row)
	id = widget_label(id_lo,val='LO')
	id_val_lo = widget_text(id_lo,val=strtrim(lo_val,2),uval='VAL LO', $
	  /edit,xsize=15)
	id = widget_label(id_lo,val='   ')
	id_drw_lo = widget_draw(id_lo,xs=psz,ys=psz,uval='DRW LO', $
	  /button_events, /align_bottom)
	id = widget_label(id_lo,val='   ')
	id = widget_label(id_lo, $
	  val='Lower Limit')

	;-----------------------------------------------------------
        ;  Color table type and interpolation mode
	;-----------------------------------------------------------
	b3 = widget_base(toprgt,/col)
	  b4 = widget_base(b3,/row)
	  id = widget_label(b4,val='Color table type:')
	  b5 = widget_base(b4,/row,/exclusive)
	    id_lin = widget_button(b5,val='LIN',uval='TYP_LIN', $
	      tooltip='Color table is linear.')
	    widget_control, id_lin, set_button=1
	    id_log = widget_button(b5,val='LOG',uval='TYP_LOG', $
	      tooltip='Color table is logarithmic.')
	  b4 = widget_base(b3,/row)
	  id = widget_label(b4,val='Interpolation mode:')
	  b5 = widget_base(b4,/row,/exclusive)
	    id_rgb = widget_button(b5,val='RGB',uval='INT_RGB', $
	      tooltip='Interpolate between tiepoints in RGB color space.')
	    widget_control, id_rgb, /set_button
	    id_hsv = widget_button(b5,val='HSV',uval='INT_HSV', $
	      tooltip='Interpolate between tiepoints in HSV color space.')
 
	;-----------------------------------------------------------
	;  Color table tiepoints.
	;    May change value (position), color, and add or
	;    drop tiepoint.
	;    This is just a starting tiepoint.
	;-----------------------------------------------------------
	id_tp = widget_base(top,/col,/frame,/scroll, $	; Tiepoint base.
	  x_scroll_size=barx, scr_ysize=1)
	id = widget_base(id_tp)
 
	;-----------------------------------------------------------
	;  HI = Color table top.  Value and color may be changed.
	;-----------------------------------------------------------
        bot2 = widget_base(top,/row)
	botlft = widget_base(bot2,/col)
	id = widget_label(bot2,/align_left, val='                        ')
	botrgt = widget_base(bot2,/col)
	id_hi = widget_base(botlft,/row)
	id = widget_label(id_hi,val='HI')
	id_val_hi = widget_text(id_hi,val=strtrim(hi_val,2),uval='VAL HI', $
	  /edit,xsize=15)
	id = widget_label(id_hi,val='   ')
	id_drw_hi = widget_draw(id_hi,xs=psz,ys=psz,uval='DRW HI', $
	  /button_events, /align_bottom)
	id = widget_label(id_hi,val='   ')
	id = widget_label(id_hi, $
	  val='Upper Limit')
	id = widget_label(botlft,/align_left, val=' ')
	id_status = widget_label(botlft,/dynamic, /align_left, $
	  val='Use the buttons below to edit color table')
 
	;-----------------------------------------------------------
	;  Step = Color table step controls
	;-----------------------------------------------------------
	b = widget_base(botrgt,/row)
	bb = widget_base(b,/row,/nonexclusive)
	id_sflag = widget_button(bb,val='Stepped color table?', $
	  uval='STEP_FLAG', $
	  tooltip='Select between smooth or stepped color tables.')
	id_stepstat = widget_label(b,value='NO',/dynamic)
	widget_control, id, set_button=step_flag
	id_bstep1 = widget_base(botrgt,/row)
	id = widget_label(id_bstep1,val='Step:')
	id_step = widget_text(id_bstep1,xsiz=10,/edit,val=strtrim(step,2), $
	  uval='STEP')
	id_bstep2 = widget_base(id_bstep1,/row)
	id = widget_label(id_bstep2,val='Offset:')
	bb = widget_base(id_bstep2,/exclusive,/row)
	id_stepm = widget_button(bb,val='-1/2',uval='STEP-', $
	  tooltip='Constant color from -0.5*step to 0.5*step, ... (shift up)')
	id_stepz = widget_button(bb,val='0',uval='STEP0', $
	  tooltip='Constant color from 0 to step, step to 2*step, ...')
	widget_control, id_stepz, set_button=1
	id_stepp = widget_button(bb,val='1/2',uval='STEP+', $
	  tooltip='Constant color from -0.5*step to 0.5*step, ... (shift down)')
	widget_control, id_bstep2, sensitive=step_flag
 
	;-----------------------------------------------------------
	;  Build initial tiepoint lists: just Lo and HI to start.
	;-----------------------------------------------------------
	tp_num = 2				; Number of tiepoint.
	tp_hsv = [[lo_hsv],[hi_hsv]]		; Tiepoint HSV.
	tp_val_list = [lo_val,hi_val]		; List of tiepoint values.
	tp_ind_list = ['000','001']		; List of tiepoint indices.
	tp_bas_list = [id_lo, id_hi]		; List of tiepoint bases.
        tp_txt_list = [id_val_lo,id_val_hi]     ; List of tiepoint text areas.
	
	;-----------------------------------------------------------
	;  Buttons
	;-----------------------------------------------------------
	id_con = widget_base(top,/row)
	id = widget_button(id_con,val='DONE',uval='DONE', $
	  tooltip='Quit program')
	id = widget_button(id_con,val='ADD',uval='ADD', $
	  tooltip='Add a new tiepoint.  Change value to move it.')
	id = widget_button(id_con,val='DROP',uval='DROP', $
	  tooltip='Drop a tiepoint by index number.')
	id = widget_button(id_con,val='OPEN',uval='OPEN', $
	  tooltip='Open an absolute color table file.')
	id = widget_button(id_con,val='SAVE',uval='SAVE', $
	  tooltip='Save current color table in a file.')
	id = widget_button(id_con,val='Units Conversion',uval='UNITS', $
	  tooltip='Add or edit color table units conversion.')
	id = widget_button(id_con,val='HELP',uval='HELP', $
	  tooltip='Nothing here yet.  To be added.')
	id = widget_button(id_con,val='DEBUG',uval='DEBUG', $
	  tooltip='Check internal values (try help,/st,s).')
 
	;-----------------------------------------------------------
	;  Color picker choice
	;-----------------------------------------------------------
	id = widget_label(id_con,val='                            ')
	bf = widget_base(id_con,/row)
	id = widget_label(bf,val='Color picker:')
	b = widget_base(bf,/row,/exclusive)
	id = widget_button(b,val='WHEEL/BAR',uval='CWHEEL',$
          tooltip='Adjust colors using a color wheel and brightness bar.')
	widget_control, id, /set_button
	cpick = 1
	id = widget_button(b,val='RGB/HSV sliders',uval='CSLIDE', $
          tooltip='Adjust colors using RGB and HSV sliders.')
 
	;------------------------------------------------------------------
	;  Activate widget
	;------------------------------------------------------------------
	widget_control, top, /realize
 
	;------------------------------------------------------------------
	;  Initialize draw widgets
	;------------------------------------------------------------------
	widget_control, id_drw_lo, get_val=winlo	; LO color window.
	clr_lo = tarclr(/hsv,lo_hsv)			; LO color.
	wset, winlo					; Set to LO color win.
	erase, clr_lo					; Fill in LO color.
	widget_control, id_drw_hi, get_val=winhi	; HI color window.
	clr_hi = tarclr(/hsv,hi_hsv)			; HI color.
	wset, winhi					; Set to HI color win.
	erase, clr_hi					; Fill in HI color.
	widget_control, id_drw_bar, get_val=winbar	; BAR window.
 
	;------------------------------------------------------------------
	;  Pack up needed info and save it
	;------------------------------------------------------------------
	s = {top:top, modflag:0, id_tp:id_tp, $
		tp_num:tp_num, tp_val_list:tp_val_list, $
		tp_ind_list:tp_ind_list, tp_bas_list:tp_bas_list, $
                tp_txt_list:tp_txt_list, $
		tp_hsv:tp_hsv, id_status:id_status, tpdy:tpdy, $
		barmin:barmin, barmax:barmax, rgb:1, log:0, $
		psz:psz, winlo:winlo, winhi:winhi, winbar:winbar, $
 
		id_bmin:id_bmin, id_bmax:id_bmax, $
                id_rgb:id_rgb, id_hsv:id_hsv, $
                id_lin:id_lin, id_log:id_log,$
		id_val_lo:id_val_lo, id_drw_lo:id_drw_lo, $
		id_val_hi:id_val_hi, id_drw_hi:id_drw_hi, $
		svdef:svdef, id_name:id_name, $
                desc:desc, id_desc:id_desc, $
                abs_flag:abs_flag, id_abs:id_abs, id_absstat:id_absstat, $
 
		id_bstep1:id_bstep1,id_bstep2:id_bstep2, $
                id_step:id_step,id_sflag:id_sflag, $
		id_stepm:id_stepm,id_stepz:id_stepz,id_stepp:id_stepp, $
	        step_flag:step_flag, id_stepstat:id_stepstat, $
		step:step, step_offset:step_offset, $
 
		bpos:bpos, max_y_scr:max_y_scr, cpick:cpick }
	widget_control, top, set_uval=s
	act_edit_refresh_bar, s				; Update color bar.
 
	;------------------------------------------------------------------
	;  Manage widget
	;------------------------------------------------------------------
	xmanager, 'act_edit', top, /no_block
 
	end
