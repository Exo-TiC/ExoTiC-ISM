;-------------------------------------------------------------
;+
; NAME:
;       TXTDB_DASH
; PURPOSE:
;       For a text array, find the txtdb_rd reference line of dashes.
; CATEGORY:
; CALLING SEQUENCE:
;       dashtxt = txtdb_dash(txt)
; INPUTS:
;       txt = text array with data lines only.  in
;         Must be more than 1 line of text.
; KEYWORD PARAMETERS:
;       Keywords:
;         TAB=tb number of spaces per tab (def=8).
; OUTPUTS:
;       dashtxt = Returned string with dashes.  out
; COMMON BLOCKS:
; NOTES:
;       Notes: This routine is intended to help find the 3
;       data description lines for a text data file to be
;       read by txtdb_rd.  This routine only finds the reference
;       line, the line of dashes that delineate the columns of data.
;       This line can then be added to the file and the
;       Type and Tag lines added above it.
;       If the target file has lines other than the data lines,
;       like headers and trailers, isolate the data lines (manually)
;       and send those to this function.  A file may contain
;       multiple sets of data lines, call this function for
;       each set.
; MODIFICATION HISTORY:
;       R. Sterner, 2008 Feb 28
;       R. Sterner, 2010 Jun 04 --- Converted arrays from () to [].
;
; Copyright (C) 2008, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	function txtdb_dash, txt, tab=tb, help=hlp
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' For a text array, find the txtdb_rd reference line of dashes.'
	  print,' dashtxt = txtdb_dash(txt)'
	  print,'   txt = text array with data lines only.  in'
	  print,'     Must be more than 1 line of text.'
	  print,'   dashtxt = Returned string with dashes.  out'
	  print,' Keywords:'
	  print,'   TAB=tb number of spaces per tab (def=8).'
	  print,' Notes: This routine is intended to help find the 3'
	  print,' data description lines for a text data file to be'
	  print,' read by txtdb_rd.  This routine only finds the reference'
	  print,' line, the line of dashes that delineate the columns of data.'
	  print,' This line can then be added to the file and the'
	  print,' Type and Tag lines added above it.'
	  print,' If the target file has lines other than the data lines,'
	  print,' like headers and trailers, isolate the data lines (manually)'
	  print,' and send those to this function.  A file may contain'
	  print,' multiple sets of data lines, call this function for'
	  print,' each set.'
	  return,''
	endif
 
	;-------------------------------------------------------------
	;  
	;-------------------------------------------------------------
	t = detab(txt,tab=tb)
	return, string(([45B,32B])[min(byte(t) eq 32B, dim=2)])
 
	end
