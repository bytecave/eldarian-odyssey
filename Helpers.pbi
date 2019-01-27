Declare AddRoomDescription(fForce.i)
Declare DialogBox(nDialogMode.i, strQuestion.s = "", strVerb.s = "")
  
#DEFAULTSAVEFILE = "SAVEGAME.EOS"
#EO_EXTENSION = ".EOS"
#VOWELSTART = "aeiou"

Procedure.s AorAnorAny(strNoun.s)
  Protected str.s
  
  strNoun = LCase(strNoun)
  
  If Right(strNoun, 1) = "s"
    str = "any"
  ElseIf FindString(#VOWELSTART, Left(strNoun, 1))
    str = "an"
  Else
    str = "a"
  EndIf
  
  ProcedureReturn str
EndProcedure

Macro ChangeAvailDirection(roomx, roomy, idir, strnew)
  ReplaceString(rgMove(roomx, roomy)\strAvail, Mid(rgMove(roomx, roomy)\strAvail, idir, 1), strnew, #PB_String_InPlace, idir, 1)
  GU\iDirty + 1
EndMacro

Macro quote
  "
EndMacro

Macro _COMMAS(str)
  "," + str + ","
EndMacro

Procedure.i SplitString(str.s, delim.s, Array Arr.s(1))
  Protected iSize.i, iCount.i, i.i, strToken.s
  
  ;get number of delimiters and size array to account for largest possible size
  iSize = CountString(str, delim) + 1
  ReDim Arr.s(iSize)
  
  For i = 1 To iSize
    strToken = StringField(str, i, delim)
    
    ;Only add if valid string found. This prevents blank tokens in strings like "<delim>WORD<delim><delim><delim>WORD2<delim>"
    If strToken <> ""
      Arr(iCount) = strToken
      iCount + 1
    EndIf
  Next
  
  If iCount
    ReDim Arr.s(iCount - 1)   ;ReDim(1) = 2 elements, just how ReDim works
  EndIf
  
  ProcedureReturn iCount
EndProcedure

;load from data section, private to this app -- after initial load from disk it exists in memory only, cleaned up by OS when app terminates
Procedure.i LoadPrivateFont(strFontFile.s, strFontFace.s, *pFontBuffer, iFontLength.i, iPointSize.i, iFlags.i = 0)
  Protected hFont.i, hFile.i
  Protected i.i
  Static strFontsLoaded.s
  
  If strFontFile > "" And Not FindString(strFontsLoaded, strFontFile)
    strFontsLoaded + strFontFile + ","
    
CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    hFont = AddFontMemResourceEx_(*pFontBuffer, iFontLength, 0, @i)
CompilerEndIf

    If hFont = 0
      strFontFile = GetTemporaryDirectory() + strFontFile
      
      If FileSize(strFontFile) = -1  ;if font file <> exist
        hFile = CreateFile(#PB_Any, strFontFile)
        If hFile
          WriteData(hFile, *pFontBuffer, iFontLength)
          CloseFile(hFile)
        EndIf
      EndIf
    
      ;If font file is corrupt or can't be matched, no worry, IsFont test below will fail and we'll get the default system font
      RegisterFontFile(strFontFile)
    EndIf    
  EndIf
  
  hFont = LoadFont(#PB_Any, strFontFace, iPointSize, iFlags)
  If Not IsFont(hFont)
    hFont = GetGadgetFont(#PB_Default)
  EndIf
  
  ProcedureReturn hFont
EndProcedure

Procedure.s TrimDelimiters(str.s)
  Protected i.i = 1, j.i
  
  While Mid(str, i, 1) = ","
    i + 1
  Wend
  
  j = Len(str)
  While Mid(str, j, 1) = ","
    j - 1
  Wend
  
  ProcedureReturn Mid(str, i, j - i + 1)
EndProcedure

Procedure.s RemovePunctuation(source.s,  charsToStrip.s)
  Protected i, *ptrChar.Character, length = Len(source), result.s
  
  *ptrChar = @source
  For i = 1 To length
    If Not FindString(charsToStrip, Chr(*ptrChar\c))
      result + Chr(*ptrChar\c)
    EndIf
    
    *ptrChar + SizeOf(Character)
  Next
  
  ProcedureReturn result 
EndProcedure


;%a replaced with a/an/any
;%o replaced with one/any
;%i replaced with is/are
;%t replaced with it/them

;substitute parm strings for tokens in input string. Ex: ...("Hello %1", "you") returns Hello you
Procedure.s FormatString(strIn.s, str1.s = "", str2.s = "", str3.s = "", str4.s = "")
  Protected strout.s, strTest.s, strToken.s
  Protected i.i, iStart.i = 1, iPos.i
  
  Repeat
    iPos = FindString(strIn, "%", iStart)
    
    If iPos 
      strout + Mid(strIn, iStart, iPos - iStart)
      iStart = iPos + 2  ;point past the %blah token
      strToken = Mid(strIn, iPos + 1, 1)
      
      Select strToken
        Case "1"
          strOut + str1
        Case "2"
          strOut + str2
        Case "3"
          strOut + str3
        Case "4"
          strOut + str4
        Default
          If FindString("AOIT", strToken)
            iStart + 1  ;point past the digit after the %blah token
            
            ;number after %<word selector> indicates which token to check
            Select Val(Mid(strIn, iPos + 2, 1))
              Case 1
                strTest = str1
              Case 2
                strTest = str2
              Case 3
                strTest = str3
              Case 4
                strtest = str4
            EndSelect
              
            Select strToken
              Case "A", "a"
                If Right(strTest, 1) = "s"
                  strOut + "any"
                ElseIf FindString("aeiou", Left(strTest, 1), #PB_String_NoCase)
                  strOut + "an"
                Else
                  strOut + "a"
                EndIf
              Case "O", "o"
                If Right(strTest, 1) = "s"
                  strOut + "any"
                Else
                  strOut + "one"
                EndIf
              Case "I", "i"
                If Right(strTest, 1) = "s"
                  strOut + "are"
                Else
                  strOut + "is"
                EndIf
              Case "T", "t"
                If Right(strTest, 1) = "s"
                  strOut + "them"
                Else
                  strOut + "it"
                EndIf
            EndSelect
          Else
            ;Only process percent signs followed by a digit/special letter, otherwise include % and bump start past it
            strOut + "%"
            iStart = iPos + 1
          EndIf
      EndSelect
    EndIf
  Until iPos = 0
  
  ProcedureReturn strOut + Mid(strIn, iStart)
EndProcedure

Procedure.s ReadFileFromMemory(iStart.i = 0)
  Static iPtr.i
  Protected str.s, fNewLine.i
  
  If iStart
    iPtr = iStart
  Else
    iStart = iPtr
    
    While #True
      Select PeekB(iPtr)
        Case $0D, $0A, $00
          PokeB(iPtr, 0)
          fNewLine = #True

        Default
          If fNewLine
            str = Trim(PeekS(iStart, -1, #PB_Ascii))
            iStart = iPtr
            
            ;If we got a non-blank line, return it
            If str <> ""
              Break
            Else
              fNewLine = #False  ;line was blank, but still flag that we processed the line
            EndIf
          EndIf
      EndSelect
      
      iPtr + 1
    Wend
  EndIf
  
  ProcedureReturn str.s
EndProcedure
  
;save to #DEFAULTSAVEFILE unless user specified, or previously specified, filename in the SAVE command
Procedure SaveGame(strFileName.s)
  Protected str.s
  
  If strFileName = "" Or strFileName = "GAME"   ;if no file name or used typed "SAVE GAME"
    If GG\strLastSaveFile <> ""
      strFileName = GG\strLastSaveFile
    Else
      strFileName = #DEFAULTSAVEFILE
    EndIf
  EndIf
  
  If Not Right(strFilename, Len(#EO_EXTENSION)) = #EO_EXTENSION
    strFileName + #EO_EXTENSION
  EndIf
  
  strFileName = UCase(strFileName)
  
  If CreatePreferences(GetCurrentDirectory() + strFilename, #PB_Preference_NoSpace)
    If strFileName <> #DEFAULTSAVEFILE
      GG\strLastSaveFile = strFileName
    EndIf
    
    PreferenceComment("Eldarian Odyssey Adventure game save file [" + FormatDate("%yyyy/%mm/%dd %hh:%ii:%ss", Date()) + "]")
    PreferenceComment("")
    
    PreferenceGroup("G:GameGlobals")
    
    WritePreferenceInteger("lightsource", GG\fLightSource)
    WritePreferenceInteger("lightpermanent", GG\fLightPermanent)
    WritePreferenceInteger("intree", GG\fInTree)
    WritePreferenceString("current",  GG\ptrRoom\strRoom)
    WritePreferenceString("prev", GG\ptrPrevRoom\strRoom)
    WritePreferenceInteger("backpack", GG\fHaveBackpack)
    WritePreferenceInteger("numcommands", GG\iNumCommands)
    WritePreferenceInteger("coins", GG\iCoins)
    WritePreferenceInteger("torchburn", GG\iTorchBurnTime)
    
    ;save timers. millisecond based timers will have already expired by the time they are loaded so action will complete immediately after load
    ResetMap(GG\Timers())
    While NextMapElement(GG\Timers())
      With GG\Timers()
        WritePreferenceString(\strEvent, Str(\iType) + "," + Str(\iStart) + "," + Str(\iCount))
      EndWith
    Wend
    
    ResetMap(Rooms())
    
    While NextMapElement(Rooms())
      With Rooms()
        PreferenceGroup("R:" + \strRoom)

        WritePreferenceInteger("state", \iState)
        If \iRoomX <> -1  ;this is special "inventory" room
          WritePreferenceString("directions", rgMove(\iRoomX, \iRoomY)\strAvail)
        EndIf
        
        ResetMap(\mapNouns())
        While NextMapElement(\mapNouns())
          WritePreferenceString(MapKey(\mapNouns()), \mapNouns())
        Wend
      EndWith
    Wend
    
    ResetMap(Nouns())
    
    While NextMapElement(Nouns())
      With Nouns()
        If \strBaseNoun = ""    ;don't need to save synonyms, the just point to base noun
          PreferenceGroup("O:" + \strNoun)
          
          WritePreferenceInteger("state", \iState)
          WritePreferenceString("room", \strRoom)
        EndIf
      EndWith
    Wend
    
    ClosePreferences()
    
    If strFileName <> #DEFAULTSAVEFILE
      str = "Game saved to " + strFileName + "."
    Else
      str = "Game saved."
    EndIf
  Else
    str = "Unable to save game to " + strFileName + "."
  EndIf
  
  AddToOutput(str)
  
  ;flag that no state has changed since last save or load
  GU\iDirty = 0
EndProcedure

;load from #DEFAULTSAVEFILE unless user specified filename in the LOAD command
Procedure LoadGame(strFileName.s, fPermitted.i = #False)
  Protected str.s, strGroup.s, strKey.s, strValue.s
  Protected *ptrRoom.ROOM, *ptrNoun.NOUN
  Protected fNewGroup.i
  Dim rgTimer.s(0)
  
  If strFileName = "" Or strFileName = "GAME"   ;if no file name or used typed "SAVE GAME"
    If GG\strLastSaveFile <> ""
      strFileName = GG\strLastSaveFile
    Else
      strFileName = #DEFAULTSAVEFILE
    EndIf
  EndIf
  
  If Not Right(strFilename, Len(#EO_EXTENSION)) = #EO_EXTENSION
    strFileName + #EO_EXTENSION
  EndIf
  
  strFileName = UCase(strFileName)
  GG\strLoadFileName = strFileName     ;used for load dialog confirmation call
  
  If FileSize(strFileName) < 0
    AddToOutput("There is no saved game with the name " + strFileName)
    ProcedureReturn
  EndIf

  If Not fPermitted And GU\iDirty
    DialogBox(#DIALOG_QUESTION, "Understood, however...^^all progress of the current game will be lost. You can save your game first if you'd like. Are you sure you want to load?", "LOAD")
    ProcedureReturn
  EndIf

  If OpenPreferences(GetCurrentDirectory() + strFileName, #PB_Preference_NoSpace)
    ExaminePreferenceGroups()
    
    While NextPreferenceGroup()
      strGroup = PreferenceGroupName()
      fNewGroup = #True
      
      ExaminePreferenceKeys()
      While  NextPreferenceKey()
        strKey = PreferenceKeyName()
        strValue = PreferenceKeyValue()
        
        Select Left(strGroup, 1)
          Case "G"    ;game globals
            Select strKey
                
              Case "lightsource"
                GG\fLightSource = Val(strValue)
              Case "lightpermanent"
                GG\fLightPermanent = Val(strValue)
              Case "intree"
                GG\fInTree = Val(strValue)
              Case "current"
                GG\ptrRoom = FindMapElement(Rooms(), strValue)
              Case "prev"
                GG\ptrPrevRoom = FindMapElement(Rooms(), strValue)
              Case "backpack"
                GG\fHaveBackpack = Val(strValue)
              Case "numcommands"
                GG\iNumCommands = Val(strValue)
              Case "coins"
                GG\iCoins = Val(strValue)
              Case "torchburn"
                GG\iTorchBurnTime = Val(strValue)
              Default
                SplitString(strValue, ",", rgTimer())
                AddMapElement(GG\Timers(), strKey)
                
                With GG\Timers()
                  \iType = Val(rgTimer(0))
                  \iStart = Val(rgTimer(1))
                  \iCount= Val(rgTimer(2))  ;iTime and iCount are a union, so filling in \iCount will fill in \iTime
                  \strEvent = strKey
                EndWith
            EndSelect

          Case "R"
            If fNewGroup
              *ptrRoom = FindMapElement(Rooms(), Mid(strGroup, 3))
              
              ;we've got a new room. remove all items from the room, and default case below will add back saved game contents
              ResetMap(*ptrRoom\mapNouns())
              While NextMapElement(*ptrRoom\mapNouns())
                DeleteMapElement(*ptrRoom\mapNouns())
              Wend
              
              fNewGroup = #False
            EndIf
            
            With *ptrRoom
              Select strKey
                Case "state"
                  \iState = Val(strValue)
                Case "directions"
                  If \iRoomX <> -1    ;if it's not the special "inventory" room
                    rgMove(\iRoomX, \iRoomY)\strAvail = strValue
                  EndIf
                Default
                  AddMapElement(\mapNouns(), strKey)  
                  \mapNouns() = strValue
              EndSelect
            EndWith
            
          Case "O"    ;nouns or "(O)bjects"
            If fNewGroup
              *ptrNoun = FindMapElement(Nouns(), Left(Mid(strGroup, 3), #PARSELEN))
              fNewGroup = #False
            EndIf
            
            With *ptrNoun
              Select strKey
                Case "state"
                  \iState = Val(strValue)
                Case "room"
                  \strRoom = strValue
              EndSelect
            EndWith
        EndSelect
      Wend   
    Wend
    
    ClearOutputBuffer()
    
    If strFileName <> #DEFAULTSAVEFILE
      str = "Game loaded from " + strFileName + "."
    Else
      str = "Game loaded."
    EndIf
    
    AddToOutput(#COMMANDINDICATOR + GG\strCommand + "^" + str + "^^")
    AddRoomDescription(#True)
    
    ;flag that no state has changed since last save or load
    GU\iDirty = 0
  Else
    AddToOutput("Unable to load game from " + strFileName + ".")
  EndIf
EndProcedure

CompilerIf #PB_Compiler_Debugger
Procedure.s GetState(iState.i)
  Protected str.s
  
  If iState & #STATE0
    str + "#0, " 
  EndIf
  If iState & #STATE1
    str + "#1, " 
  EndIf
  If iState & #STATE2
    str + "#2, "
  EndIf
  If iState & #STATE3
    str + "#3, " 
  EndIf
  If iState & #STATE4
    str + "#4, " 
  EndIf
  If iState & #STATE5
    str + "#5, " 
  EndIf
  If iState & #STATE6
    str + "#6, " 
  EndIf
  If iState & #STATE7
    str + "#7, " 
  EndIf
  If iState & #SAVAIL
    str + "#SAVAIL, "
  EndIf
  If iState & #SDARK
    str + "#SDARK, "
  EndIf
  If iState & #SFIXED
    str + "#SFIXED, "
  EndIf
  If iState & #SDROPPED
    str + "#SDROPPED, "
  EndIf
  If iState & #SPLAYERAWARE
    str + "#SPLAYERAWARE, "
  EndIf
  str+"END"
  
  ProcedureReturn str
EndProcedure
CompilerEndIf
; IDE Options = PureBasic 5.70 LTS beta 1 (Windows - x64)
; CursorPosition = 70
; FirstLine = 48
; Folding = ---
; EnableXP