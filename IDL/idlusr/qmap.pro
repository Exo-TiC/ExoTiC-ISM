;-------------------------------------------------------------
;+
; NAME:
;       QMAP
; PURPOSE:
;       Draw a quick map.
; CATEGORY:
; CALLING SEQUENCE:
;       qmap, lat, lon
; INPUTS:
;       lat, lon = Latitude, Longitude of map center.   in
; KEYWORD PARAMETERS:
;       Keywords:
;         SCALE=sc  Map scale (def=4E7).
;         /GRID Add a coordinate grid.
;         TITLE=ttl Optional map title.
;         SUBTITLE=sttl Optional map subtitle title.
;         PNG=png  Name of PNG image to save map in.
;         /HIRES  Use high resolution coastlines.
;         BGCOLOR=bgclr 24 bit Background color (def=white).
;         CRAD=rad  Radius of an optional circle to plot.
;           Radius is in m by default but if rad is a string the
;           units may follow and be nmiles, miles, km, meters,
;           m, yards, feet.  May be an array of radii.
;         CCOLOR=cclr Optional array of 24-bit colors for circle,
;           one for each radii (def=red).
;         ALON=alon, ALAT=alat  Optional area definition.
;           If alon and alat have 1 element:
;             Center of a circle of radius crad (def is
;               lon, lat if CRAD is given).
;           If alon and alat have 2 elements:
;             Box defined by alon=[min_lon,max_lon],
;               alat=[min_lat, max_lat].
;           If alon and alat have 3 or more elements:
;             Polygon defined by alon=[lon1,lon2,...,lonn],
;               alat=[lat1,lat2,...,latn].
;             Last point assumed to connect to first point.
;         IMAGE=img  Image to display on map.  Assumed global.
;         /CBAR  Display color bar using last absolute color table.
;           Call act_apply before calling qmap to set up the color
;           table.  Displays default bar range. May also set range:
;         CBAR=[vmin,vmax]  Display bar with the range vmin to vmax.
;         CBTITLE=cbttl  Title for color bar.
;         /EXISTS Use existing window, else make a window.
;         WINDOW=[nx,ny]  Give size for a new window.
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
;       Notes: Map is plotted using othographic projection and
;         default colors.
; MODIFICATION HISTORY:
;       R. Sterner, 2012 Jan 31
;       R. Sterner, 2012 Feb 12 --- Added IMAGE=img.
;       R. Sterner, 2012 Feb 12 --- Added Box and Polygon areas.
;       R. Sterner, 2012 Feb 13 --- Added /EXIST keyword.
;       R. Sterner, 2012 Mar 06 --- Added TITLE=ttl, /CBAR, CBTITLE=cbttl.
;       R. Sterner, 2012 Mar 07 --- Added WINDOW=[nx,ny].
;       R. Sterner, 2012 Mar 07 --- Added SUBTITLE=sttl.
;       R. Sterner, 2012 Mar 08 --- Made title and subtitle size adaptive.
;       R. Sterner, 2012 May 08 --- Allow an array of circle radii.
;       R. Sterner, 2012 Oct 16 --- Allow color bar min, max.
;       R. Sterner, 2012 Nov 01 --- Fixed cbar error if none requested.
;       R. Sterner, 2012 Nov 01 --- Added background color.
;       R. Sterner, 2013 Mar 05 --- Added new keyword BSPACE.
;
; Copyright (C) 2012, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
        pro qmap, lat, lon, scale=sc, grid=grid, png=png, hires=hires, $
          crad=crad, ccolor=cclr, alon=alon, alat=alat, image=img, $
          exists=exists, window=winsz, title=ttl, subtitle=sttl, cbar=cbar, $
          cbtitle=cbttl, bgcolor=bgclr, bspace=bspace, help=hlp
 
        if (n_params(0) lt 2) or keyword_set(hlp) then begin
          print,' Draw a quick map.'
          print,' qmap, lat, lon'
          print,'   lat, lon = Latitude, Longitude of map center.   in'
          print,' Keywords:'
          print,'   SCALE=sc  Map scale (def=4E7).'
          print,'   /GRID Add a coordinate grid.'
          print,'   TITLE=ttl Optional map title.'
          print,'   SUBTITLE=sttl Optional map subtitle title.'
          print,'   PNG=png  Name of PNG image to save map in.'
          print,'   /HIRES  Use high resolution coastlines.'
          print,'   BGCOLOR=bgclr 24 bit Background color (def=white).'
          print,'   CRAD=rad  Radius of an optional circle to plot.'
          print,'     Radius is in m by default but if rad is a string the'
          print,'     units may follow and be nmiles, miles, km, meters,'
          print,'     m, yards, feet.  May be an array of radii.'
          print,'   CCOLOR=cclr Optional array of 24-bit colors for circle,'
          print,'     one for each radii (def=red).'
          print,'   ALON=alon, ALAT=alat  Optional area definition.'
          print,'     If alon and alat have 1 element:'
          print,'       Center of a circle of radius crad (def is'
          print,'         lon, lat if CRAD is given).'
          print,'     If alon and alat have 2 elements:'
          print,'       Box defined by alon=[min_lon,max_lon],'
          print,'         alat=[min_lat, max_lat].'
          print,'     If alon and alat have 3 or more elements:'
          print,'       Polygon defined by alon=[lon1,lon2,...,lonn],'
          print,'         alat=[lat1,lat2,...,latn].'
          print,'       Last point assumed to connect to first point.'
          print,'   IMAGE=img  Image to display on map.  Assumed global.'
          print,'   /CBAR  Display color bar using last absolute color table.'
          print,'     Call act_apply before calling qmap to set up the color'
          print,'     table.  Displays default bar range. May also set range:'
          print,'   CBAR=[vmin,vmax]  Display bar with the range vmin to vmax.'
          print,'   CBTITLE=cbttl  Title for color bar.'
          print,'   BSPACE=bspace  Extra space to add to bottom in pixels'
          print,'     to allow extra text to be added (def=0).'
          print,'   /EXISTS Use existing window, else make a window.'
          print,'   WINDOW=[nx,ny]  Give size for a new window.'
          print,' Notes: Map is plotted using othographic projection and'
          print,'   default colors.'
          return
        endif
 
        ;----------------------------------------------------------------------
        ;  Defaults
        ;----------------------------------------------------------------------
        if n_elements(sc) eq 0 then sc=4E7
 
        ;----------------------------------------------------------------------
        ;  Deal with window and plot position
        ;----------------------------------------------------------------------
        if not keyword_set(exists) then begin
          if n_elements(winsz) eq 0 then begin      
            window
          endif else begin
            nx = winsz[0]
            ny = (winsz[[1]])[0]
            window,xsize=nx,ysize=ny
          endelse
        endif
        nx = !d.x_size                  ; Window dimensions.
        ny = !d.y_size
        xmar1 = 36
        xmar2 = 36
        ;---  Map Title  ---
        if n_elements(ttl) eq 0 then begin
          ymar2 = 24                    ; No title.
        endif else begin
          ymar2 = 40                    ; Space for just title.
          if keyword_set(grid) then ymar2=ymar2+10
          if n_elements(sttl) gt 0 then ymar2=ymar2+15
        endelse
        ;---  Deal with bottom space  ---
        if n_elements(bspace) eq 0 then bspace=0
        ;---  Color Bar  ---
        if n_elements(cbar) eq 0 then begin
          ymar1 = 24 + bspace           ; No color bar.
        endif else begin
          ymar1 = 70 + bspace           ; Space for just bar.
          if keyword_set(grid) then ymar1=ymar1+10
          if n_elements(cbttl) gt 0 then ymar1=ymar1+10
          bx = 300 < (2.*nx/3.)         ; Bar length (< 2/3 nx).
          by = 25                       ; Bar height.
          ibx1 = nx/2 - bx/2            ; Bar position in /dev.
          ibx2 = nx/2 + bx/2
;          iby1 = 25
          iby1 = ymar1 - 45             ; Offset down from bottom margin.
          iby2 = iby1 + by
          bx1 = float(ibx1)/nx          ; Bar position in /norm.
          bx2 = float(ibx2)/nx
          by1 = float(iby1)/ny
          by2 = float(iby2)/ny
          bpos = [bx1,by1,bx2,by2]      ; Bar position.
        endelse
        ix1 = xmar1                     ; Plot position in /dev.
        ix2 = nx - 1 - xmar2
        iy1 = ymar1
        iy2 = ny - 1 - ymar2
        x1 = float(ix1)/nx              ; Plot position in /norm.
        x2 = float(ix2)/nx
        y1 = float(iy1)/ny
        y2 = float(iy2)/ny
        maxlen = (ix2-ix1)/float(nx-1)  ; Normalized plot window width.
 
        ;----------------------------------------------------------------------
        ;  Initialize
        ;----------------------------------------------------------------------
        if n_elements(bgclr) eq 0 then bgclr=tarclr(255,255,255) ; Backgr clr.
	blk = tarclr(0,0,0)		; Black.
	wtr = tarclr(169,237,234)	; Water color.
	lnd = tarclr(230,217,187)	; Land color.
	cst = tarclr(121,172,121)	; Coastline color.
	uclr = tarclr(121,172,121)	; Coastline color.
	gclr = tarclr(190,190,190)	; Grid color.
	pclr = tarclr(200,000,000)	; Circle color.
	pos = [x1,y1,x2,y2]
	ixx = [x1,x2,x2,x1,x1]
	iyy = [y1,y1,y2,y2,y1]
        hres_flag = keyword_set(hires)
        cntry_flag = 1
        usa_flag = 1
 
        ;----------------------------------------------------------------------
        ;  Make map
        ;----------------------------------------------------------------------
        erase, bgclr
        polyfill,/norm,ixx,iyy,col=wtr
	map_set2,lat,lon,/ortho,/iso,/hor,scale=sc,/nobord,/noerase,pos=pos
 
        ;----------------------------------------------------------------------
        ;  Deal with image if given
        ;----------------------------------------------------------------------
        if n_elements(img) gt 0 then begin
          ;---  Remap image  ---
          r = img_map_image(img,comp=1)
 
          ;---  Coastlines  ---
	  if hres_flag then begin
	    map_continents,/hires,/coast,col=cst
	    if cntry_flag then map_continents,/hires,/countries, color=cst
	  endif else begin
	    map_continents,/coast,col=cst
	    if cntry_flag then map_continents,/countries, color=cst
	  endelse
          ;---  USA States  ---
	  if usa_flag then begin
	    if hres_flag then begin
	      map_continents,/usa,col=uclr,/hires
	    endif else begin
	      map_continents,/usa,col=uclr
	    endelse
	  endif
        endif
 
        ;----------------------------------------------------------------------
        ;  Fill Continents if no image given
        ;----------------------------------------------------------------------
        if n_elements(img) eq 0 then begin
          ;---  Coastlines  ---
	  if hres_flag then begin
	    map_continents,/hires,/coast,/fill,col=lnd
	    map_continents,/hires,/coast,col=cst
	    if cntry_flag then map_continents,/hires,/countries, color=cst
	  endif else begin
	    map_continents,/coast,/fill,col=lnd
	    map_continents,/coast,col=cst
	    if cntry_flag then map_continents,/countries, color=cst
	  endelse
          ;---  USA States  ---
	  if usa_flag then begin
	    if hres_flag then begin
	      map_continents,/usa,col=uclr,/hires
	    endif else begin
	      map_continents,/usa,col=uclr
	    endelse
	  endif
        endif
 
        ;----------------------------------------------------------------------
        ;  Fill any space, outline window
        ;----------------------------------------------------------------------
	map_space
	map_set2,lat,lon,/ortho,/iso,/hor,scale=sc,/nobord, $
	  /noerase,col=blk,pos=pos
	plots,ixx,iyy,col=blk,/norm,thick=2
 
        ;----------------------------------------------------------------------
        ;  Optional map grid
        ;----------------------------------------------------------------------
	if keyword_set(grid) then begin
	  maplatlong_grid,col=gclr,/labels,lcol=blk,chars=1.
	  plots,ixx,iyy,col=blk,/norm,thick=2
	endif
 
        ;----------------------------------------------------------------------
        ;  Optional circle
        ;
        ;  alon and alat should only have 1 element.  Also crad must be given.
        ;  If crad given a circle is assume, number of elements in alon, alat
        ;  not checked but only first element used.
        ;----------------------------------------------------------------------
        if n_elements(crad) ne 0 then begin              ; Circle radius given?
          if n_elements(alon) eq 0 then alon=lon         ; Default center is
          if n_elements(alat) eq 0 then alat=lat         ; map center.
          if n_elements(cclr) ne 0 then clrc=cclr else clrc=pclr ; Circle color(s).
          lstc = n_elements(clrc)-1                      ; Last circle color.
          for ir=0,n_elements(crad)-1 do begin           ; Loop over circles.
            rm = to_meters(crad[ir])                     ; Radius in m.
            ell_rb2ll,alon[0],alat[0],rm,makex(0,360,1),lonp,latp  ; Circle points.
            plots, lonp, latp, color=clrc[ir<lstc]       ; Plot circle.
          endfor ; ir
        endif
        ;----------------------------------------------------------------------
        ;  Optional box
        ;
        ;  If alon and alat have 2 elements a lon/lat box is defined.
        ;----------------------------------------------------------------------
        if (n_elements(alon) eq 2) and (n_elements(alat) eq 2) then begin
          x = alon[[0,1,1,0]]
          y = alat[[0,0,1,1]]
          fl = ['L','L','L','L']
          ell_polygon,x,y,fl,lng2=lonp,lat2=latp,step=5  ; 5 km steps.
          plots, lonp, latp, color=pclr                  ; Plot Box.
        endif
        ;----------------------------------------------------------------------
        ;  Optional polygon
        ;
        ;  If alon and alat have 3 or more  elements a polygon is defined.
        ;  The sides are assumed geodesics.
        ;----------------------------------------------------------------------
        if (n_elements(alon) gt 2) and (n_elements(alat) gt 2) then begin
          ell_polygon,alon,alat,fl,lng2=lonp,lat2=latp,step=5   ; 5 km steps.
          plots, lonp, latp, color=pclr                         ; Plot polygon.
        endif
 
        ;----------------------------------------------------------------------
        ;  Embed map scaling
        ;----------------------------------------------------------------------
        map_put_scale
 
        ;----------------------------------------------------------------------
        ;  Map Title
        ;----------------------------------------------------------------------
        if n_elements(ttl) ne 0 then begin
          if keyword_set(grid) then yoff=25 else yoff=15
          if n_elements(sttl) gt 0 then yoff=yoff+15
          csz = 2.0
          ;---  Check size and adapt if needed  ---
          xyouts, 0.5, -0.5, /norm,ttl,charsize=csz,width=wd
          if wd gt maxlen then csz=csz*(maxlen/wd)
          ;---  Plot text  ---
          xyouts, nx/2,  ny-ymar2+yoff,  ttl,/dev,charsize=csz,color=0,align=0.5
          xyouts, nx/2-1,ny-ymar2+yoff,  ttl,/dev,charsize=csz,color=0,align=0.5
          xyouts, nx/2,  ny-ymar2+yoff-1,ttl,/dev,charsize=csz,color=0,align=0.5
          xyouts, nx/2-1,ny-ymar2+yoff-1,ttl,/dev,charsize=csz,color=0,align=0.5
        endif
 
        ;----------------------------------------------------------------------
        ;  Sub Title
        ;----------------------------------------------------------------------
        if n_elements(sttl) ne 0 then begin
          stoff = 10
          if keyword_set(grid) then stoff=stoff+12
          csz = 1.5
          ;---  Check size and adapt if needed  ---
          xyouts, 0.5, -0.5, /norm,sttl,charsize=csz,width=wd
          if wd gt maxlen then csz=csz*(maxlen/wd)
          ;---  Plot text  ---
          xyouts, nx/2,  ny-ymar2+stoff,  sttl,/dev,charsize=csz,color=0,align=0.5
        endif
 
        ;----------------------------------------------------------------------
        ;  Color Bar
        ;----------------------------------------------------------------------
        if n_elements(cbar) ne 0 then begin
          if n_elements(cbar) eq 2 then begin
            act_cbar, cbar[0], cbar[1], pos=bpos, col=0, title=cbttl
          endif else begin
            act_cbar, 0, 0, pos=bpos, col=0, title=cbttl
          endelse
        endif
   
        ;----------------------------------------------------------------------
        ;  Save map
        ;----------------------------------------------------------------------
        if n_elements(png) gt 0 then begin
          pngscreen, png
        endif
 
        end
