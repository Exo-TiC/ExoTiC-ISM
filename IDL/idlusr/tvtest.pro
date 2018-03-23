;----  tvtest.pro = Test writing to display window  -----
;	R. Sterner, 2004 Sep 30

	pro tvtest, v=v

	for ch=1,3 do begin		; Loop through channels.
	  print,' Testing channel ',ch
	  for ib=0,255 do begin		; Loop through values.
	    tv,[byte(ib)],0,0,chan=ch	; Write byte.
	    ib2 = tvrd(0,0,1,1,chan=ch)	; Read back.
	    if (ib ne ib2) or keyword_set(v) then print,ib,ib2
	  endfor
	endfor

	end
