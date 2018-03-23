;-------------------------------------------------------------
;+
; NAME:
;       IMG_LS
; PURPOSE:
;       Scale 24-bit image value (of HSV) between percentiles 1 and 99 (or specified percentiles).
; CATEGORY:
; CALLING SEQUENCE:
;       out = img_ls(in, [l, u, vlo, vhi])
; INPUTS:
;       in = input image.                           in
;       l = lower percentile to ignore (def = 1).   in
;       u = upper percentile to ignore (def = 1).   in
; KEYWORD PARAMETERS:
;       Keywords:
;         SCALE_ON=[vlo,vhi]   Optional values to scale to 0, 1.
;           Useful with the returned vlo, vhi to scale multiple
;           the same.
;         /QUIET  Inhibit scaling message.
;         NBINS=nb  Number of histogram bins to use (def=2000).
;         /NOSCALE  Do not actually scale the data (returns 0).
; OUTPUTS:
;       vlo = img value scaled to 0.                out
;       vhi = value scaled to 1.                    out
;       out = scaled 24-bit image.                  out
; COMMON BLOCKS:
; NOTES:
;       Notes: Uses cumulative histogram.
; MODIFICATION HISTORY:
;       R. Sterner, 2010 Feb 11
;       R. Sterner, 2010 Feb 15 --- Fixed vlo, vhi for constant image.
;       R. Sterner, 2010 May 12 --- Converted arrays from () to [].
;
; Copyright (C) 2010, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	function img_ls, img, l, u, vlo, vhi, nbins=nbins, quiet=quiet, $
	  noscale=noscale, scale_on=sc, help=hlp
 
        np = n_params(0)
 
        if (np lt 1) or keyword_set(hlp) then begin
          print,' Scale 24-bit image value (of HSV) between percentiles '+$
            '1 and 99 (or specified percentiles).' 
          print,' out = img_ls(in, [l, u, vlo, vhi])' 
          print,'   in = input image.                           in'
          print,'   l = lower percentile to ignore (def = 1).   in' 
          print,'   u = upper percentile to ignore (def = 1).   in'
          print,'   vlo = img value scaled to 0.                out'
          print,'   vhi = value scaled to 1.                    out'
          print,'   out = scaled 24-bit image.                  out'
          print,' Keywords:'
          print,'   SCALE_ON=[vlo,vhi]   Optional values to scale to 0, 1.'
	  print,'     Useful with the returned vlo, vhi to scale multiple'
	  print,'     the same.'
          print,'   /QUIET  Inhibit scaling message.'
          print,'   NBINS=nb  Number of histogram bins to use (def=2000).'
          print,'   /NOSCALE  Do not actually scale the data (returns 0).'
          print,' Notes: Uses cumulative histogram.'
          return, -1
        endif
 
	;---  Check image type (monochrome or color) ---
	img_shape, img, true=tr			; Check if monochrome or color.
	if tr eq 0 then begin			; 2-D image = monochrome.
	  return, ls(img,l, u, vlo, vhi, nbins=nbins, $
	    quiet=quiet, noscale=noscale)
	endif
 
	;---  Split image  ---
	img_split, img, /hsv, h, s, v		; Get image value, v.
 
	;---  Deal with scale_on  ---
	if n_elements(sc) eq 2 then begin
	  vlo = min(sc,max=vhi)
	  goto, scl
	endif ; n_elements
 
	;---  Set defaults  ---
        if np lt 2 then l = 1			; Lower cutoff (1%).
        if np lt 3 then u = l			; Upper cutoff (1%).
        clo = l/100.				; Normalized cutoff for
        chi = (100.-u)/100.			;   cumulative hist.
        if n_elements(nbins) eq 0 then nbins=2000  ; Hist bins to use.
 
        vmn = min(v)                          	; Find value extremes.
        vmx = max(v)
        dv = vmx - vmn                        	; Value range.
        if dv eq 0 then begin                 	; Error.
          txt = strtrim(vmn,2)
          print,' Error in img_ls: given image value is constant ('+$
            txt+'), no stretch possible.'
    	  vlo = vmn
	  vhi = vmx
          return, img
	endif
 
        b = (v - vmn)*nbins/dv                	; Force into NBIN bins.
	
        hh = histogram(b)                     	; Histogram.
        c = cumulate(hh)                      	; Look at cumulative histogram.
        c = c - c[0]                          	; Ignore 0s.
        c = float(c)/max(c)                   	; Normalize.
        w = where((c gt clo) and (c lt chi),count) ; Pick central window.
        if count gt 0 then begin
          lo = min(w)                         	; Find limits of rescaled data.
          hi = max(w)
        endif else begin
          lo = 0
          hi = nbins
          if not keyword_set(quiet) then print,$
            ' LS Warning: could not scale array properly.'
        endelse
        vlo = vmn + dv*lo/nbins               	; Limits in original array.
        vhi = vmn + dv*hi/nbins
 
scl:	if not keyword_set(quiet) then print,$
          ' Scaling image from ',vlo,' to ',vhi
        if keyword_set(noscale) then return, 0   ; Skip scaling.
 
	if vlo ne vhi then begin
	  v2 = scalearray(v>vlo<vhi,vlo,vhi,0.,1.) ; scale array.
	endif else v2=v
 
	img2 = img_merge(/hsv,h,s,v2)
 
	return, img2
 
	end
