
#EOLCHARS = ~".,-:\"; "
#NOMULTICHARS = ".,-:;"
#NEWLINETOKEN = "^"
#SPECIALSPACE = "~"
#MAXOUTPUTLINES = 16

Prototype.s ProtoDrawTextProc(arg.s)
Declare DrawAboutText(str.s)
Global DrawTextProc.ProtoDrawTextProc = @DrawAboutText()

Structure OUTPUTBUFFER
  iHead.i 
  iTail.i
  strLine.s[#MAXOUTPUTLINES]
EndStructure

Global g_Output.OUTPUTBUFFER

Macro _WRAPBUFFER(ptr)
  ptr + 1
  If ptr = #MAXOUTPUTLINES
    ptr = 0
  EndIf
EndMacro


Procedure PrintOutputBuffer()
  Protected i.i, iLines.i
  
  ;start drawing buffer lines to output area of screen
  DrawingMode(#PB_2DDrawing_Transparent)
  DrawingFont(GU\hOutputFont)
  FrontColor(GU\RGBOutputColor)
  
  iLines = 0
  i = g_Output\iHead
  
  While iLines < #MAXOUTPUTLINES
    
    ;#SPECIALSPACE characters allow forcing spaces at the beginning of a line
    DrawText(GU\iXStart, GU\iYStartO + GU\iOutputFontHeight * iLines, ReplaceString(Trim(g_Output\strLine[i]), #SPECIALSPACE, " "))
    
    _WRAPBUFFER(i)
    iLines + 1
  Wend
EndProcedure

Procedure AddToOutput(sText.s, fDrawText.i = #False)
  Protected fGotLine.i, strChar.s
  Protected iLineLen.i, iStrLen.i
  Protected iTemp.i, iNext.i
  
  If sText = ""
    ProcedureReturn
  EndIf
  
  If Not fDrawText
    ;specify drawing context, just for sizing width of text being added. 
    DrawingMode(#PB_2DDrawing_Transparent)
    DrawingFont(GU\hOutputFont)
  EndIf
  
  Repeat
    iLineLen = 1
    iStrLen = Len(sText)
    fGotLine = #False
    
    While Not fGotLine
      If TextWidth(Left(sText, iLineLen)) < GU\iXWidth
        strChar = Mid(sText, iLineLen, 1)
        
        ;remove new line tokens, carriage returns, and line feeds for printing. CR, LF, or CRLF all okay
        Select strChar
          Case #NEWLINETOKEN
            ReplaceString(sText, #NEWLINETOKEN, " ", #PB_String_InPlace, iLineLen, 1)
            fGotLine = #True
          Case #CR$
            ReplaceString(sText, #CR$, " ", #PB_String_InPlace, iLineLen, 1)
            ReplaceString(sText, #LF$, " ", #PB_String_InPlace, iLineLen + 1, 1)
            iLineLen + 1   ;bump past linefeed as we just processed two characters
            fGotLine = #True
          Case #LF$
            ReplaceString(sText, #LF$, " ", #PB_String_InPlace, iLineLen, 1)
            fGotLine = #True
          Default
            If  iLineLen = iStrLen
              fGotLine = #True
            Else
              iLineLen + 1
            EndIf
        EndSelect
      Else
        iTemp = iLineLen
        
        Protected x.i, sss.s
        
        While Not fGotLine
          ;if next line is set to begin with a non-space #EOLCHAR character, back up in case there are multiple.
          ;all multiple occurrences of a #NOMULTICHAR must appear on same line. This prevents an ellipsis, for
          ;example, from being broken between two lines.
          If FindString(#NOMULTICHARS, Mid(sText, iLineLen + 1, 1))
            While FindString(#NOMULTICHARS, Mid(sText, iLineLen, 1))
              iLineLen - 1
            Wend
          EndIf
          
          ;now just back up until we find a valid end of line character
          While Not FindString(#EOLCHARS, Mid(sText, iLineLen, 1))
            iLineLen - 1
            
            If iLineLen = 0
              iLineLen = iTemp
              Break
            EndIf
          Wend
          
          fGotLine = #True
        Wend
      EndIf
    Wend
    
    ;If flagged to add text *and* draw it, call back to drawing proc
    If fDrawText
      DrawTextProc(Left(sText, iLineLen))
    Else
      With g_Output
        ;add line to circular buffer, phasing old lines out
        \strLine[\iTail] = Left(sText, iLineLen)
        
        If \iTail = \iHead
          _WRAPBUFFER(\iHead)
        EndIf
        
        _WRAPBUFFER(\iTail)
      EndWith
    EndIf
    
    ;last pass through, iLineLen + 1 is always > stringlen, but it's okay 'cause Purebasic just returns ""
    sText = Mid(sText, iLineLen + 1)
  Until iLineLen = iStrLen
EndProcedure

Procedure ClearOutputBuffer()
  Protected i.i
  
  With g_Output
    For i = 0 To #MAXOUTPUTLINES - 1
      \strLine[i] = ""
    Next
    
    \iTail = 0
    \iHead = 0
  EndWith
EndProcedure

; IDE Options = PureBasic 5.70 LTS beta 1 (Windows - x64)
; CursorPosition = 122
; FirstLine = 91
; Folding = +
; EnableXP