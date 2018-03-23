;-------------------------------------------------------------
;+
; NAME:
;       IMG_TOKMZ
; PURPOSE:
;       Convert an image array to a *.kmz file.
; CATEGORY:
; CALLING SEQUENCE:
;       img_tokmz, img
; INPUTS:
;       img = Image array.                 in
;         May be an image file name instead.
; KEYWORD PARAMETERS:
;       Keywords:
;         lon0=lon0, lat0=lat0: Point to look at (def=0,0).
;         range=rng View range (string with units, def='12E6 m').
;         description=desc Image description (def=image).
;         name=name Name of image (def=image).
;         lon1=lon1, lon2=lon2  Image longitude bounds.
;         lat1=lat1, lat2=lat2  Image latitude bounds.
;         tilt=tilt  View tilt (def=0).
;         heading=hdg  View heading (def=0).
;         out=out  Name of output file (no extension, def=image).
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
;       Notes: Creates a *.kmz file to view the data in Google Earth.
; MODIFICATION HISTORY:
;       R. Sterner, 2010 May 10
;       R. Sterner, 2010 Aug 13 --- Added /quiet to img_redim call.
;
; Copyright (C) 2010, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
        pro img_tokmz, img00, lon0=lon00, lat0=lat00, range=rng0, $
            description=desc, name=name, lon1=lon10, lon2=lon20, $
            lat1=lat10, lat2=lat20, tilt=tilt0, heading=hdg0, $
            out=out, help=hlp
 
        if (n_params(0) lt 1) or keyword_set(hlp) then begin
          print,' Convert an image array to a *.kmz file.'
          print,' img_tokmz, img'
          print,'   img = Image array.                 in'
          print,'     May be an image file name instead.'
          print,' Keywords:'
          print,'   lon0=lon0, lat0=lat0: Point to look at (def=0,0).'
          print,"   range=rng View range (string with units, def='12E6 m')."
          print,'   description=desc Image description (def=image).'
          print,'   name=name Name of image (def=image).'
          print,'   lon1=lon1, lon2=lon2  Image longitude bounds.'
          print,'   lat1=lat1, lat2=lat2  Image latitude bounds.'
          print,'   tilt=tilt  View tilt (def=0).'
          print,'   heading=hdg  View heading (def=0).'
          print,'   out=out  Name of output file (no extension, def=image).'
          print,' Notes: Creates a *.kmz file to view the data in Google Earth.'
          return
        endif
 
        ;-----------------------------------------------
        ;  Read image if given a file name
        ;-----------------------------------------------
        if n_elements(img00) eq 1 then begin
          if datatype(img00) eq 'STR' then begin
            img0 = read_image(img00)
            if img0[0] eq -1 then begin
              print,' Error in img_tokmz: Could not read image: ',img00
              return
            endif
          endif else begin
            print,' Error in img_tokmz: Problem with given image.'
            return
          endelse
        endif else img0=img00
 
        ;-----------------------------------------------
        ;  Reshape image
        ;-----------------------------------------------
        img = img_redim(img0,tr=1,/quiet)
 
        ;-----------------------------------------------
        ;  Make temporary directory
        ;-----------------------------------------------
        dir = 'images_kmz'
        for i=1,5 do begin
          f = file_search(dir,count=cnt)
          if cnt eq 0 then break
          dir = dir + 'x'
        endfor
        if cnt ne 0 then $
          stop,' Error in cf_tokmz: could not find an unused dir.'
        file_mkdir, dir
 
        ;-----------------------------------------------
        ;  Write image
        ;-----------------------------------------------
        print,' Writing image ...'
        png = filename(dir,'image.png',/nosym)
        write_png, png, img
 
        ;-----------------------------------------------
        ;  Set values
        ;-----------------------------------------------
        if n_elements(out) eq 0 then out='image'
        filebreak,out,name=base
        kml = base + '.kml'
        kmz = base + '.kmz'
        if n_elements(lon00) eq 0 then lon00=0.
        if n_elements(lat00) eq 0 then lat00=0.
        if n_elements(rng0) eq 0 then rng0='12E6 m'
        lon0 = strtrim(lon00,2)
        lat0 = strtrim(lat00,2)
        rng = strtrim(to_meters(rng0),2)
        if n_elements(desc) eq 0 then desc='image'
        if n_elements(name) eq 0 then name='Image'
        if n_elements(lon10) eq 0 then lon10=-180
        if n_elements(lon20) eq 0 then lon20= 180
        if n_elements(lat10) eq 0 then lat10=-90
        if n_elements(lat20) eq 0 then lat20= 90
        lon1 = strtrim(lon10,2)
        lon2 = strtrim(lon20,2)
        lat1 = strtrim(lat10,2)
        lat2 = strtrim(lat20,2)
        if n_elements(tilt0) eq 0 then tilt0= 0.
        if n_elements(hdg0) eq 0 then hdg0= 0.
        tilt = strtrim(tilt0,2)
        hdg = strtrim(hdg0,2)
        ;---  Structure used to edit marker strings  ---
        s = {name:name,description:desc,lon_look:lon0,lat_look:lat0, $
             range:rng,tilt:tilt,heading:hdg,img_link:png, $
             lat_min:lat1,lat_max:lat2,lon_min:lon1,lon_max:lon2}
 
        ;-----------------------------------------------
        ;  KML code with markers ($$MARKER$$)
        ;-----------------------------------------------
        print,' Making KML file ...'
        text_block,txt,/quiet
;<?xml version="1.0" encoding="UTF-8"?>
;  <kml xmlns="http://earth.google.com/kml/2.0">
;    <Folder>
;      <name>$$NAME$$</name>
;      <description>$$DESCRIPTION$$</description>
;      <LookAt>
;        <longitude>$$LON_LOOK$$</longitude>
;        <latitude>$$LAT_LOOK$$</latitude> 
;        <range>$$RANGE$$</range>
;        <tilt>$$TILT$$</tilt>
;        <heading>$$HEADING$$</heading>
;      </LookAt>
;      <GroundOverlay>
;        <name>$$NAME$$</name>
;        <color>ffffffff</color>
;        <Icon>
;          <href>$$IMG_LINK$$</href>
;          <viewBoundScale>0.75</viewBoundScale>
;        </Icon>
;        <LatLonBox>
;          <north>$$LAT_MAX$$</north>
;          <south>$$LAT_MIN$$</south>
;          <west>$$LON_MIN$$</west>
;          <east>$$LON_MAX$$</east>
;        </LatLonBox>
;      </GroundOverlay>
;    </Folder>
;  </kml>
 
        ;-----------------------------------------------
        ;  Build kmz file
        ;-----------------------------------------------
        rep_txtmarks, txt, s    ; Replace text marker strings.
        putfile, kml, txt
 
        ;-----------------------------------------------
        ;  Make KMZ from KML
        ;-----------------------------------------------
        print,' Making KMZ file ...'
        cmd= 'zip ' + kmz + ' ' + kml + ' ' + png
;print,cmd
        spawn, cmd
 
        ;-----------------------------------------------
        ;  Cleanup
        ;-----------------------------------------------
        print,' Cleaning up ...'
        file_delete, kml
        file_delete, dir, /recursive
        print,' KMZ file complete: '+kmz
 
        end
 
