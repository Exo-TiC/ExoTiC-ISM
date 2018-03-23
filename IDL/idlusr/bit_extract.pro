;-------------------------------------------------------------
;+
; NAME:
;       BIT_EXTRACT
; PURPOSE:
;       Extract a specified bit string from a byte array.
; CATEGORY:
; CALLING SEQUENCE:
;       out = bit_extract(inbytes,b1,b2,[nwrds])
; INPUTS:
;       inbytes = Byte array to extract bits from.   in
;         1-D or 2-D.
;       b1 = Start bit of bit string.                in
;       b2 = End bit of bit string.                  in
;         The bit address can range up to the total
;         number of bits in the byte array.
;       nwrds = Optional number of words (def=1).    in
;         Number of equal size bit strings from b1 to b2.
;         nwrds must go evenly into the number of bits
;         from b1 to b2.
; KEYWORD PARAMETERS:
;       Keywords:
;         /ONE means bit addresses start at 1, else 0.
;         /BYTES Return right justified bit string in
;           a byte array even if it has less than 64 bits.
;           Only the number of bytes needed to contain the
;           bit string are returned.  Normally an integer
;           value is returned if it can hold the value.
;         DESCRIPTION=txt  Text array describing the bits in the
;           given byte array.  When this is given the items listed
;           in txt are extracted and out is returned as a structure.
;           Each line in txt describes one extracted item and
;           has FOUR required parts (separated by whitespace):
;              tag b1 b2 nwds [optional text]
;           Tag is the name that will be used in the structure and
;           b1 and b2 are the start and end bit in the byte array.
;           nwds is the number of words in the returned item.
;           The bits/word = (b2-b1+1)/nwds.
;         ERROR=err Error flag: 0=ok.
; OUTPUTS:
;       out = Returned extracted bit string.         out
;         Normally an unsigned integer but will be
;         a byte array if more than 64 bits or if
;         the keyword /BYTES is used.
;         If the keyword DESCRIPTION is used then out will
;         be a structure containing the items described.
; COMMON BLOCKS:
;       bit_extract_com
; NOTES:
;       Notes: b1 is the most significant bit (MSB) or the
;       bit string, b2 is the least significant bit (LSB).
;       When extracting from a 2-D byte array b1 and b2
;       are bit addresses in the X dimension of the array,
;       and columns of bit strings are extracted.  Extracted
;       bit strings are returned as unsigned integers big
;       enough to contain the bit string.
; MODIFICATION HISTORY:
;       R. Sterner, 2011 Aug 23
;       R. Sterner, 2011 Sep 01 --- Added keyword DESCRIPTION.
;       R. Sterner, 2011 Sep 05 --- Was initializing common every time. Fixed.
;       R. Sterner, 2011 Sep 06 --- Added nwords as input.
;       R. Sterner, 2011 Sep 06 --- Fixed forced byte array for all records.
;       R. Sterner, 2011 Sep 06 --- Added bit string array handling.
;       R. Sterner, 2011 Sep 19 --- Returned an error flag instead of stopping.
;       R. Sterner, 2011 Sep 19 --- Added bit_unpack when nwrds GT 1.
;       R. Sterner, 2011 Sep 28 --- More detailed error message for recursive.
;       R. Sterner, 2012 Jul 27 --- Made /BYTES work for bit arrays.
;
; Copyright (C) 2011, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
        function bit_extract, inbytes, b10, b20, nwrds, one=one, $
          bytes=byte_flag, description=dtxt, error=err, help=hlp
 
        common bit_extract_com, padtab, typtab, msk08, msk16, msk32, msk64
 
        if (n_params(0) lt 1) or keyword_set(hlp) then begin
          print,' Extract a specified bit string from a byte array.'
          print,' out = bit_extract(inbytes,b1,b2,[nwrds])'
          print,'   inbytes = Byte array to extract bits from.   in'
          print,'     1-D or 2-D.'
          print,'   b1 = Start bit of bit string.                in'
          print,'   b2 = End bit of bit string.                  in'
          print,'     The bit address can range up to the total'
          print,'     number of bits in the byte array.'
          print,'   nwrds = Optional number of words (def=1).    in'
          print,'     Number of equal size bit strings from b1 to b2.'
          print,'     nwrds must go evenly into the number of bits'
          print,'     from b1 to b2.'
          print,'   out = Returned extracted bit string.         out'
          print,'     Normally an unsigned integer but will be'
          print,'     a byte array if more than 64 bits or if'
          print,'     the keyword /BYTES is used.'
          print,'     If the keyword DESCRIPTION is used then out will'
          print,'     be a structure containing the items described.'
          print,' Keywords:'
          print,'   /ONE means bit addresses start at 1, else 0.'
          print,'   /BYTES Return right justified bit string in'
          print,'     a byte array even if it has less than 64 bits.'
          print,'     Only the number of bytes needed to contain the'
          print,'     bit string are returned.  Normally an integer'
          print,'     value is returned if it can hold the value.'
          print,'   DESCRIPTION=txt  Text array describing the bits in the'
          print,'     given byte array.  When this is given the items listed'
          print,'     in txt are extracted and out is returned as a structure.'
          print,'     Each line in txt describes one extracted item and'
          print,'     has FOUR required parts (separated by whitespace):'
          print,'        tag b1 b2 nwds [optional text]'
          print,'     Tag is the name that will be used in the structure and'
          print,'     b1 and b2 are the start and end bit in the byte array.'
          print,'     nwds is the number of words in the returned item.'
          print,'     The bits/word = (b2-b1+1)/nwds.'
          print,'   ERROR=err Error flag: 0=ok.'
          print,' Notes: b1 is the most significant bit (MSB) or the'
          print,' bit string, b2 is the least significant bit (LSB).'
          print,' When extracting from a 2-D byte array b1 and b2'
          print,' are bit addresses in the X dimension of the array,'
          print,' and columns of bit strings are extracted.  Extracted'
          print,' bit strings are returned as unsigned integers big'
          print,' enough to contain the bit string.'
          return, ''
        endif
 
        err = 0
 
        ;-----------------------------------------------------
        ;  Process DESCRIPTION=dtxt if given
        ;
        ;  Recursively call this routine to extract each bit
        ;  string described in dtxt.  Ignore null tags.
        ;  Build a structure with all extracted bit strings.
        ;-----------------------------------------------------
        ntxt = n_elements(dtxt)                 ; Number of lines in txt.
        if ntxt gt 0 then begin                 ; Any lines in txt?
          c1 = strmid(dtxt,0,1)                 ; First character of txt.
          for i=0,ntxt-1 do begin               ; Yes. Loop over them.
            if c1[i] eq ' ' then continue       ; Skip null tags.
            tag   = getwrd(dtxt[i],0)           ; Get tag name.
            bt1   = getwrd('',1)+0              ; Get start bit.
            bt2   = getwrd('',2)+0              ; Get end bit.
            nwrds = getwrd('',3)+0              ; Number of bits/word.
            val = bit_extract(inbytes,bt1,bt2,nwrds, $
              one=one,bytes=byte_flag,error=err)
;            if err ne 0 then return,''          ; Return on error.
            if err ne 0 then begin
              print,' Problem found in line '+strtrim(i,2)+':'
              print,'   '+dtxt[i]
              return,''                         ; Return on error.
            endif
            if i eq 0 then begin                ; Create structure on 1st item.
              out = create_struct(tag,val)
            endif else begin
              out = create_struct(out,tag,val)  ; Add next item to structure.
            endelse
          endfor ; i
          return, out                           ; Return structure.
        endif
 
        ;-----------------------------------------------------
        ;  Initialize common first time
        ;
        ;  nbits is the length of the bit string to extract
        ;    = b2-b1+1.
        ;  nbyts is the number of bytes needed to hold the
        ;    extracted bit string = ceil(nbits/8.)
        ;  padtab = For nbyts padtab[nbyts] is number of
        ;    bytes needed to pad up to next integet size.
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
          padtab = [0, 0, 0, 1, 0, 3, 2, 1, 0] ; # pad bytes needed.
          typtab = [0, 1,12,13,13,15,15,15,15] ; Data type to hold value.
          ;---  Generate bit masks  ---
          msk64 = [0,2ULL^(1+indgen(64))-1ULL]
          msk32 = ulong(msk64[0:32])
          msk16 = uint(msk64[0:16])
          msk08 = byte(msk64[0:8])
        endif
 
        ;-----------------------------------------------------
        ;  Initialize
        ;-----------------------------------------------------
        ;---  Make sure input array is type byte  ---
        typ   = size(inbytes,/type)                 ; Data type.
        if typ ne 1 then begin
          print,' Error in bit_extract: Input array must be bytes.'
          err = 1
          return,''
        endif
        ;---  make sure input array is 1-D or 2-D  ---
        ndims = size(inbytes,/n_dimensions)         ; # dimensions.
        if (ndims lt 1) or (ndims gt 2) then begin  ; 1-D or 2-D?
          print,' Error in bit_extract: Input byte array must be'
          print,'   1-D or 2-D.'
          err = 1
          return,''
        endif
        ;---  Get dimensions of input array  ---
        dims = size(inbytes,/dimensions) ; # dimensions.
        nx = dims[0]                            ; Byte array size in x.
        if ndims eq 2 then ny=dims[1] else ny=1 ; Byte array size in y.
        ;---  Deal with start bit of 0 or 1  ---
        if keyword_set(one) then begin   ; Start bit is 1.
          b1 = b10 - 1
          b2 = b20 - 1
        endif else begin                 ; Staft bit is 0.
          b1 = b10
          b2 = b20
        endelse
        ;---  Number of bits in bit string to extract  ---
        nbits = b2 - b1 + 1
        ;---  Number of words  ---
        if n_elements(nwrds) eq 0 then nwrds=1  ; Default to 1 word.
        if (nbits mod nwrds) ne 0 then begin
          print,' Error in bit_extract: the number of words requested'
          print,'   must evenly divide into the number of bits specified.'
          print,'   Start bit, end bit: '+strtrim(b10,2)+', '+strtrim(b20,2)
          print,'   Number of bit strings (words): '+strtrim(nwrds,2)
          print,'   Total number of bits (b2-b1+1): '+strtrim(nbits,2)
          err = 1
          return,''
        endif
        ;---  Number of bytes needed to hold extracted bit string  ---
        nbyts = ceil(nbits/8.)
 
        ;-----------------------------------------------------
        ;  Find subarray containing target bit string
        ;
        ;  At this point (and on) bit addresses start at 0.
        ;  Bit 0 is the leftmost bit of the leftmost byte.
        ;  Byte 0 is the leftmost byte in the array.
        ;  Find the byte indices of the start and end bits.
        ;  Grab the subarray containing the target bit string.
        ;-----------------------------------------------------
        byt1 = long(b1/8)         ; Start byte index.
        byt2 = long(b2/8)         ; End byte index.
        bb = inbytes[byt1:byt2,*] ; Subarray containing target bit string.
        num_bytes = byt2-byt1+1   ; Number of bytes grabbed.
        lo_abs = 8*byt1           ; Absolute bit address of first bit in bb.
 
        ;-----------------------------------------------------
        ;  Bit String Arrays: deal with multiple words
        ;
        ;  Bit strings are packed inside byte array bb
        ;  but not yet justified.  Left justify the packed
        ;  bits, and then drop any exta byte on right side
        ;  of bb.  AND off extra bits on right side?
        ;  Make sure to allow 2-D (records).
        ;
        ;  If /BYTE requested then return as bytes.
        ;  Use byte field extraction to convert output from
        ;  bit_unpack to a byte array.  This reverses the
        ;  byte order in x so reverse back.
        ;  Each bit string will be contained in the same
        ;  number of bytes as the numeric item would have had.
        ;-----------------------------------------------------
        if nwrds gt 1 then begin    ; Have a bit string array.
          ;---  Shift to left justify bits in byte array  ---
          b1_rel = b1-lo_abs        ; Address of start bit of bit string in bb.
          bb = bit_shift(bb,b1_rel) ; Left Justify: start bit to MSB in array.
          ;---  Keep only bytes needed  ---
          lst = nbyts-1             ; Last byte index.
          bb = bb[0:lst,*]          ; Keep only the needed bytes.
          ;---  Mask off any extra bits  ---
          ubits = nbits mod 8       ; Bits used in rightmost byte.
          msk = not msk08[8-ubits]  ; Mask to keep used bits.
          bb[lst,*] = bb[lst,*] AND msk ; Masked away any others.
          ;---  Unpack bits  ---
          nbts = nbits/nwrds        ; Number of bits in each bit string.
          out = bit_unpack(bb,nbts,nwrds,out_bytes=cbyts)
          ;---  Deale with /BYTE request  ---
          if keyword_set(byte_flag) then begin ; Wnt bytes out.
            nrec = dimsz(bb,2)>1    ; Number of records in input.
            bb = reverse(byte(out,0,cbyts*nwrds,nrec),1)  ; To bytes.
            return, bb
          endif
          return, out               ; Return result.
        endif
 
        ;-----------------------------------------------------
        ;  Find relative bit addresses in subarray bb.
        ;
        ;  The target bit string is contained in the
        ;  subarray bb but not yet right justified.
        ;-----------------------------------------------------
        b2_rel = b2-lo_abs        ; Address of end bit of bit string in bb.
        last_bit = 8*num_bytes-1  ; Address of last bit in bb.
 
        ;-----------------------------------------------------
        ;  Shift end bit to LSB in grabbed byte subarray.
        ;  (Right justify target bit string inside bb)
        ;-----------------------------------------------------
        nshft = b2_rel - last_bit ; Shift needed to make end bit LSB.
        bb = bit_shift(bb,nshft)  ; Shift end bit to LSB in subarray.
 
        ;-----------------------------------------------------
        ;  Return a byte array if requested or too many bits
        ;
        ;  At this point the target bit string is right
        ;  justified in the byte subarray bb of length
        ;  num_bytes.
        ;
        ;  An unsigned integer will be returned if the number
        ;  of bits will fit into one or unless the /BYTES
        ;  keyword is used.  If there are too many bits for
        ;  any of the integer types then a byte array
        ;  containing the target bit string will be returned.
        ;-----------------------------------------------------
        bflag = 0                              ; Assume will be an integer.
        if nbits gt 64 then bflag=1            ; Too many bits for an integer.
        if keyword_set(byte_flag) then bflag=1 ; Byte array requested.
        if bflag eq 1 then begin               ; Will return a byte array.
          ;---  If not all the bytes needed drop leftmost  ---
          if ceil(nbits/8.) lt num_bytes then bb=bb[1:*,*]
          ;---  Mask off any extra bits  ---
          exbits = nbits mod 8                 ; Bits needed in leftmost byte.
          if exbits eq 0 then exbits=8         ; Need all bits.
          bb[0,*] = bb[0,*] AND msk08[exbits]  ; Masked away any others.
          return, bb
        endif
 
        ;-----------------------------------------------------
        ;  Reduce or pad to bytes needed to hold value
        ;
        ;  Bit string may cover one more bytes than is needed
        ;  to hold it as an integer data type when right
        ;  aligned.  Drop leftmost byte in that case.
        ;
        ;  Bit string may fit into fewer bytes than the
        ;  integer needed to hold it (like 17 bits in 3
        ;  bytes).  Pad with 0s in that case.
        ;-----------------------------------------------------
        ;---  Needed zero pad bytes and needed data type  ---
        npad = padtab[nbyts]     ; Number of pad bytes needed.
        ;---  Needed bytes to hold data  ---
        ndata_bytes = nbyts+npad ; Number of bytes needed to hold data.
        ;---  Have 1 more byte in subarray than is needed  ---
        if num_bytes gt ndata_bytes then begin  ; Drop excess byte.
          bb = bb[1:*,*]                        ; Drop left most byte.
        endif
        if num_bytes lt ndata_bytes then begin  ; Pad with 0s.
          zpad = bytarr(npad,ny)                ; Zero pad bytes.
          bb = [zpad,bb]                        ; Pad on left.
        endif
 
        ;-----------------------------------------------------
        ;  Field extract value from modifed subarray
        ;-----------------------------------------------------
        typ  = typtab[nbyts]     ; Data type needed.
        if ndims eq 1 then begin
          out = fix(bb,0,typ=typ)
        endif else begin
          out = fix(bb,0,ny,typ=typ)
        endelse
 
        ;-----------------------------------------------------
        ;  Deal with endian: must swap on little
        ;    endian machines.
        ;-----------------------------------------------------
        out = swap_endian(out,/swap_if_little_endian)
 
        ;-----------------------------------------------------
        ;  Mask off extra bits
        ;
        ;  Mask depends on data type.
        ;-----------------------------------------------------
        case typ of
 1:       msk = msk08[nbits]    ; Byte (8 bits)
12:       msk = msk16[nbits]    ; Unsigned integer (16 bits)
13:       msk = msk32[nbits]    ; Unsigned long integer (32 bits)
15:       msk = msk64[nbits]    ; Unsigned 64 bit integer (64 bits)
else:     begin
            stop,' Internal error in bit_extract (typ).'
          end
        endcase
 
        out = out AND msk
 
        return, out
 
        end
