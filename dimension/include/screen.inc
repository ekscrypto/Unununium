;Struc Needed by anyone wishinig to know the base address of the screen they
;have created with a display manager (ie: silicium) 
 
      struc screen ;  This is what a screen looks like
.previous_link:         resd 1     ; in memory, not so bad huh? 
.next_link:             resd 1     ; 36bytes.
.driver:                resd 1     ;id of video driver used
.videomode:             resd 1     ; video mode for this screen
.video_options:         resd 1     ;any options to be passed to driver
.size_of_screen:        resd 1     ;size of screen in bytes
.base_address:          resd 1     ;where the screen is currently located
.active_point:          resd 1     ;where the screen will be once active
.verify_point:          resd 1     ;silicium specific, to check for stupid coders.
        endstruc