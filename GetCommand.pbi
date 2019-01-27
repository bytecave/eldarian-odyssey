#HISTORYBUFSIZE = 10
#PUSHKEYDELAY = 60
#CURSORBLINKRATE = 500
#MAXCOL = 30
#BACKSPACE = 8
#ENTERKEY = 13
#ESCAPEKEY = 27
#VALIDKEYS = ~"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz ,.?!'\""
#NORMALCURSOR = "_"
#ARROWCURSOR = ">"
#BACKCURSOR = "<"
#NOCURSOR = ""
#NOCOMMAND = 0
#GOTCOMMAND = 1
#HISTORYUP = -1
#HISTORYDOWN = 1

#COLOR_PROMPT = $00FF00
#COLOR_EDITLINE = $80FF80

;
; GLOBALS USED
;   GU\strCommand -        when rc = #GOTCOMMAND, this contains the command that was typed
;   GU\hCommandFont -      for drawing command line text
;   GU\iXStart -          left column of command line text
;   GU\iTStartC -         top row of command line text
;   GU\iFontPixelHeight -  height of command line font
;   GU\strENTRYPROMPT -   "Enter Command" prompt for command area
;

Macro _HISTORY(direction)
  If (direction = #HISTORYUP And iDistance > -#HISTORYBUFSIZE) Or (direction = #HISTORYDOWN And iDistance < 0)
    
    ;we track distance from the current entry line (iLine) to ensure we don't wrap history buffer
    iDistance + direction
    iTemp = iLine + iDistance
    
    If iTemp < 0
      iTemp = #HISTORYBUFSIZE + iTemp
    ElseIf iTemp = #HISTORYBUFSIZE
      iTemp = 0
    EndIf
    
    ;if we're at end of input, allow user to get a blank line
    If iDistance = 0
      strLine = ""
      iCol = 0
    ElseIf strLineBuf(iTemp) > ""   ;if there's a history command in the direction we're going
      strLine = strLineBuf(iTemp)
      iCol = Len(strLine)
      
      ;always keep arrow cursor on when actively arrowing up, and double key delay to avoid too rapid scrolling
      msCursor = msCurrent
      strCursor = #ARROWCURSOR
      
      ;Delay between each up/down arrow command so things don't scroll by too fast for the user
      msDelay = ElapsedMilliseconds() + #PUSHKEYDELAY * 3
    Else
      ;there was no command in the history, so reverse the change to iDistance
      iDistance - direction
    EndIf
  EndIf
EndMacro

Procedure.i GetCommand()
  Static Dim strLineBuf.s(#HISTORYBUFSIZE)
  Static iLine.i, iCol.i, strLine.s
  Static msDelay.q, msCursor.q
  Static strCursor.s = #NORMALCURSOR
  Define strkey.s, msCurrent.q, rc.i, iTemp.i
  Static iDistance.i = 0
  
  If GU\fPauseInput
    ProcedureReturn
  EndIf
  
  If GU\iDialog = #DIALOG_NONE
    ExamineKeyboard()
    strKey = Left(KeyboardInkey(), 1)  ;PB bug, sometimes KeyboardInkey() returns 2 characters
    
    rc = #NOCOMMAND
    msCurrent = ElapsedMilliseconds()
    
    If Asc(strKey) = 0
      ;Keypad enter gets 0 from KeyboardInkey(), so handle that here
      If KeyboardPushed(#PB_Key_PadEnter)
        strKey = Chr(#ENTERKEY)
      ElseIf msCurrent - msDelay > #PUSHKEYDELAY   ;delay between backspace and buffer scroll (up/down arrow) keys
        If KeyboardPushed(#PB_Key_Back) And iCol
          iDistance + 1
          iCol - 1
          strLine = Left(strLine, iCol)
                  
          ;always keep backspace cursor on when actively backspacing
          msCursor = msCurrent
          strCursor = #BACKCURSOR
          
          ;delay between backspace when it's held down or things happen too fast for user
          msDelay = ElapsedMilliseconds() + #PUSHKEYDELAY
        ElseIf KeyboardPushed(#PB_Key_Up)
          _HISTORY(#HISTORYUP)
        ElseIf KeyboardPushed(#PB_Key_Down)
          _HISTORY(#HISTORYDOWN)
        EndIf
      EndIf
      
      ;blink cursor at the #CURSORDELAY rate
      If msCurrent - msCursor > #CURSORBLINKRATE
        msCursor = ElapsedMilliseconds()
        
        If strCursor = #NORMALCURSOR
          strCursor = #NOCURSOR
        Else
          strCursor = #NORMALCURSOR
        EndIf
      EndIf
    EndIf
      
    ;don't want this in an else clause from above, because keypad enter could have sent an #ENTERKEY
    ;this weird code structure gets around a timning bug in PB to do with KeyboardInkey()
    Select Asc(strKey)
      Case #ESCAPEKEY
        strLine = ""
        iCol = 0
        
      Case #ENTERKEY      
        ;save line in history, a circular buffer
        If strLine > ""
          strLineBuf(iLine) = strLine
          
          iLine + 1
          If iLine = #HISTORYBUFSIZE
            iLine = 0
          EndIf
          
          ;put text of entered command in global variable for use in main program and set to return #GOTCOMMAND
          GG\strCommand = strLine
          rc = #GOTCOMMAND
          
          ;clear current line
          strLine = ""
        EndIf
        
        iCol = 0
        iDistance = 0
        msDelay = 0
        
        Case 0    ;do nothing here, it was handled far above already

      Default      
        ;while actively typing, keep cursor on
        msCursor = ElapsedMilliseconds()
        strCursor = #NORMALCURSOR
        
        ;if not at max line length and a valid character was typed, add to current line
        If FindString(#VALIDKEYS, strKey) And iCol < #MAXCOL
          ;we want all commands in upper case
          strLine + UCase(strKey)
          iCol + 1
        EndIf
    EndSelect
  Else
    ;if dialog box shown, don't draw a cursor
    strCursor = ""
  EndIf
  
  DrawingMode(#PB_2DDrawing_Transparent)
  DrawingFont(GU\hCommandFont)
  
  FrontColor(#COLOR_PROMPT) 
  DrawText(GU\iXCommand, GU\iYStartC, GU\strENTRYPROMPT)
  
  FrontColor(#COLOR_EDITLINE)
  DrawText(GU\iXCommand, GU\iYStartC + GU\iCommandFontHeight, strLine + strCursor)
  
  ProcedureReturn rc
EndProcedure
; IDE Options = PureBasic 5.62 (Windows - x64)
; CursorPosition = 75
; FirstLine = 30
; Folding = -
; EnableXP