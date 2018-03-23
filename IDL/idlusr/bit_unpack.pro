;-------------------------------------------------------------
;+
; NAME:
;       BIT_UNPACK
; PURPOSE:
;       Unpack bit string arrays from a given byte array.
; CATEGORY:
; CALLING SEQUENCE:
;       out = bit_unpack(in,nbits,nwrds)
; INPUTS:
;       in = Input byte array containing bit string array.  in
;       nbits = The number of bits in each bit string.      in
;       nwrds = The number of bit strings.                  in
; KEYWORD PARAMETERS:
;       Keywords:
;         ERROR=err Error flag: 0=ok.
;         OUT_BYTES=cbyts Returned # bytes in each output element.
; OUTPUTS:
;       out = returned bit strings as an array of integers. out
; COMMON BLOCKS:
;       bit_unpack_com
; NOTES:
;       Notes: in may be 1-D (single record) or 2-D (multiple
;         records).  The bit strings are assumed to start at the
;         first bit in the input byte array (which may have more
;         bits than are needed, but not less). The output will be
;         an array of the smallest unsigned integers that can hold
;         the bit strings.
; MODIFICATION HISTORY:
;       R. Sterner, 2011 Sep 06
;       R. Sterner, 2012 Feb 22 --- Cleaned up comments.
;       R. Sterner, 2012 Jul 27 --- Added OUT_BYTES=cbyts.
;
; Copyright (C) 2011, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
        function bit_unpack, inarr0, nbits, nwrds, error=err, $
                out_bytes=cbyts, help=hlp
 
        common bit_unpack_com, padtab,cbyttb,typtab, msk08,msk16,msk32,msk64
 
        if (n_params(0) lt 3) or keyword_set(hlp) then begin
          print,' Unpack bit string arrays from a given byte array.'
          print,' out = bit_unpack(in,nbits,nwrds)'
          print,'   in = Input byte array containing bit string array.  in'
          print,'   nbits = The number of bits in each bit string.      in'
          print,'   nwrds = The number of bit strings.                  in'
          print,'   out = returned bit strings as an array of integers. out'
          print,' Keywords:'
          print,'   ERROR=err Error flag: 0=ok.'
          print,'   OUT_BYTES=cbyts Returned # bytes in each output element.'
          print,' Notes: in may be 1-D (single record) or 2-D (multiple'
          print,'   records).  The bit strings are assumed to start at the'
          print,'   first bit in the input byte array (which may have more'
          print,'   bits than are needed, but not less). The output will be'
          print,'   an array of the smallest unsigned integers that can hold'
          print,'   the bit strings.'
          return,''
        endif
 
        err = 0
 
        ;--------------------------------------------------
        ;  Check inputs
        ;--------------------------------------------------
        if size(inarr0,/typ) ne 1 then begin
          print,' Error in bit_unpack: Input array must be type byte.'
          err = 1
          return,''
        endif
        ;---  make sure input array is 1-D or 2-D  ---
        ndims = size(inarr0,/n_dimensions)          ; # dimensions.
        if (ndims lt 1) or (ndims gt 2) then begin  ; 1-D or 2-D?
          print,' Error in bit_unpack: Input byte array must be'
          print,'   1-D or 2-D.'
          err = 1
          return,''
        endif
        dims = size(inarr0,/dimensions) ; Get dimensions.
        nx = dims[0]                    ; Bytes in record.
        if ndims eq 2 then ny=dims[1] else ny=1 ; Number of records.
        if nbits*nwrds gt nx*8 then begin
          print,' Error in bit_unpack: requested bit array is too big.'
          print,'   Stated bits per word = '+strtrim(nbits,2)
          print,'   Stated word = '+strtrim(nwrds,2)
          print,'   Total bits needed = '+strtrim(nbits*nwrds,2)
          print,'   Total bits available = '+strtrim(nx*8,2)
          err = 1
          return,''
        endif
 
        ;-----------------------------------------------------
        ;  Initialize common first time
        ;
        ;  nbits is the length of each bit string in array.
        ;  nbyts is the number of bytes needed to hold an
        ;    extracted bit string = ceil(nbits/8.)
        ;
        ;  cbyttb = Number of bytes in the output integers.
        ;  padtab = For nbyts padtab[nbyts] is number of
        ;    bytes needed to pad up to next integer size.
        ;    Will have from 1 to 8 bytes.
        ;  typtab = Type table for nbyts: 1=byte,
        ;    12=unsigned 16-bit int, 13=unsigned 32-bit int,
        ;    15=unsigned 64-bit int.
        ;  Bit masks: msk64 is a 64-bit bit mask array, with
        ;    from 0 to 64 bits turned on, type ULONG64.
        ;    msk32 is derived from msk64 and is all 32 bit
        ;    masks, m16 is all 16 bit masks, and msk08 is
        ;    all 8 bit masks.  These mask arrays are bigger
        ;    then needed (except msk08) but for indexing
        ;    convenience all the elements are included.
        ;-----------------------------------------------------
        if n_elements(padtab) eq 0 then begin
          ;---  Set up lookup tables  ---
          ;         0  1  2  3  4  5  6  7  8  <-- nbyts = number of bytes.
          cbyttb = [0, 1, 2, 4, 4, 8, 8, 8, 8] ; # bytes in output integers.
          padtab = [0, 0, 0, 1, 0, 3, 2, 1, 0] ; # pad bytes needed.
          typtab = [0, 1,12,13,13,15,15,15,15] ; Data type to hold value.
          ;---  Generate bit masks  ---
          msk64 = [0,2ULL^(1+indgen(64))-1ULL]
          msk32 = ulong(msk64[0:32])
          msk16 = uint(msk64[0:16])
          msk08 = byte(msk64[0:8])
        endif
 
        ;--------------------------------------------------
        ;  Find the needed output data type
        ;--------------------------------------------------
        nbyts = ceil(nbits/8.)  ; # bytes needed to hold extracted bit string.
        cbyts = cbyttb[nbyts]   ; # bytes in output integers.
        typ   = typtab[nbyts]   ; IDL data type needed for output.
 
        ;--------------------------------------------------
        ;  Find the number of bytes in a repeat group
        ;
        ;  A repeat group is a group of bytes that will
        ;  hold a subset of the packed bit strings of length nbits
        ;  with the first bit string starting at the first bit
        ;  in the repeat group and the last ending at the
        ;  last bit in the repeat group.  The input bytes
        ;  containing the bit string array can be divided
        ;  into repeat groups of bytes.
        ;
        ;  The smallest repeat group size in bytes is
        ;    gbyts = LCM(nbits,8)/8
        ;  where LCM is the least common multipe of
        ;  nbits and 8 (bits per byte).
        ;  If this is smaller than the number of bytes in
        ;  the output integer (cbyts) needed to hold the
        ;  bit string then double the size.  This will
        ;  work over the range of bit lengths needed
        ;  (1 to 64).
        ;
        ;  The number of bit strings in each repeat group
        ;    ngstr = gbyts*8/nbits (will be 1, 2, 4, or 8)
        ;  This will be the number of loops needed to pick
        ;  out the bytes to move into the output array and
        ;  will be 8 or less (1, 2, 4, or 8).
        ;--------------------------------------------------
        gbyts = lcm_mod(nbits,8)/8
        if gbyts lt cbyts then gbyts=2*gbyts
        ngstr = gbyts*8/nbits   ; <-- Number of loops needed.
 
        ;--------------------------------------------------
        ;  Find the number of pad bytes needed and add
        ;
        ;    nx = Number of bytes in each input record.
        ;    ny = Number of records.
        ;    gbyts = Number of bytes in each repeat group.
        ;  Want a whole number of repeat groups.
        ;  The number of repeat groups needed will be
        ;    ngrp = ceil(float(nx)/gbyts) for a total of
        ;    tbyts = ngrp*gbyts bytes.  Have nx bytes so
        ;  need to pad with
        ;    npad = tbyts-nx
        ;--------------------------------------------------
        ngrp = ceil(float(nx)/gbyts)  ; Number of repeat groups needed.
        tbyts = ngrp*gbyts            ; Total bytes in all repeat groups.
        npad = tbyts - nx             ; Number of pad bytes needed.
        if npad gt 0 then begin       ; Any pad bytes needed?
          zpad = bytarr(npad,ny)      ; Pad bytes.
          inarr = [inarr0,zpad]       ; Add pad bytes.
        endif else inarr=inarr0
 
        ;--------------------------------------------------
        ;  Set up the pickoff indices
        ;
        ;  The repeat groups have a bit string right
        ;  aligned at the end of each group, pick the
        ;  bytes containing this string off and move
        ;  them  into the output array. The bytes to pick
        ;  off will always be at the end of the groups
        ;  because each next bit string will be shifted
        ;  there.  There will be ngstr such shifts and
        ;  pick offs.  The unused upper bits will be
        ;  removed later.
        ;
        ;  The are cbyts to pick off from the end of each
        ;  repeat group.  Think of each record made up of
        ;  ngrp groups of gbyts bytes each (repeat groups).
        ;  The indices of the byte after the last bytes of
        ;  each group are: indx=(1+indgen(ngrp))*gbyts
        ;  To get the pick off indices, offset by ...,-2,-1
        ;  (whatever is needed to offset to the last cbyts
        ;  indices) = indgen(cbyts)-cbyts.  Reshape indx
        ;  into cbyts columns and add the needed offsets.
        ;  inarr[inx,*] will pull the needed bytes.
        ;--------------------------------------------------
        indx = rebin(transpose(1+indgen(ngrp))*gbyts,cbyts,ngrp)
        inx = (rebin(indgen(cbyts)-cbyts,cbyts,ngrp) + indx)[0:*]
 
        ;--------------------------------------------------
        ;  Set up the holding array
        ;
        ;    ngstr = Number of bit strings in each group.
        ;    ngrp = Number of groups in padded input.
        ;  The number of bit strings in each record is
        ;    n_arr = ngstr*ngrp
        ;  Each bit string will be placed in cbyts bytes.
        ;  The dimensions of the holding byte array is
        ;    x size = n_arr * cbyts
        ;    y size = ny   (ny records)
        ;--------------------------------------------------
        n_arr = ngstr*ngrp
        hold = bytarr(n_arr*cbyts, ny)
 
        ;--------------------------------------------------
        ;  Set up the indices into the hold array
        ;
        ;  Will loop over the bit strings in each
        ;  repeat groups in each record. Each loop will
        ;  pull out ngrp bit strings in each record, each
        ;  bit string is held in cbyts. So cbyts*ngrp bytes
        ;  are pulled from each input record, and there
        ;  are ny records for a total of cbyts*ngrp*ny
        ;  bytes.
        ;
        ;  The x indices into the hold array are computed
        ;  from 2 parts, the index into the cbyts (ix),
        ;  and the index into the group (iy0). iy0 starts
        ;  pointing to the last member of each group and
        ;  will be decremented by 1 each loop to get each
        ;  member.  ix and iy0 are combined to get the
        ;  complete indices into each record:
        ;    ixx = ix + (iy0-i)*cbyts
        ;  where i is the loop index (0 to ngstr-1).
        ;  This is the same as ixx = ix + iy0*cbyts - i*cbyts
        ;  So let ixx = ix + iy0*cbyts
        ;  and at the end of each loop do ixx=ixx-cbyts
        ;  Don't bother to decrement or shift on last loop.
        ;  iyy are the indices into the records and do not
        ;  change.  For each loop, compute ixx, then
        ;    hold[ixx,iyy] = inarr[inx,*]
        ;--------------------------------------------------
        ix = rebin(indgen(cbyts),cbyts,ngrp)      ; For one record.
        ix = rebin(ix[0:*],cbyts*ngrp,ny)         ; For all records.
        iy0 = rebin(transpose(1+indgen(ngrp))*ngstr-1,cbyts,ngrp) ; For 1 rec.
        iy0 = rebin(iy0[0:*],cbyts*ngrp,ny)       ; For all records.
        ixx = ix + iy0*cbyts                      ; For first loop.
        iyy = (lonarr(cbyts*ngrp)+1)#lindgen(ny)  ; For all records (and loops).
 
        ;--------------------------------------------------
        ;  Loop over the bit strings in each group
        ;
        ;  The number of bit strings in each group is
        ;  ngstr and that is the loop size.  It is never
        ;  more than 8 (and may be 1, 2, 4, or 8).
        ;  In each loop do the following steps:
        ;  (1) Copy the last bit string in the group to the hold array.
        ;  Skip steps (2) and (3) on last loop.
        ;  (2) Shift the records by nbits down in inarr.
        ;  (3) Compute the next hold array indices.
        ;--------------------------------------------------
        last = ngstr - 1                  ; Loop over all bit strings in group.
        for i=0,last do begin             ; Loop will be at most 8 times.
          hold[ixx,iyy] = inarr[inx,*]    ; Copy last bit string in groups.
          if i eq last then break         ; On last loop break out here.
          ;---  Shift the next bit string into last place  ---
          inarr = bit_shift(inarr,-nbits)
          ;---  Shift hold array insertion indices  ---
          ixx = ixx - cbyts
        endfor
 
        ;--------------------------------------------------
        ;  Field extract the output values
        ;
        ;  When hold is a 1-D array for a single record
        ;    then the field extraction uses only the needed bytes.
        ;  When hold is a 2-D array then any added pad
        ;    bytes must be dropped before doing field
        ;    extraction or they will end up in the next
        ;    record.
        ;--------------------------------------------------
        if ndims eq 1 then begin
          out = fix(hold,0,nwrds,typ=typ)
        endif else begin
          rbyts = nwrds*cbyts                   ; Bytes used in each record.
          out = fix(hold[0:rbyts-1,*],0,nwrds,ny,typ=typ)
        endelse        
 
        ;--------------------------------------------------
        ;  Get byte order correct
        ;
        ;  On a little endian machine the byte order after
        ;  field extraction will be reverse what it was in
        ;  the input bit string.  In that case endian swap
        ;  to correct the byte order.
        ;--------------------------------------------------
        swap_endian_inplace, out, /swap_if_little_endian
 
        ;--------------------------------------------------
        ;  AND off the bad upper bits
        ;
        ;  Except for bit strings that fit exactly in the
        ;  output integer, each extracted bit string (except
        ;  the last) will include some of the lower bits
        ;  of the next bit string, which will fall into
        ;  the high bits of the output integer.  These
        ;  extra bits must be ANDed off.
        ;--------------------------------------------------
        case typ of
 1:       msk = msk08[nbits]    ; Byte (8 bits)
12:       msk = msk16[nbits]    ; Unsigned integer (16 bits)
13:       msk = msk32[nbits]    ; Unsigned long integer (32 bits)
15:       msk = msk64[nbits]    ; Unsigned 64 bit integer (64 bits)
else:     begin
            stop,' Internal error in bit_unpack (typ).'
          end
        endcase
 
        out = out AND msk
 
        return, out
 
        end
