;===============================================================
;  TEMP NAME: xpar_load_helpx.pro.
;  but still xpar_load_help internally and as called.
;  Call is very different and called from a new place in
;  main code.
;  R. Sterner, 2008 Oct 22
;
;       xpar_load_help = Load help text variables
;	R. Sterner, 2006 Nov 27 --- from eqv3_load_help.
;	Separated to keep file short for fast loading.
;===============================================================
 
	pro xpar_load_help, bar_in, txt_out
 
	;-----  Grab all help text in one big chunk (into txt)  ----------
	text_block, txt, /quiet
;<menu>
;hlp Help
;  ov XPAR overview
;  lay XPAR widget layout
;  fil XPAR file format
;  ex XPAR examples
;  tr XPAR troubleshooting
;</menu>
;
;<ov>
; Overview
;
; The Parameter Explorer tool, XPAR, makes it easy to execute
; IDL code and vary parameters (variables) used in that code.
; Parameters may be varied by moving a slider
; bar allowing the effects of hundreds of values to be
; examined in seconds.  The IDL code itself may be modified
; with the result being instantly displayed.  Binary flag
; values may also be used in the code and tied to toggle
; buttons on the xpar tool.
;
; The code may display IDL graphics or be non-graphic.
; The IDL command line is not blocked so other IDL commands
; may be given, including plotting in the current plot window.
;
; Other help topics:
;
;	XPAR widget layout
;	  A detailed look at each part of the XPAR widget:
;	    Menus (File, Options, User, Help), Code Area, 
;	    Parameter sliders, and Flags.
;
;	XPAR file format
;	  Details on exactly what can be in the XPAR file,
;	  describing every allowed item:
;	    Items that control widget layout, User routines,
;	    Code, Parameters, Flags, Exclusive options.
;
;	XPAR examples
;	  Several example XPAR files that show what can be
;	  done.
;
;</ov>
;<lay>
; XPAR widget layout
;
; Topics covered here are
;   Menus
;     File
;     Options
;     User
;     Help
;   Code Area
;   Parameter buttons
;   Parameter sliders
;   Flags
;   Color patches
;   Drop-down lists
;
; Along the top of the XPAR widget are several drop-down menus,
; these are described in this section.
;
;   File Menu
;     Quit: Destroy the XPAR widget and return.
;     Cancel: Just continue in XPAR.
;     Snapshot: List the code, current parameter values,
;       and flags in a time tagged text file.
;
;   Options Menu
;     Turn Win_redirect On/Off: Toggles win_redirect mode.
;       When win_redirect is on the graphics are created in
;       an invisible pixmap window and then quickly copied
;       to the current graphics window.  This greatly reduces
;       problems with flickering as the graphics are updated.
;     WSHOW: Just brings the current graphics window to the front.
;     Turn Debug On/Off: Toggles debug mode.
;       When debug is on the current parameter and flag values
;       are listed and also the current code being exectuted.
;
;   User Menu
;     This menu contains IDL routines written by the user. Each
;     routine must take one and only one keyword, info=s, where
;     s is the info structure with current parameter and flag values.
;     See the help section on user routines and the info structure
;     for details.
;
;   Help Menu
;     The help menu gives details on the xpar routine and how to use it.
;
;   Code Area
;     Below the drop-down menus is a text entry area where the IDL code
;     will be displayed.  The code may be edited by entering new text
;     or modifying the existing text.  The code area may have a horizontal
;     scroll bar if needed or requested.  Use of the Enter key is ignored.
;
;   Parameter buttons
;     Below the code area there may be a set of buttons, one for each
;     parameter.  These buttons are used to link a parameter with a
;     slider bar if there are more parameters than sliders.  If the
;     number of sliders matches the number of parameters then these
;     buttons are not needed and will not appear.  If parameter buttons
;     are used they may be grouped into frames.  The layout of the
;     buttons inside the frames may be specified (like in 2 rows, or 3
;     columns), the default is one row.  Example parameters might be
;     Latitude and Longitude used to plot a globe view of the Earth.
;
;   Parameter sliders
;     Variables in the code area are given slider bars to vary their
;     values.  The layout for each parameter slider is: parameter name,
;     slider bar, current value area, min range area, max range area,
;     set current value as min range button, set current value as max
;     range button, set current value to default button.  Each slider
;     bar may be assigned a color, this may be useful to group related
;     parameters.  Each time a slider bar is moved the value for that
;     parameter is updated and the code is executed using the new values.
;     The range is the range of values covered by the slider.  This range
;     is easily changed just by entering new values for the min and max
;     (use the Enter key to set the new value).  It may also be changed
;     using the Min and Max buttons to set the range min or range max to
;     the current slider value.  This makes it easy to zoom in on a
;     desired value.  The Def button sets the current value to a default
;     value (clipped to the current range) that is specified in the
;     setup file.  Example slider values might be Latitude with a range
;     of -90 to +90, default 0, and Longitude with a range of -180 to
;     +180 with a default of 0.  The range area may be dropped by setting
;     a value in the xpar text.  Also the Min/Max/Def buttons may be
;     dropped in a similar way.  This may be useful when they are not
;     needed to give a more compact layout.
;
;   Flags
;     If any flags are specifed they will appear below the slider bars.
;     Like the parameter buttons, flags may be grouped into frames and
;     their layout specified (rows or colums).  Frames may be exclusive
;     or non-exclusive (default). Flags in an ordinary (non-exclusive)
;     frame may be selected or unselected as desired by clicking on them.
;     Flags in an exclusive frame may have only one selected in that
;     frame at a time, all the others are automatically unselected.
;     Example flags might control the display of a grid on a globe plot,
;     or if continents are plotted.  Exclusive flags might control the
;     map project for example.
;
;   Color Patches
;     A set of named Color patches may be tied to variables in the IDL
;     code that are used as plot colors.  Each color patch has a small
;     square of color followed by the variable name.  Clicking on the
;     color patch will bring up an interactive color wheel to allow the
;     color to be changed.  Color patches may be grouped into frames,
;     similar to parameter buttons.
;
;   Drop-Down Lists
;     A set of drop-down list buttons may be set up to select values
;     from a list.  These are useful for items that have more than
;     two values like flags, but less than a continuous range like
;     the parameter sliders.  The list button name is the name of the
;     variable in the IDL code.  The items in the list are the values
;     that this variable is set to when that item is selecetd.  These
;     values are always strings.  Drop-down lists may be grouped into
;     frames, similar to parameter buttons.
;
;
;
;</lay>
;<fil>
; XPAR file format
;
; ####> Describe all allowed file entries.
;
; ####> Describe frames and how they are all similar:
;   frame = parameter button frames
;   flag_frame = Flag frames, normal and exclusive.
;   color_frames = Color patch frames.
;
;</fil>
;<ex>
; XPAR Examples
;  
;</ex>
;<tr>
; XPAR troubleshooting
;  
;     Parameter sliders and color patches use Draw WIdgets. The
;     last slider or color patch set up is the current window,
;     so before using xpar to do any graphics a working window
;     must be set up.  This is done in the INIT code in the layout
;     file or text array, init: window,/free
;
;     If having trouble getting correct window try
;     win_redirect,/cleanup. 
;  
;</tr>
;<us>
; User Routines and the Info Structure
;
; How to write a user routine
; Details on the info structure
;</us>


	;---------------------------------------------------------
	;  Use add_helpmenu to add help menu based on above.
	;---------------------------------------------------------
	add_helpmenu, bar_in, txt, cmd='HELP'
	txt_out  =txt
 
	end
