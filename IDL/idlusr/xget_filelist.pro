;-------------------------------------------------------------
;+
; NAME:
;       XGET_FILELIST
; PURPOSE:
;       Get a list of files using a widget.
; CATEGORY:
; CALLING SEQUENCE:
;       xget_filelist, list
; INPUTS:
; KEYWORD PARAMETERS:
;       Keywords:
;         COUNT=nf Returned number of files found (-1 if cancelled).
;         TITLE=tt   Widget title text (def="Get a list of files").
;         DEFDIR=defdir  Initial directory (def=current).
;           May use an environment variable prefixed by $, like
;           $HOME, it will be replaced by the value of the variable.
;           Can switch the displayed directory to the current
;           directory by deleting it all and pressing ENTER.
;         DEFWLD=defwld  Initial wildcard (def="*.png").
;         GROUP_LEADER=g Give group leader (needed if called
;           from another widget routine).  Can use the top level
;           base wid of the calling routine.
;         XSIZE=directory entry area size in characters (minimum).
;         XOFFSET=xoff, YOFFSET=yoff Widget position.
; OUTPUTS:
;       list = Returned list of files (null for CANCEL).    out
;         Will have full path to files.
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 2009 Sep 18
;
; Copyright (C) 2009, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro xget_filelist_event, ev
 
	widget_control, ev.id, get_uval=name	; Get button uval.
	widget_control, ev.top, get_uval=m	; Get info structure.
 
	;------  OK button or return in text area  -----------
	if name eq 'OK' then begin
	  list = tag_value(m,'list')
	  widget_control, m.res, set_uval={list:list,nf:m.nf}
	  widget_control, ev.top, /dest
	  return
	endif
 
	;------  Cancel button  ------------------
	if name eq 'CANCEL' then begin
	  widget_control, m.res, set_uval={list:'',nf:-1}
	  widget_control, ev.top, /dest
	  return
	endif
 
	;-------  Search  --------
	if name eq 'SEARCH' then begin
	  widget_control, m.id_dir, get_val=dir
	  widget_control, m.id_wld, get_val=wld
	  file = filename(dir,wld,/nosym) & file=file[0]
	  widget_control, m.id_num,set_val='Searching ...'
	  list = file_search(file,count=nf)
	  tag_add,m,'list',list
	  m.nf = nf
	  widget_control, ev.top, set_uval=m
	  widget_control, m.id_num,set_val=strtrim(nf,0)+' file'+plural(nf)
	  return
	endif
 
	;-------  Browse  ---------
	if name eq 'BROWSE' then begin
	  widget_control, m.id_dir, get_val=dir
	  r = dialog_pickfile(/dir,title='Pick directory',path=dir)
	  if r eq '' then return
	  widget_control, m.id_dir, set_val=r
	  return
	endif
 
	;-------  DIR  ---------
	;  Undo ENTER commands.  If all erased use curr dir.
	if name eq 'DIR' then begin
	  widget_control, m.id_dir,get_value=val
	  w = where(val ne '',cnt)
	  if cnt gt 0 then begin
	    val=val[w[0]]
	  endif else begin
	    cd,curr=val
	  endelse
	  widget_control, m.id_dir,set_value=val
	  return
	endif
 
	end
 
;=====================================================================
;	xget_filelist.pro = Widget text input.
;	R. Sterner, 2009 Sep 18
;=====================================================================
 
	pro xget_filelist, list, title=ttl, $
	  xoffset=xoff, yoffset=yoff, group_leader=grp, $
	  defdir=defdir0, defwld=defwld, outdir=outdir, outwld=outwld, $
	  count=nf, xsize=xsize, help=hlp
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Get a list of files using a widget.'
	  print,' xget_filelist, list'
	  print,'   list = Returned list of files (null for CANCEL).    out'
	  print,'     Will have full path to files.'
	  print,' Keywords:'
	  print,'   COUNT=nf Returned number of files found (-1 if cancelled).'
	  print,'   TITLE=tt   Widget title text (def="Get a list of files").'
	  print,'   DEFDIR=defdir  Initial directory (def=current).'
	  print,'     May use an environment variable prefixed by $, like'
	  print,'     $HOME, it will be replaced by the value of the variable.'
	  print,'     Can switch the displayed directory to the current'
	  print,'     directory by deleting it all and pressing ENTER.'
	  print,'   DEFWLD=defwld  Initial wildcard (def="*.png").'
          print,'   GROUP_LEADER=g Give group leader (needed if called'
	  print,'     from another widget routine).  Can use the top level'
	  print,'     base wid of the calling routine.'
	  print,'   XSIZE=directory entry area size in characters (minimum).'
	  print,'   XOFFSET=xoff, YOFFSET=yoff Widget position.'
	  return
	endif
 
	;-----  Defaults  -----------------
	;  Replace environment variables ($VAR) with their values.
	if n_elements(ttl) eq 0 then ttl='Get a list of files'
	if n_elements(defdir0) eq 0 then cd,curr=defdir else defdir=defdir0
	if strmid(defdir,0,1) eq '$' then defdir=getenv(strmid(defdir,1))
	if n_elements(defwld) eq 0 then defwld='*.png'
	if n_elements(xsize) eq 0 then xsize=60
	nf = -1 
 
	;------  Lay out widget  ----------
	top = widget_base(/col,title=ttl,xoff=xoff,yoff=yoff, group_Leader=grp)
 
	bb = widget_base(top,/row)
	id  = widget_label(bb,value='Directory:')
	id_dir = widget_text(bb,val=defdir,xsize=xsize,ysize=1,/edit, $
	  /scroll,uval='DIR')
 
	bb = widget_base(top,/row)
	id = widget_button(bb,val='Browse',uval='BROWSE')
 
	bb = widget_base(top,/row)
	id = widget_label(bb,value='Wildcard:')
	id_wld = widget_text(bb,xsize=20,/edit,val=defwld,uval='WLD')
	id_num = widget_label(bb,val='Click Search',/dynamic)
	
	bb = widget_base(top,/row)
	id = widget_button(bb, val='Search',uval='SEARCH')
	id = widget_button(bb, val='OK',    uval='OK'    )
	id = widget_button(bb, val='Cancel',uval='CANCEL')
 
	;------  Package and store needed info  ------------
	res = widget_base()
	map = {id_dir:id_dir, id_wld:id_wld, id_num:id_num, nf:nf, res:res}
	widget_control, top, set_uval=map
 
	;------  realize widget  -----------
	widget_control, top, /real
 
	;------  Event loop  ---------------
	xmanager, 'xget_filelist', top
 
	;------  Get result  ---------------
	widget_control, res, get_uval=res
	list = res.list
	nf = res.nf
 
	return
	end
