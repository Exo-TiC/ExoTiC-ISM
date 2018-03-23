;-------------------------------------------------------------
;+
; NAME:
;       BIT_SHIFT
; PURPOSE:
;       Shift bits in a byte array by any amount.
; CATEGORY:
; CALLING SEQUENCE:
;       out = bit_shift(in,n)
; INPUTS:
;       in = Input byte array.                 in
;          May be 1-D or 2-D.  Always shifts
;          the X dimension.
;       n = Number of bits to shift (+ or -).  in
; KEYWORD PARAMETERS:
;       Keywords:
;         /ONE_D Shift input array as a 1-D array even if 2-D.
;         ERROR=err Error flag: 0=ok.
; OUTPUTS:
;       out = Resulting byte array.            out
; COMMON BLOCKS:
; NOTES:
;       Note: The shift may be left (n>0) or right (n<0).
;       Same direction as ishft.
;       Bits will shift between bytes in the array and will
;       be lost when they go out of either end.  Bits that shift
;       into the array will be 0.
; MODIFICATION HISTORY:
;       R. Sterner, 2011 Aug 11
;       R. Sterner, 2011 Aug 23 --- Fixed shift direction in help text.
;       R. Sterner, 2011 Sep 05 --- Added keyword /ONE_D.
;
; Copyright (C) 2011, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
        function bit_shift, arr0, n, one_d=one_d, error=err, help=hlp
 
        if (n_params(0) lt 2) or keyword_set(hlp) then begin
          print,' Shift bits in a byte array by any amount.'
          print,' out = bit_shift(in,n)'
          print,'   in = Input byte array.                 in'
          print,'      May be 1-D or 2-D.  Always shifts'
          print,'      the X dimension.'
          print,'   n = Number of bits to shift (+ or -).  in'
          print,'   out = Resulting byte array.            out'
          print,' Keywords:'
          print,'   /ONE_D Shift input array as a 1-D array even if 2-D.'
          print,'   ERROR=err Error flag: 0=ok.'
          print,' Note: The shift may be left (n>0) or right (n<0).'
          print,' Same direction as ishft.'
          print,' Bits will shift between bytes in the array and will'
          print,' be lost when they go out of either end.  Bits that shift'
          print,' into the array will be 0.'
          return,''
        endif
 
        ;------------------------------------------------
        ;  Initialize
        ;------------------------------------------------
        err = 0                         ; Assume ok.
        ndim = dimsz(arr0,0)>1          ; Number of dimensions.
        if ndim gt 2 then begin         ; Wrong number of dimensions.
          print,' Error in bit_shift: Must be 1-D or 2-D.  # dims was ',ndim
          err = 1
          return,''
        endif
        arr = arr0                          ; Working copy.
        if keyword_set(one_d) then begin    ; Shift input as a 1-D array.
          dims = size(arr,/dim)             ; Get original array dimensions.
          arr = reform(arr,dims[0]*dims[1],/overwrite) ; Reform to 1-D.
          ndim = 1                          ; Now is 1-D.
        endif
        last = dimsz(arr,1)-1                   ; Last index in x dimension.
        if ndim eq 1 then dim=1 else dim=[1,0]  ; Shift flags.
 
        ;------------------------------------------------
        ;  Handle any needed byte shift
        ;
        ;  Note: ishft shifts in the opposite direction
        ;  from shift, so a sign switch is needed.
        ;  Also shift does a wrap-around shift, the bytes
        ;  that wrap must be zeroed out (in all rows).
        ;------------------------------------------------
        nbyt = -n/8                     ; nbyt has opposite sign from n.
        arr2 = shift(arr,nbyt*dim)      ; Shift in x only.
        if nbyt gt 0 then arr2[0:nbyt-1,*]=0B
        if nbyt lt 0 then arr2[last+nbyt+1:last,*]=0B
 
        ;------------------------------------------------
        ;  Left over bit shift
        ;
        ;  The shift above handled any multiple of 8 bits
        ;  shift.  There may be some shift left over
        ;  (from -7 to +7 only).
        ;------------------------------------------------
        n2 = n + 8*nbyt                 ; nbyt has opposite sign from n.
 
        ;------------------------------------------------
        ;  Now do left over bit shift
        ;
        ;  Some bits will in general shift out of the
        ;  bytes and be lost.  That is corrected later.
        ;------------------------------------------------
        a = ishft(arr2,n2)
 
        ;------------------------------------------------
        ;  Deal with any bits that shift out of a byte.
        ;------------------------------------------------
        nbyt2 = -sign(n2)               ; # bytes to shift (+/-1).
        b = ishft(arr2,n2+8*nbyt2)      ; Complimentary shift to a above.
        b = shift(b,nbyt2)              ; Shift to carry position.
        if nbyt2 gt 0 then b[0,*]=0B    ; Zero out wrapped bytes.
        if nbyt2 lt 0 then b[last,*]=0B
 
        ;------------------------------------------------
        ;  Merge carry bits
        ;------------------------------------------------
        arr2 = a or b
 
        if keyword_set(one_d) then begin      ; Array was treated as 1-D.
          arr2 = reform(arr2,dims,/overwrite) ; Restore original array shape.
        endif
 
        return, arr2
 
        end
