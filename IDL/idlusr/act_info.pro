;-------------------------------------------------------------
;+
; NAME:
;       ACT_INFO
; PURPOSE:
;       Return values from current absolute color table.
; CATEGORY:
; CALLING SEQUENCE:
;       val = act_info(item)
; INPUTS:
;       item = Name of item.           in
; KEYWORD PARAMETERS:
;       Keywords:
;         /LIST List color table info.
; OUTPUTS:
;       val = Returned value of item.  out
; COMMON BLOCKS:
;       act_apply_com
; NOTES:
;       Note:
;        Item:
;          z = Tiepoint value for each color entry.
;          h = Hue for each color entry.
;          s = Saturation for each color entry.
;          v = Value for each color entry.
;          r = Red component for each color entry.
;          g = Green component for each color entry.
;          b = Blue component for each color entry.
;          rgb = RGB or HSV flag.
;          step_flag = Stepped table flag.
;          step = Stepped table step size.
;          step_offset = Stepped table offset.
;          barmin = Color bar display minimum.
;          barmax = Color bar display maximum.
;          act_file = Name of act file used.
; MODIFICATION HISTORY:
;       R. Sterner, 2008 May 21
;       R. Sterner, 2008 Nov 17 --- Modified common.  Added /LIST.
;       R. Sterner, 2008 Nov 12 --- Fixed a typo in a comment.
;       R. Sterner, 2008 Nov 12 --- Now can return act file name.
;       R. Sterner, 2010 Mar 22 --- Now can return user added items in act file.
;       R. Sterner, 2010 Apr 12 --- Added /TABLES,/LIB_TABLES,DIR=dir.
;       R. Sterner, 2010 Nov 10,11 --- Handled Log color tables.
;
; Copyright (C) 2008, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	function act_info, item, list=list, lib_tables=lib_tab, $
          tables=tables, dir=dir0, help=hlp
 
	;--- lo, hi no longer used in the act_* routines  ---
	common act_apply_com, z,h,s,v,r,g,b,rgb,step_flag,step,step_offset, $
	  barmin,barmax, src, act_file, act_tm, act_caller, act_str, log_flag
	;---------------------------------------------------------
	;  z = Array of tiepoint values.
	;  h = Hues at tiepoints.
	;  s = Saturations at tiepoints.
	;  v = Values at tiepoints.
	;  r = Reds at tiepoints.
	;  g = Greens at tiepoints.
	;  b = Blues at tiepoints.
        ;  log_flag = Flag: 1 if log, 0 if linear.
	;  rgb = Flag: 1 use as RGB, 0 use as HSV.
	;  step_flag = Flag: 1 if stepped, 0 if smooth.
	;  step = Step size for stepped color table.
	;  step_offset = -0.5, 0, or 0.5 to offset step.
	;  barmin = Data start range in z (def=min(z)).
	;  barmax = Data end range in z (def=max(z)).
	;  src = Color table source: File or structure.
	;  act_file = Name of file used.
	;  act_tm = Time when color table was initialized.
	;  act_caller = Who called this routine.
        ;  act_str = Structure containing the color table.
	;---------------------------------------------------------
 
	if keyword_set(hlp) then begin
hlp:	  print,' Return values from current absolute color table.'
	  print,' val = act_info(item)'
	  print,'   item = Name of item.           in'
	  print,'   val = Returned value of item.  out'
	  print,' Keywords:'
	  print,'   /LIST List color table info.'
          print,'   /TABLES with /LIST will also list any local color tables'
          print,'     with names like act_*.txt.'
          print,'     DIR=path will list tables (act_*.txt) in given directory.'
          print,'     /LIB_TABLES will list tables in the source directory of'
          print,'        this routine (act_info.pro).'
	  print,' Note:'
	  print,'  Item:'
	  print,'    z = Tiepoint value for each color entry.'
	  print,'    h = Hue for each color entry.'
	  print,'    s = Saturation for each color entry.'
	  print,'    v = Value for each color entry.'
	  print,'    r = Red component for each color entry.'
	  print,'    g = Green component for each color entry.'
	  print,'    b = Blue component for each color entry.'
	  print,'    log_flag = Log color table flag.'
	  print,'    rgb = RGB or HSV flag.'
          print,'       log = 1 if log, 0 if linear color table.'
	  print,'    step_flag = Stepped table flag.'
	  print,'    step = Stepped table step size.'
	  print,'    step_offset = Stepped table offset.'
	  print,'    barmin = Color bar display minimum.'
	  print,'    barmax = Color bar display maximum.'
	  print,'    act_file = Name of act file used.'
	  return,''
	endif
 
	if keyword_set(list) then begin
	  print,' '
	  if n_elements(src) eq 0 then begin
	    print,' No Absolute Color Table has been specified with'+ $
	      ' act_apply.'
	    goto, skip
	  endif
	  print,' Color table was initialized using'
	  print, act_caller
	  txt = src
	  if txt eq 'File' then txt=txt+': '+act_file else txt=txt+'.'
	  print,' with a '+txt
	  print,' '+act_tm
          print,' '
          if log_flag eq 1 then print,' Color table is LOG' else $
            print,' Color table is LINEAR'
	  print,' The color table has '+strtrim(n_elements(z),2)+' tiepoints.'
	  print,' It uses '+(['HSV','RGB'])[rgb]+' format.'
	  print,' It is '+(['not',''])[step_flag]+' stepped.'
	  print,' The color table range is from '+$
	    strtrim(min(z),2)+' to '+strtrim(max(z),2)
	  print,' It is set to display from '+$
	    strtrim(min(barmin),2)+' to '+strtrim(barmax,2)
skip:
          if keyword_set(tables) then begin
            dir = ''
            if n_elements(dir0) ne 0 then dir=dir0
            if keyword_set(lib_tab) then whoami, dir
            if dir eq '' then cd,curr=dir
            print,' '
            print,' Absolute color tables found in '+dir+':'
            wld = filename(dir,'act_*.txt',/nosym)
            f = file_search(wld,count=cnt)
            if cnt eq 0 then begin
              print,'     None.'
            endif else begin
              filebreak,f,file=f2
              more,'    '+f2,lines=100
            endelse
          endif
          print,' '
	  return,''
	endif
 
	if n_elements(item) eq 0 then goto, hlp

    ;---  Check if requested item is in the saved structure  ---
    if tag_test(act_str,item) then begin
      val = tag_value(act_str,item)
      return, val
    endif
;stop
 
    ;---  Try to get item from common  ---
	case strlowcase(item) of
;'z':	val = z
;'h':	val = h
;'s':	val = s
;'v':	val = v
'r':	val = r
'g':	val = g
'b':	val = b
;'rgb':	val = rgb
'log_flag': val = log_flag
;'step_flag': val = step_flag
;'step':	val = step
;'step_offset': val = step_offset
'barmin': val = barmin
'barmax': val = barmax
'act_file': val = act_file
else:	val = ''
	endcase
 
	return, val
 
	end
