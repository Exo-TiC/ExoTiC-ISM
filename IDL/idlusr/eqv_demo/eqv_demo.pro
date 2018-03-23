;------  eqv_demo.pro = demo eqv  ---------
;	R. Sterner, 26 Oct, 1993

	pro eqv_demo

    whoami, dir
    f = filename(dir,'eqv_list.txt',/nosym)
	txt = getfile(f)
	ff = filename(dir,txt,/nosym)
	eqvc, list=ff

	return
	end
