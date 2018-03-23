;-------------------------------------------------------------
;+
; NAME:
;       WAV_PLAY
; PURPOSE:
;       Play a wave file.
; CATEGORY:
; CALLING SEQUENCE:
;       wav_play, file
; INPUTS:
;       file = Name of wave file to play.  in
;         May be an array of wave files.
; KEYWORD PARAMETERS:
;       Keywords:
;         PAUSE=sec Seconds to pause bewteen files (def=0).
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 2006 Apr 26
;       R. Sterner, 2006 May 03 --- Allowed arrays, fixed wait.
;       R. Sterner, 2010 Jun 07 --- Converted arrays from () to [].
;       R. Sterner, 2010 Jun 07 --- Cleaned up the code, added Mac support.
;
; Copyright (C) 2006, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
        pro wav_play, file, pause=psec, app=app, help=hlp
 
        if (n_params(0) lt 1) or keyword_set(hlp) then begin
          print,' Play a wave file.'
          print,' wav_play, file'
          print,'   file = Name of wave file to play.  in'
	  print,'     May be an array of wave files.'
	  print,' Keywords:'
	  print,'   PAUSE=sec Seconds to pause bewteen files (def=0).'
          print,'   APP=app Application to play wave file.'
          print,'     For Unix this defaults to play.'
          print,'     For Mac OS X this defaults to afplay.'
          return
        endif
 
	n = n_elements(file)
	if n_elements(psec) eq 0 then psec=0.
        if n_elements(app) eq 0 then $
          if !version.os_family eq 'unix' then $
            if !version.os eq 'darwin' then app='afplay' else app='play' $
          else app=''
 
	for i=0, n-1 do begin
          a = read_wav(file[i], rate)
          sec = dimsz(a,dimsz(a,0))/float(rate)
          if app ne '' then begin
            spawn, app + ' ' + file[i]
            wait, psec
          endif else begin
            wait, sec + psec
          endelse
	endfor
 
        end
