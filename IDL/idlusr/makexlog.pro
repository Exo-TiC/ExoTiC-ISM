;---  makexlog.pro = Make an array of logarithmic friendly values.
;     R. Sterner, 2010 Nov 12

        function makexlog, v1, v2, step, count=cnt, help=hlp

        if (n_params(0) lt 3) or keyword_set(hlp) then begin
          print,' Make an array of logarithmic friendly values.'
          print,' arr = makexlog(start, end, step)'
          print,'   start = start value.                    in'
          print,'   end = end value.                        in'
          print,'   step = step between values.             in'
          print,'     This step must be specified in the prime decade'
          print,'     from 1 to 10 and must be 1, 2, 5, or 10.'
          print,'   arr = Returned array of values.         out'
          print,'     Contains the multiples of the step size that'
          print,'     fall between start and end.'
          print,' Keywords:'
          print,'   COUNT=n Returned number of values in arr.'
          print,' Notes:  Some examples:'
          print,'   makexlog(0.2,20,5) gives 0.5,1,5,10.'
          print,'   makexlog(0.2,20,10) gives 1,10.'
          print,'   makexlog(0.1,3,2) gives 0.1,0.2,0.4,0.6,0.8,1,2.'
          print,'   makexlog(0.1,100,10) gives 0.1,1,10,100.'
          print,'   makexlog(0.2,101,10) gives 1,10,100.'
          return,''
        endif

        dec1 = floor(alog10(v1))        ; Starting decade.
        dec2 =  ceil(alog10(v2))        ; Ending decade.
        ndec = dec2 - dec1              ; Number of decades.

        case step of
'1':    begin
          x0 = [1,2,3,4,5,6,7,8,9]
          p0 = fltarr(9)+dec1
        end
'2':    begin
          x0 = [1,2,4,6,8]
          p0 = fltarr(5)+dec1
        end
'5':    begin
          x0 = [1,5]
          p0 = fltarr(2)+dec1
        end
'10':   begin
          x0 = [1]
          p0 = dec1
        end
else:   begin
          print,' Error in makexlog: Step size must be 1, 2, 5, or 10.'
          print,'   Was '+strtrim(step,2)
          return,''
        end
        endcase

        x = x0
        p = p0
        for i=1,ndec-1 do begin
          x = [x,x0]
          p = [p,p0+i]
        endfor
        x = [x,1]
        p = [p,dec1+i]

        a = x*10.^p
        w = where((a ge v1) and (a le v2),cnt)
        if cnt gt 0 then a=a[w]

        return, a

        end
