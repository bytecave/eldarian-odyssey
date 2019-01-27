Declare.s InventoryHandler(iMode.i, strNoun.s = "")
Declare TorchHandler(strVerb.s)
Declare.s TimerCommand(*sTIMER.EOTIMER = #NUL)
  
Enumeration
  #NORTH = 1
  #SOUTH
  #EAST
  #WEST
EndEnumeration

#DIRECTIONS = "NSEW"
#DIRNOPE = "0"
#DIROK = "1"
#DIRLOCKED = "2"
#DIRCLOSED = "3"
#DIRBLOCKED = "5"
#DIRTELEPORT = "6"
#DIRCONFUSING = "7"   ;available direction, but player can't be sure until she tries it
#DIRUNAVAILABLE = "8"
#DIRCODE = "9"

#COLOR_DIRNOPE = $505050
#COLOR_DIROK = $00FF00
#COLOR_DIRNOTREADY = $0000FF
#COLOR_DARK = $0069FF

#NOUN_STATE = "^"
#ROOM_STATE = "$"
#ROOMOUTPUTINDICATOR = ""

#STATECHANGENOT = "!"
#STATECHANGEONLY = "&"
#STATECHANGESUBTRACT = "-"
#STATECHANGEADD = "+"

#NOROOMREFRESH = #False

Procedure MakePlayerAware()
  With GG\ptrRoom
    
    ;If it's not dark or if a light source i on
    If Not \iState & #SDARK Or GG\fLightSource
      
      ResetMap(\mapNouns())
      While NextMapElement(\mapNouns())
        
        ;Enumerate nouns and if not falled for "code aware" only in the data section, reveal to player
        FindMapElement(Nouns(), MapKey(\mapNouns()))    ;always search Nouns() with #PARSELEN characters, i.e.; mapkey of mapNouns()
        
        If Not Nouns()\iState & #SCODEAWARE
          Nouns()\iState | #SPLAYERAWARE
        EndIf
      Wend
    EndIf
  EndWith
EndProcedure

Procedure.i CheckDarkAction()
  Protected fLightsOn.i
  
  If GG\ptrRoom\iState & #SDARK And Not GG\fLightSource
    AddToOutput("It's too dark to do that.")
  Else
    fLightsOn = #True
  EndIf
  
  ProcedureReturn fLightsOn
EndProcedure

;pass in either x,y or name of room
Procedure ChangeCurrentRoom(x.i, y.i, strRoom.s = "")
  GG\ptrPrevRoom = GG\ptrRoom
  
  If strRoom = ""
    strRoom = rgMove(x, y)\strRoom
  EndIf
  
  GG\ptrRoom = FindMapElement(Rooms(), strRoom)

  ;when player enters a new room, he has "discovered" the nouns in it and now can reference them successfully
  MakePlayerAware()
  
  GU\iDirty + 1
EndProcedure

;noun can be full or #PARSELEN
Procedure.i ItemState(nMode.i, strNoun.s, iSetStateMask.i = #NUL, iUnsetStateMask.i = #NUL)
  Protected *ptrNoun.NOUN
  
  *ptrNoun = FindMapElement(Nouns(), Left(strNoun, #PARSELEN))
  
  If nMode = #STATESET
    *ptrNoun\iState & ~(iUnsetStateMask)
    *ptrNoun\iState | iSetStateMask
  
    GU\iDirty + 1
  Else
    ProcedureReturn *ptrNoun\iState
  EndIf
EndProcedure

;room is full name
Procedure.i RoomState(nMode.i, strRoom.s, iSetStateMask.i = #NUL, iUnsetStateMask.i = #NUL)
  Protected *ptrRoom.ROOM
  
  *ptrRoom = FindMapElement(Rooms(), strRoom)
  
  If nMode = #STATESET
    *ptrRoom\iState & ~(iUnsetStateMask)
    *ptrRoom\iState | iSetStateMask
  
    GU\iDirty + 1
  Else
    ProcedureReturn *ptrRoom\iState
  EndIf
EndProcedure

Procedure CheckTorch(iDirtyStart)
  Protected iState.i = 0
  
  With GG
    If \fLightSource
      If Not \fLightPermanent And iDirtyStart < GU\iDirty
        \iTorchBurnTime - 1
        
        If \iTorchBurnTime = 0
          TorchHandler("EXTI")  ;extinguish torch
          AddToOutput("^")
        EndIf
      EndIf
    EndIf

    If \fLightSource
      iState = #STATE1
      If \fLightPermanent
        iState | #STATE2
      EndIf
    ElseIf \iTorchBurnTime
      iState = #STATE4
    Else
      iState = #STATE5
    EndIf
  EndWith
  
  ;set desired torch state and unset all other torch state
  ItemState(#STATESET, "TORCH", iState, (#STATE1 | #STATE2 | #STATE3 | #STATE4 | #STATE5) & ~iState)
EndProcedure

;full name on noun
Procedure ChangeItemRoom(strNoun.s, strNew.s, strPrev.s = "")
  Protected *ptrRoom.ROOM
  
  ;add item to new room
  *ptrRoom = FindMapElement(Rooms(), strNew)
  AddMapElement(*ptrRoom\mapNouns(), Left(strNoun, #PARSELEN))  ;always #PARSELEN for mapkey
  *ptrRoom\mapNouns() = strNoun    ;always full noun for map value
  
  ;change room string for noun
  FindMapElement(Nouns(), Left(strNoun, #PARSELEN))
  Nouns()\strRoom = *ptrRoom\strRoom
  
  ;item added to inventory is automatically made playeraware and available
  If *ptrRoom\strRoom = #INVENTORY
    ItemState(#STATESET, strNoun, #SPLAYERAWARE | #SAVAIL)
  EndIf
    
  ;default to current room, but lookup room if name supplied in call
  If strPrev = ""
    *ptrRoom = GG\ptrRoom
  Else
    *ptrRoom = FindMapElement(Rooms(), strPrev)
  EndIf
  
  DeleteMapElement(*ptrRoom\mapNouns(), Left(strNoun, #PARSELEN))
  
  If strPrev = #INVENTORY
    GG\ptrInventory\iCount - 1
  EndIf
  
  GU\iDirty + 1
EndProcedure

Procedure.i SpendCoin(iNumCoins.i = 1)
  Protected *ptrCoin, *ptrNoun.NOUN, fRC.i
  
  If InventoryHandler(#INVENTORYCHECK, "COIN") = #HASITEM
    GG\iCoins - iNumCoins
    
    If GG\iCoins < 0
      GG\iCoins + iNumCoins
      AddToOutput("You don't have enough gold, sorry.")
    Else
      If GG\iCoins = 0
        *ptrCoin = FindMapElement(Nouns(), "COIN")
        ChangeItemRoom("COIN", #ITEMGONE, #INVENTORY)
      EndIf
    
      fRC = #True
      GU\iDirty + 1
    EndIf
  Else
    AddToOutput("You're not carrying any coins right now. Your good looks are not paying the price.")
  EndIf
  
  ProcedureReturn fRC
EndProcedure

Procedure  DoTeleport(iRefreshDescription.i = #True)
  Protected strNewRoom.s, iRand.i
  
  Select GG\ptrRoom\strRoom
    Case "WOODS1", "WOODS2", "WOODS3", "WOODSBURIED", "WOODSTREE"
      If Random(10000) > 7500 ;25% chance
        strNewRoom = "WOODSBURIED"
      Else
        strNewRoom = "WOODS" + Chr(Asc("0") + Random(10000, 1) % 3 + 1)
      EndIf
      
      ChangeCurrentRoom(#NUL, #NUL, strNewRoom)
      
    Case "FAKEMAZE"
      ;this doesn't actually change room, just changes state to make it appear room has changed.
      RoomState(#STATESET, "FAKEMAZE", #NUL, #STATE0|#STATE1|#STATE2|#STATE3|#STATE4|#STATE5|#STATE6|#STATE7)
      
      iRand = Random(10000,1) % 7 + 1   ;number between 1 and 7 for #STATE1 - #STATE7
      GG\ptrRoom\iState | Int(Pow(2, iRand)) 
  EndSelect
  
  If iRefreshDescription
    ;force update room description because we could have been teleported to the SAME room and we need to display "new" room to the player
    AddRoomDescription(#True)
  EndIf

  GU\iDirty + 1
EndProcedure

;NSEW positions: 0=no,1=yes,2=locked,3=closed,5=blocked,6=teleport,7=hidden,8=unavailable,9=codehandler <--these numbers help us draw the map
Procedure TryMovePlayer(iDir.i)
  Protected strResult.s, x.i, y.i
  
  With GG
    If \fInTree
      AddToOutput(FormatString(HandleMessage("dirtree")))
    Else
      x = \ptrRoom\iRoomX
      y = \ptrRoom\iRoomY
      
      Select Mid(rgMove(x, y)\strAvail, iDir, 1)
        Case #DIRNOPE, #DIRCODE

          strResult = HandleMessage("noexit")
          
        Case #DIROK, #DIRCONFUSING
          Select iDir
            ;1=North, 2=South, 3=East, 4=West. rgMove is a string with directional availability state for each direction
            Case #NORTH
              If y
                y - 1
              EndIf
            Case #SOUTH
              If y < #ROOMY - 1
                y + 1
              EndIf
            Case #EAST
              If x < #ROOMX - 1
                x + 1
              EndIf
            Case #WEST
              If x
                x - 1
              EndIf
          EndSelect
          
          ChangeCurrentRoom(x, y)
          GU\iDirty + 1
          
        Case #DIRLOCKED
          ResetMap(\ptrRoom\mapNouns())
          
          While NextMapElement(\ptrRoom\mapNouns())
            If FindMapElement(Nouns(), MapKey(\ptrRoom\mapNouns()))  ;always search Nouns() with MapKey of mapNouns(), both #PARSELEN chars long
            
            ;Look for a lockable fixed noun in the room, and if found tell the user that noun is locked
            If FindString(Nouns()\strVerbs, _COMMAS("UNLOCK")) And Nouns()\iState & #SFIXED
              strResult = FormatString(HandleMessage("lockedexit"), LCase(Nouns()\strNoun))
              Break
            EndIf
            EndIf
          Wend
          
          ;no fixed, lockable noun found
          If strResult = ""
            strResult = _L(genericlockedexit)
          EndIf
          
        Case #DIRCLOSED
          strResult = "Sorry, it's closed."
        Case #DIRBLOCKED
          strResult = "I can't do that, it's blocked."
        Case #DIRTELEPORT
          DoTeleport()
        Case #DIRUNAVAILABLE
          strResult = "That way is not currently passable."
          
          Select GG\ptrRoom\strRoom
            Case "CLEARING", "ISLAND"
              strResult = "You will have to swim to go that way."
          EndSelect
      EndSelect
    EndIf
  EndWith
  
  If strResult <> ""
    AddToOutput(strResult)
  EndIf
EndProcedure

Procedure PrintDirections()
  Protected iCharWidth.i, i.i, strDir.s
  
  DrawingMode(#PB_2DDrawing_Transparent)
  DrawingFont(GU\hDirectionsFont)
  iCharWidth = TextWidth("W") * 1.5
  
  With GG\ptrRoom
  ;Print available directions - NSEW positions: 0=no,1=yes,2=locked,3=closed,5=blocked,6=teleport,9=codehandler 
    For i = 1 To 4   ;N,S,E,W
      Select Mid(rgMove(\iRoomX, \iRoomY)\strAvail, i, 1)
        Case #DIRNOPE, #DIRCODE
          FrontColor(#COLOR_DIRNOPE)
        Case #DIROK, #DIRTELEPORT, #DIRCONFUSING
          FrontColor(#COLOR_DIROK)
        Case #DIRLOCKED, #DIRCLOSED, #DIRBLOCKED, #DIRUNAVAILABLE
          FrontColor(#COLOR_DIRNOTREADY)
        Default
          Debug "Unrecognized move state: " + \strRoom
          FrontColor(#COLOR_DIRNOPE)
      EndSelect
      
      If \iState & #SDARK And Not GG\fLightSource
        FrontColor(#COLOR_DARK)
        strDir = "?"
      Else
        strDir = Mid(#DIRECTIONS, i, 1)
      EndIf
      
      DrawText(GU\iXDir + iCharWidth * i, GU\iYStartC, strDir)
      DrawText(GU\iXDir + 2 + iCharWidth * i, GU\iYStartC + 3, strDir)
    Next
  EndWith
EndProcedure  

;given a room/item state string, only print the sections that match state bits that are set
Procedure.s GetStateString(strIn.s, iState.i)
  Protected strNew.s, iStart.i, iEnd.i
  Protected strState.s, fApplies.i, fAllDone.i
   
  iStart = 1
  While Not fAllDone
    iStart = FindString(strIn, #START_DESC, iStart)
    
    If iStart
      iStart + 1
      
      strState = Mid(strIn, iStart, 1)
      Select strState
        Case #START_STATE
          If GG\ptrRoom\iState & #SDARK And Not GG\fLightSource      ;test for dark state with no light source
            fApplies = #True
          Else
            fApplies = #False
          EndIf
          
          fAllDone = fApplies
        Default
          fApplies = iState & Int(Pow(2, Val(strState)))    ;test state bit for value between [] in strIn
      EndSelect
      
      If fApplies
        iStart + 2
        iEnd = FindString(strIn, #START_DESC, iStart)
        
        If Not iEnd
          iEnd = Len(strIn) + 1
        EndIf
        
        strNew + Mid(strIn, iStart, iEnd - iStart)
      EndIf
    Else
      Break
    EndIf
  Wend
  
  ProcedureReturn strNew
EndProcedure

;Noun is either full noun or #PARSELEN (doesn't matter), verb is full word as specified via code that calls this procedure
;IF Noun = #ROOM_STATE, then this is a room state action, not a Noun state action
;Format of state action is [+/-] [state #] : [room], ex. "-5:ZARBURGSOUTHGATE"
;First parameter is verb that was applied, will read state action string for actions associated with that verb
;strNoun is #PARSELEN of found noun, or #PARSELEN of just what the user typed in
Procedure ChangeStateAction(strVerb.s, strNoun.s)
  Protected *ptrNoun.NOUN, *ptrRoom.ROOM
  Protected iState.i, i.i, j.i
  Protected iPos.i, iWhere.i, iItemState.i
  Protected iNotState.i = 0, iOnlyIfState.i = -1
  Protected strAction.s, strStateAction.s
  Protected strChange.s, strStateBit.s
  Dim rgActions.s(0)
  
  If strNoun = #ROOM_STATE
    strStateAction = GG\ptrRoom\strStateAction
  Else
    *ptrNoun = FindMapElement(Nouns(), Left(strNoun, #PARSELEN))
    strStateAction = Nouns()\strStateAction
  EndIf
  
  ;there can be multiple state actions per noun/room, process on at a time
  SplitString(strStateAction, ",", rgActions())
  
  For i = 0 To ArraySize(rgActions())
    strAction = rgActions(i)
    *ptrRoom = #NUL
    *ptrNoun = #NUL
    
    ;find the verb for this state action
    iPos = FindString(strAction, ":")
    If Left(strAction, iPos - 1) = strVerb
      iWhere = FindString(strAction, #ROOM_STATE)
      
      ;get pointer to the room or noun this action applies to
      If iWhere
        *ptrRoom = FindMapElement(Rooms(), Mid(strAction, iWhere + 1))
        *ptrNoun = 0
        
         iItemState = *ptrRoom\iState
      Else
        iWhere = FindString(strAction, #NOUN_STATE)
        
        ;if noun state indicator found for this saction
        If iWhere
          *ptrNoun = FindMapElement(Nouns(), Left(Mid(strAction, iWhere + 1), #PARSELEN))
          
          iItemState = *ptrNoun\iState
        ElseIf strNoun = #ROOM_STATE
          ;applies to the room where state action is declared
          *ptrRoom = GG\ptrRoom
          *ptrNoun = 0
          
          iItemState = *ptrRoom\iState
        Else
          ;applies to the noun where state action is declared
          *ptrNoun  = FindMapElement(Nouns(), Left(strNoun, #PARSELEN))
          
          iItemState = *ptrNoun\iState
        EndIf
      EndIf
      
      ;state modifiers start after colon. Ex: @BUY:-1+2
      iPos = FindString(strAction, ":") + 1
      
      ;reset restrictive state at start of line
      iNotState = 0
      iOnlyIfState.i = -1
      
      While #True
        ;get state modifier and state value
        strChange = Mid(strAction, iPos, 1)
        strStateBit = Mid(strAction, iPos + 1, 1)
        
        Select strStateBit
          Case "A"
            iState = #SAVAIL
          Case "F"
            iState = #SFIXED
          Case "D"
            iState = #SDROPPED
          Case "P"
            iState = #SPLAYERAWARE
          Default
            iState = Pow(2, Val(strStateBit))
        EndSelect
        
        ;if restrictive state flag found, apply it for rest of the line
        If strChange = #STATECHANGENOT
          iNotState = iState
          iOnlyIfState = -1
        ElseIf strChange = #STATECHANGEONLY
          iOnlyIfState = iState
          iNotState = 0
        EndIf
        
        If iItemState & iOnlyIfState And Not iItemState & iNotState
          If strChange = #STATECHANGESUBTRACT
            If *ptrRoom
              *ptrRoom\iState & ~(iState)
            Else
              *ptrNoun\iState & ~(iState)
            EndIf
          ElseIf strChange = #STATECHANGEADD
            If *ptrRoom
              *ptrRoom\iState | iState
            Else
              *ptrNoun\iState | iState
            EndIf
          EndIf
          
          GU\iDIrty + 1    ;state has changed
        EndIf
       
        ;point to next set for next pass through the loop
        iPos + 2
        
        ;if no more state modifiers on this line
        If Not FindString("!&+-", Mid(strAction, iPos, 1))
          Break
        EndIf
      Wend
    EndIf
  Next
  
  GU\iDirty + 1
EndProcedure

Procedure OnRoomEntry()
  Protected *ptrRoom.ROOM, *ptrMap.NOUN
  
  ChangeStateAction("ONENTRY", #ROOM_STATE)
  
  With GG\ptrRoom
    Select \strRoom
      Case "ELVENWOODS2"  ;open path from elvenwoods directly to elvenwoods2
        *ptrRoom = FindMapElement(Rooms(), "ELVENWOODS")
        ChangeAvailDirection(*ptrRoom\iRoomX, *ptrRoom\iRoomY, #SOUTH, #DIROK)
        
      Case "CLIFFPATH"  ;open path from Zarburg cliff directly to this cliff path
        *ptrRoom = FindMapElement(Rooms(), "ZARBURGCLIFF")
        ChangeAvailDirection(*ptrRoom\iRoomX, *ptrRoom\iRoomY, #SOUTH, #DIROK)
        
      Case "FAKEMAZE"
        If InventoryHandler(#INVENTORYCHECK, "MAP") = #HASITEM
          \iState = #STATE0
          ChangeAvailDirection(\iRoomX, \iRoomY, #SOUTH, #DIROK)
          ChangeAvailDirection(\iRoomX, \iRoomY, #WEST, #DIROK)
          ChangeAvailDirection(\iRoomX, \iRoomY, #EAST, #DIRNOPE)
        Else
          If ItemState(#STATEGET, "MAP") & #SDROPPED
            ;Wherever the map was dropped, bring it back to the room north of the maze
            *ptrMap = FindMapElement(Nouns(), "MAP")
            ChangeItemRoom("MAP", "PASSAGEWAY", *ptrMap\strRoom)
          EndIf
          
          GG\ptrRoom\iState = #STATE0
          ChangeAvailDirection(\iRoomX, \iRoomY, #SOUTH, #DIRTELEPORT)
          ChangeAvailDirection(\iRoomX, \iRoomY, #WEST, #DIRTELEPORT)
          ChangeAvailDirection(\iRoomX, \iRoomY, #EAST, #DIRTELEPORT)
          
          ;this doesn't actually change room, just changes state to make it appear room has changed.
          DoTeleport(#NOROOMREFRESH)
        EndIf
        
      Case "ARMORY"
        If RoomState(#STATEGET, "ARMORY") & #STATE1  ;if skeleton is in the room
          If InventoryHandler(#INVENTORYCHECK, "DAGGER") = #HASITEM
            RoomState(#STATESET, "ARMORY", #STATE2)  ;room description to dagger hum
            ItemState(#STATESET, "DAGGER", #STATE2)  ;make dagger hum
          Else
            RoomState(#STATESET, "ARMORY", #STATE3)  ;room description to wishing player had a weapon
          EndIf
        EndIf
        
      Case "RADIANTPOOL"
        If RoomState(#STATEGET, "RADIANTPOOL") & #STATE3  ;if prisoner opened gate
          ChangeAvailDirection(\iRoomX, \iRoomY, #WEST, #DIROK)
        EndIf
        
      Case "FOUNTAIN", "CORRIDOR", "PRINCE", "STONEGATE"
        ItemState(#STATESET, "DAGGER", #NUL, #STATE2 | #STATE3)  ;remove skeleton and lich hum from dagger
        
      Case "CRYPT"
        DoCryptOnEntry()
        
    EndSelect
  EndWith
  
  GU\iDirty + 1
EndProcedure

Procedure OnRoomPostEntry()
  Protected sTimer.EOTIMER
  
  ChangeStateAction("POSTENTRY", #ROOM_STATE)
  
  With GG\ptrRoom
    Select \strRoom
      Case "CRYPT" 
        DoCryptPostEntry()
    EndSelect
  EndWith
  
  GU\iDirty + 1
EndProcedure

Procedure AddRoomDescription(fForce.i)
  Protected str.s, fFoundAnItem
  
  With GG
    ;if explicit request or if user changed room since last call or if room toggled between light and dark
    If fForce Or \ptrRoom <> \ptrPrevRoom
      
      If \ptrRoom <> \ptrPrevRoom
        \ptrPrevRoom = \ptrRoom
        OnRoomEntry()
      EndIf
      
      ;if one time text exists for this room, print the text, a line full of underlines, and a newline
      If \ptrRoom\iState & #SONETIME
        AddToOutput(GetStateString(\ptrRoom\strOneTime, #STATE0))
        
        ;print a line of underlines the width of the output area
        AddToOutput(RSet("_", GU\iXWidth / TextWidth("_"), "_"))
        AddToOutput("^")
        
        \ptrRoom\strOneTime = ""
        \ptrRoom\iState & ~(#SONETIME)
      EndIf
      
      ResetMap(\ptrRoom\mapNouns())
      
      ;If it's not dark or if a light source i on
      If Not GG\ptrRoom\iState & #SDARK Or GG\fLightSource
        ;enumerate nouns found in this room
        While NextMapElement(\ptrRoom\mapNouns())
          FindMapElement(Nouns(), MapKey(\ptrRoom\mapNouns()))
          
          ;only "dropped" nouns are listed. Items already described in active state strings do not appear
          If Nouns()\iState & #SDROPPED
            If Not fFoundAnItem
              str = "The following items are here: "
              fFoundAnItem = #True
            EndIf
            
            str + LCase(Nouns()\strNoun) + ", "
          EndIf
        Wend
      EndIf
      
      AddToOutput(#ROOMOUTPUTINDICATOR + GetStateString(\ptrRoom\strDescription, \ptrRoom\iState) + " " + TrimDelimiters(Trim(str)))
      
      OnRoomPostEntry()
    EndIf
  EndWith 
EndProcedure

;if in woods and user tried look/exam/inspect woods, just print out the room description
;instead of giving a "woods not found" message
Procedure.i CheckForest()
  Protected fRC.i = #True
  
  Select GG\ptrRoom\strRoom
    Case "WOODS1", "WOODS2", "WOODS3", "FIRROOM", "FIRROOM2", "BIRCHROOM", "WOODSBURIED", "WOODSTREE", "ELVENWOODS", "ELVENWOODS2", "ELVENBARRICADE"
      AddRoomDescription(#True)
    Default
      fRC = #False
  EndSelect
  
  ProcedureReturn fRC
EndProcedure
; IDE Options = PureBasic 5.70 LTS beta 1 (Windows - x64)
; CursorPosition = 577
; FirstLine = 574
; Folding = ---
; Markers = 217
; EnableXP