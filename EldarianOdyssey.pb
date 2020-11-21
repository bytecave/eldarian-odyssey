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
  SetThreadExecutionState(#ES_SYSTEM_REQUIRED | #ES_DISPLAY_REQUIRED | #ES_AWAYMODE_REQUIRED | #ES_CONTINUOUS)
  CloseLibrary(kernel32)
EndIf
CompilerEndIf

InitializeGame()

;
;main game loop
;
Define rc.i, Event.i, strEvent.s

While #True
  Repeat
    Event = WaitWindowEvent(1)
    
    If Event = #PB_Event_CloseWindow
      End
    EndIf
  Until Event = 0
  
  ;draw onto buffer image
  ClearScreen(0)
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
  
  ExamineKeyboard()
  
  If GU\iDialog <> #DIALOG_NONE
    DialogBox(#DIALOG_REFRESH)
    
    If GU\iDialog = #DIALOG_QUESTION
      If KeyboardReleased(#PB_Key_Y)
        OkayToAct("Y")
      ElseIf KeyboardReleased(#PB_Key_N) Or KeyboardReleased(#PB_Key_Escape)
        OkayToAct("N")
      EndIf
    Else
      ;Credits, About, or Help
      If KeyboardReleased(#PB_Key_Escape)
        GU\fGray = #False
        GU\iDialog = #DIALOG_NONE
      ElseIf KeyboardReleased(#PB_Key_PageDown)
        GU\iPageKey = #PB_Key_PageDown
      ElseIf KeyboardReleased(#PB_Key_PageUp)
        GU\iPageKey = #PB_Key_PageUp
      EndIf
    EndIf
  EndIf
  
  If GU\iDialog <> #DIALOG_QUESTION
    If GU\iDialog <> #DIALOG_HELP
      ;if request for Dialog box
      If KeyboardReleased(#PB_Key_F1)
        DialogBox(#DIALOG_ABOUT)
      ElseIf KeyboardReleased(#PB_Key_F2)
        DialogBox(#DIALOG_CREDITS)
      EndIf
    EndIf
    
    ;change theme
    If KeyboardReleased(#PB_Key_F5) 
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