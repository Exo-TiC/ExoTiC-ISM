	PRO XDISK_EVENT, ev
	;
	WIDGET_CONTROL, ev.id,  GET_UVAL = uval
        WIDGET_CONTROL, ev.top, GET_UVAL = map
        ;
        IF (UVAL EQ 'UPDATEALL')  THEN BEGIN
            IF (!version.os EQ 'hp-ux') THEN BEGIN
	        SPAWN,'bdf ', bdf & bdf = bdf(1:*)
	    ENDIF
	    IF (!version.os EQ 'sunos') THEN BEGIN
	        SPAWN,'df -k', bdf & bdf = bdf(1:*)
	    ENDIF 
	    IF (!version.os EQ 'linux') THEN BEGIN
	        SPAWN,'df -k', bdf & bdf = bdf(1:*)
	    ENDIF 	    
	    ;
            ;  Eliminate any lines that do not have % in them ...
	    ;
            chpercnt = STRPOS(bdf, '%')
            ntmp = WHERE(chpercnt GE 0)
            IF (ntmp(0) LT 0) THEN BEGIN
                PRINT, ' No appropriate disks found!  ...'
                RETURN
            ENDIF
            bdf    = bdf(ntmp)
	    ndisks = N_ELEMENTS(bdf)
	    ;
	    disknames = STRARR(ndisks)
	    ;
	    FOR i = map.imin, map.imax DO BEGIN
	        WSET, map.d1(i) & ERASE
	    ENDFOR    
	    ;
	    usn        = LONARR(ndisks)
	    cfree      = FLTARR(ndisks)
	    cfreelabel = STRARR(ndisks)
	    FOR i = 0L, ndisks-1L DO BEGIN
	        ;  Now Find location of % sign ...
	        pcntloc = STRPOS(bdf(i), '%')
	        FNDWRD, bdf(i), n, loc, len
	        distmp = pcntloc - loc
	        ntmp   = WHERE(distmp LT 0) 
	        distmp(ntmp) = MAX(distmp)
	        ntmp   = WHERE(distmp EQ MIN(distmp)) 
	        pospcnt = ntmp(0)
	        ;

	        disknames(i) = STRMID(bdf(i), loc(pospcnt+1L), len(pospcnt+1L)) 
	        usn(i) = LONG(STRMID(bdf(i), loc(pospcnt), len(pospcnt)-1))
	        cfree(i)  = FLOAT(STRMID(bdf(i), loc(pospcnt-1), len(pospcnt-1)))/(1024.*1024.)  
	    ENDFOR	    
	    cfree2 = cfree(map.asort)
	    cfree  = cfree2
	    usn2   = usn(map.asort)
	    usn    = usn2
	    FOR i = map.imin, map.imax DO BEGIN
	        cfreelabel(i) = ' GB'
	        IF (cfree(i) LT .5) THEN BEGIN
	            cfree(i) = cfree(i) * 1024.
	            cfreelabel(i) = ' MB'
	        ENDIF
	        ;
	        WSET, map.d1(i) & ERASE
                PLOT, [0., 100.], [0., 1.], /NODATA, POS = [0., 0., 1., 1.], $
                      XSTYLE = 5, YSTYLE = 5	        
	        POLYFILL, [0., usn(i), usn(i), 0.], [0., .0, 1., 1.], COLOR = TARCLR(255,0,0)
	        POLYFILL, [usn(i), 100., 100., usn(i)], [0., .0, 1., 1.], COLOR = TARCLR(0,255,0)
	        usn(i) = 100L - usn(i)
	        WIDGET_CONTROL, map.id2(i), SET_VAL = STRCOMPRESS(FIX(usn(i))) + '% Free:  ' + $
	                        STRING(cfree(i),FORMAT='(F6.1)') + cfreelabel(i) 
	    ENDFOR                               
        ENDIF
        ;
        IF (UVAL EQ 'EXIT') THEN BEGIN
            WIDGET_CONTROL, ev.top, /DESTROY
        ENDIF              
	;
	RETURN
	END
	;
	;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=-==-=-=-=-=-=
	;
	PRO XDISK, SHOW = show, XSIZE = xsize, MINDISKSIZE = mindisksize, HELP = help
	;
	IF KEYWORD_SET(help) THEN BEGIN
	   PRINT,'  XDISK:  SHOW = show, MINDISKSIZE = mindisksize, XSIZE=xsize'
	   PRINT,'  e.g. show=2 will show the 2 largest disks'
	   PRINT,'       mindisksize is in GB.  Default is 1GB'
	   PRINT,'       mindisksize=2 shows disks of size larger than 2 GB'
	   RETURN	
	ENDIF
	;
	IF (N_ELEMENTS(mindisksize) EQ 0) THEN mindisksize=1.
	;
	IF (N_ELEMENTS(xsize) EQ 0) THEN xsize = 200
	;
	IF (!version.os NE 'hp-ux' AND !version.os NE 'sunos' AND !version.os NE 'linux') THEN BEGIN
	    XMESS,'Error!  Only hp-ux, sunos and PC-Linux are supported ...', /WAIT
	    RETURN
	ENDIF
	IF (!version.os EQ 'hp-ux') THEN BEGIN
	    SPAWN,'bdf ', bdf 
	ENDIF
	IF (!version.os EQ 'sunos') THEN BEGIN
	    SPAWN,'df -k', bdf
	ENDIF
	IF (!version.os EQ 'linux') THEN BEGIN
	    SPAWN,'df -k', bdf
	ENDIF	
	;
	FNDWRD, bdf(0), n, loc, len
	IF (STRMID(bdf(0), loc(0), len(0)) NE 'Filesystem') THEN BEGIN
            top1 = WIDGET_BASE(TITLE = 'XDISK: AHN', /COLUMN)
            top1base1  = WIDGET_BASE(top1, /COLUMN)                                              	                	    
            txtwid     = WIDGET_LIST(top1base1, VALUE = bdf, XSIZE = 45, YSIZE = 20) 
            WIDGET_CONTROL, TOP1, /REALIZE                  		
	    WAIT, 5
	    WIDGET_CONTROL, TOP1, /DESTROY
	    a = GETENV('IDL_XDAT') + '/xdisk.err'
	    PUTFILE, a, bdf
	    XMESS,'  System Error!  Check xdisk.err file ...', /WAIT
	    RETURN
	ENDIF
        ;
	bdf         = bdf(1:*)
	ndisks      = N_ELEMENTS(bdf)
        ;
        ;  Eliminate any lines that do not have % in them ...
	;
        chpercnt = STRPOS(bdf, '%')
        ntmp = WHERE(chpercnt GE 0)
        IF (ntmp(0) LT 0) THEN BEGIN
            PRINT, ' No appropriate disks found!  ...'
            RETURN
        ENDIF
        bdf    = bdf(ntmp)
        ndisks = N_ELEMENTS(bdf)
        ;
	disknames   = STRARR(ndisks)
	ctotal      = FLTARR(ndisks)
	ctotallabel = STRARR(ndisks)
	lenmax      = 0L
        ;
	FOR i = 0L, ndisks-1L DO BEGIN
	    ;  Now Find location of % sign ...
	    pcntloc = STRPOS(bdf(i), '%')
	    FNDWRD, bdf(i), n, loc, len
	    lenmax = MAX([lenmax, len])
	    distmp = pcntloc - loc
	    ntmp   = WHERE(distmp LT 0) 
	    distmp(ntmp) = MAX(distmp)
	    ntmp   = WHERE(distmp EQ MIN(distmp)) 
	    pospcnt = ntmp(0)
	    ;
	    disknames(i) = STRMID(bdf(i), loc(pospcnt+1L), len(pospcnt+1L)) 
	    ctotal(i) = FLOAT(STRMID(bdf(i), loc(pospcnt-3L), len(pospcnt-3L)))/(1024.*1024)
	    ctotallabel(i) = ' GB'  
	ENDFOR
	;
	disknames2 = STRARR(ndisks) 
	FOR j = 0L, ndisks-1L DO BEGIN
            FNDWRD, disknames(j), n, loc, len & len = len(0)
            IF (len LT lenmax) THEN BEGIN
                temp = ' '
                FOR k = 0, lenmax-len-2L DO BEGIN
                    temp = temp + ' '
                ENDFOR
                disknames2(j) = disknames(j) + temp
            ENDIF ELSE BEGIN
                disknames2(j) = disknames(j)
            ENDELSE               
	ENDFOR
	;
	asort = SORT(ctotal)
	disknames2 = disknames(asort)
	disknames  = disknames2
	ctotal2    = ctotal(asort)
	ctotal     = ctotal2	
	ctotalgb   = ctotal
	;
	ctotallengths = FLTARR(ndisks)
	ctotallengths(ndisks-1) = 200.
	FOR i = 0L, ndisks-2L DO BEGIN
	    ctotallengths(i) = 200. * ctotal(i)/ctotal(ndisks-1)
	    IF (ctotallengths(i) LT 10.) THEN ctotallengths(i) = 10.
	    IF (ctotal(i) LT .5) THEN BEGIN
	        ctotal(i) = ctotal(i) * 1024.
	        ctotallabel(i) = ' MB'
	    ENDIF 	    
	ENDFOR	
	;
	;disknames  = disknames2
	disknames2 = 0 	
	;	
	;
	top           = WIDGET_BASE(TITLE = 'XDISK:  '+ !version.os + '  [A.H.Najmi]', /COLUMN)
	b             = WIDGET_BASE(top, /COLUMN)
	bb            = WIDGET_BASE(b, /ROW)
	;
	id0           = LONARR(ndisks)
	id1           = LONARR(ndisks)
	id2           = LONARR(ndisks)
	;
	imin = 0
	imax = ndisks-1L
	IF (N_ELEMENTS(show) GT 0) THEN BEGIN
	    imax = ndisks-1
	    imin = imax - show + 1L
	    IF (imin LT 0) THEN imin = 0L	
	ENDIF
	;
	IF (mindisksize GT 0.) THEN BEGIN
	    imin = WHERE(ctotalgb GE mindisksize)
	    IF (imin(0) LT 0) THEN BEGIN
	        mindisksize = 1.
	        imin = WHERE(ctotalgb GE mindisksize)
	        imin = MIN(imin)
	        IF (imin LT 0) THEN BEGIN
	            PRINT,'  Can only run when partitions larger than 1.0 GB are available!'
	            RETURN
	        ENDIF
	    ENDIF ELSE BEGIN
	        imin = MIN(imin)
	    ENDELSE	
	ENDIF	
	;
	FOR i = imin, imax DO BEGIN
	    id      = WIDGET_LABEL(bb, Value = disknames(i) + ':  ' + STRING(ctotal(i),FORMAT='(F5.1)') + ctotallabel(i), XSIZE = xsize)
	    ;id0(i)  = WIDGET_LABEL(bb, Value = '                         ', XSIZE = 300)
	    id1(i)  = WIDGET_DRAW(bb, XSIZE = ctotallengths(i), YSIZE = 20)
	    id2(i)  = WIDGET_LABEL(bb, Value = '                                                ')
	    bb      = WIDGET_BASE(b, /ROW, /ALIGN_LEFT)
	ENDFOR
	id = WIDGET_LABEL(bb, VALUE = !version.os)
	id = WIDGET_LABEL(bb, VALUE = '     ')
	id = WIDGET_BUTTON(bb, VALUE = ' Update ', uval = 'UPDATEALL')
	id = WIDGET_LABEL(bb, VALUE = '     ')
	id = WIDGET_BUTTON(bb, VALUE = '  Exit  ', uval = 'EXIT')
	id = WIDGET_LABEL(bb, VALUE = ' [Minimum Disk Size set at ' + STRING(mindisksize,FORMAT='(F8.1)') + ' GB]')	
	;	
	WIDGET_CONTROL, top, /REALIZE	
	;
	d1 = LONARR(ndisks)
	FOR i = imin, imax DO BEGIN
	    WIDGET_CONTROL, id1(i), GET_VAL = temp
	    d1(i) = temp
        ENDFOR
        ;
	usn        = LONARR(ndisks)
	cfree      = FLTARR(ndisks)
	cfreelabel = STRARR(ndisks)
	FOR i = 0L, ndisks-1L DO BEGIN	
	    ;  Now Find location of % sign ...
	    pcntloc = STRPOS(bdf(i), '%')
	    FNDWRD, bdf(i), n, loc, len
	    distmp = pcntloc - loc
	    ntmp   = WHERE(distmp LT 0) 
	    distmp(ntmp) = MAX(distmp)
	    ntmp   = WHERE(distmp EQ MIN(distmp)) 
	    pospcnt = ntmp(0)		
	    FNDWRD, bdf(i), n, loc, len
	    usn(i)        = LONG(STRMID(bdf(i), loc(pospcnt), len(pospcnt)-1))
	    cfree(i)      = FLOAT(STRMID(bdf(i), loc(pospcnt-1), len(pospcnt-1)))/(1024.*1024.)
	ENDFOR
	cfree2 = cfree(asort)
	cfree  = cfree2
	usn2   = usn(asort)
	usn    = usn2
	;
	FOR i = imin, imax DO BEGIN
	    IF (cfree(i) LT 0.) THEN cfree(i) = 0.
	    cfreelabel(i) = ' GB'
	    IF (cfree(i) LT .5) THEN BEGIN
	        cfree(i) = cfree(i) * 1024.
	        cfreelabel(i) = ' MB'
	    ENDIF
	    ;
	    WSET, d1(i) & ERASE
            PLOT, [0., 100.], [0., 1.], /NODATA, POS = [0., 0., 1., 1.], $
                  XSTYLE = 5, YSTYLE = 5	        
	    POLYFILL, [0., usn(i), usn(i), 0.], [0., .0, 1., 1.], COLOR = TARCLR(255,0,0)
            POLYFILL, [usn(i), 100., 100., usn(i)], [0., .0, 1., 1.], COLOR = TARCLR(0,255,0)
	    usn(i) = 100L - usn(i)
	    WIDGET_CONTROL, id2(i), SET_VAL = STRCOMPRESS(FIX(usn(i))) + '% Free:  ' + $
	                    STRING(cfree(i),FORMAT='(F6.1)') + cfreelabel(i)
	ENDFOR  
        ;
	map  = {d1:d1, id1:id1, id2:id2, imin:imin, imax:imax, asort:asort}
	WIDGET_CONTROL, top, SET_UVAL = map
	;
	XMANAGER, 'XDISK',top
	;
	RETURN
	END
