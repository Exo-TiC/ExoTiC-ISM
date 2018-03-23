;-------------------------------------------------------------
;+
; NAME:
;       ACT_APPLY
; PURPOSE:
;       Apply an absolute color table to an array of values.
; CATEGORY:
; CALLING SEQUENCE:
;       img = act_apply(z)
; INPUTS:
;       z = Input 2-d array of values to color.   in
; KEYWORD PARAMETERS:
;       Keywords:
;         STR=s  Structure with absolute color table.
;           s={z:z,h:h,s:s,v:v,rgb:rgb,step_flag:step_flag, $
;              step:step,step_offset:step_offset}
;             z = Array of tiepoint values.
;             h = Array of hues at tiepoints.
;             s = Array of saturations at tiepoints.
;             v = Array of values at tiepoints.
;             log = 1 if log, 0 if linear color table.
;             rgb = 1: interpolate in rgb, 0: interpolate in hsv.
;             abs_flag = 1 if absolute, 0 if not.
;               Software can use this value as a suggestion.
;             step_flag = 1 if stepped, 0 if smooth.
;             step = Step size for stepped color table.
;               For log color tables use 1, 2, 5, or 10.
;             step_offset = -0.5, 0, or 0.5 to offset step.
;               Assumed 0 for log color tables.
;             barmin = Data start range in z (def=min(z)).
;             barmax = Data end range in z (def=max(z)).
;         FILE=file Name of absolute color table file.
;           This is a text file in txtdb format with the same items
;           as in the structure above. Such a color table is built
;           by act_edit.  Use either STR or FILE but not both.
;           Give the path and file name for the color table, or use
;           the keywords /lib_tables, /my_tables to set the path as
;           described below.  Other flags or values may be given in
;           either the structure or the txtdb file and their value
;           accessed using val=act_info(tag).
;         /LIB_TABLES Assume the given color table file is in the
;           same directory (like IDLUSR) as this routine, act_apply.
;         /MY_TABLES Assume the given color table file is in the
;           same directory as the routine that calls act_apply.
;           These two keywords will add the indicated path to file
;           only if the given file has no path.
;         SLOPE=slope, OFFSET=offset Convert color table units.
;           These keywords allow a single color table to be displayed
;           in different units by converting the original table units.
;           Color tables are defined in terms of colors at certain
;           values where the values are in some units.
;           Unit conversion: NEW = OLD*slope + offset
;           Be careful mixing this conversion with the NEWRANGE keyword.
;           Avoid SLOPE and OFFSET with log color tables.
;         UNITS=units Instead of giving SLOPE and OFFSET may give
;           units for some color tables that have units conversions.
;           For example, the color table act_temp_k.txt is an
;           absolute color table with the following units.
;           Set units to one of these: 'deg C', 'deg F', 'deg K'
;           This allows the same color table to be applied to an
;           array with values in the corresponding units.
;         NEWRANGE=nran The original color table as given by the
;           FILE keyword has a data range and a display range,
;           may be the same but need not be (the table might
;           also color out of range flag values for example).
;           The data range covered by the color table may not be
;           a good match to the actual data range in the given
;           data array.  The same color table can be remapped to
;           a new data range using the NEWRANGE keyword:
;             NEWRANGE=[data_lo, data_hi] which applies the full
;           color table display range to data_lo to data_hi.  If
;           -1 is used for data_lo then min(data) is used.  If
;           -1 is used for data_hi then max(data) is used.
;           To use only part of the original color table the desired
;           section may also be given:
;             NEWRANGE=[data_lo, data_hi, newmin, newmax]
;           which will use the colors between newmin and newmax
;           to color data in the range data_lo to data_hi, where
;           newmin and newmax refer to the original color table,
;           not the remapped color table.
;           To use the color table to autoscale the data do
;           NEWRANGE=[min(z),max(z)]  which makes the color table
;           relative.  The new scaling is not remembered on next
;           call so the original color table is not changed.
;           May also do NEWRANGE=[-1,-1] to autoscale (relative).
;           NEWRANGE=[0,0] or [0,0,0,0] does nothing.
;           NEWRANGE=[0,0,newmin,newmax] only sets newmin and newmax.
;         /CLIP clip data to color table range.  If /clip is not
;           used then the data can use flag values outside the
;           range barmin to barmax if the color table extends there.
;         /DETAILS displays a more detailed explanation of absolute
;           color tables and how the NEWRANGE keyword works.
;         TRUE=tr Specify dimension to interleave (1, 2, or 3=def).
;         ERROR=err Error flag: 0=ok.
;         CFLAG=cflag Returned flag: 0=no, 1=yes (image is constant).
;         CONSTANT=const Returned value if image is constant.
;         /C24 Return an array of 24-bit colors instead of a color image.
; OUTPUTS:
;       img = Returned color image.               out
;         or an array of 24-bit colors if /C24 is used.
; COMMON BLOCKS:
;       act_apply_com
; NOTES:
;       Notes: The color table is remembered until a new one
;        is given.
; MODIFICATION HISTORY:
;       R. Sterner, 2007 Dec 20
;       R. Sterner, 2008 Jan 03 --- Added NEWRANGE keyword.
;       R. Sterner, 2008 Jan 07 --- Allowed NEWRANGE to use partial table.
;       R. Sterner, 2008 Jan 15 --- Handled constant arrays.
;       R. Sterner, 2008 Jan 18 --- Allowed NEWRANGE to be all 0s, ignored.
;       R. Sterner, 2008 May 22 --- Upgraded NEWRANGE.  Added /CLIP.
;       R. Sterner, 2008 Nov 17 --- Modified common.
;       R. Sterner, 2008 Nov 25 --- Adjusted step to vary as range varies.
;       R. Sterner, 2008 Nov 25 --- Better help text for NEWRANGE.
;       R. Sterner, 2008 Dec 12 --- Fixed a comment typo.
;       R. Sterner, 2010 Mar 22 --- Kept copy of structure in common.
;       R. Sterner, 2010 Apr 08 --- Forced returned image to be type byte.
;       R. Sterner, 2010 Apr 12 --- Fixed path & added /lib_tables, /my_tables.
;       R. Sterner, 2010 Apr 12 --- Fixed clipping to use barmin, barmax.
;       R. Sterner, 2010 Apr 13 --- Fixed the error return when no array given.
;       R. Sterner, 2010 May 07 --- Added keyword TRUE=tr (interleave dim).
;       R. Sterner, 2010 Jul 06 --- Added SLOPE=slope, OFFSET=offset for units conversion.
;       R. Sterner, 2010 Nov 10 --- Added support for log color tables.
;       R. Sterner, 2010 Nov 11 --- Made better log color table stepping.
;       R. Sterner, 2010 Dec 14 --- Added /DETAILS.
;       R. Sterner, 2010 Dec 14 --- Allowed NEWRANGE=[0,0,newmin,newmax].
;       R. Sterner, 2010 Dec 31 --- Added UNITS=units keyword.
;       R. Sterner, 2011 Jan 07 --- The no units case got broken, fixed.
;       R. Sterner, 2011 Dec 07 --- Allowed NEWRANGE=[-1,-1,...]
;       R. Sterner, 2012 May 30 --- Added /C24.
;
; Copyright (C) 2007, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	function act_apply, zz0, file=file0, str=str0, error=err, $
	  newrange=nran, cflag=cflag, constant=const, clip=clip, $
          lib_tables=lib_tab, my_tables=my_tab, true=tr, help=hlp, $
          slope=slope0, offset=offset0, details=details, units=units, c24=c24
 
	common act_apply_com, z,h,s,v,r,g,b,rgb,step_flag,step,step_offset, $
	  barmin,barmax, src, act_file, act_tm, act_caller, act_str, log_flag
	;---------------------------------------------------------
	;  act_apply common
        ;
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
	  print,' Apply an absolute color table to an array of values.'
	  print,' img = act_apply(z)'
	  print,'   z = Input 2-d array of values to color.   in'
	  print,'   img = Returned color image.               out'
          print,'     or an array of 24-bit colors if /C24 is used.'
	  print,' Keywords:'
	  print,'   STR=s  Structure with absolute color table.'
	  print,'     s={z:z,h:h,s:s,v:v,rgb:rgb,step_flag:step_flag, $'
	  print,'        step:step,step_offset:step_offset}'
	  print,'       z = Array of tiepoint values.'
	  print,'       h = Array of hues at tiepoints.'
	  print,'       s = Array of saturations at tiepoints.'
	  print,'       v = Array of values at tiepoints.'
	  print,'       log = 1 if log, 0 if linear color table.'
	  print,'       rgb = 1: interpolate in rgb, 0: interpolate in hsv.'
          print,'       abs_flag = 1 if absolute, 0 if not.'
          print,'         Software can use this value as a suggestion.'
	  print,'       step_flag = 1 if stepped, 0 if smooth.'
	  print,'       step = Step size for stepped color table.'
          print,'         For log color tables use 1, 2, 5, or 10.'
	  print,'       step_offset = -0.5, 0, or 0.5 to offset step.'
          print,'         Assumed 0 for log color tables.'
	  print,'       barmin = Data start range in z (def=min(z)).'
	  print,'       barmax = Data end range in z (def=max(z)).'
	  print,'   FILE=file Name of absolute color table file.'
	  print,'     This is a text file in txtdb format with the same items'
	  print,'     as in the structure above. Such a color table is built'
	  print,'     by act_edit.  Use either STR or FILE but not both.'
          print,'     Give the path and file name for the color table, or use'
          print,'     the keywords /lib_tables, /my_tables to set the path as'
          print,'     described below.  Other flags or values may be given in'
          print,'     either the structure or the txtdb file and their value'
          print,'     accessed using val=act_info(tag).'
          print,'   /LIB_TABLES Assume the given color table file is in the'
          print,'     same directory (like IDLUSR) as this routine, act_apply.'
          print,'   /MY_TABLES Assume the given color table file is in the'
          print,'     same directory as the routine that calls act_apply.'
          print,'     These two keywords will add the indicated path to file'
          print,'     only if the given file has no path.'
          print,'   SLOPE=slope, OFFSET=offset Convert color table units.'
          print,'     These keywords allow a single color table to be displayed'
          print,'     in different units by converting the original table units.'
          print,'     Color tables are defined in terms of colors at certain'
          print,'     values where the values are in some units.'
          print,'     Unit conversion: NEW = OLD*slope + offset'
          print,'     Be careful mixing this conversion with the NEWRANGE keyword.'
          print,'     Avoid SLOPE and OFFSET with log color tables.'
          print,'   UNITS=units Instead of giving SLOPE and OFFSET may give'
          print,'     units for some color tables that have units conversions.'
          print,'     For example, the color table act_temp_k.txt is an'
          print,'     absolute color table with the following units.'
          print,"     Set units to one of these: 'deg C', 'deg F', 'deg K'"
          print,'     This allows the same color table to be applied to an'
          print,'     array with values in the corresponding units.'
	  print,'   NEWRANGE=nran The original color table as given by the'
	  print,'     FILE keyword has a data range and a display range,'
	  print,'     may be the same but need not be (the table might'
	  print,'     also color out of range flag values for example).'
	  print,'     The data range covered by the color table may not be'
	  print,'     a good match to the actual data range in the given'
	  print,'     data array.  The same color table can be remapped to'
	  print,'     a new data range using the NEWRANGE keyword:'
	  print,'       NEWRANGE=[data_lo, data_hi] which applies the full'
	  print,'     color table display range to data_lo to data_hi.  If'
          print,'     -1 is used for data_lo then min(data) is used.  If'
          print,'     -1 is used for data_hi then max(data) is used.'
	  print,'     To use only part of the original color table the desired'
	  print,'     section may also be given:'
	  print,'       NEWRANGE=[data_lo, data_hi, newmin, newmax]'
	  print,'     which will use the colors between newmin and newmax'
	  print,'     to color data in the range data_lo to data_hi, where'
	  print,'     newmin and newmax refer to the original color table,'
	  print,'     not the remapped color table.'
	  print,'     To use the color table to autoscale the data do'
	  print,'     NEWRANGE=[min(z),max(z)]  which makes the color table'
	  print,'     relative.  The new scaling is not remembered on next'
	  print,'     call so the original color table is not changed.'
          print,'     May also do NEWRANGE=[-1,-1] to autoscale (relative).'
          print,'     NEWRANGE=[0,0] or [0,0,0,0] does nothing.'
          print,'     NEWRANGE=[0,0,newmin,newmax] only sets newmin and newmax.'
	  print,'   /CLIP clip data to color table range.  If /clip is not'
	  print,'     used then the data can use flag values outside the'
	  print,'     range barmin to barmax if the color table extends there.'
          print,'   /DETAILS displays a more detailed explanation of absolute'
          print,'     color tables and how the NEWRANGE keyword works.'
          print,'   TRUE=tr Specify dimension to interleave (1, 2, or 3=def).'
	  print,'   ERROR=err Error flag: 0=ok.'
	  print,'   CFLAG=cflag Returned flag: 0=no, 1=yes (image is constant).'
	  print,'   CONSTANT=const Returned value if image is constant.'
          print,'   /C24 Return an array of 24-bit colors instead of a color image.'
	  print,' Notes: The color table is remembered until a new one'
	  print,'  is given.'
	  return,''
	endif
 
	;---------------------------------------------------------
        ;  Details
	;---------------------------------------------------------
        if keyword_set(details) then begin
          text_block, tmp
;
;  Absolute Color Table layout and control'
;
;  Absolute color tables are intended to match a target data set.
;  For example, an absolute color table intended for weather forcast
;  surface temperature might cover the range -40 to +40 deg C.  In
;  the diagram below these values would be BARMIN and BARMAX.
;  It might also have optional values outside that range that can be
;  used to flag out of range values.  The data to be displayed could
;  be clipped to the range -41 to +41 and the values from -41 to -40
;  colored to indicate too low and the values form +40 to +41 colored
;  to indicate too high.  The values -41 and +41 would be LO and HI
;  on the diagram below.
;
;                        NEW_MIN    NEW_MAX
;             |---------|---|----------|-----|----------|
;         Z = LO      BARMIN               BARMAX      HI
;
;  Consider BARMIN, BARMAX to be the normal data range for the color table.
;  The data range of the color table may be remapped to a new range
;  using the keyword NEWRANGE as shown below.
;  The reason that LO may differ from BARMIN, or HI from BARMAX is
;  to allow flag values.  These may be below BARMIN or above BARMAX, or
;  both.  The flag areas are just other sections of color table and may
;  be smooth or stepped, however they are set up.
;
;  Consider BARMIN, BARMAX to be the normal data range for the color table.
;  The full color table range goes from LO to HI and these may be equal to
;  or outside the BARMIN, BARMAX range. 
;
;  For a given data array to display, values from BARMIN to BARMAX will
;  scale to the corresponding part of the color table by default.  The
;  color table may be remapped using the NEWRANGE keyword.
;  To scale the color table to a different data range do:
;	NEWRANGE=[Data_lo, Data_hi]  which scales the internal Z value
;  so BARMIN maps to Data_lo and BARMAX maps to Data_hi.
;  If Data_lo = -1 then the min of the input data is used for Data_lo.
;  If Data_hi = -1 then the max of the input data is used for Data_hi.
;  To use only part of the original color table do:
;	NEWRANGE=[Data_lo, Data_hi ,NEW_MIN, NEW_MAX]  which scales Z so 
;  NEW_MIN scales to Data_lo and NEW_MAX scales to Data_hi, where NEW_MIN
;  and NEW_MAX refer to the original color table values.
;  NEWRANGE=[0,0] or [0,0,0,0] does nothing.
;  NEWRANGE=[0,0,newmin,newmax] only sets newmin and newmax.
;
;  The /CLIP keyword will clip the data array to the range Data_lo to Data_hi.
;  If clipping is not requested then data values outside that range may be
;  used as flag values and may be controlled by the color table using
;  values outside the BARMIN and BARMAX range.
;
;
;  Absolute Color Table file names and locations
;
;  The FILE keyword is used to give the name of an absolute color table.
;  If the path is not included the table is assumed to be in the current
;  directory.  The color table directory may be set to IDLUSR, the
;  library containing this routine (act_apply) using the keyword /LIB_TABLES.
;  The color table directory may be set to the directory containing the
;  routine that calls this routine using the keyword /MY_TABLES.
;  For example, if a routine named my_routine from the directory named
;  my_library calls act_apply and the IDL session is in current_dir, then
;  the color table 'act_example.txt' may be located in one of the
;  following locations:
;       (1) FILE='act_example.txt'                  In current_dir
;       (2) FILE='/aaa/bbb/ccc/act_example.txt'     In /aaa/bbb/ccc/
;       (3) FILE='act_example.txt', /LIB_TABLES     In IDLUSR
;       (4) FILE='act_example.txt', /MY_TABLES      In my_library
;  Note, the absolute color tables in the /LIB_TABLES directory (IDLUSR)
;  may be listed by the call: act_show,/list
;
          return,''
        endif
 
	;---------------------------------------------------------
        ;  Initialize
	;---------------------------------------------------------
	err = 0                 ; No errors yet.
	flag = 0		; New table flag: 0=old.
	cflag = 0		; Constant flag: 0=no, 1=yes.
 
	;---------------------------------------------------------
	;  Structure given
	;---------------------------------------------------------
	if n_elements(str0) ne 0 then begin
	  str = str0            ; Working copy.
	  flag = 1		; New table.
	  src = 'Structure'     ; Source of color table.
	  act_file = ''
	endif
 
	;---------------------------------------------------------
	;  File name given
	;---------------------------------------------------------
	if n_elements(file0) ne 0 then begin
          file = file0                  ; Working copy.
          filebreak, file, dir=fdir     ; Get path from filename.
          if fdir eq '' then begin      ; If there was no path ...
            ;---  Look in directory containing parent routine  ---
            if keyword_set(my_tab) then begin   ; Use caller tables.
              whocalledme, dir                  ; Directory of calling routine.
              file = filename(dir,file,/nosym)  ; Add to given file.
            endif
            ;---  Look in directory containing this routine (act_apply)  ---
            if keyword_set(lib_tab) then begin  ; Use IDLUSR tables.
              whoami, dir                       ; Directory of act_apply.pro.
              file = filename(dir,file,/nosym)  ; Add to given file.
            endif
          endif
          ;---  Read color table  ---
	  str = txtdb_rd(file,err=err)  ; Read act file.
	  if err ne 0 then begin        ; Error.
	    print,' Error in act_apply: color table file not read.'
	    print,'   '+file
            if n_elements(zz0) eq 0 then return,''
	    return, zz0                 ; return original array.
	  endif
	  flag = 1                      ; Flag as a new table.
	  src = 'File'                  ; Remember source of color table.
	  act_file = file               ; Remember act file name.
	endif
 
	;---------------------------------------------------------
        ;  New color table given
	;---------------------------------------------------------
	if flag eq 1 then begin
          act_str = str                 ; Keep copy of structure in common.
 
	  ;-------------------------------------------------------
	  ;  Caller info
	  ;-------------------------------------------------------
	  whocalledme, pdir, pfile      ; Get calling routine dir and name.
	  if pdir eq '' then begin
	    cd,curr=pdir
	    act_caller = ' act_apply called interactively in IDL in '+pdir
	  endif else begin
	    act_caller = ' act_apply called by IDL routine: '+pfile+' in '+pdir
	  endelse
	  act_tm = systime()            ; When color table loaded.
 
	  ;-------------------------------------------------------
	  ;  Extract needed items from structure
          ;  (see help for explanation)
	  ;-------------------------------------------------------
	  z = reform(str.z)
	  h = reform(str.h)
	  s = reform(str.s)
	  v = reform(str.v)
	  rgb = str.rgb + 0
	  step_flag = str.step_flag + 0
	  step = str.step + 0.
	  step_offset = str.step_offset + 0.
	  if tag_test(str,'barmin') eq 1 then begin
	    barmin = str.barmin + 0.
	    barmax = str.barmax + 0.
	  endif else begin
	    barmin = min(z)
	    barmax = max(z)
	  endelse
          if tag_test(str,'log') eq 1 then log_flag=str.log else log_flag=0
 
	  ;-------------------------------------------------------
	  ;  Interpolate in RGB color space
	  ;-------------------------------------------------------
	  if rgb eq 1 then begin
	    color_convert, h, s, v, r, g, b, /hsv_rgb
	    r = float(r)
	    g = float(g)
	    b = float(b)
	  endif else begin
            r = ''
            g = ''
            b = ''
          endelse
	endif ; flag
	;---------------------------------------------------------
 
	;---------------------------------------------------------
	;  Check if color table initialized
	;---------------------------------------------------------
	if n_elements(z) eq 0 then begin
	  print,' Error in act_apply: Must initialize color table'
	  print,'   by giving a structure or an absolute color table file name.'
	  return,''
	endif
 
	;-----------------------------------------------------------------
        ;  Deal with units conversion
	;-----------------------------------------------------------------
	z2 = z				; Working copy of color table values.
	data_lo = barmin		; Default data min and max.
	data_hi = barmax
	astep = step			        ; Default step size.
        if n_elements(slope0) ne 0 then slope=slope0
        if n_elements(offset0) ne 0 then offset=offset0
        ;---  Handle given UNITS=units  ----
        if n_elements(units) ne 0 then begin
          if tag_test(act_str,'new_units') then begin
            new_units = tag_value(act_str,'new_units')
            w = where(units eq new_units,cnt)
            if cnt eq 1 then begin
              w = w[0]
              slope = act_str.slope[w] + 0.D0
              offset = act_str.offset[w] + 0.D0
            endif ; Requested units matches a color table units.
          endif ; Color table has new units.
        endif ; UNITS requested.
        ;-------------------------------------
        if n_elements(slope) ne 0 then begin    ; Do units conversion.
;        if n_elements(slope) eq 1 then begin    ; Do units conversion.
          if n_elements(offset) eq 0 then offset=0.
          z2 = z2*slope + offset                ; Convert independent var.
          data_lo = data_lo*slope + offset      ; Convert data limits.
          data_hi = data_hi*slope + offset
          astep = astep*slope + offset          ; Convert step size.
        endif
 
	;-----------------------------------------------------------------
	;  Deal with NEWRANGE: Color table range
	;
	;  Color table is defined as functions of z:
	;    r=fr(z) & g=fg(z) & b=fb(z) OR
	;    h=fh(z) & s=fs(z) & v=fv(z)
	;  z2 is a copy of z that may be rescaled without changing
	;    the original table on next call.
	;  data_lo, data_hi = Default is z min/max before any NEWRANGE.
	;    This is the actual data range covered by the whole bar.
	;  barmin, barmax = Section of bar to display in color bar.
	;    newmin, newmax = That section by default but can set
	;    using NEWRANGE, where newmin, newmax refer to the original
	;    color table values.
	;-----------------------------------------------------------------
	nr = n_elements(nran)		; Any new scaling given?
	if nr ne 0 then nr=(total(abs(nran)) ne 0) ? nr : 0 ; Ignore all 0s.
	if nr gt 0 then begin		; If new scaling then deal with it.
          if total(abs(nran[0:1])) ne 0 then begin
            if nran[0] eq -1 then begin
	      data_lo = min(zz0)        ; Use data minimum.
            endif else begin
	      data_lo = nran[0]		; New data min given.
            endelse
            if nran[1] eq -1 then begin
	      data_hi = max(zz0)        ; Use data maximum.
            endif else begin
	      data_hi = nran[1]         ; New data max given.
            endelse
          endif
	  newmin = barmin		; Default colors.
	  newmax = barmax
	  if nr eq 4 then begin		; If new color range given
	    newmin = nran[2]		; use them.
	    newmax = nran[3]
	  endif ; nr eq 4
          if log_flag eq 1 then begin   ; LOG
            zlg = alog10(z)             ; Want to scale in log space.
            newminlg = alog10(newmin)
            newmaxlg = alog10(newmax)
            data_lolg = alog10(data_lo)
            data_hilg = alog10(data_hi)
	    ;---  Scale color table value as specified to fit data  ---
	    z2 = 10^scalearray(zlg,newminlg,newmaxlg,data_lolg,data_hilg)
          endif else begin              ; LINEAR.
	    ;---  Scale color table value as specified to fit data  ---
	    z2 = scalearray(z,newmin,newmax,data_lo,data_hi)
	    ;---  Adjust step to vary as range varies  ---
	    ratio = (data_hi-data_lo)/(newmax-newmin)	; Range ratio.
	    astep = step*ratio				; Adjusted step.
          endelse
	endif ; nr gt 0
 
	;---------------------------------------------------------
	;  Make working copy of data array
	;---------------------------------------------------------
	if n_elements(zz0) eq 0 then return,''
	zz = zz0
 
	;---------------------------------------------------------
	;  Clip data array copy if requested
	;---------------------------------------------------------
	if keyword_set(clip) then zz=zz>data_lo<data_hi
 
	;---------------------------------------------------------
	;  Check for constant image
	;---------------------------------------------------------
	mn = min(zz,max=mx)			; Check array min/max.
	if mn eq mx then begin			; Is array constant?
	  cflag = 1				; Flag data as constant.
	  const = mn				; Return constant value.
	endif
 
	;---------------------------------------------------------
        ;  Deal with log color table
	;---------------------------------------------------------
        if log_flag eq 1 then begin             ; LOG.
	  ;-------------------------------------------------------
          ;  Deal with stepped log color table
          ;    Step size will vary over data range.
          ;    This is handled by converting all the data to the
          ;    range 1 to 10, stepping in that range, and then
          ;    converting back to the original data range.
          ;    There is no step offset allowed for log tables.
	  ;-------------------------------------------------------
          if step_flag eq 1 then begin          ; Create steps.
            f = floor(alog10(zz))               ; Log of decade of each sample.
            fact = 10.^f                        ; Decade of each sample.
            zzm = zz/fact                       ; Convert to 1 to 10.
            zzms = (floor(zzm/astep)*astep)>1.  ; Step data (in 1 to 10 range).
            zmod = zzms*fact                    ; Back to original data range.
          endif else zmod=zz                    ; Data not stepped.
          z2w = alog10(z2)                      ; Working values.
          zzw = alog10(zmod)
	;---------------------------------------------------------
        ;  Deal with linear color table
	;---------------------------------------------------------
        endif else begin                        ; LINEAR.
	  ;-------------------------------------------------------
	  ;  Deal with stepped color table
          ;    floor should work I think.
	  ;-------------------------------------------------------
	  if step_flag eq 1 then begin
	    zzm = astep*gfloor((zz/astep)+step_offset)
	  endif else zzm=zz
          z2w = z2                              ; Working copy independent var.
          zzw = zzm                             ; Working copy of data.
        endelse
 
	;---------------------------------------------------------
	;  Apply color table
	;---------------------------------------------------------
	if rgb eq 1 then begin			; Work in RGB.
	  rr = interpol(float(r),z2w,zzw)
	  gg = interpol(float(g),z2w,zzw)
	  bb = interpol(float(b),z2w,zzw)
	  img = img_merge(rr,gg,bb,true=tr)
	endif else begin			; Work in HSV.
	  hh = interpol(fixang(h),z2w,zzw)
	  ss = interpol(s,        z2w,zzw)
	  vv = interpol(v,        z2w,zzw)
	  img = img_merge(/hsv,hh,ss,vv,true=tr)
	endelse
 
	;---------------------------------------------------------
        ;  Return an array of 24-bit colors
	;---------------------------------------------------------
        if keyword_set(c24) then begin
          img_split, img, rr, gg, bb
          rr = long(rr)
          gg = long(gg)
          bb = long(bb)
          clr = rr + 256L*(gg + 256L*bb)
          return, clr
        endif
 
	;---------------------------------------------------------
        ;  Return color image as a byte array
	;---------------------------------------------------------
	return, byte(img+0.5)
 
	end
