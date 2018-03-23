;------------------------------------------------------------------------------
;  make_video.pro = Make a video from an array of image file names.
;
;  Based on the IDL help section "Creating Video".
;  R. Sterner, 2014 Sep 10
;------------------------------------------------------------------------------

    pro make_video, list, movname, fps=fps, codec=codec, list_codecs=listc, help=hlp

    if keyword_set(hlp) then begin
      print,' Make a video from an array of image file names.'
      print,' make_video, list, movname'
      print,'   list = String array of image file names.        in'
      print,"   movname = Name of movie file (def='Movie.mp4'). in"
      print,' Keywords:'
      print,'   FPS=fps Playback frames per second (def=10).'
      print,"   CODEC=codec  CODEC to use (def='mpeg4')."
      print,'   /LIST_CODECS List available CODECS.'
      return
    endif

    ;---  List CODECS  ---
    if keyword_set(listc) then begin
      oVid = IDLffVideoWrite('__temp.avi')
      print," Supported video codecs: ", oVid.GetCodecs(/VIDEO)
      print," For example: make_video, list, codec='mpeg4'"
      obj_destroy, oVid
      file_delete,'__temp.avi'
      return
    endif

    ;---  Check list of images  ---
    if n_elements(list) eq 0 then begin
      make_video,/help
      return
    endif

    ;---  Movie name  ---
    if n_elements(movname) eq 0 then movname='Movie.mp4'

    ;---  Get image size from first image  ---
    a = read_image(list[0])
    img_shape, a, nx=nx, ny=ny, tr=tr

    ;---  Frames/second  ---
    if n_elements(fps) eq 0 then fps=10

    ;---  CODEC  ---
    if n_elements(codec) eq 0 then codec='mpeg4'

    ;---  Start video  ---
    oVid = IDLffVideoWrite(movname)
    vidStream = oVid.AddVideoStream(nx, ny, fps, codec=codec)

    ;---  Loop over frames  ---
    foreach f, list do begin
      print,'  '+f
      a = read_image(f)
      !NULL = oVid.Put(vidStream, a)
    endforeach

    oVid.Cleanup

    print,' Video complete: ',movname

    end
