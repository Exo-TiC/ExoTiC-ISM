;-------------------------------------------------------------
;+
; NAME:
;       SCALEDATA
; PURPOSE:
;       Linearly scale data from one range to another (allow missing).
; CATEGORY:
; CALLING SEQUENCE:
;       b = scaledata( a, in1, in2, out1, out2)
; INPUTS:
;       a = Array to scale.                          in
;       in1 = array value to scale to out1.          in
;       in2 = array value to scale to out2.          in
;       out1 = value in1 gets scaled to (def=0).     in
;       out2 = value in2 gets scaled to (def=255).   in
; KEYWORD PARAMETERS:
;       Keywords:
;         MISSING=miss Missing data value.  Anything less than
;           out1 or greater than out2 is set to miss if given.
;         /SBYTE The input array is a signed byte.
;           IDL does not have signed bytes so signed byte data will
;           be in a byte with values from 0 to 255 but anything
;           over 127 represents a negative value.  This keyword
;           corrects the values into a signed integer before
;           applying the scaling.
; OUTPUTS:
;       b = scaled array.                            out
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 2012 Nov 27
;
; Copyright (C) 2012, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
        function scaledata, a0, in1, in2, out1, out2, missing=miss, sbyte=sbyte, help=hlp
 
        if (n_params(0) lt 5) or keyword_set(hlp) then begin
          print,' Linearly scale data from one range to another (allow missing).'
          print,' b = scaledata( a, in1, in2, out1, out2)'
          print,'   a = Array to scale.                          in'
          print,'   in1 = array value to scale to out1.          in'
          print,'   in2 = array value to scale to out2.          in'
          print,'   out1 = value in1 gets scaled to (def=0).     in'
          print,'   out2 = value in2 gets scaled to (def=255).   in'
          print,'   b = scaled array.                            out'
          print,' Keywords:'
          print,'   MISSING=miss Missing data value.  Anything less than'
          print,'     out1 or greater than out2 is set to miss if given.'
          print,'   /SBYTE The input array is a signed byte.'
          print,'     IDL does not have signed bytes so signed byte data will'
          print,'     be in a byte with values from 0 to 255 but anything'
          print,'     over 127 represents a negative value.  This keyword'
          print,'     corrects the values into a signed integer before'
          print,'     applying the scaling.'
          return,''
        endif
 
        ;---  Deal with signed byte data  --------
        if keyword_set(sbyte) then begin
          a = fix(a0)                         ; Convert to int.
          w = where(a gt 127, n)              ; Any negative values?
          if n gt 0 then a[w]=a[w]-256        ; Correct negative values.
        endif else a=a0                       ; Work on a copy.
 
        ;---  Scale the data  ---
        b = scalearray(a, in1, in2, out1, out2)
 
        ;---  Deal with missing data  ---
        if n_elements(miss) ne 0 then begin
          w = where((b lt out1) or (b gt out2), cnt)
          if cnt gt 0 then b[w] = miss
        endif
 
        return, b
 
        end
