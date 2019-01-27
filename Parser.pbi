#BADPUNCTUATION = ~",.'\"!-_"
#BADWORDS = ",AND,OR,THEN,IF,AT,PUT,PLACE,IN,ON,UNDER,OVER,NOR,WITH"
#BADWORDFOUND = -1

;is user trying to move N,S,E,W?
Procedure.i CheckDirectionVerb(strVerb.s)
  Protected iRC.i
  
  If FindString(",NORT,SOUT,EAST,WEST,N,S,E,W,", _COMMAS(Left(strVerb, #PARSELEN)))
    TryMovePlayer(FindString("NSEW", Left(strVerb, 1)))   ;1=North, 2=South, 3=East, 4=West. Just like datasection declarations in noun list
    iRC = #True
  EndIf
  
  ProcedureReturn iRC
EndProcedure

;N/S/E/W aren't nouns, so process further in case they follow the word go
Procedure.i CheckGoVerb(strVerbs.s)
  Protected iRC.i, i.i
  Dim rgVerbs.s(0)
  
  ;input will have verb list in the format of "VERB1,VERB2,VERB3"
  strVerbs = "," + strVerbs + ","    ;ensure each verb in list starts and ends with a comma for FindString searches below
  
  If (FindString(strVerbs, _COMMAS("GO")) Or FindString(strVerbs, _COMMAS("MOVE"))) And SplitString(strVerbs, ",", rgVerbs())
    For i = 0 To ArraySize(rgVerbs())
      If CheckDirectionVerb(rgVerbs(i))
        iRC = #True
        Break
      EndIf
    Next
  EndIf
  
  ProcedureReturn iRC
EndProcedure

;only get here if a single word was entered by the user. strVerb is full word.
Procedure.i ValidSingleWordVerb(strVerb.s, *sNoun.STRING)
  Protected iRC.i = #True, iCount.i
  Protected strWord.s = " what?"
  
  Select Left(strVerb, #PARSELEN)
    Case "HELP"
      DialogBox(#DIALOG_HELP)
    Case "HINT"
      AddToOutput("A clue!")
    Case "LOOK", "L"
      AddRoomDescription(#True)
    Case "GET", "TAKE", "GRAB"
      *sNoun\s = "ALL"
    Case "EXAM"
      AddToOutput("What should I examine?")
    Case "INSPECT", "INSP"
      AddToOutput("What should I inspect?")
    Case "DROP"
      AddToOutput("Drop what?")
    Case "DIR", "LS"
      If strVerb = "DIR"
        AddToOutput("C:\>DIR^DIR is not recognized as an internal or external command, operable program or batch file.")
      Else
        AddToOutput("#ls: command not found.")
      EndIf
    Case "SAVE"
      SaveGame("")  ;single word save, no filename passed in
    Case "LOAD"
      LoadGame("")
    Case "QUIT", "NEW"
      If GU\iDirty
        DialogBox(#DIALOG_QUESTION, "WAIT!^^Are you sure you want to quit this game? All progress will be lost. You can save your progress first if you'd like, just press ESC or answer No and type SAVE.", "QUIT")
      Else
        OkayToAct("Y", "QUIT")
      EndIf
    Case "EXIT"
      If GU\iDirty
        DialogBox(#DIALOG_QUESTION, "JUST CHECKING...^^All progress will be lost. You can save your progress first if you'd like, just press ESC or answer No and type SAVE. Are you sure you want to exit the game?", "EXIT")
      Else
        OkayToAct("Y", "EXIT")
      EndIf
    Case "INV", "INVE", "I"
      InventoryHandler(#INVENTORYDISPLAY)
    Case "TALK", "SPEA"  ;speak
      AddToOutput("Talk to whom?")
    Default
      iRC = CheckDirectionVerb(strVerb)
      
      If iRC = #False
        iCount = LookupApplicableNouns(strVerb, *sNoun)
        
        If iCount = 1
          iRC = #True
        Else
          iRC = #False
          
          ;convert verb to CamelCase, i.e.; LIGHT -> light -> Light
          strVerb = LCase(TrimDelimiters(strVerb))
          strVerb = UCase(Left(strVerb, 1)) + Mid(strVerb, 2)
          
          Select UCase(strVerb)    ;special case words so output makes better sense
            Case "GO"
              strWord = " where?"
          EndSelect
            
          AddToOutput(strVerb + strWord)
        EndIf
      EndIf
  EndSelect
  
  ProcedureReturn iRC
EndProcedure

;returns full word noun in *strNoun
Procedure.i FindNoun(Array rgWords.s(1), *strNoun.STRING)
  Protected i.i, iNumNouns.i, strWord.s
  Protected *ptrNoun.NOUN
  
  For i = 0 To ArraySize(rgWords())
    strWord = rgWords(i)
    
    ;typed word can't be longer than stored word. "BOWLER" will not match "BOW"
    If FindMapElement(Nouns(), Left(strWord, #PARSELEN)) And (strWord = Left(Nouns()\strNoun, Len(strWord)))
      *ptrNoun = Nouns()
      *strNoun\s = *ptrNoun\strNoun
      
      ;if user typed an unattached synonym, resolve it to the associated noun
      If *ptrNoun\strBaseNoun = #START_UNATTACHEDSYNONYM
        ResolveUnattached(*strNoun)
        *ptrNoun = FindMapElement(Nouns(), Left(*strNoun\s, #PARSELEN))
      ElseIf *ptrNoun\strBaseNoun <> ""    ;synonyms refer to base nouns. resolve to base noun
        *ptrNoun = FindMapElement(Nouns(), Left(*ptrNoun\strBaseNoun, #PARSELEN))
      EndIf
      
      ;only return a noun as recognized if the player has encountered it already. "no guessing nouns."
      If *ptrNoun\iState & #SPLAYERAWARE
        If iNumNouns = 0
          *strNoun\s = *ptrNoun\strNoun     ;return first noun only
        EndIf
      
        iNumNouns + 1
      Else
        ;always return what user typed if player is not aware yet
        *strNoun\s = strWord
      EndIf
    ElseIf FindString(#BADWORDS, _COMMAS(strWord))
      *strNoun\s = strWord
      iNumNouns = -1
      Break
    EndIf
  Next
  
  ;if no valid noun found, parser always assumes SECOND word typed is the noun
  If iNumNouns = 0 And *strNoun\s = "" And ArraySize(rgWords()) > 0  ;if a second word was typed and we didn't find a noun
    *strNoun\s = rgWords(1)
  EndIf
  
  ProcedureReturn iNumNouns
EndProcedure

;returns _COMMAS separated list of full words of verbs
Procedure.i FindVerb(Array rgWords.s(1), *strVerb.STRING)
  Protected i.i, iNumVerbs.i
  
  For i = 0 To ArraySize(rgWords())
    If FindMapElement(Verbs(), Left(rgWords(i), #PARSELEN))
      
      ;don't allow a user that types LIGHTNING to match the verb LIGHT
      ;but if the user types LIGH that should match the verb LIGHT
      If rgWords(i) = Left(Verbs(), Len(rgWords(i)))
        iNumVerbs + 1
        
        ;if more than 1 verb, will return a comma separated list of full verbs
        If iNumVerbs > 1
          *strVerb\s + ","
        EndIf
        
        *strVerb\s + Verbs()  ;use full word of verb
      EndIf
    EndIf
  Next
  
  ;if no valid verb found, parser always assumes FIRST word typed is the verb
  If iNumVerbs = 0
    *strVerb\s = rgWords(0)
  EndIf
  
  ProcedureReturn iNumVerbs
EndProcedure

;Calls all handlers with full word noun (for found nouns; what user typed otherwise) and verbs
Procedure ProcessCommand()
  Protected sVerb.STRING, sNoun.STRING
  Protected iNumVerb.i, iNumNoun.i, iDirtyStart.i
  Dim rgWords.s(0)
  
  GG\strCommand = RemovePunctuation(GG\strCommand, #BADPUNCTUATION)
  GG\iNumCommands + 1
  iDirtyStart = GU\iDirty
  
  SplitString(GG\strCommand, " ", rgWords())
  
  ;returns count plus full work of noun/verbs if found
  iNumVerb = FindVerb(rgWords(), @sVerb)
  iNumNoun = FindNoun(rgWords(), @sNoun)
  
  If  iNumNoun = 1 And iNumVerb = 1
    HandleValidCommand(sNoun\s, sVerb\s)
  ElseIf iNumNoun = #BADWORDFOUND
    HandleBadWord(sNoun\s)
  ElseIf iNumNoun > 1 And iNumVerb > 1
    HandleVerbNounTooMany(sNoun\s, sVerb\s)
  ElseIf iNumNoun > 1
    HandleTooManyNouns(sNoun\s)   ;I can't deal with more than 1 thing at once type of erros
  ElseIf iNumVerb > 1
    If Not CheckGoVerb(sVerb\s)
      HandleTooManyVerbs(sVerb\s)
    EndIf
  ElseIf iNumVerb = 0
    If iNumNoun = 0
      HandleInvalidInput(GG\strCommand, sNoun\s, sVerb\s)
    Else
      HandleNoValidVerb(sVerb\s, sNoun\s)   ;got a valid noun but not a valid verb
    EndIf
  ElseIf iNumNoun = 0
    If ArraySize(rgWords()) = 0   ;if only a single word typed
      If ValidSingleWordVerb(sVerb\s, @sNoun)
        
        ;if applicable noun found, dispatch this as a valid command. otherwise the single word verb was already handled
        If sNoun\s <> ""
          HandleValidCommand(sNoun\s, sVerb\s)
        EndIf
      EndIf
    Else
      HandleNoValidNoun(sVerb\s, sNoun\s)   ;got a valid verb but not a valid noun
    EndIf
  EndIf
  
  CheckTorch(iDirtyStart)
EndProcedure
; IDE Options = PureBasic 5.70 LTS beta 1 (Windows - x64)
; CursorPosition = 48
; FirstLine = 44
; Folding = --
; Markers = 68
; EnableXP