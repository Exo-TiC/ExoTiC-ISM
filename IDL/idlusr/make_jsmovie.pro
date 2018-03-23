;-------------------------------------------------------------
;+
; NAME:
;       MAKE_JSMOVIE
; PURPOSE:
;       Generate web pages to display a Javascript movie from images.
; CATEGORY:
; CALLING SEQUENCE:
;       make_jsmovie, img_url
; INPUTS:
;       img_url = URL of image directory.    in
;          This may be relative to the location of the movie page.
;          The generated web pages must be placed in the correct
;          directory to access these images.
; KEYWORD PARAMETERS:
;       Keywords:
;         TITLE=ttl Main page title (def='Javascript Movie Player').
;         DELAY=ms Delay at end of loop in ms (def=1000).
;         OUT=out Name of output page (def='jsmovie').
;         SPEED=spd Initial # of frames/second to display (def=10).
;            Valid range is 0.01 to 100 (will use a close value).
;         DIRECTORY=dir Output directory for generated files.  The
;            given img_url should be based in this value.
;         /FILE Set for display from a file, else from a web
;            server. Sets the internal JS variable named skip.
;            Will not display all frames if displaying as a file when
;            generated for web display.  In the page *_main.html can
;            manually edit the variable skip to 1 for file, 5 for web.
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
;       Notes: Will generate 4 files:
;         jsmovie.html, jsmovie_main.html, jsmovie_blank.html,
;           and jsmovie_loading.png.
;         These must be kept together, link to the first one.
;         These names may be changed using the OUT keyword.
;         The images may be accessed from the web page.  One way
;         is to right click on the image (in some browsers).
;         Another way is to drag the frame divider line at the very
;         bottom of the web page upward to view a directory listing
;         of all the images.  Drag it back to the bottom to get
;         back to the movie frame.
;       
;         Example call:
;         make_jsmovie,'img',title='East Coast 2 m Temperature',del=1500,out='temp2m'
; MODIFICATION HISTORY:
;       R.Sterner, 2008 Mar 20
;       R.Sterner, 2009 Jul 13 --- Added /FILE keyword.
;       R.Sterner, 2009 Jul 13 --- Added SPEED keyword.
;       R.Sterner, 2012 Feb 01 --- Added DIRECTORY keyword.
;
; Copyright (C) 2008, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro make_jsmovie, img_url, title=ttl, delay=del0, out=out, $
	  quiet=quiet, file=file, speed=speed0, directory=dir, help=hlp 
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Generate web pages to display a Javascript movie from images.'
	  print,' make_jsmovie, img_url'
	  print,'   img_url = URL of image directory.    in'
	  print,'      This may be relative to the location of the movie page.'
	  print,'      The generated web pages must be placed in the correct'
	  print,'      directory to access these images.'
	  print,' Keywords:'
	  print,"   TITLE=ttl Main page title (def='Javascript Movie Player')."
	  print,'   DELAY=ms Delay at end of loop in ms (def=1000).'
	  print,"   OUT=out Name of output page (def='jsmovie')."
	  print,'   SPEED=spd Initial # of frames/second to display (def=10).'
	  print,'      Valid range is 0.01 to 100 (will use a close value).'
	  print,'   DIRECTORY=dir Output directory for generated files.  The'
	  print,'      given img_url should be based in this value.'
	  print,'   /FILE Set for display from a file, else from a web'
	  print,'      server. Sets the internal JS variable named skip.'
	  print,'      Will not display all frames if displaying as a file when'
	  print,'      generated for web display.  In the page *_main.html can'
	  print,'      manually edit the variable skip to 1 for file, 5 for web.'
	  print,' Notes: Will generate 4 files:'
	  print,'   jsmovie.html, jsmovie_main.html, jsmovie_blank.html,'
	  print,'     and jsmovie_loading.png.'
	  print,'   These must be kept together, link to the first one.'
	  print,'   These names may be changed using the OUT keyword.'
	  print,'   The images may be accessed from the web page.  One way'
	  print,'   is to right click on the image (in some browsers).'
	  print,'   Another way is to drag the frame divider line at the very'
	  print,'   bottom of the web page upward to view a directory listing'
	  print,'   of all the images.  Drag it back to the bottom to get'
	  print,'   back to the movie frame.'
	  print,' '
	  print,'   Example call:'
	  print,"   make_jsmovie,'img',title='East Coast 2 m Temperature',"+$
	    "del=1500,out='temp2m'"
	  return
	endif
 
	;---------------------------------------------------------------
	;  Set defaults
	;---------------------------------------------------------------
	if n_elements(ttl) eq 0 then ttl='Javascript Movie Player'
	if n_elements(del0) eq 0 then del0=1000
	if n_elements(dir) eq 0 then dir=''
	del = strtrim(del0,2)
	if n_elements(out) eq 0 then out='jsmovie'
	if keyword_set(file) then skip='1' else skip='5'
	if n_elements(speed0) eq 0 then speed0=10
	speed = speed0>0.01<100
	sp = [-100,-80,-60,-40,-30,-20,-15,-10,-5,-3,-2,1,2,3,5,10,15,20,30,40,60,80,100]
	if speed lt 1 then t=-1./speed else t=speed
	d = abs(sp - t)
	w = where(d eq min(d))
	spin = w[0]
	spd = sp[spin]
	spin = strtrim(spin,2)
	if spd lt 0 then begin
	  spd = -spd
	  spd = '1/'+strtrim(spd,2)
	endif else begin
	  spd = strtrim(spd,2)
	endelse
 
	;---------------------------------------------------------------
	;  Output file names
	;---------------------------------------------------------------
	page = out + '.html'
	page_blank = out + '_blank.html'
	page_main = out + '_main.html'
	page_loading = out+'_loading.png'
 
	;---------------------------------------------------------------
	;  Make loading image
	;---------------------------------------------------------------
	dv = !d.name
	set_plot,'z'
	device,set_pixel_depth=24,z_buffering=0
	device,set_resolution=[350,100]
	erase,-1
	tv,makez(350,100)*100+100,chan=1
	xyoutb,.5,.5,/norm,align=.5,col=tarclr(0,0,255),chars=2, $
	  'Loading images ...',bold=3
	page_loading = filename(/nosym,dir,page_loading) ; Add output dir.
	pngscreen,page_loading
	set_plot,dv
 
	;---------------------------------------------------------------
	;  Page
	;---------------------------------------------------------------
	text_block, txt, /quiet
;<html>
;<head>
;<script language="JavaScript"><!--
;function reload_main() {
;  window.main.location.href = "#page_main";
;}
;//--></script>
;</head>
;
;<frameset rows="*,1" onLoad="reload_main()">
;<frame src="#page_blank" name="main">
;<frame src="#img_url" name="directory">
;</frameset>
;
;</html>
 
	txt = repstr(txt,'#page_main',page_main)
	txt = repstr(txt,'#page_blank',page_blank)
	txt = repstr(txt,'#img_url',img_url)
	page = filename(/nosym,dir,page)	; Add output dir.
	putfile,page,txt
 
	;---------------------------------------------------------------
	;  Page_blank
	;---------------------------------------------------------------
	text_block, txt, /quiet
;<html>
;<head>
;</head>
;
;</html>
 
	page_blank = filename(/nosym,dir,page_blank)	; Add output dir.
	putfile,page_blank,txt
 
	;---------------------------------------------------------------
	;  Page_main
	;---------------------------------------------------------------
	txt0 = ['<!--','   '+created(),'   '+created(/by),'-->',' ']
	text_block, txt, /quiet
;<HTML>
;<HEAD>
;<TITLE>#ttl</TITLE>
;</HEAD>
; 
;<BODY FONT=3 BGCOLOR=FFFFFF>
; 
;<CENTER>
; 
;<H1>#ttl</H1>
; 
;<!-- =========================================================== -->
;<!--   Movie Control Buttons                                     -->
;<!-- =========================================================== -->
;<FORM NAME="form">
; <INPUT TYPE=button VALUE="Start" onClick="start_play();">
; <INPUT TYPE=button VALUE="Stop" onClick="stop_play();">
; <INPUT TYPE=button VALUE="Faster" onClick="spin+=1; show_speed();">
; <INPUT TYPE=button VALUE="Slower" onClick="spin-=1; show_speed();">
; <INPUT TYPE=button VALUE="Step+" onClick="step_p();">
; <INPUT TYPE=button VALUE="Step-" onClick="step_m();">
; <INPUT TYPE=button VALUE="Reset" onClick="reset_frame();">
; <INPUT TYPE=button VALUE="Loop" onClick="loop_mode();">
; <INPUT TYPE=text VALUE="YES" NAME="loopon" SIZE=3>
; <BR>
; Frame: <INPUT TYPE=text VALUE="0"  NAME="frame"  SIZE=3> &nbsp;
; Speed: <INPUT TYPE=text VALUE="#spd" NAME="rate"   SIZE=5> (frames/sec)
;</FORM>
; 
;<!-- =========================================================== -->
;<!--   Image Display Area                                        -->
;<!--       Load with first image to set size,                    -->
;<!--       But will actually display last image after loading.   -->
;<!-- =========================================================== -->
;<TABLE BORDER="10" CELLPADDING="8">
;<TR>
;<TD align="center">
;<!--  Initial movie frame  -->
;<IMG SRC=#page_loading NAME=animation ALT=FRAME>
;</TR>
;</TABLE>
;
;</CENTER>
;
;<!-- =========================================================== -->
;<!--   Javascript Code                                           -->
;<!--                                                             -->
;<!--   Original code from a Javascript movie player written by   -->
;<!--   Zarro, NASA/GSFC, 7 July 1997.                            -->
;<!--   Modified: 27 July 1997, Freeland, LSAL - added nice       -->
;<!--   SWING option.  Fully rewritten: 14 July 1998, G. Toth,    -->
;<!--   Eotvos University, Hungary.  Modified for 4 digit frame   -->
;<!--   numbers, 2006 May 02, R. Sterner, JHU/APL.  Rewritten     -->
;<!--   2008 Mar 18, R. Sterner, JHU/APL to allow displaying all  -->
;<!--   images in a specified directory without renaming them.    -->
;<!--   Also dropped play direction and swing option and added    -->
;<!--   single step, reset, and loop options.                     -->
;<!-- =========================================================== -->
;<SCRIPT>
;<!--
;// ------------------------------------------------------------------
;//   Define variables
;//     N is set by the variable SKIP:
;//     Skip over first N links on directory listing page since they
;//     are not images (they are column headings that sort when clicked
;//     and/or a link to the parent page).  So the number of images (movie
;//     frames) will be N less than the number of links on the directory
;//     listing page.  If accessing this page from a web server N=5.
;//     If accessing this page using File/Open N=1.
;//     nframe is the number of images to display.
;//     link is a temporary variable.  frame is the current image index.
;//     loopon is the loop flag (0 means loop).  ps is the number of
;//     milliseconds to pause at the end of the loop.  speed is the
;//     number of frames to display each second.  delay is the computed
;//     delay in ms to get the requested frame rate.
;//     timeout_id is a timer id.
;//     images will be the array of images.
;// ------------------------------------------------------------------
;var skip = #skip
;var nframe = parent.directory.window.document.links.length - skip;
;var link = "";
;var frame=-1, loopon=0, ps=0;
;var speed=#spd, delay = 1000/speed;
;var timeout_id=null, images=null;
;var sp=[-100,-80,-60,-40,-30,-20,-15,-10,-5,-3,-2,1,2,3,5,10,15,20,30,40,60,80,100];
;var spin=#spin
; 
;// ------------------------------------------------------------------
;//   Load the images
;// ------------------------------------------------------------------
;load_images();
;
;// ------------------------------------------------------------------
;//   Load images function.  Skipping over first 5 non-image links.
;// ------------------------------------------------------------------
;function load_images()
;{
; var frame;
; if (timeout_id) clearTimeout(timeout_id); 
; timeout_id=null;
; images = Array(nframe);
; for(frame=0; frame<nframe; frame++){
;    link = parent.directory.window.document.links[frame+skip].href;
;    images[frame] = new Image();
;    images[frame].src = link;
;    document.animation.src=images[frame].src;
;    document.form.frame.value= frame+1; 
; }
;}
; 
;// ------------------------------------------------------------------
;//   START button
;// ------------------------------------------------------------------
;function start_play()  // start movie
;{
; if (timeout_id == null) {
;  if (images==null) load_images();
;  if (images!=null) animate();
; }
;} 
; 
;// ------------------------------------------------------------------
;//   STOP button
;// ------------------------------------------------------------------
;function stop_play() // stop movie
;{ 
;  if (timeout_id) clearTimeout(timeout_id); timeout_id=null;
;} 
; 
;// ------------------------------------------------------------------
;//   STEP+ button: Step forward one frame
;// ------------------------------------------------------------------
;function step_p() // step frames forward
;{
; if (timeout_id) clearTimeout(timeout_id); timeout_id=null;
; if (images==null) load_images();
; if (images!=null){
;  frame=(frame+1+nframe)%nframe;
;  document.animation.src=images[frame].src;
;  document.form.frame.value=frame+1;
; }
;}
; 
;// ------------------------------------------------------------------
;//   STEP- button: Step backward one frame
;// ------------------------------------------------------------------
;function step_m() // step frames backward
;{
; if (timeout_id) clearTimeout(timeout_id); timeout_id=null;
; if (images==null) load_images();
; if (images!=null){
;  frame=(frame-1+nframe)%nframe;
;  document.animation.src=images[frame].src;
;  document.form.frame.value=frame+1;
; }
;}
;
;// ------------------------------------------------------------------
;//   RESET button: Reset to first frame
;// ------------------------------------------------------------------
;function reset_frame()
;{
;  frame=0;
;  document.animation.src=images[frame].src;
;  document.form.frame.value=frame+1;
;}
;
;// ------------------------------------------------------------------
;//   LOOP button: Toggle Looping on or off
;// ------------------------------------------------------------------
;function loop_mode()    // set loop mode
;{
; loopon=1-loopon;
; if(loopon){document.form.loopon.value="NO ";
;       }else{document.form.loopon.value="YES";}
;}
; 
;// ------------------------------------------------------------------
;//   Play movie frames
;// ------------------------------------------------------------------
;function animate()  // control movie loop
;{
; frame=(frame+1+nframe)%nframe;
; document.animation.src=images[frame].src;
; document.form.frame.value=frame+1;
; if ((loopon==0) && (frame==0)) {
;    pausecomp(ps);
;    }
; ps = #del;
; timeout_id=setTimeout("animate()",delay);
; if (loopon && (frame==nframe-1)) stop_play();
;}
; 
;// ------------------------------------------------------------------
;//   Display current speed
;// ------------------------------------------------------------------
;function show_speed()      // show speed
;{
;  if(spin>22) spin=22;
;  if(spin<0) spin=0;
;  speed=sp[spin];
;  if (speed > 0) sptxt=speed; else {speed=-speed; sptxt='1/'+speed; speed=1./speed;}
;  document.form.rate.value=sptxt;
;  delay = 1000.0/speed;
;}
;
;// ------------------------------------------------------------------
;//   Pause (from www.sean.co.uk)
;// ------------------------------------------------------------------
;function pausecomp(millis)
;{
;var date = new Date();
;var curDate = null;
;do { curDate = new Date(); }
;while(curDate-date < millis);
;} 
; 
;// -->
;</SCRIPT>
; 
;</BODY>
;</HTML>
 
	txt = [txt0,txt]
	txt = repstr(txt,'#page_loading',page_loading)
	txt = repstr(txt,'#ttl',ttl)
	txt = repstr(txt,'#del',del)
	txt = repstr(txt,'#skip',skip)
	txt = repstr(txt,'#spd',spd)
	txt = repstr(txt,'#spin',spin)
	page_main = filename(/nosym,dir,page_main)	; Add output dir.
	putfile,page_main,txt
 
	if keyword_set(quiet) then return
	print,' '
	print,' Place the following three web pages in the appropriate ' + $
	  'directory:'
	print,'     '+page
	print,'     '+page_main
	print,'     '+page_blank
	print,'     '+page_loading
	print,' '
	print,' Link to '+page
	print,' '
	if keyword_set(file) then begin
	  print," Page written to be displayed from a disk file, not a web server."
	  print,' Call make_jsmovie without the /FILE keyword to display the result'
	  print,' from a web server.  Or edit the variable skip in '+page_main+' to be 5'
	  print,' instead of 1.'
	endif else begin
	  print," Page written to be displayed from a web server, not a disk file."
	  print,' Call make_jsmovie with the /FILE keyword to display the result'
	  print,' from a disk file.  Or edit the variable skip in '+page_main+' to be 1'
	  print,' instead of 5.'
	endelse
 
	end
