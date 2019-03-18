Procedure.i IsNounAvailable(strNoun.s)
  Protected i.i, *ptrSearch.ROOM, fAvailable.i
  
  For i = 1 To 2
    If i = 1
      *ptrSearch = GG\ptrRoom
    Else
      *ptrSearch = GG\ptrInventory
    EndIf
        
    ;see if the noun is in this room or ininventory
    ResetMap(*ptrSearch\mapNouns())
  
    While NextMapElement(*ptrSearch\mapNouns())
      If strNoun = MapKey(*ptrSearch\mapNouns())
        fAvailable = #True
      EndIf
    Wend
    
    If fAvailable
      Break
    EndIf
  Next
  
  ;special case band around player's neck that's always available, not not in room or inventory
  If strNoun = "BAND"
    fAvailable = #True
  EndIf
  
  ProcedureReturn fAvailable
EndProcedure

;See if specified verb is a valid action for any nearby (in room or inventory) nouns
Procedure LookupApplicableNouns(strVerb.s, *sNoun.STRING)
  Protected iNumNouns.i, str.s, i.i, *ptrRoom.ROOM
  
  For i = 0 To 1
    Select i
      Case 0
        *ptrRoom = GG\ptrRoom
      Case 1
        *ptrRoom = GG\ptrInventory
    EndSelect
    
    ;If there are any nouns in this room/inventory
    ResetMap(*ptrRoom\mapNouns())
    
    While NextMapElement(*ptrRoom\mapNouns())
      FindMapElement(Nouns(), MapKey(*ptrRoom\mapNouns()))    ;search Nouns() by #PARSELEN chars, i.e.; mapkey of mapNouns()
      
      ;verb lists are stored as full words in each noun record
      If FindString(Nouns()\strVerbs, _COMMAS(strVerb))
        
        ;as always, player can only interact with items she knows about
        If Nouns()\iState & #SPLAYERAWARE  
          *sNoun\s = Nouns()\strNoun
          iNumNouns + 1
        EndIf
      EndIf
    Wend
  Next
    
  ProcedureReturn iNumNouns
EndProcedure

;noun and verb are passed in as full words. noun is full word from found Nouns(), or what user typed
Procedure HandleValidCommand(strNoun.s, strVerb.s)
  Protected strFullNoun.s, strVerbIn.s, fHandled.i = #True
  
  strFullNoun = strNoun
  strVerbIn = strVerb
  
  ;typically, dispatch happens with 4 letter (maximum) nouns and verbs
  strNoun = Left(strNoun, #PARSELEN)
  strVerb = Left(strVerb, #PARSELEN)
  
  Select strVerb
    Case "GET", "TAKE", "GRAB"
      GetHandler(strFullNoun)
    Case "DROP"
      DropHandler(strFullNoun)
    Case "EXAM", "LOOK", "INSP", "L"  ;inspect
      If CheckDarkAction()
        ExamineHandler(strFullNoun)
      EndIf
    Case "SAVE"
      SaveGame(strFullNoun)
    Case "LOAD"
      LoadGame(strFullNoun)
    Default  
      If IsNounAvailable(strNoun)    
        ;items can be done in the light or the dark
        Select strNoun
          Case "TORC"   ;torch
            TorchHandler(strVerb)
          Default
            fHandled = #False
        EndSelect
        
        ;if we have light
        If Not fHandled And CheckDarkAction()
          Select strNoun
            Case "OAK", "BIRC", "FIR"  ;birch
              fHandled = TreeHandler(strVerbIn, strFullNoun)
            Case "MAIN"  ;main gate
              fHandled = MainGateHandler(strVerb, strNoun)
            Case "WATC"  ;watchman
              fHandled = WatchmanHandler(strVerb, strNoun)
            Case "MEAL"  ;mealbar
              fHandled = MealbarHandler(strVerb, strNoun)
            Case "MERC"  ;merchant
              fHandled = MerchantHandler(strVerb, strNoun)
            Case "TRAY" 
              fHandled = TrayHandler(strVerb, strNoun)
            Case "COIN"
              fHandled = CoinHandler(strVerb, strNoun)
            Case "STAC"  ;stack
              fHandled = StackHandler(strVerb, strNoun)
            Case "CLIF"  ;cliff
              fHandled = CliffHandler(strVerb, strNoun)
            Case "RAT"
              fHandled = RatHandler(strVerb, strNoun)
            Case "SIGN"
              fHandled = SignHandler(strVerb, strNoun)
            Case "DEFE"  ;Defender
              fHandled = DefenderHandler(strVerb, strNoun)
            Case "SENT"  ;Sentinel
              fHandled = SentinelHandler(strVerb, strNoun)
            Case "THRO"  ;Throne
              fHandled = ThroneHandler(strVerb, strNoun)
            Case "QUEU"  ;Queue
              fHandled = PetitionerQueueHandler(strVerb, strNoun)
            Case "KING"
              fHandled = KingHandler(strVerb, strNoun)
            Case "CLER"  ;clerk
              fHandled = ClerkHandler(strVerb, strNoun)
            Case "NOTE" 
              fHandled = NoteHandler(strVerb, strNoun)
            Case "BARM"  ;barmaid
              fHandled = BarmaidHandler(strVerb, strNoun)
            Case "TAVD"  ;tavdoor = tavern door
              fHandled = TavernDoorHandler(strVerb, strNoun)
            Case "DROW"
              fHandled = DrowHandler(strVerb, strNoun) 
            Case "MAP"
              fHandled = MapHandler(strVerb, strNoun)
            Case "DAGG"  ;dagger
              fHandled = DaggerHandler(strVerb, strNoun)
            Case "BAND"
              fHandled = BandHandler(strVerb, strNoun)
            Case "TENT"
              fHandled = TentHandler(strVerb, strNoun)
            Case "SYMB"  ;symbols
              fHandled = SymbolsHandler(strVerb, strNoun)
            Case "BARR"  ;barricade
              fHandled = BarricadeHandler(strVerb, strNoun)
            Case "DAMB"  ;Damben guards
              fHandled = DambenHandler(strVerb, strNoun)
            Case "BOTT"  ;bottle
              fHandled = BottleHandler(strVerb, strNoun)
            Case "POTI"  ;potion
              fHandled = PotionHandler(strVerb, strNoun)
            Case "BEER"
              fHandled = BeerHandler(strVerb, strNoun)
            Case "TABL"  ;table
              fHandled = TableHandler(strverb, strNoun)
            Case "BENC"  ;bench
              fHandled = BenchHandler(strVerb, strNoun)
            Case "BUIL"  ;building
              fHandled = BuildingHandler(strVerb, strNoun)
            Case "VILL"  ;villagers
              fHandled = VillagersHandler(strVerb, strNoun)
            Case "CHIE"  ;chieftain
              fHandled = ChieftainHandler(strVerb, strNoun)
            Case "ELDE"  ;elder
              fHandled = EldersHandler(strVerb, strNoun)
            Case "BRAC"  ;bracelet
              fHandled = BraceletHandler(strVerb, strNoun)
            Case "ROPE"
              fHandled = RopeHandler(strVerb, strNoun)
            Case "CHAS"  ;chasm
              fHandled = ChasmHandler(strVerb, strNoun)
            Case "STUM"  ;stump
              fHandled = StumpHandler(strVerb, strNoun)
            Case "MEAD"  ;meadow
              fHandled = MeadowHandler(strVerb, strNoun)
            Case "FLOW"  ;flower
              fHandled = FlowerHandler(strVerb, strNoun)
            Case "MUSH"  ;mushroom
              fHandled = MushroomHandler(strVerb, strNoun)
            Case "GRAS"  ;grass
              fHandled = GrassHandler(strVerb, strNoun)
            Case "BOX"  ;box
              fHandled = BoxHandler(strVerb, strNoun)
            Case "RIVE"  ;river
              fHandled = RiverHandler(strVerb, strNoun)
            Case "KEY"
              fHandled = KeyHandler(strVerb, strNoun)
            Case "PORT"  ;portcullis
              fHandled = PortcullisHandler(strVerb, strNoun)
            Case "POND"
              fHandled = PondHandler(strVerb, strNoun)
            Case "FISH"
              fHandled = FishHandler(strVerb, strNoun)
            Case "POLE"
              fHandled = PoleHandler(strVerb, strNoun)
            Case "HOOK"
              fHandled = HookHandler(strVerb, strNoun)
            Case "DRAG"  ;dragonling
              fHandled = DragonlingHandler(strVerb, strNoun)
            Case "CELL"  ;cell door
              fHandled = CellDoorHandler(strVerb, strNoun)
            Case "SKEL"  ;skeleton
              fHandled = SkeletonHandler(strVerb, strNoun)
            Case "RACK" 
              fHandled = RackHandler(strVerb, strNoun)
            Case "FOUN"  ;fountain
              fHandled = FountainHandler(strVerb, strNoun)
            Case "PRIS"  ;prisoner
              fHandled = PrisonerHandler(strVerb, strNoun)
            Case "POOL"  ;fountain
              fHandled = PoolHandler(strVerb, strNoun)
            Case "GRAN"  ;granite gate
              fHandled = GraniteGateHandler(strVerb, strNoun)
            Case "LICH"
              fHandled = LichHandler(strVerb, strNoun)
            Case "SARC"
              fHandled = SarcophagusHandler(strVerb, strNoun)
            Case "BUTT"  ;button
              fHandled = ButtonHandler(strVerb, strNoun)
            Case "OPEN"  ;opening
              fHandled = OpeningHandler(strVerb, strNoun)
            Default
              fHandled = #True
              AddToOutput(HandleMessage("nounverberr"))
          EndSelect
        EndIf
        
        ;not handled by noun handler, special case here, and then one default case for "sorry, i don't know how to do that."
        If Not fHandled
          Select strVerb
            Case "BURN"
              AddToOutput("I can't just let you go burning down everything in sight, sorry.")
            Case "CHOP"
              AddToOutput("You throw a fierce karate chop, but nothing is damaged except your hand.")
            Case "READ"
              AddToOutput("You can't read that.")
            Default
              AddToOutput(HandleMessage("cannotdo"))
          EndSelect
        EndIf
      Else
        AddToOutPut("There is no " + LCase(strFullNoun) + " available here.")
      EndIf
  EndSelect
EndProcedure

;noun and verb are passed in as full words. noun is full word from found Nouns(), or what user typed
Procedure HandleBadWord(strWord.s)
  AddToOutput(FormatString(HandleMessage("badword"), LCase(strWord)))
EndProcedure

;noun and verb are passed in as full words. noun is full word from found Nouns(), or what user typed
Procedure HandleVerbNounTooMany(strNouns.s, strVerbs.s)
  AddToOutput(HandleMessage("toomanynv"))
EndProcedure

;noun and verb are passed in as full words. noun is full word from found Nouns(), or what user typed
Procedure HandleTooManyNouns(strNouns.s)
  AddToOutput(HandleMessage("toomanyn"))
EndProcedure

;noun and verb are passed in as full words. noun is full word from found Nouns(), or what user typed
Procedure HandleTooManyVerbs(strVerbs.s)
  Dim rgVerbs.s(0)
  Protected sNoun.STRING, strWord.s, fRC.i = #False, i.i
  Protected strDir.s, fGo.i
  
  ;special case the command combinations CLIMB UP and CLIMB DOWN to prevent "too many verbs" error
  If strVerbs = "CLIMB,UP" 
    strDir = "UP"
    fGo = #True
  ElseIf strVerbs = "CLIMB,DOWN"
    strDir = "DOWN"
    fGo = #True
  Else
    SplitString(strVerbs, ",", rgVerbs())
    
    For i = 0 To ArraySize(rgVerbs())
      strWord = rgVerbs(i)
      
      Select strWord
        Case "UP", "DOWN"
          strDir = strWord
          
        Case "GO"
          fGo = #True
      EndSelect
  
      If LookupApplicableNouns(strWord, @sNoun) = 1
        Select strWord
          Case "CLIMB"
            ClimbHandler("CLIM", sNoun\s)
            fRc = #True
        EndSelect
        
        Break
      Else
        
      EndIf
    Next
  EndIf
  
  If fGo And strDir <> ""
    ClimbHandler(strDir, "")
  ElseIf Not fRC
    AddToOutput("It sounds like there are too many things you want to do. Sorry, I'm not sure how to help.")
  EndIf
EndProcedure

;noun and verb are passed in as full words. noun is full word from found Nouns(), or what user typed
Procedure HandleInvalidInput(strCommand.s, strNoun.s, strVerb.s)
  AddToOutput(FormatString(HandleMessage("dontknow"), strCommand.s, Chr(34)))
EndProcedure

;noun and verb are passed in as full words. noun is full word from found Nouns(), or what user typed
Procedure HandleNoValidVerb(strVerb.s, strNoun.s)
  If GG\ptrRoom\strRoom = "FISHPOND" And strNoun = "FISH"
    FishHandler("CATC", "FISH")  ;catch
  Else
    AddToOutput(HandleMessage("noverb"))
  EndIf
EndProcedure

;noun and verb are passed in as full words. noun is full word from found Nouns(), or what user typed
Procedure HandleNoValidNoun(strVerb.s, strNoun.s)
  Protected sNoun.STRING, iCount.i, fHandled.i = #True
  
  Select Left(strVerb, #PARSELEN)
    Case "GET", "TAKE", "GRAB"
      If Not GG\ptrRoom\iState & #SDARK Or GG\fLightSource
        AddToOutput(FormatString(HandleMessage("badget"), LCase(strNoun)))
      Else
        AddToOutput("It's too dark to find anything.")
      EndIf
    Case "DROP"
      If strNoun = "COINS"    ;workaround for drop multiple coins
        DropHandler("COIN")
      Else
        AddToOutput(FormatString(HandleMessage("baddrop"), LCase(strNoun)))
      EndIf
    Case "SAVE"
      SaveGame(strNoun)
    Case "LOAD"
      LoadGame(strNoun)
    Default
      If CheckDarkAction()
        Select Left(strVerb, #PARSELEN)
          Case "EXAM", "INSP", "LOOK"  ;examine, inspect
            If Not CheckForest()
              AddToOutput("I can't find " + AorAnorAny(strNoun) + " " + LCase(strNoun) + " to examine.")
            EndIf
            
          Case "CLIM", "DESC"  ;climb, descend
            If strNoun = "UP" Or strNoun = "DOWN"
              ClimbHandler(strNoun, "")
            Else
              fHandled = #False
            EndIf
            
          Default
            fHandled = #False
        EndSelect
      EndIf
  EndSelect

  If Not fHandled
    AddToOutput("I haven't seen " + AorAnorAny(strNoun) + " " + LCase(strNoun) + " around here.")
  EndIf
EndProcedure

;full always found noun is passed in, noun to use returned in *strNoun\s
Procedure ResolveUnattached(*strNoun.STRING)
  With *strNoun
    Select \s
      Case "TREE"
        Select GG\ptrRoom\strRoom
          Case "ZARBURGSOUTHGATE", "OAKROOM"
            \s = "OAK"
          Case "WOODSBURIED", "BIRCHROOM"
            \s = "BIRCH"
          Case "WOODSTREE", "FIRROOM", "FIRROOM2"
            \s = "FIR"
          Case "WOODS3"
            \s = "PINE"
        EndSelect
        
      Case "WOOD"
        If GG\ptrRoom\strRoom = "ZARBURGSOUTHGATE"
          \s = "STACK"
        EndIf
        
      Case "HOLE"
        Select GG\ptrRoom\strRoom
          Case "ELVENTOWNHALL"
            \s = "OPENING"
          Case "CELLAR"
            \s = "PEEPHOLE"
        EndSelect
        
      Case "WATER"
        Select GG\ptrRoom\strRoom
          Case "FOUNTAIN"
            \s = "FOUNTAIN"
          Case "POND"
            \s = "POND"
          Case "RADIANTPOOL"
            \s = "POOL"
        EndSelect
        
      Case "DOOR"
        Select GG\ptrRoom\strRoom
          Case "ZARBURGINN"
            \s = "TAVDOOR"
          Case "HALLWAY2"
            \s = "CELLDOOR"
        EndSelect
        
      Case "ROCK"
        Select GG\ptrRoom\strRoom
          Case "CLEARING"
            \s = "STONE"
          Case "DRAGONLING"
            \s = "IGNEOUS"
        EndSelect
        
      Case "GATE"
        Select GG\ptrRoom\strRoom
          Case "ZARBURGSOUTHGATE"
            \s = "MAINGATE"
          Case "PASSAGEWAY"
            \s = "PORTCULLIS"
          Case "RADIANTPOOL"
            \s = "GRANITEGATE"
        EndSelect
        
      Case "GUARDS"
        Select GG\ptrRoom\strRoom
          Case "ZARBURGTHRONEROOM"
            \s = "DEFENDER"
          Case "ZARBURGTREASURY"
            \s = "SENTINEL"
          Case "ELVENBARRICADE"
            \s = "DAMBEN"
        EndSelect
            
      Case "ELF", "ELVES"
        Select GG\ptrRoom\strRoom
          Case "ZARBURGINN"
            If \s = "ELF"
              \s = "DROW"
            EndIf
          Case "ELVENBARRICADE"
            \s = "DAMBEN"
          Case "ELVENVILLAGE"
            \s = "VILLAGERS"
        EndSelect
    EndSelect
  EndWith
EndProcedure

Procedure.s TimerCommand(*sTIMER.EOTIMER = #NUL)
  Protected iElasped.i, strElapsed.s, strMetadata.s
  Protected *ptrTImer.EOTIMER
  
  ;we can update existing timer or create a new one
  If *sTIMER
    *ptrTimer = FindMapElement(GG\Timers(), *sTimer\strEvent)
    
    If Not *ptrTImer
      *ptrTimer = AddMapElement(GG\Timers(), *sTimer\strEvent)
    EndIf
    
    ;don't need to set \strEvent in Map, it's just used for the MapKeys
    With *ptrTimer
      \strEvent = *sTimer\strEvent
      \iType = *sTimer\iType
      \strMetadata = *sTimer\strMetadata
      
      Select \iType
        Case #TIMERMILLISECONDS
          \iStart = ElapsedMilliseconds()
          \iTime = *sTimer\iTime
        Case #TIMERCOMMANDS
          \iStart = GG\iNumCommands
          \iCount= *sTimer\iCount
        Case #TIMERROOM
          \strRoom = *sTimer\strRoom
      EndSelect
    EndWith
  Else
    iElasped  = ElapsedMilliseconds()
    
    ;Look for an expired timer
    ResetMap(GG\Timers())
    While NextMapElement(GG\Timers())
      With GG\Timers()
        strMetadata = \strMetadata
        
        Select \iType
          Case #TIMERMILLISECONDS
            If iElasped - \iStart >= \iTime
              strElapsed = \strEvent
              Break
            EndIf
          Case #TIMERCOMMANDS
            If GG\iNumCommands - \iStart >= \iCount
              strElapsed = \strEvent
              Break
            EndIf
          Case #TIMERROOM
            If \strRoom = GG\ptrRoom\strRoom    ;we're now in the correct room
              strElapsed = \strEvent
            EndIf
        EndSelect
      EndWith
    Wend
  
    If strElapsed <> ""
      DeleteMapElement(GG\Timers(), strElapsed)
      
      If strMetadata <> ""
        strElapsed + "," + strMetadata
      EndIf
    EndIf
  EndIf
  
  ProcedureReturn strElapsed  
EndProcedure
; IDE Options = PureBasic 5.70 LTS (Windows - x64)
; CursorPosition = 231
; FirstLine = 205
; Folding = ---
; EnableXP