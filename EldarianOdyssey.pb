EnableExplicit 

#COMMANDINDICATOR = "> "

;- Image Plugins
UseJPEGImageDecoder()
UsePNGImageDecoder()

XIncludeFile "Globals.pbi"
XIncludeFile "Grayscale.pbi"
XIncludeFile "TextHelpers.pbi"
XIncludeFile "Resources.pbi"
XIncludeFile "Helpers.pbi"
XIncludeFile "GetCommand.pbi"
XIncludeFile "Initialize.pbi"
XIncludeFile "Messages.pbi"
XIncludeFile "LichEncounter.pbi"
XIncludeFile "AdventureCore.pbi"
XIncludeFile "Handlers.pbi"
XIncludeFile "TimerHandlers.pbi"
XIncludeFile "DoThings.pbi"
XIncludeFile "Dialogs.pbi"
XIncludeFile "Parser.pbi"

;keep app from hanging when screen saver turns on
CompilerIf #PB_Compiler_OS = #PB_OS_Windows
Prototype protoSetThreadExecutionState(esFlags.l)
Global SetThreadExecutionState.protoSetThreadExecutionState
Define kernel32.i

kernel32 = OpenLibrary(#PB_Any, "kernel32.dll")
                
If IsLibrary(kernel32)
  SetThreadExecutionState = GetFunction(kernel32, "SetThreadExecutionState")
  If SetThreadExecutionState
    SetThreadExecutionState(#ES_SYSTEM_REQUIRED | #ES_DISPLAY_REQUIRED | #ES_AWAYMODE_REQUIRED | #ES_CONTINUOUS)
  EndIf
  CloseLibrary(kernel32)
EndIf
CompilerEndIf

InitializeGame()

;
;main game loop
;
Define rc.i, Event.i, strEvent.s
Define fYReleased.i, fNReleased.i, fEscapeReleased.i
Define fPageDownReleased.i, fPageUpReleased.i
Define fF1Released.i, fF2Released.i, fF5Released.i

While #True
  Repeat
    Event = WaitWindowEvent(1)
    
    If Event = #PB_Event_CloseWindow
      End
    EndIf
  Until Event = 0
  
  ;draw onto buffer image
  ClearScreen(0)
  ;Capture release edges before KeyboardInkey() processes command input.
  ExamineKeyboard()
  fYReleased = KeyboardReleased(#PB_Key_Y)
  fNReleased = KeyboardReleased(#PB_Key_N)
  fEscapeReleased = KeyboardReleased(#PB_Key_Escape)
  fPageDownReleased = KeyboardReleased(#PB_Key_PageDown)
  fPageUpReleased = KeyboardReleased(#PB_Key_PageUp)
  fF1Released = KeyboardReleased(#PB_Key_F1)
  fF2Released = KeyboardReleased(#PB_Key_F2)
  fF5Released = KeyboardReleased(#PB_Key_F5)
  StartDrawing(ImageOutput(#IMAGEBUFID))
  
  ;Draw background
  DrawImage(ImageID(GU\imgBackground), 0, 0)
  
  ;Draw torch on or off
  If GG\ptrTorch\iState & (#STATE4 | #STATE5)   ;if torch is not lit
    DrawAlphaImage(ImageID(GU\imgFlameOff), GU\iXFlame, GU\iYFlame)
  Else
    DrawAlphaImage(ImageID(GU\imgFlameOn), GU\iXFlame, GU\iYFlame)
  EndIf
  
  If GetCommand() = #GOTCOMMAND                      ;also draws current input
    AddToOutput("^" + #COMMANDINDICATOR + GG\strCommand)   ;add blank line + command to output buffer
    
    ProcessCommand()
  EndIf
  
  ;Draw available exits
  PrintDirections()
  
  ;Add room description to output buffer
  AddRoomDescription(#False)
  
  TimerCommandHandler(TimerCommand())

  ;DrawText output buffer onto buffer image
  PrintOutputBuffer()
  
  ;if grayscale set during save/load, gray screen
  If GU\fGray
    Grayscale::Grayscale(#IMAGEBUFID)
  EndIf
  
  If GU\iDialog <> #DIALOG_NONE
    DialogBox(#DIALOG_REFRESH)
    
    If GU\iDialog = #DIALOG_QUESTION
      If fYReleased
        OkayToAct("Y")
      ElseIf fNReleased Or fEscapeReleased
        OkayToAct("N")
      EndIf
    Else
      ;Credits, About, or Help
      If fEscapeReleased
        GU\fGray = #False
        GU\iDialog = #DIALOG_NONE
      ElseIf fPageDownReleased
        GU\iPageKey = #PB_Key_PageDown
      ElseIf fPageUpReleased
        GU\iPageKey = #PB_Key_PageUp
      EndIf
    EndIf
  EndIf
  
  If GU\iDialog <> #DIALOG_QUESTION And Not GU\fPauseInput
    If GU\iDialog <> #DIALOG_HELP
      ;if request for Dialog box
      If fF1Released
        DialogBox(#DIALOG_ABOUT)
      ElseIf fF2Released
        DialogBox(#DIALOG_CREDITS)
      EndIf
    EndIf
    
    ;change theme
    If fF5Released
      If GG\iTheme = #THEME2
        SetTheme(#THEME1)
      Else
        SetTheme(#THEME2)
      EndIf
    EndIf
  EndIf
  
  ;stop drawing on image
  StopDrawing()

  ;now draw to screen output
  StartDrawing(ScreenOutput())
  DrawImage(ImageID(#IMAGEBUFID), 0, 0)
  StopDrawing()
  
  FlipBuffers()
  
  Delay(1)
Wend
; IDE Options = PureBasic 5.70 LTS beta 1 (Windows - x64)
; CursorPosition = 14
; FirstLine = 10
; Folding = -
; Markers = 84
; EnableXP
; CompileSourceDirectory
