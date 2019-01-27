Declare.i ItemState(nMode.i, strNoun.s, iSetStateMask.i = #NUL, iUnsetStateMask.i = #NUL)
Declare.i RoomState(nMode.i, strRoom.s, iSetStateMask.i = #NUL, iUnsetStateMask.i = #NUL)
Declare.s InventoryHandler(iMode.i, strNoun.s = "")
Declare.s TimerCommand(*sTIMER.EOTIMER = #NUL)
Declare ChangeItemRoom(strNoun.s, strNew.s, strPrev.s = "")
Declare CheckTorch(iDirtyStart)
Declare ChangeStateAction(strVerb.s, strNoun.s)
Declare ChangeCurrentRoom(x.i, y.i, strRoom.s = "")

Structure CRYPTLICHSTATE
  iNumItems.i
  iCryptState.i
  iLichState.i
EndStructure

Procedure.i LichState(*iState.CRYPTLICHSTATE)
  Protected iNumItems.i, iCryptState.i, iLichState.i
  
  ;remove lich hands state and get remaining state
  ItemState(#STATESET, "LICH", #NUL, #STATE1 | #STATE2 | #STATE3)
  iLichState = ItemState(#STATEGET, "LICH")
  
  ;remove all room description state, we'll rebuild it appropriately below
  RoomState(#STATESET, "CRYPT", #NUL, #STATE0|#STATE1|#STATE2|#STATE3|#STATE4|#STATE5|#STATE6)

  ;get room state with Lich alive
  iCryptState = RoomState(#STATEGET, "CRYPT")

  If InventoryHandler(#INVENTORYCHECK, "DAGGER") = #HASITEM
    iCryptState | #STATE2
    iNumItems + 1
  EndIf
  
  If GG\fLightPermanent
    iCryptState | #STATE3
    iNumItems + 1
  EndIf

  If InventoryHandler(#INVENTORYCHECK, "SCEPTER") = #HASITEM
    iCryptState | #STATE4
    iNumItems + 1
  EndIf
  
  Select iNumItems
    Case 0, 1
      iLichState | #STATE1
    Case 2
      iLichState | #STATE2
    Case 3
      iLichState | #STATE3
  EndSelect
  
  ;set Lich hands state
  ItemState(#STATESET, "LICH", iLichState, #NUL)
  
  *iState\iCryptState = iCryptState
  *iState\iLichState = iLichState
  *iState\iNumItems = iNumItems
  
  ProcedureReturn *iState
EndProcedure

Procedure DoLichTimer(strEvent.s)
  Select strEvent
    Case "LICHINSTANT"
      AddToOutput("^*** You awaken, shivering, in the burrow near entrace to the dungeon. Your icy heart warms and beats to the rhythm of the green pulsing on the band about you neck. Your band returns to a light blue and you sit up, ready for more.^^")
      
      GU\fPauseInput = #False
      GU\fGray = #False
      GG\fLightSource = #False
      CheckTorch(GU\iDirty)
      
      ChangeStateAction("PLAYERDIED", "BAND")
      ChangeCurrentRoom(0, 0, "BURROW")
    Case "LICHDEATH"
      ;sdfs
  EndSelect
EndProcedure

Procedure DoCryptOnEntry()
  Protected sState.CRYPTLICHSTATE
  
  If Not ItemState(#STATEGET, "LICH") & #STATE7   ;if lich is still alive
    ;Die immediately (handled on OnPostEntry if no light or no ward bracelet
    If GG\fLightSource And ItemState(#STATEGET, "BRACELET") & #STATE7
      LichState(@sState)
      
      ItemState(#STATESET, "LICH", sState\iLichState)
      RoomState(#STATESET, "CRYPT", sState\iCryptState | #STATE1, #NUL)  ;set just the room entry states we want
      
      ItemState(#STATESET, "DAGGER", #STATE3, #NUL)  ;state 3 = dagger white hum
    EndIf
  EndIf
EndProcedure

Procedure DoCryptPostEntry()
  Protected sTimer.EOTIMER
  
  If Not GG\fLightSource Or Not ItemState(#STATEGET, "BRACELET") & #STATE7
    ;die instantly if enter Crypt while dark or not wearing warding bracelet
    
    GU\fGray = #True
    GU\fPauseInput = #True

    sTimer\strEvent = "LICHINSTANT"
    sTimer\iType = #TIMERMILLISECONDS
    sTimer\iTime = 5000
    sTimer\iStart = ElapsedMilliseconds()
    
    TimerCommand(@sTimer)
  EndIf
EndProcedure

Procedure.s LichKillsYou()
  Protected str.s, sTimer.EOTIMER
  
  str = "D'rella screams, " + Chr(34) + "You are unprepared, now die!" + Chr(34) + " Shocking streaks of blue and velvet streak from her withered claws. "
  str + "You feel like you're being torn apart as you die, most wretchedly."
  
  GU\fGray = #True
  GU\fPauseInput = #True

  sTimer\strEvent = "LICHDEATH"
  sTimer\iType = #TIMERMILLISECONDS
  sTimer\iTime = 5000
  sTimer\iStart = ElapsedMilliseconds()
  
  TimerCommand(@sTimer)
  
  ProcedureReturn str
EndProcedure

;noun and verb are both valid, #PARSELEN words
Procedure.i LichHandler(strVerb.s, strNoun.s)
  Protected iState.i, fRC.i = #True, str.s
  Protected iNumItems.i, sState.CRYPTLICHSTATE
  
  LichState(@sState)
  iState = sState\iLichState
  
  Select strVerb
    Case "TALK", "SPEAK"
      If sState\iNumItems <> 3
        str = LichKillsYou()
      ElseIf Not iState & #STATE6   ;first time talking to Lich
        str = "Let me be, lest I strike thee down, wyrm."
        ItemState(#STATESET, "LICH", #STATE6, #NUL)
      Else
        str = "Take thy leave, runt. My patience runs thin."
      EndIf
      
    Case "FIGH", "ATTA", "KILL"  ;fight, attack
      If sState\iNumItems <> 3
        str = LichKillsYou()
      ElseIf Not iState & #STATE5
        str = "The scepter comes to life and shoots a bright golden light at the lich, clearly damaging it! She screams in agony and points to you. "
        str + Chr(34) + "Die, vermin!" + Chr(34) + " For a few seconds, you feel like you are suffocating, but the bracelet on your wrist turns brilliant amber and the feeling subsides. Thank goodness for the elven ward! "
        str + "Still, you are weakened and unable to continue the fight. Have you a magic elixir that might restore you?"
        
        ItemState(#STATESET, "LICH", #STATE5, #NUL)  ;fought lich once
      ElseIf ItemState(#STATEGET, "POTION") & #STATE7   ;drank potion
        ;dagger attack to kill
        str = "You plunge the radiant, white dagger deep into the lich where you guess the heart to be. Success! With a final wailing scream, D'rella evaporates into an ethereal vapor and is gone. You have defeated the lich queen!"
        
        ItemState(#STATESET, "LICH", #STATE7)  ;lich dead
        ChangeItemRoom("LICH", #ITEMGONE, "CRYPT")
        ItemState(#STATESET, "DAGGER", #NUL, #STATE3)  ;remove dagger hum
        RoomState(#STATESET, "CRYPT", #STATE0, #STATE6)  ;generic room description, without the lich
      Else
        str = "You are too weak to fight! You must find a way to restore your energy."
      EndIf
      
    Default
      fRC = #False
  EndSelect
  
  AddToOutput(str)
  
  ProcedureReturn fRC
EndProcedure
      



; IDE Options = PureBasic 5.70 LTS beta 1 (Windows - x64)
; CursorPosition = 171
; FirstLine = 126
; Folding = --
; EnableXP