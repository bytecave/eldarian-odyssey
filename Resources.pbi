XIncludeFile "Localize.pbi"
XIncludeFile "StringTable.pbi"

;font resources
DataSection
  start_command_font:
    IncludeBinary "resources/font/Glass_TTY_VT220.ttf"
  end_command_font:
    
  start_output_font:
   IncludeBinary "resources/font/SVBasicManual.ttf"
  end_output_font:
EndDataSection

;artwork
DataSection
  img_main_background1: 
    IncludeBinary "resources/background/DarkBackground.jpg"
  img_main_background2:
    IncludeBinary "resources/background/LightBackground.jpg"
  img_logo:
    IncludeBinary "resources/images/logo.png"
  img_flameon:
    IncludeBinary "resources/icons/flameon.png"
  img_flameoff:
    IncludeBinary "resources/icons/flameoff.png"
EndDataSection
  
;dialog text
DataSection
  start_text_about:
  IncludeBinary "resources/about.txt"
  end_text_about:
  
  start_text_credits:
  IncludeBinary "resources/credits.txt"
  end_text_credits:
  
  start_text_help:
  IncludeBinary "resources/help.txt"
  end_text_help:
EndDataSection

DataSection
  start_nouns:
    IncludeBinary "resources/Nouns.txt"
  start_rooms:
    IncludeBinary "resources/Rooms.txt"
EndDataSection
; IDE Options = PureBasic 5.70 LTS beta 1 (Windows - x64)
; CursorPosition = 48
; FirstLine = 6
; EnableXP