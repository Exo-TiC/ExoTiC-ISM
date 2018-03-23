	;---  crash_test_event = Event handler  ---
	pro crash_test_event, ev
 
	widget_control, ev.top, /destroy
	return
 
	end
 
	;---  crash_test.pro = Main routine  ---
	pro crash_test

	top = widget_base(/column)

    ;---  Line with tooltip crashes on Mac  ---
	id = widget_button(top,val='DONE', tooltip='')              ; Works.
;	id = widget_button(top,val='DONE', tooltip='Quit program')  ; Crashes 2nd or 3rd time.
;	id = widget_button(top,val='DONE')                          ; Works.

	widget_control, top, /realize
	xmanager, 'crash_test', top, /no_block
 
	end
