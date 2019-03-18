#DROPBACKPACK = 1
#GETBACKPACK = 2
#GETINVSTRING = "LIST"

Declare LookupApplicableNouns(strVerb.s, *sNoun.STRING)
Declare.s TimerCommand(*sTIMER.EOTIMER = #NUL)
Declare GetHandler(strNoun.s)
  
;display inventory contents, check inventory, or change count of items in inventory. strNoun, when supplied, is always full noun
Procedure.s InventoryHandler(iMode.i, strNoun.s = "")
  Protected str.s, iHowMany.i, iStateSet.i, iStateUnset.i
  
  strNoun = UCase(strNoun)
  
  With GG\ptrInventory
    Select iMode
      Case #INVENTORYADD
        AddMapElement(GG\ptrInventory\mapNouns(), Left(strNoun, #PARSELEN))  ;always #PARSELEN for mapkey
        GG\ptrInventory\mapNouns() = strNoun       ;always full noun for map value
        \iCount + 1 
        
        FindMapElement(Nouns(), Left(strNoun, #PARSELEN))
        Nouns()\strRoom = #INVENTORY
        
        ;item added to inventory is automatically made playeraware and available, if not already
        ItemState(#STATESET, strNoun, #SPLAYERAWARE | #SAVAIL)
  
      Case #INVENTORYDROP
        DeleteMapElement(GG\ptrInventory\mapNouns(), Left(strNoun, #PARSELEN))
        \iCount - 1
        
      Case #INVENTORYDISPLAY
        str = HandleMessage("inventory")
        ResetMap(\mapNouns())
        
        While NextMapElement(\mapNouns())
          FindMapElement(Nouns(), MapKey(\mapNouns()))  ;always search Nouns() with #PARSELEN chars, i.e; mapkey of mapNouns()
          
          ;don't include backpack in list of items inside backpack!
          If Nouns()\strNoun <> "BACKPACK" Or strNoun = ""
            str + " " 
            
            If Nouns()\strNoun = "COIN"
              str + Str(GG\iCoins) + " "
            EndIf
            
            str + LCase(Nouns()\strNoun)
            If Nouns()\strNoun = "COIN" And GG\iCoins > 1
              str + "s"
            EndIf
            str + ","
            
            iHowMany + 1
          EndIf
        Wend
        
        If iHowMany = 0
          str = "You aren't carrying anything."
        EndIf
        
      Case #INVENTORYCHECK
        If FindMapElement(GG\ptrInventory\mapNouns(), Left(strNoun, #PARSELEN))
          str = #HASITEM
        Else
          str = #NOTHASITEM
        EndIf
    EndSelect
    
    If \iCount = 0
      iStateSet = #STATE1
      iStateUnset = #STATE2 | #STATE3 | #STATE4
    ElseIf \iCount = #MAXINVENTORY
      iStateSet = #STATE4
      iStateUnset = #STATE1 | #STATE2 | #STATE3
    ElseIf \iCount > #MAXINVENTORY / 2
      iStateSet = #STATE3
      iStateUnset = #STATE1 | #STATE2 | #STATE4
    Else
      iStateSet = #STATE2
      iStateUnset = #STATE1 | #STATE3 | #STATE4
    EndIf
    
    ItemState(#STATESET, "BACKPACK", iStateSet, iStateUnset)
  EndWith
  
  str = TrimDelimiters(str)
  If strNoun <> #GETINVSTRING And iMode <> #INVENTORYCHECK
    AddToOutput(str)
  EndIf

  ProcedureReturn str
EndProcedure

;noun is full word of found noun, or just what user typed as second word
Procedure ExamineHandler(strNoun.s)
  Protected str.s, *ptrNoun.NOUN, fItemIsHere.i
  
  *ptrNoun = FindMapElement(Nouns(), Left(strNoun, #PARSELEN))
  
  If *ptrNoun
    If *ptrNoun\strRoom <> #INVENTORY 
      If *ptrNoun\iState & #SPLAYERAWARE
        strNoun = *ptrNoun\strNoun
      EndIf
      
      Select *ptrNoun\strNoun
        Case "BAND", "BRACELET"
          fItemIsHere = #True
        Default
          ResetMap(GG\ptrRoom\mapNouns())
          
          While NextMapElement(GG\ptrRoom\mapNouns())
            If  *ptrNoun\strNoun = GG\ptrRoom\mapNouns()
              fItemIsHere = #True
              Break
            EndIf
          Wend
      EndSelect
    Else
      fItemIsHere = #True
    EndIf
  EndIf
  
  If fItemIsHere
    If Not GG\fHaveBackpack And strNoun = "BACKPACK"
      str = "Your backpack lies on the ground. You'll have to pick it up to see what's in it."
    Else
      
      str = GetStateString(*ptrNoun\strDescription, *ptrNoun\iState)
      
      If strNoun = "BACKPACK"
        str + " " + InventoryHandler(#INVENTORYDISPLAY, #GETINVSTRING) + "."
      EndIf
    EndIf
  Else 
    str = "I don't see " + AorAnorAny(strNoun) + " " + LCase(strNoun) + "."
  EndIf
  
  AddToOutput(str)
EndProcedure

;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure TorchHandler(strVerb.s)
  Protected str.s, iState.i
  
  If FindString("LIGH,BURN", strVerb)
    If Not GG\fLightSource
      If  GG\ptrTorch\strRoom = #INVENTORY
        If GG\iTorchBurnTime > 0
          GG\fLightSource = #True
        
          ;Make player aware of any objects in the room, since they couldn't see them before
          MakePlayerAware()
          
          str = "* The torch is now burning"
          If GG\fLightPermanent
            str + " (and glowing)"
          EndIf
          
          str + "."
          
          If GG\ptrRoom\iState & #SDARK     ;if room wasn't already dark, no need to describe room again
            AddRoomDescription(#True)
          EndIf
          
          ;change torch description
          CheckTorch(0)
          
          GU\iDirty + 1
        Else
          str = "* The torch is used up. You'll have to find a way to make its light last."
        EndIf
      Else
        str = "You must be carrying the torch to light it."
      EndIf
    Else
      str = "The torch burns on, oblivious to your extraneous lighting attempt."
    EndIf
  EndIf
  
  If FindString("SNUF,EXTI,UNLI,DROP", strVerb)
    If GG\fLightSource
      GG\fLightSource = #False
      
      ;change torch description
      CheckTorch(0)
      
      str = "* The torch goes out"
      If GG\ptrRoom\iState & #SDARK
        str + " and you're plunged into darkness!"
      Else
        str + "."
      EndIf
      
      If GG\iTorchBurnTime = 0
        str + " The torch is used up. You'll have to find a way to make its light last."
      EndIf
      
      GU\iDirty + 1
    Else
      If strVerb <> "DROP"
        str = "The torch is unable to not burn less than it already is."
      EndIf
    EndIf
  EndIf
  
  AddToOutput(str)
EndProcedure

#CHASMTOP = 1
#CHASMBOTTOM = 2
#CHASMNOPE = 3
;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure.i RopeHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True, nChasm.i, str.s, iState.i
  
  iState = ItemState(#STATEGET, "ROPE")
  
  Select GG\ptrRoom\strRoom
    Case "DEEPCHASM"
      nChasm = #CHASMTOP
    Case "MEADOW"
      nChasm = #CHASMBOTTOM
    Default
      nChasm = #CHASMNOPE
  EndSelect
    
  Select strVerb
    Case "TIE", "USE", "FAST"  ;fasten
      If nChasm = #CHASMTOP
        If iState & #STATE1  ;rope tied around stump
          str = "You double check the rope. It's definitely fastened securely to the stump."
        Else
          str = "You expertly tie one end of the rope to the stump and drop the other end into the chasm."
          ChangeItemRoom("ROPE", "DEEPCHASM", #INVENTORY)
          ChangeStateAction("TIE", "ROPE")
        EndIf
      Else
        fRc = #False
      EndIf
      
    Case "UNTI", "UNFA", "REMO"  ;untie, unfasten, remove
      If nChasm = #CHASMTOP
        If iState & #STATE1  ;rope tied around stump
          str = "You pull the rope up to the top of the chasm and then untie it from the stump."
          ChangeStateAction("UNTIE", "ROPE")
        Else
          str = "The rope isn't tied to anything. But you perform a fancy rope trick!"
        EndIf
      Else
        fRC = #False
      EndIf
        
    Case "GO", "CLIM", "DESC", "ASCE", "UP", "DOWN"  ;climb, descend, ascend
      If nChasm = #CHASMTOP
        If strVerb = "ASCE" Or strVerb = "UP" ;ascend
          str = "You're already at the top."
        ElseIf iState & #STATE1  ;rope tied around stump
          str = "* You climb down the rope to a broad meadow far below.^"
          
          ChangeStateAction("DESCEND", "ROPE")        
          ChangeItemRoom("ROPE", "MEADOW", "DEEPCHASM")
          ChangeCurrentRoom(#NUL, #NUL, "MEADOW")
        Else
          str = "You'll need to use a rope or something."
        EndIf
      ElseIf nChasm = #CHASMBOTTOM
        If strVerb = "DESC" Or strVerb = "DOWN" ;descend
          str = "You're already at the bottom."
        Else
          str = "* You climb back up the rope to the edge of the chasm.^"
          
          ChangeStateAction("CLIMB", "ROPE")
          ChangeItemRoom("ROPE", "DEEPCHASM", "MEADOW")
          ChangeCurrentRoom(#NUL, #NUL, "DEEPCHASM")
        EndIf
      Else
        fRC = #False
      EndIf
      
    Default
      fRC = #False
  EndSelect
  
  AddToOutput(str)
  
  ProcedureReturn fRC
EndProcedure

;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure.i StumpHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True, nChasm.i, str.s, fRopeAvailable.i

  fRopeAvailable = Bool(InventoryHandler(#INVENTORYCHECK, "ROPE") = #HASITEM)
  If Not fRopeAvailable
    fRopeAvailable = FindMapElement(GG\ptrRoom\mapNouns(), "ROPE")
  EndIf
  
  Select strVerb
    Case "TIE", "FAST"  ;fasten
      If fRopeAvailable
        fRC = RopeHandler(strVerb, strNoun)  ;use same actions for rope, as they are intertwined with stump
      Else
        str = "You don't have a rope."
      EndIf
      
    Case "UNTI", "UNFA"  ;untie, unfasten
      If fRopeAvailable
        fRC = RopeHandler(strVerb, strNoun)  ;use same actions for rope, as they are intertwined with stump
      Else
        str = "There's nothing tied to the stump."
      EndIf
      
    Case "REMOVE", "DIG"
      str = "The stump isn't going anywhere, no matter how hard you try."
        
    Case "KICK"
      str = "OUCH! Don't do that!"
      
    Default
      fRC = #False
  EndSelect
  
  AddToOutput(str)
  
  ProcedureReturn fRC
EndProcedure

;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure.i MeadowHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #False
  
  Select strVerb
    Case "CLIM", "ASCE", "UP"  ;climb, ascend
      fRC = RopeHandler("ASCE", "ROPE")
  EndSelect
  
  ProcedureReturn fRC
EndProcedure

;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure.i FlowerHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True
  
  Select strVerb
    Case "PICK", "GATH"  ;gather
      AddToOutput("The flowers here are so beautiful. Let's just leave them alone.")
      
    Case "SMEL"  ;smell
      AddToOutput("Each flower seems to smell even better than the last. It's like a meadow full of freshly-baked cookies!")
      
    Default
      fRC = #False
  EndSelect
  
  ProcedureReturn fRC
EndProcedure

;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure.i GrassHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True
  
  Select strVerb
    Case "MOW", "CUT"
      AddToOutput("Whirr! Whirr! You stroll about the clearning pretending to mow the pretty grass. It's adorable.")
      
    Case "SMEL"  ;smell
      AddToOutput("Seriously, does anything smell better than freshly cut grass? But this uncut grass smells pretty good too.")
      
    Case "SMOK"  ;smoke
      AddToOutput("Maybe you should do that on your own time! No judgement.")
      
    Case "BURN", "LIGH"  ;light
      AddToOutput("The grass does not burn.")
      
    Default
      fRC = #False
  EndSelect
  
  ProcedureReturn fRC
EndProcedure

;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure.i RiverHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True
  
  Select strVerb
    Case "DRIN"   ;drink
      AddToOutput("The water doesn't taste great, but you drink some anyway. Bleghhh!")
      
    Case "SWIM"
      If GG\ptrRoom\strRoom = "CLEARING"
        AddToOutput("* You swim northward and soon step out of the water onto the island.^^")
        
        ItemState(#STATESET, "RIVER", #STATE1, #STATE0)  ;describe river from island
        ChangeItemRoom("RIVER", "ISLAND", "CLEARING")
        ChangeCurrentRoom(#NUL, #NUL, "ISLAND")
        
        GG\fLightSource = #False
        CheckTorch(GU\iDirty)
     Else
        AddToOutput("* As you jump in the water, the current takes you swiftly southward toward the clearing.^^")
        
        ItemState(#STATESET, "RIVER", #STATE0, #STATE1)  ;describe river from clearing
        ChangeItemRoom("RIVER", "CLEARING", "ISLAND")
        ChangeCurrentRoom(#NUL, #NUL, "CLEARING")
        
        GG\fLightSource = #False
        CheckTorch(GU\iDirty)
      EndIf
    Default
      fRC = #False
  EndSelect
  
  ProcedureReturn fRC
EndProcedure

;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure.i BoxHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True, str.s
  
  Select strVerb
    Case "LIFT"
      str = "The box is far too heavy to lift."
      
    Case "BREA", "SMAS"  ;break, smash
      If ItemState(#STATEGET, "BOX") & #STATE1   ;box not open
        If InventoryHandler(#INVENTORYCHECK, "STONE") = #HASITEM
         str = "You smash the stone cover with the stone, revealing a key inside. The rock itself crumbles to bits."
         ChangeItemRoom("STONE", #ITEMGONE, #INVENTORY)
         ChangeStateAction("BREAK", "BOX")
       Else
         str = "Break the box with what? You'll need something solid."
       EndIf
     Else
       str = "The box is already open, there's no need to smash it anymore."
     EndIf
     
   Case "UNLO", "PICK", "OPEN"  ;unlock
     str = "You need a very special key to unlock this box. I'm not sure where you'd find one. Consider a more brute force approach."
     
   Case "CLOS", "SHUT"  ;close, shut
     str = "The box is permanently stuck open now that you've broken in."
     
   Default
     fRC = #False
  EndSelect
  
  AddToOutput(str)
  
  ProcedureReturn fRC       
EndProcedure

;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure.i KeyHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True
  
  Select strVerb
    Case "USE", "TURN"
      Select GG\ptrRoom\strRoom
        Case "PASSAGEWAY"
          If ItemState(#STATEGET, "PORTCULLIS") & #STATE1  ;currently down and locked
            AddToOutput("The iron key fits the portcullis lock perfectly! The gate slowly rises into the ceiling, giving you time to snatch the key out of the lock.")
            ChangeStateAction("USEPORT", "KEY")
            ChangeAvailDirection(GG\ptrRoom\iRoomX, GG\ptrRoom\iRoomY, #SOUTH, #DIROK)
          Else
            AddToOutput("The portcullis is raised up. There is no keyhole available here.")
          EndIf
          
        Case "HALLWAY2"
          If Not ItemState(#STATEGET, "CELLDOOR") & #STATE7  ;cell door is still locked
            AddToOutput("You turn the iron key in the rusty lock of the prison cell and it swings open, latching to the wall. You won't be able to close the door now.")
            ChangeStateAction("USECELL", "KEY")
            ChangeAvailDirection(GG\ptrRoom\iRoomX, GG\ptrRoom\iRoomY, #WEST, #DIROK)
          Else
            AddToOutput("The cell is already unlocked!")
          EndIf
          
        Default
          AddToOutput("The iron key doesn't help with anything here.")
      EndSelect
      
    Default
      fRC = #False
  EndSelect
  
  ProcedureReturn fRC
EndProcedure

;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure.i PortcullisHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True, str.s
  
  Select strVerb
    Case "UNLO"  ;unlock
      If InventoryHandler(#INVENTORYCHECK, "KEY") = #HASITEM
        fRC = KeyHandler("USE", "KEY")
      Else
        str = "You can't unlock the portcullis without a key."
      EndIf
      
    Case "BREA", "FORC", "SMAS", "KICK" ;break, force, smash, kick
      str = "Imagine a flea trying to break down a castle wall. You hurt yourself, but the portcullis remains locked."
      
    Case "LIFT"
      str = "You strain mightily, but the heavy grating doesn't move."
      
    Case "CLIM"  ;climb
      str = "The portcullius goes from floor to ceiling. You can climb on it, but not over it."
      
    Case "OPEN"
      str = "The portcullis is locked."
      
    Default
      fRC = #False
  EndSelect
  
  AddToOutput(str)
  
  ProcedureReturn fRC
EndProcedure

;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure.i CellDoorHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True
  
  Select strVerb
    Case "UNLO"  ;unlock
      fRC = KeyHandler("USE", "KEY")
      
    Case "OPEN"
      AddToOutput("The prison cell door is locked.")
      
    Default
      fRC = #False
  EndSelect
  
  ProcedureReturn fRC
EndProcedure

;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure.i RackHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True
  
  Select strVerb
    Case "KICK", "BREA", "SMAS"
      AddToOutput("You hurt youself, but the rack is undamaged.")
      
    Case "TIP", "MOVE"
      AddToOutput("The rack can't be moved.")
      
    Default
      fRC = #False
  EndSelect
  
  ProcedureReturn fRC
EndProcedure

;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure.i SkeletonHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True, sTimer.EOTIMER
  
  Select strVerb
    Case "FIGH", "ATTA", "KILL"  ;fight, attack, kill
      If Not ItemState(#STATEGET, "BRACELET") & #STATE7
        AddToOutput("The skeleton overpowers you and you are quickly dead. Without an elven ward, battles against the undead are usually impossible.")
        
        GU\fGray = #True
        GU\fPauseInput = #True
  
        sTimer\strEvent = "SKELETONDEATH"
        sTimer\iType = #TIMERMILLISECONDS
        sTimer\iTime = 5000
        sTimer\iStart = ElapsedMilliseconds()
        
        TimerCommand(@sTimer)
      ElseIf InventoryHandler(#INVENTORYCHECK, "DAGGER") = #HASITEM
        AddToOutput("You attack the skeleton with your dagger. With a single hit, the skeleton disintegrates! The dagger darkens and stops humming.")
        
        ChangeStateAction("FIGHT", "SKELETON")
        ChangeItemRoom("SKELETON", #ITEMGONE, "ARMORY")
      Else
        AddToOutput("You have nothing to attack the skeleton with. Stay away!")
      EndIf
      
    Default
      fRC = #False
  EndSelect
  
  ProcedureReturn fRC
EndProcedure

;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure DaggerHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True
  
  Select strVerb
    Case "USE", "FIGH", "ATTA", "KILL"  ;fight, attack
      Select GG\ptrRoom\strRoom
        Case "CRYPT"
          fRC = LichHandler("FIGH", "LICH")
          
        Case "ARMORY"
          If RoomState(#STATEGET, "ARMORY") & #STATE1   ;skeleton is in room
            fRC = SkeletonHandler("FIGH", "SKEL")       ;fight skeleton
          EndIf
          
        Case "ISLAND"
          If strVerb = "USE"
            If ItemState(#STATEGET, "BOX") & #STATE2   ;box already open
              AddToOutput("You don't need the dagger; the box is already open.")
            Else
              AddToOutput("The dagger doesn't help you open the box. You might need to break in.")
            EndIf
          Else
            fRC = #False
          EndIf
          
        Case "PASSAGEWAY"
          If strVerb = "USE"
            If ItemState(#STATEGET, "PORT") & #STATE1    ;portcullis up
              AddToOutput("The portcullis is already open. You put the dagger away.")
            Else
              AddToOutput("The dagger doesn't unlock the portcullis. I think you'll need a key.")
            EndIf
          Else
            fRC = #False
          EndIf
          
        Default
          AddToOutput("The dagger is too worn down, it's of no use... here.")
      EndSelect
      
    Default
      fRC = #False
  EndSelect

  ProcedureReturn fRC
EndProcedure

;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure.i ButtonHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True
  
  Select strVerb
    Case "PUSH", "PRES", "USE"  ;press
      If Not ItemState(#STATEGET, "BUTTON") & #STATE7
        AddToOutput("You push the button and a small doorway appears in the north wall of the crypt!")
        
        ChangeStateAction("PUSH", "BUTTON")
        ChangeAvailDirection(GG\ptrRoom\iRoomX, GG\ptrRoom\iRoomY, #NORTH, #DIROK)
      Else
        AddToOutput("Pushing the button again has no effect.")
      EndIf
      
    Default
      fRC = #False
  EndSelect
  
  ProcedureReturn fRC
EndProcedure

;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure.i SarcophagusHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True
  
  Select strVerb
    Case "SEAR"  ;search
      If ItemState(#STATEGET, "LICH") & #STATE7  ;if lich is dead
        AddToOutput("You find a tiny button on one side!")
        ChangeStateAction("SEARCH", "SARCOPHAGUS")
      Else
        AddToOutput("The lich doesn't allow you near the sarcophagus.")
      EndIf
      
    Default
      fRC = #False
  EndSelect
  
  ProcedureReturn fRC
EndProcedure

;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure.i PoolHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True
  
  Select strVerb
    Case "SWIM", "JUMP"
      AddToOutput("You swim in the pool for a while and everything gets wet!")
      GG\fLightSource = #False
      
    Case "DRIN"  ;drink
      AddToOutput("The water tastes sweet, but is very warm")
      
    Case "SPLA"  ;splash
      AddToOutput("You splash a little water around the edges of the pool. It's fun, but that's really it.")
      
    Default
      fRC = #False
  EndSelect
  
  ProcedureReturn fRC
EndProcedure

;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure.i PondHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True
  
  Select strVerb
    Case "SWIM", "JUMP"
      AddToOutput("The water repels you forcefully and prevents you from entering the pond!")
    Default
      fRC = #False
  EndSelect
  
  ProcedureReturn fRC
EndProcedure

;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure.i FishHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True, str.s
  
  Select strVerb
    Case "CATC"  ;catch
      If InventoryHandler(#INVENTORYCHECK, "POLE") = #NOTHASITEM
        str = "You try to catch a fish with your hands, but you can't even touch the water!"
      ElseIf Not ItemState(#STATEGET, "POLE") & #STATE1
        str = "You drop your line into the water, but no fish seems interested. Did you bring any bait?"
      Else
        str = "As soon as your line touches the water, a fish attacks the hook and is caught! "
          
        If GG\fHaveBackpack And GG\ptrInventory\iCount < #MAXINVENTORY
          str + "You remove the fish from the hook but in the excitement, you drop the pole into the pool and it is lost to you."
          
          ChangeItemRoom("POLE", "FISHPOND", #INVENTORY)
          ChangeStateAction("CATCH", "FISH")
          InventoryHandler(#INVENTORYADD, "FISH")
        Else
          str + "You have no "
          
          If Not GG\fHaveBackpack
            str + "place"
          Else
            str + "room"
          EndIf
          
          str + " to keep the fish, so you release it from the hook and it escapes back into the pond. Check your backpack."
          ChangeStateAction("EMPTY", "HOOK")  ;remove bait from hook
        EndIf
      EndIf
      
    Case "EAT"
      str = "Um, yuck. This isn't sushi, it's a slimy, raw whole fish."
      
    Case "GIVE"
      If Not GG\ptrRoom\strRoom = "DRAGONLING"
        str = "Nobody wants the fish."
      Else
        str = "Dragonlings prefer to catch their food while it's moving!"
      EndIf
      
    Case "KISS"
      str = "You kiss the fish. Years and years hence, people you meet will sense that you are strange, "
      str + "not fully understanding the very moment when you committed to it."
      
    Case "FEED"
      str = "Dragonlings love fish. And they love to hunt."
      
    Case "SPEA", "TALK"
      str = Chr(34) + "Here fishy, fishy!" + Chr(34) + ". You're out of luck, the fish is dead."
      
    Case "THRO", "TOSS"  ;throw
      If Not GG\ptrRoom\strRoom = "DRAGONLING"
        str = "You throw the fish a short distance and it hits the ground with a dull thud."
        
        ChangeItemRoom("FISH", GG\ptrRoom\strRoom, #INVENTORY)
        ItemState(#STATESET, "FISH", #SDROPPED)
      Else
        str = "You throw the fish into the room and the dragonling flits from his perch to go get it. He ignores you and proceeds to eat."
        
        ChangeItemRoom("FISH", GG\ptrRoom\strRoom, #INVENTORY)
        ChangeStateAction("THROW", "FISH")
      EndIf        
    Default
      fRC = #False
  EndSelect
  
  AddToOutput(str)
  
  ProcedureReturn fRC
EndProcedure
 
;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure.i DragonlingHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True, str.s, sTimer.EOTIMER
  
  Select strVerb
    Case "KILL", "ATTA", "FIGH", "POKE"  ;attack, fight
      str = "A jet of molten fire encompasses you, searing your flesh as you die in a burst of deep, red pain. The flashing color of the band about your next blends with the burning crimson."
      GU\fGray = #True
      GU\fPauseInput = #True

      sTimer\strEvent = "DRAGONFIRE"
      sTimer\iType = #TIMERMILLISECONDS
      sTimer\iTime = 5000
      sTimer\iStart = ElapsedMilliseconds()
      
      TimerCommand(@sTimer)
      
    Case "SCRE"  ;scream
      str = "The dragonling screams right back at you, albeit more like a boisterous meow."
      
    Case "TALK", "SPEA"  ;speak
      str = "The dragonling gives you a curious look and chitters back. There's no use trying to communicate."
      
    Default
      fRC = #False
  EndSelect
  
  AddToOutput(str)
  
  ProcedureReturn fRC
EndProcedure


;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure.i HookHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True
  
  Select strVerb
    Case "BAIT"
      If InventoryHandler(#INVENTORYCHECK, "POLE") = #HASITEM
        If InventoryHandler(#INVENTORYCHECK, "MUSHROOM") = #HASITEM
          AddToOutput("You break off a small piece of mushroom and place it on the fishing pole's hook. Fish will love the smell!")
          ChangeStateAction("BAIT", "HOOK")
        Else
          AddToOutput("You need something to bait the hook with. Perhaps something fragrant?")
        EndIf
      Else
        AddToOutput("You need something that you can apply bait to. Hmmmmm.")
      EndIf
            
    Default
      fRC = #False
  EndSelect
  
  ProcedureReturn fRC
EndProcedure

;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure.i PoleHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True
  
  Select strVerb
    Case "BAIT"
      fRC = HookHandler("BAIT", "HOOK")
      
    Case "USE"
      If GG\ptrRoom\strRoom = "FISHPOND"
        fRC = FishHandler("CATC", "FISH")  ;catch
      Else
        AddToOutput("You can't use the pole here.")
      EndIf
      
    Default
      fRC = #False
  EndSelect
  
  ProcedureReturn fRC
EndProcedure

;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure.i FountainHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True
  
  Select strVerb
    Case "DRIN"  ;drink
      AddToOutput("The water tastes sweet.")
      
    Case "SPLA"  ;splash
      AddToOutput("You splash a little water around but quickly get bored.")
      
    Case "JUMP"
      AddToOutput("You jump into the fountain and splash awhile. Wee!")
      
    Case "SWIM"
      AddToOutput("The water is too shallow to swim in.")
      
    Default
      fRC = #False
  EndSelect
  
  ProcedureReturn fRC
EndProcedure

;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure.i GraniteGateHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True
  
  Select strVerb
    Case "OPEN", "MOVE"
      AddToOutput("Futile.")
      
    Case "UNLO"  ;unlock
      AddToOutput("There is no visible unlocking mechanism.")
      
    Case "BREA"  ;break
      AddToOutput("You'll break your body if you try to break this impenetrable gate.")
      
    Default
      fRC = #False
  EndSelect
  
  ProcedureReturn fRC
EndProcedure

;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure.i PrisonerHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True, iState.i, str.s
  
  iState = ItemState(#STATEGET, "PRISONER")
  
  Select strVerb
    Case "TALK", "SPEA"  ;speak
      If Not iState & #STATE7  ;haven't spoken to prisoner yet
        If Not iState & #STATE6  ;haven't already fed prisoner
          str = Chr(34) + "Please," + Chr(34) + " he forces a whisper, " + Chr(34) + "Food." + Chr(34)
        Else
          str = Chr(34) + "What a wondrous gift that was, my hunger is fully gone! In exchange, I have something to tell you." + Chr(34)
          ItemState(#STATESET, "PRISONER", #STATE7)
        EndIf
      Else
        str = Chr(34) + "An evil lich imprisoned me. If you see it, you will need to be warded, and have an everlasting light, an enchanted weapon, and a royal artifact to defeat it. "
        str + "Sally forth, adventurer, and may you explore safely!" + Chr(34) + " The prisoner dashes out of the cell, securing his freedom."
        
        RoomState(#STATESET, "PRISONCELL2", #NUL, #STATE1)
        ChangeItemRoom("PRISONER", "RADIANTPOOL", "PRISONCELL2")
      EndIf
      
    Case "FEED"
      If InventoryHandler(#INVENTORYCHECK, "MEALBAR") = #HASITEM
        str = "You hand the prisoner your mealbar and he devours it voraciously! He then invites you to speak."
        
        ChangeItemRoom("MEALBAR", #ITEMGONE, #INVENTORY)
        ItemState(#STATESET, "PRISONER", #STATE6)
        ChangeStateAction("FEED", "PRISONER")
      ElseIf Not iState & #STATE6
        str = "Would that you had something to feed the prisoner. Some type of meal, perhaps?"
      Else
        str = "You already gave the prisoner your mealbar."
      EndIf
      
    Case "RELE", "FREE"  ;release
      If RoomState(#STATEGET, "PRISONCELL2") & #STATE1  ;prisoner is still in cell
        str = "The cell door is open. The prisoner can leave when he wants."
      Else
        str = "The prisoner is no longer here."
      EndIf
      
    Case "FIGH", "ATTA", "KILL"  ;fight, attack    
      str = "He's defenseless, broken, harmless. I shan't allow it. Be nicer."
      
    Case "SWIM"
      AddToOutput("The water is too shallow to swim in.")
      
    Case "DRIN"  ;drink
      AddToOutput("The water tastes sweet.")
      
    Case "SPLA"  ;splash
      AddToOutput("You splash a little water around but quickly get bored.")
      
    Default
      fRC = #False
  EndSelect
  
  AddToOutput(str)
  
  ProcedureReturn fRC
EndProcedure

;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure.i MushroomHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True
  
  Select strVerb
    Case "PICK"
      GetHandler("MUSHROOM")
      
    Case "USE", "BAIT"
      If InventoryHandler(#INVENTORYCHECK, "POLE") = #HASITEM
        fRC = PoleHandler("BAIT", "HOOK")
      Else
        AddToOutput("You don't have anything that I know how to use this with.")
      EndIf
      
    Case "EAT"
      AddToOutput("Yuck! This mushroom doesn't look edible at all. But it's very beautiful.")
      
    Case "SMEL"  ;smell
      AddToOutput("Oh my goodness! What is that heavenly smell? Wow!")

    Default
      fRC = #False
  EndSelect
  
  ProcedureReturn fRC
EndProcedure

;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure.i ChasmHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True
  
  Static iTries = 0
  Protected sTimer.EOTIMER
  
  Select strVerb
    Case "JUMP", "LEAP"
      If iTries % 2
        AddToOutput("Holy cow! You jump into the chasm and rapidly enjoy the view before crashing to the ground. And dying. Dying a lot.")
    
        GU\fGray = #True
        GU\fPauseInput = #True
  
        sTimer\strEvent = "JUMPCHASM"
        sTimer\iType = #TIMERMILLISECONDS
        sTimer\iTime = 5000
        sTimer\iStart = ElapsedMilliseconds()
        
        TimerCommand(@sTimer)
      Else
        AddToOutput("It's too far down. You'd probably kill yourself.")
      EndIf
      
      iTries + 1
      
    Case "DESC", "DOWN"  ;descend
      fRC = RopeHandler("DESC", "ROPE")
      
    Case "CLIM", "ASCE", "UP"  ;climb, ascend
      fRC = RopeHandler("ASCE", "ROPE")
      
    Default
      fRC = #False
  EndSelect
  
  ProcedureReturn fRC
EndProcedure

Procedure ClimbHandler(strVerb.s, strNoun.s)
  Protected sNoun.STRING, fWrongNoun.i
  Protected *ptrRoom.ROOM
  
  Select strNoun
    Case ""
      LookupApplicableNouns(strVerb, @sNoun)
      strNoun = sNoun\s
      
    Case "CLIFF"
      strVerb = "DOWN"
  EndSelect
  
  Select Left(strVerb, #PARSELEN)
    Case "UP"
      Select GG\ptrRoom\strRoom
        Case "ZARBURGSOUTHGATE"
          If strNoun = "OAK"
            If ItemState(#STATEGET, "OAK") & #STATE0   ;normal state, not chopped down
              ChangeCurrentRoom(#NUL, #NUL, "OAKROOM")
              ChangeItemRoom("OAK", "OAKROOM", "ZARBURGSOUTHGATE")
              GG\fInTree = #True
            Else
              AddToOutput("You climb all over the felled oak, getting nothing from it but a few scrapes and some serious itching.")
            EndIf
          Else
            fWrongNoun = #True
          EndIf
          
        Case "WOODSBURIED"
          If strNoun = "BIRCH"
            ChangeCurrentRoom(#NUL, #NUL, "BIRCHROOM")
            ChangeItemRoom("BIRCH", "BIRCHROOM", "WOODSBURIED")
            GG\fInTree = #True
          Else
            fWrongNoun = #True
          EndIf
          
        Case "WOODSTREE"
          If strNoun = "FIR"
            ChangeCurrentRoom(#NUL, #NUL, "FIRROOM")
            ChangeItemRoom("FIR", "FIRROOM", "WOODSTREE")
            GG\fInTree = #True
          Else
            fWrongNoun = #True
          EndIf
          
        Case "FIRROOM"
          If strNoun = "FIR"
            ChangeCurrentRoom(#NUL, #NUL, "FIRROOM2")
            ChangeItemRoom("FIR", "FIRROOM2", "FIRROOM")
            GG\fInTree = #True
            
            ;southern path leading out of forest is no longer a teleport square; it's a valid direction
            *ptrRoom = FindMapElement(Rooms(), "WOODS3")
            ChangeAvailDirection(*ptrRoom\iRoomX, *ptrRoom\iRoomY, #SOUTH, #DIROK)
            *ptrRoom\iState | #STATE1  ;add a trail leading south
            
            ;change south from WOODSTREE to unavailable, so going south no longer teleports player within woods
            *ptrRoom = FindMapElement(Rooms(), "WOODSTREE")
            ChangeAvailDirection(*ptrRoom\iRoomX, *ptrRoom\iRoomY, #SOUTH, #DIRBLOCKED)
            *ptrRoom\iState | #STATE1  ;show that the path to the south is blocked
          Else
            fWrongNoun = #True
          EndIf
          
        Case "OAKROOM", "BIRCHROOM", "FIRROOM2"
          AddToOutput("You can't climb any higher.")
          
        Case "ZARBURGCLIFF"
          If strNoun = "CLIFF"
            AddToOutput("It's too wet and slippery to climb. You can't even get started.")
          Else
            fWrongNoun = #True
          EndIf
          
        Case "DEEPCHASM", "MEADOW"
          If strNoun = "CHASM" Or strNoun = "ROPE"
            ChasmHandler(strVerb, "CHASM")
          EndIf
          
        Default
          AddToOutput("There is nothing here to climb up.")
      EndSelect
      
    Case "DOWN"
      Select GG\ptrRoom\strRoom
        Case "OAKROOM"
          If strNoun = "OAK"
            ChangeCurrentRoom(#NUL, #NUL, "ZARBURGSOUTHGATE")
            ChangeItemRoom("OAK", "ZARBURGSOUTHGATE", "OAKROOM")
            GG\fInTree = #False
          Else
            fWrongNoun = #True
          EndIf
          
        Case "BIRCHROOM"
          If strNoun = "BIRCH"
            ChangeCurrentRoom(#NUL, #NUL, "WOODSBURIED")
            ChangeItemRoom("BIRCH", "WOODSBURIED", "BIRCHROOM")
            GG\fInTree = #False
          Else
            fWrongNoun = #True
          EndIf
          
        Case "FIRROOM"
          If strNoun = "FIR"
            ChangeCurrentRoom(#NUL, #NUL, "WOODSTREE")
            ChangeItemRoom("FIR", "WOODSTREE", "FIRROOM")
            GG\fInTree = #False
          Else
            fWrongNoun = #True
          EndIf
          
        Case "FIRROOM2"
          If strNoun = "FIR"
            ChangeCurrentRoom(#NUL, #NUL, "FIRROOM")
            ChangeItemRoom("FIR", "FIRROOM", "FIRROOM2")
          Else
            fWrongNoun = #True
          EndIf
          
        Case "ZARBURGSOUTHGATE", "WOODSBURIED", "WOODSTREE"
          AddToOutput("You're unable to climb down from the ground!")
          
        Case "ZARBURGCLIFF"
          If strNoun = "CLIFF"
            AddToOutput("It's too wet and slippery to climb. You can't even get started.")
          Else
            fWrongNoun = #True
          EndIf
          
        Case "DEEPCHASM", "MEADOW"
          If strNoun = "CHASM" Or strNoun = "ROPE"
            ChasmHandler(strVerb, "CHASM")
          EndIf
          
        Default
          AddToOutput("There is nothing here to climb down.")
       EndSelect
   EndSelect
   
   If fWrongNoun
     AddToOutput("I can't figure out how to climb " + LCase(strNoun) + ".")
   EndIf
EndProcedure

Procedure PackHandler(iMode.i)
  Protected *ptrPack.ROOM, *temp.ROOM
  
  *ptrPack = FindMapElement(Rooms(), #TEMPSTORAGE)
  *temp = GG\ptrInventory
  
  ResetMap(*ptrPack\mapNouns())
  ResetMap(GG\ptrInventory\mapNouns())
  
  If iMode = #DROPBACKPACK
    With GG\ptrInventory
      
      ;transfer each item in inventory into the #TEMPSTORAGE room
      While NextMapElement(\mapNouns())
        
        ;if dropping the backpack, user can still carry the torch
        If \mapNouns() <> "TORCH"
          AddMapElement(*ptrPack\mapNouns(), MapKey(\mapNouns()))  ;#PARSELEN for map
          *ptrPack\mapNouns() = \mapNouns()                        ;full name foe value
          
          ;set room of base noun to show that it's in the temp storage room
          FindMapElement(Nouns(), MapKey(\mapNouns()))
          Nouns()\strRoom = #TEMPSTORAGE
          
          DeleteMapElement(\mapNouns())
          \iCount - 1
        EndIf
      Wend
    EndWith
  Else
    With *ptrPack
      
      ;transfer items from temp storage back into inventory
      While NextMapElement(*ptrPack\mapNouns())
        AddMapElement(GG\ptrInventory\mapNouns(), MapKey(\mapNouns()))
        GG\ptrInventory\mapNouns() = \mapNouns()

        ;set room of base noun to show that it's in the temp backpack room
        FindMapElement(Nouns(), MapKey(\mapNouns()))
        Nouns()\strRoom = #INVENTORY
        
        DeleteMapElement(*ptrPack\mapNouns())
        GG\ptrInventory\iCount + 1
      Wend
    EndWith
  EndIf
EndProcedure

;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure.i BottleHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True
  
  Select strVerb 
    Case "DIG", "SEAR"  ;search
      AddToOutput("You dig around the bottle with your hands and uncover a dark green potion.")
      ChangeStateAction("DIG", "BOTTLE")
      
    Default
      fRC = #False
  EndSelect
  
  ProcedureReturn fRC
EndProcedure

;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure.i PotionHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True, str.s, iState.i
  
  Select strVerb 
    Case "DRIN", "IMBI", "QUAF", "SIP"  ;drink, imbibe, quaff
      If Not GG\ptrRoom\strRoom = "CRYPT"
        AddToOutput("You've suffered no substantial damage so drinking it now won't do you any good. Let's save it for later.")
      ElseIf ItemState(#STATEGET, "LICH") & #STATE5
        AddToOutput("You quaff the potion and you are fully recovered! Now, defeat the evil lich.")
        ItemState(#STATESET, "POTION", #STATE7, #NUL)
      Else
        AddToOutput("It's not time yet! Soon. You must defeat the lich!")
      EndIf

    Default
      fRC = #False
  EndSelect
  
  ProcedureReturn fRC
EndProcedure


;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure.i PetitionerQueueHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True, str.s, iState.i
  
  Select strVerb 
    Case "ENTE"  ;enter
      AddToOutput("You're in the queue. You're the only one in the queue. You're number one!")
    Case "LEAV"  ;leave
      AddToOutput("You step out of the queue but, effectively, the entire room is the queue since there's no one else in line. So, move to and fro as you wish, but try as you might you'll remain in the queue!")
    Default
      fRC = #False
  EndSelect
  
  ProcedureReturn fRC
EndProcedure

;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure.i ThroneHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True, str.s, iState.i
  
  iState = ItemState(#STATEGET, "THRONE")
  
  Select strVerb 
    Case "SIT" 
      If Not iState & #STATE7   ;Eldred sitting there
        AddToOutput(Chr(34) + "Ho-ho-ho...ld on! Let me stand up, please." + Chr(34) + " Eldred is very patient today.")
        ChangeStateAction("SIT", "THRONE")
      ElseIf Not iState & #STATE6  ;sat on throne before
        AddToOutput("It's super comfy. The guards ever so gently throw you to the floor as a peaceful reminder to not do that.")
        ItemState(#STATESET, "THRONE", #STATE6)
      ElseIf Not iState & #STATE5  ;sat on throne twice
        AddToOutput("Before you're able to settle in, a massive Defender pulls you away, clunks you upside the head, and stands in front of the throne.")
        ItemState(#STATESET, "THRONE", #STATE5)
      ElseIf Not iState & #STATE4  ;sat on throne 3 times
        AddToOutput("The Defender won't let you. Not this time nor on any subsequent attempt.")
        ItemState(#STATESET, "THRONE", #STATE4)
      Else
        AddToOutput("Nope.")
      EndIf
    Default
      fRC = #False
  EndSelect
  
  ProcedureReturn fRC
EndProcedure

;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure.i KingHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True, str.s, iState.i
  Protected sTimer.EOTIMER
  
  iState = ItemState(#STATEGET, "KING")
  
  Select strVerb 
    Case "HONO", "RESP"  ;honor, respect
      str = "How do you wish to honor the king? Perhaps a gesture?"

    Case "KNEE", "GENU", "BOW"  ;kneel, genuflect
      If InventoryHandler(#INVENTORYCHECK, "TORCH") = #HASITEM And Not iState & #STATE7  ;haven't already kneeled
        str = "Eldred motions you over and waves his hand around your torch in a strange pattern. " + Chr(34) + "May the true light ever shine about you"
        
        If iState & #STATE1
          str + "," + Chr(34) + " he mutters begrudgingly."
        Else
          str + "." + Chr(34) 
        EndIf
        
        str + " The Defenders then nudge you away"
        If iState & #STATE1
          str + ", quite forcefully"
        EndIf
        
        str + "."
        ItemState(#STATESET, "KING", #STATE7)
        
        ;make torch burn without limit
        ItemState(#STATESET, "TORCH", #NUL, #STATE5)
        GG\fLightPermanent = #True
        GG\iTorchBurnTime = #TORCHTURNS
        
      ElseIf iState & #STATE1  ;Eldred is angry
        str = "Eldred glares at you and does not accept your courtesy."
      Else
        str = "Eldred favors you with a benevolent glance."
      EndIf
      
      If Not GG\fLightPermanent
        str + " He will bless your light."
      EndIf
      
    Case "TALK", "SPEA"  ;speak
      If ItemState(#STATEGET, "LICH") & #STATE7  ;lich is dead
        str = Chr(34) + "You found my precious son! I am beyond joy. Brave, brave adventurer. Please take these 10,000 gold coins and live in peace in my kingdom forever!" + Chr(34) 
        str + "^^>>> YOU HAVE WON THE GAME, CONGRATULATIONS! <<< -- please continue to explore or QUIT the game when ready. Thank you for playing."
        
        GG\iCoins + 10000
      ElseIf Not iState & #STATE6   ;haven't spoken to Eldred yet
        str = Chr(34) + "Have you seen my son, the prince? He's been missing for days and I'm quite worried." + Chr(34)
        ItemState(#STATESET, "KING", #STATE6)
      ElseIf Not iState & #STATE5  ;haven't spoken to Eldred twice yet or don't have note
        str = Chr(34) + "You look very brave. Please find my son and you'll be rewarded. Visit the clerk and the armory for help on your journey." + Chr(34) 
        
        If GG\fHaveBackpack
          If GG\ptrInventory\iCount < #MAXINVENTORY
            str + " Eldred gives you a note for the Royal Clerk."
        
            ItemState(#STATESET, "KING", #STATE5)
            InventoryHandler(#INVENTORYADD, "NOTE")
          Else
            str + " Eldred attempts to give you a note, but your backpack is full. You'll need to drop something first."
          EndIf
        Else
          str + " Eldred wants to give you a note, but you'll need your backpack in order to carry it."
        EndIf
      Else
        str = Chr(34) + "Please be on your way quickly. I must have my son back!" + Chr(34)
      EndIf
      
    Case "FIGH", "ATTA", "KILL"  ;fight, attack
      str = "You rush to attack the king. A black-clad Defender springs from behind the throne and stabs you through the heart in one motion. The band on your neck pulses a deep red through a spreading black haze as you die."
      
      GU\fGray = #True
      GU\fPauseInput = #True

      sTimer\strEvent = "FIGHTKING"
      sTimer\iType = #TIMERMILLISECONDS
      sTimer\iTime = 5000
      sTimer\iStart = ElapsedMilliseconds()
      
      TimerCommand(@sTimer)

      ChangeStateAction("FIGHT", "KING")
      
    Default
      fRC = #False
  EndSelect
  
  AddToOutput(str)
  
  ProcedureReturn fRC
EndProcedure

;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure.i BarricadeHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True, str.s, iState.i
  Protected sTimer.EOTIMER
  
  iState = ItemState(#STATEGET, "BARRICADE")
  
  Select strVerb
    Case "BURN"
      If GG\fLightSource
        str = "The flames dance over the surface of the barricade, but the wood does not burn. The two Damben laugh delightedly. " + Chr(34) + "Enchanted elven wood will not burn without magic, fool!" + Chr(34)
      Else
        str = "You have no fire to burn it with."
      EndIf
      
    Case "BREA", "REMO", "DEST", "DISM"  ;break, remove, destroy, dismantle
      str = "The barricade is impervious to your pummeling. Every time you attack, it feels like it's hitting back! You soon wear out, a bit beaten and bruised. " + Chr(34) + "Hahaha! Nothing gets into our village without permission, scoundrel." + Chr(34)
      
    Case "CLIM"  ;climb
      str = "The barrier actively rejects your attempt to climb and throws you back several feet! The guards laugh and laugh."
      
    Case "OPEN", "UNLO", "GO"  ;open, unlock
      str = "There is no way you can open the barricade. Maybe the Damben can help?"
      
    Default
      fRC = #False
  EndSelect
  
  AddToOutput(str)
  
  ProcedureReturn fRC
EndProcedure

;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure.i DambenHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True, str.s, iState.i
  Protected sTimer.EOTIMER
  
  iState = ItemState(#STATEGET, "DAMBEN")
  
  Select strVerb 
    Case "TALK"  ;enter
      If Not iState & #STATE7  ;haven't talked to guard
        str = "One of the guards "
        If iState & #STATE2
          str + "growls"
        Else
          str + "drawls"
        EndIf
        
        str + " " + Chr(34) + "One each." + Chr(34)
        ItemState(#STATESET, "DAMBEN", #STATE7)
      ElseIf Not iState & #STATE6
        str = Chr(34) + "To pass. One each." + Chr(34)
        ItemState(#STATESET, "DAMBEN", #STATE6)
      Else
        str = "The tallest Damben winks at you"
        If iState & #STATE2
          str + ", in a disconcertingly angry fashion,"
        EndIf
        str + " and says "+ Chr(34) + "gold is good." + Chr(34)
      EndIf
      
    Case "FIGH", "KILL", "ATTA"  ;fight, attack
      If Not iState & #STATE2    ;haven't fought Damben before
        str = "Both guards fire their bows at you, faster than anything you've ever seen. You are pinned to a tree, but unharmed."
        
        ChangeStateAction("FIGHT", "DAMBEN")
        sTimer\strEvent = "FIGHTDAMBEN1"
        sTimer\iTime = 2000
      Else
        str = "Two arrows pierce you in nearly the same spot between your eyes. The band around your neck flashes the same color as the blood coloring your eyes, and the last words you hear are " + Chr(34) + "Too bad. Could have used the gold." + Chr(34)
        sTimer\strEvent = "FIGHTDAMBEN2"
        sTimer\iTime = 5000
      EndIf        

      GU\fGray = #True
      GU\fPauseInput = #True
  
      sTimer\iType = #TIMERMILLISECONDS
      sTimer\iStart = ElapsedMilliseconds()
    
      TimerCommand(@sTimer)

    Case "BRIB", "PAY"           ;bribe
      If iState & #STATE5        ;have already bribed Damben
        str = "The barricade is already open. You remain free to pass."
        If Not iState & #STATE3
          str + " Have a really great journey!"
        EndIf
      Else
        If GG\iCoins > 1   ;do we have sufficient coins
          SpendCoin(2)
          
          str = Chr(34) + "Oh, no, we really shouldn't. It's quite against the law of our village to accept bribes." + Chr(34) + " The guard takes two gold coins from your hand. " + Chr(34) + "We'll dampen our great feelings of guilt with this gold!" + Chr(34)
          str + " The Damben waves his hands in an intricate pattern and soon the barricade slides open, allowing passage to the west."
          
          ChangeStateAction("BRIBE", "DAMBEN")

          ;barricade is now open, allowing passage
          ChangeAvailDirection(GG\ptrRoom\iRoomX, GG\ptrRoom\iRoomY, #WEST, #DIROK)
          
        Else
          str = Chr(34) + "One each. You don't have enough gold. Come back later if you're able to find some." + Chr(34)
        EndIf
      EndIf
      
    Default
      fRC = #False
  EndSelect
  
  AddToOutput(str)
  
  ProcedureReturn fRC
EndProcedure


;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure BandHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True
  
  Select strVerb
    Case "REMO"  ;remove
      AddToOutput("The band is fastened securely around your neck. You can't remove it.")
      
    Default
      fRC = #False
  EndSelect

  ProcedureReturn fRC
EndProcedure

;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure BraceletHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True
  
  Select strVerb
    Case "REMO"  ;remove
      AddToOutput("The bracelet traces a deep amber circle about your left wrist. It looks like it is a part of you, there is no way to remove it.")
      
    Default
      fRC = #False
  EndSelect

  ProcedureReturn fRC
EndProcedure

;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure.i ClerkHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True, str.s, iState.i, fTrouble.i
  Protected sTimer.EOTIMER, *ptrCoin.NOUN
  
  iState = ItemState(#STATEGET, "CLERK")
  
  Select strVerb 
    Case "ROB"
      If iState & #STATE7  ;already tried to rob
        str = Chr(34) + "Sighhhh. Guards!" + Chr(34) + " Within an instant, a Sentinel slices your hand off. You pass out from the pain and crack your skull as you hit the floor. The band about your neck pulses red in harmony with the pool of blood that was once inside you. Death has come."
        fTrouble = #True
      Else
        str = Chr(34) + "Better than you have tried it, whelp. Keep your hands to yourself, lest you lose them."
        ChangeStateAction("ROB", "CLERK")
      EndIf
     
    Case "FIGH", "KILL", "ATTA"  ;fight, attack
      If iState & #STATE6        ;already fought clerk
        str = Chr(34) + "Watch this!" + Chr(34) + " Sadly, you are unconscious too quickly to appreciate the lethal flurry of blows the bare-fisted clerk rains down upon you. The band around your neck flashes a deep red as you fade into oblivion."
        fTrouble = #True
      Else
        str = "Quick as lightning, the clerk knocks you on the head, firmly, with the back of her hand. It feels like you've been hit with a club. The clerk nods and smiles. " + Chr(34) + "Think twice, bucko." + Chr(34)
        ChangeStateAction("FIGHT", "CLERK")
      EndIf
      
    Case "TALK", "SPEA"  ;speak
      If InventoryHandler(#INVENTORYCHECK, "NOTE") = #HASITEM
        str = Chr(34) + "Here, let me see that note." + Chr(34) + " The clerk grabs the note that Eldred gave you and glances at it briefly. "
        
        If GG\fHaveBackpack
          *ptrCoin = FindMapElement(Nouns(), "COIN")
          
          If *ptrCoin\strRoom = #ITEMGONE
            If GG\ptrInventory\iCount = #MAXINVENTORY
              str = "I have some coins to give you, but your pack is full. Talk to me again after you've dropped something. The clerk hands the note back to you."
            Else
              ChangeItemRoom("COIN", #INVENTORY, #ITEMGONE)
            EndIf
          EndIf
          
          If *ptrCoin\strRoom = #INVENTORY
            str + "She keeps the note and hands you 5 gold coins."
            ChangeItemRoom("NOTE", #ITEMGONE, #INVENTORY)
            
            GG\iCoins + 5
          EndIf
        Else
          str + "The clerk hands the note back to you. " + Chr(34) + "Come back when you have something to carry a few coins in." + Chr(34)
        EndIf
      ElseIf iState & #STATE1
        str = "The clerk gives you an icy stare. " + Chr(34) + "Leave." + Chr(34)
      Else
        str = Chr(34) + "Don't you have better things to do? Please leave." + Chr(34)
      EndIf
      
    Default
      fRC = #False
  EndSelect
  
  If fTrouble
    GU\fGray = #True
    GU\fPauseInput = #True

    sTimer\strEvent = "FIGHTCLERK"
    sTimer\iType = #TIMERMILLISECONDS
    sTimer\iTime = 5000
    sTimer\iStart = ElapsedMilliseconds()
    
    TimerCommand(@sTimer)
  EndIf
  
  AddToOutput(str)
  
  ProcedureReturn fRC
EndProcedure

;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure NoteHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True
  
  Select strVerb
    Case "READ"
      ExamineHandler("NOTE")
      
    Case "GIVE"
      fRC = ClerkHandler("TALK", "CLERK")
      
    Default
      fRC = #False
  EndSelect

  ProcedureReturn fRC
EndProcedure

;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure.i DefenderHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True, str.s, iState.i
  Protected sTimer.EOTIMER
  
  iState = ItemState(#STATEGET, "DEFENDER")
  
  Select strVerb
    Case "TALK", "SPEA"  ;speak
      If iState & #STATE2  ;tried to bribe
        str = Chr(34) + "You insult our honor with your pitiful bribery attempt, ye vile wretch!" + Chr(34)
      ElseIf iState & #STATE1   ;tried to fight Defenders or king
        str = Chr(34) + "Get about your business soon, rapscallion. Our patience is limited." + Chr(34)
      Else
        str = Chr(34) + "Good day. We hope your petition to the king goes well." + Chr(34)
      EndIf
      
    Case "FIGH", "ATTA", "KILL"  ;Fight, attack
      If iState & #STATE1  ;tried to fight already
        GU\fGray = #True
        GU\fPauseInput = #True
  
        sTimer\strEvent = "FIGHTGUARD"
        sTimer\iType = #TIMERMILLISECONDS
        sTimer\iTime = 5000
        sTimer\iStart = ElapsedMilliseconds()
        
        TimerCommand(@sTimer)

        str = "The guards are no longer restrained. One of them buries her sword deep in your chest. The band about your neck briefly pulsates a deep red before you lose consciousness."
      Else
        str = "The guard easily blocks your clumsy attack. " + Chr(34) + "Tread carefully, miscreant. Finish your business and leave!" + Chr(34)
      EndIf
      
      ChangeStateAction("FIGHT", "DEFENDER")
      
    Case "BRIB"  ;Bribe
      str = Chr(34) + "We're not interested in your money, churl. The Defender and her mates give you a chorus of raucous laughter!" + Chr(34)
      
      ChangeStateAction("BRIBE", "DEFENDER")
      
    Default
      fRC = #False
  EndSelect
  
  AddToOutput(str)
  
  ProcedureReturn fRC
EndProcedure

;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure.i SentinelHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True, str.s, iState.i
  Protected sTimer.EOTIMER
  
  iState = ItemState(#STATEGET, "SENTINEL")
  
  Select strVerb
    Case "TALK", "SPEA"  ;speak
      If iState & #STATE2  ;tried to bribe
        str = Chr(34) + "In this room full of gold, your paltry offering was quite amusing. Begone!" + Chr(34)
      ElseIf iState & #STATE1   ;tried to fight Defenders or king
        str = Chr(34) + "MOVE! Speak with the clerk; do not linger in our sight." + Chr(34)
      Else
        str = Chr(34) + "Your business is with the clerk. Talk to her." + Chr(34)
      EndIf
      
    Case "FIGH", "ATTA", "KILL"  ;Fight, attack
      If iState & #STATE1        ;tried to fight already
        GU\fGray = #True
        GU\fPauseInput = #True
  
        sTimer\strEvent = "FIGHTGUARD"
        sTimer\iType = #TIMERMILLISECONDS
        sTimer\iTime = 5000
        sTimer\iStart = ElapsedMilliseconds()
        
        TimerCommand(@sTimer)

        str = "A massive sentinel strikes you in the head with his axe. You don't feel a thing, nor do you notice the rhythmic, red flashing of the band around your neck."
      Else
        str = "The sentinel blocks your careless attack with an easy grace. " + Chr(34) + "There, there young one. Best not play with those bigger than you. Finish your work with the clerk and begone from our sight." + Chr(34)
      EndIf
      
      ChangeStateAction("FIGHT", "SENTINEL")
      
    Case "BRIB"  ;Bribe
      str = Chr(34) + "Your 'riches' don't interest us, sirrah. Pathetic." + Chr(34)
      
      ChangeStateAction("BRIBE", "SENTINEL")
      
    Default
      fRC = #False
  EndSelect
  
  AddToOutput(str)
  
  ProcedureReturn fRC
EndProcedure

;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure DrowHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True, str.s, iState.i, fPlayerHasMap.i
  Protected sTimer.EOTIMER
  
  iState = ItemState(#STATEGET, "DROW")
  fPlayerHasMap = Bool(InventoryHandler(#INVENTORYCHECK, "MAP") = #HASITEM)
  
  Select strVerb
    Case "TALK", "SPEA", "BARG"  ;speak, bargain
      If fPlayerHasMap
        str = Chr(34) +  "We have no further business. Be on about your day." + Chr(34)
      Else
        If Not iState & #STATE6  ;talked to drow
          If iState & #STATE7  ;tried to fight drow
            str = Chr(34) + "You are foolish, nave, but I still"
          Else
            str = Chr(34) + "I"
          EndIf
          
          str + " have something to sell." + Chr(34)
          
          ItemState(#STATESET, "DROW", #STATE6)  ;talked to drow
        ElseIf Not iState & #STATE5
            str = Chr(34) + "One gold coin for the map I carry." + Chr(34)
            ItemState(#STATESET, "DROW", #STATE5)  ;talked to drow twice
          Else
            str = Chr(34) + "Don't waste my time. One... gold... coin." + Chr(34)
        EndIf
      EndIf
      
    Case "ROB"
      str = "The drow deflects your clumsy pickpocket attempt and continues to sip her ale. Nothing seems to phase her."
      
    Case "FIGH", "ATTA", "KILL"  ;fight, attack
      If iState & #STATE7
        str = "The dark elf thwarts your feeble attack with a single graceful motion. " + Chr(34) + "You'll never best me." + Chr(34) + " She means it and you're quite certain that she is right."
        
        If Not fPlayerHasMap And iState & #STATE5  ;have talked to drow twice
          str + " " + Chr(34) + "I said... Do... we have a deal?" + Chr(34)
        EndIf
      Else
        str = "In a blink, you find yourself on the floor, rubbing your aching backside."
        
        If Not fPlayerHasMap And iState & #STATE5  ;have talked to drow twice
          str + " " + Chr(34) + "Do we have a deal?" + Chr(34)
        EndIf
      EndIf
      
      ChangeStateAction("FIGHT", "DROW")
      
    Case "PAY", "BRIB"  ;bribe
      If Not fPlayerHasMap 
        If GG\fHaveBackpack And GG\iCoins > 0
          If GG\ptrInventory\iCount < #MAXINVENTORY
            SpendCoin()
            ChangeItemRoom("MAP", "INVENTORY", "ITEMGONE")
          
            str = "The drow hands you a well-read map. " + Chr(34) + "Be careful. If you drop it, the map will eventually return home. Hahahaha!" + Chr(34)
          Else
            str = "You have no room to carry anything. Come back when you've made some room in your pack."
          EndIf
        Else
          str = Chr(34) + "Go get some gold, then talk to me again!" + Chr(34)
        EndIf
      Else
        str = Chr(34) + "I've nothing left to sell." + Chr(34) + " The lovely, lethal dark elf turns back to her ale."
      EndIf
      
    Case "PICK", "ROB"  ;pickpocket
      GU\fGray = #True
      GU\fPauseInput = #True

      sTimer\strEvent = "FIGHTDROW"
      sTimer\iType = #TIMERMILLISECONDS
      sTimer\iTime = 5000
      sTimer\iStart = ElapsedMilliseconds()
      
      TimerCommand(@sTimer)

      str = "The drow detects your attempt. You are surely and swiftly dead. The band around your neck strobes red as the room fades to black."
      ChangeStateAction("FIGHT", "DROW")
      
    Default
      fRC = #False
  EndSelect
  
  AddToOutput(str)
  
  ProcedureReturn fRC      
EndProcedure

;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure MapHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True
  
  Select strVerb
    Case "READ"
      ExamineHandler("MAP")
      
    Case "BUY"
      fRC = DrowHandler("BRIB", "DROW")  ;bribe
    Default
      fRC = #False
  EndSelect

  ProcedureReturn fRC
EndProcedure

;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure BarmaidHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True, str.s, iState.i
  Protected sTimer.EOTIMER
  
  iState = ItemState(#STATEGET, "BARMAID")
  
  Select strVerb
    Case "TALK", "SPEA"  ;speak
      If iState & #STATE7  ;tried to fight barmaid
        str = Chr(34) + "St... st... stay away. HELP!"
      Else
        str = "The barmaid ignores you and remains fixated on the door. You look, but see nothing interesting out there."
      EndIf
      
    Case "FLIR", "KISS"  ;flirt
      If iState & #STATE7  ;tried to fight barmaid
        str = "The barmaid shudders and gives you a look of fearful disdain. " + Chr(34) + "Leave me be, scum!" + Chr(34) + " Someday, your broken heart will heal."
      Else
        str = "The fair lass heaves a depressed sigh and turns back to the door. In no way do you sense that she's interested."
      EndIf
      
    Case "FIGH", "ATTA", "KILL"  ;fight, attack
      ItemState(#STATESET, "BARMAID", #STATE7)
      
      GU\fGray = #True
      GU\fPauseInput = #True

      sTimer\strEvent = "FIGHTBARMAID"
      sTimer\iType = #TIMERMILLISECONDS
      sTimer\iTime = 5000
      sTimer\iStart = ElapsedMilliseconds()
      
      TimerCommand(@sTimer)

      str = "You didn't realize that drunken bar patrons could move so swift, or so deadly. You reach for the barmaid and feel the dagger in your back, piercing through to your heart, at the same time. The red glow from the band around your neck pulsates along with the blood from your heart. You die quickly, and painfully."
      
      ChangeStateAction("FIGHT", "BARMAID")
      
    Default
      fRC = #False
  EndSelect
  
  AddToOutput(str)
  
  ProcedureReturn fRC  
EndProcedure

;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure BeerHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True
  
  Select strVerb
    Case "BUY", "PURC"  ;purchase
      If GG\iCoins
        AddToOutput("The barmaid take a quick glance at your coin, stiffens in fear, and refuses to serve you.")
      Else
        AddToOutput("Ale isn't free. You don't have any money.")
      EndIf
      
    Case "DRIN", "CHUG", "QUAF"  ;drink, chug, quaff
      AddToOutput("You can't get your hands on any ale, and nobody is interested in sharing with you. No new drinking stories for you today!")
      
    Default
      fRC = #False
  EndSelect
  
  ProcedureReturn fRC
EndProcedure

;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure TableHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True
  
  Select strVerb
    Case "SIT"
      AddToOutput("The Drow mumbles, " + Chr(34) + "ain't gonna happen." + Chr(34) + " You wisely choose to remain standing.")
      
    Case "BREA", "FLIP", "TIP", "TOPP"  ;break, topple
      AddToOutput("The table is far too heavy and sturdy. You hurt yourself a little bit. But just a little.")
      
    Default
      fRC = #False
  EndSelect
  
  ProcedureReturn fRC
EndProcedure

;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure.i CliffHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True
  
  Static iTries = 0
  Protected sTimer.EOTIMER
  
  Select strVerb
    Case "JUMP", "LEAP"
      If iTries % 2
        AddToOutput("AAAIIiieeeeeeee! You jump from the edge of the cliff. You're very brave. Also, it appears, very dead.")
    
        GU\fGray = #True
        GU\fPauseInput = #True
  
        sTimer\strEvent = "JUMPCLIFF"
        sTimer\iType = #TIMERMILLISECONDS
        sTimer\iTime = 6000
        sTimer\iStart = ElapsedMilliseconds()
        
        TimerCommand(@sTimer)
      Else
        AddToOutput("What?! That would be crazy. Don't do that!")
      EndIf
      
      iTries + 1
      
    Case "CLIM", "DOWN", "UP"  ;climb
      ClimbHandler("DOWN", "CLIFF")
      
    Default
      fRC = #False
  EndSelect
  
  ProcedureReturn fRC
EndProcedure

;full word noun and verbs passed in. Specific tree type guaranteed to be in current room if we get here
Procedure.i TreeHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True, sTimer.EOTIMER, str.s
  
  If strVerb = "CLIMB" Or strVerb = "UP"
    ClimbHandler("UP", strNoun)
  ElseIf strVerb = "DESCEND" Or strVerb = "DOWN"
    ClimbHandler("DOWN", strNoun)
  Else
    Select Left(strVerb, #PARSELEN)
      Case "CHOP", "CUT"
        If InventoryHandler(#INVENTORYCHECK, "AXE") = #HASITEM
          Select GG\ptrRoom\strRoom
            Case"ZARBURGSOUTHGATE"
              ChangeStateAction("CHOP", strNoun)
              
              str = "You hack mightily at the base of the large oak tree, and soon it crashes to the ground, barely missing the Zarburg gate!"
              ChangeItemRoom("AXE", "ZARBURGSOUTHGATE", #INVENTORY)
              
              If Not ItemState(#STATEGET, "WATCHMAN") & #SPLAYERAWARE
                With sTimer
                  \iType = #TIMERMILLISECONDS
                  \iTime = 3000
                  \strEvent = "KNOCKGATE"
                  \strMetadata = "CHOP"
                EndWith
                
                TimerCommand(@sTimer)
              Else
                If ItemState(#STATEGET, "MAINGATE") & #STATE2  ;gate open
                  str + " The watchman is temporarily startled, but then goes back into his reverie."
                Else
                  str + " The watchman shakes his head and glares at you."
                EndIf
              EndIf
              
              AddToOutput(str)
              
            Case "WOODSBURIED", "WOODSTREE"
              AddToOutput("You try to chop the tree and the axe flies from your hands, lost forever in the dark woods.")
              ChangeItemRoom("AXE", #ITEMGONE, #INVENTORY)
              InventoryHandler(#INVENTORYDROP, "AXE")
              
            Default      
            AddToOutput("It's too dangerous to chop down the tree while you're in it!")
          EndSelect
        Else
          fRC = #False
        EndIf
        
      Case "BURN"
        AddToOutput("I can't let you burn down the " + LCase(strNoun) + " tree. Smokey the Bear would kill me.")
      
      Default        
       fRC = #False      
   EndSelect
 EndIf
 
 ProcedureReturn fRC
EndProcedure

;full word noun and verbs passed in. Specific tree type guaranteed to be in current room if we get here
Procedure.i BenchHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True
  
  Select strVerb
    Case "SIT"
      AddToOutput("You sit on the nearest bench. It's not terribly comfortable and you soon get bored of sitting. You stand up feeling a bit rested.")
      
    Case "TIP", "FLIP", "TOPP"  ;topple
      AddToOutput("All of the benches are anchored deep into the earth.")
      
    Default
      fRC = #False
  EndSelect
  
  ProcedureReturn fRC
EndProcedure

;full word noun and verbs passed in. Specific tree type guaranteed to be in current room if we get here
Procedure.i BuildingHandler(strVerb.s, strNoun.s)
  Protected sTIMER.EOTIMER, fRC.i = #True
  
  Select strVerb
    Case "GO", "ENTER"
      AddToOutput("The buildings and homes are all shielded somehow, and you're not even able to touch the doors.")
      
    Case "BURN"
      If GG\fLightSource
        GU\fGray = #True
        GU\fPauseInput = #True
  
        sTimer\strEvent = "BURNBUILDING"
        sTimer\iType = #TIMERMILLISECONDS
        sTimer\iTime = 5000
        sTimer\iStart = ElapsedMilliseconds()
        
        TimerCommand(@sTimer)
        
        AddToOutput("A mob of angry drow beats you to death as others quickly quench the flames. The red flickering of the band about your next is the last thing you see.")
        ChangeStateAction("BURN", "BUILDINGS")
      Else
        AddToOutput("And what, pray tell, will you start the fire with?")
      EndIf
      
    Default
      fRC = #False
  EndSelect
  
  ProcedureReturn fRC
EndProcedure

;full word noun and verbs passed in. 
Procedure.i VillagersHandler(strVerb.s, strNoun.s)
  Protected sTIMER.EOTIMER, fRC.i = #True, str.s
  
  Select strVerb
    Case "TALK", "SPEA"  ;speak
      str = Chr(34)
      
      Select Random(5)
        Case 0
          str + "I hear that the human prince is missing!"
        Case 1
          str + "I saw the lich once. Without my amulet, I would be dead."
        Case 2
          str + "The trees are so beautiful this time of year."
        Case 3
          str + "Dragons like to catch their food, they won't eat you if you don't move."
        Case 4
          str + "Eldred keeps our torches burning."
        Case 5
          str + "You can't swim the river if you're carrying too much."
      EndSelect
      
      str + Chr(34)
      
    Case "FIGH", "ATTA", "KILL"  ;fight, attack
      GU\fGray = #True
      GU\fPauseInput = #True

      sTimer\strEvent = "FIGHTVILLAGERS"
      sTimer\iType = #TIMERMILLISECONDS
      sTimer\iTime = 5000
      sTimer\iStart = ElapsedMilliseconds()
      
      TimerCommand(@sTimer)
      
      str = "As you attack one villager, all of the dark elves respond as one, like a surging river of daggers and agony. The red blood mixes with the red pulsing of the band about your neck as you lay, regretful, whimpering, and dying."
      ChangeStateAction("FIGHT", "VILLAGERS")
      
    Default
      fRC = #False
  EndSelect
  
  AddToOutput(str)
  
  ProcedureReturn fRC
EndProcedure

;full word noun and verbs passed in. 
Procedure.i TavernDoorHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True
  
  Select strVerb
    Case "GO"
      ChangeCurrentRoom(#NUL, #NUL, "ZARBURGCOURTYARD")
      
    Case "OPEN"
      AddToOutput("The tavern door is always open. Always.")
      
    Case "CLOS"  ;close
      AddToOutput("The tavern door is held open, permanently, by some unknown means.")
    Default
      fRC = #False
  EndSelect
  
  ProcedureReturn fRC
EndProcedure

;noun and verb are both valid, #PARSELEN words
Procedure.i ChieftainHandler(strVerb.s, strNoun.s)
  Protected iState.i, fRC.i = #True, str.s
  
  iState = ItemState(#STATEGET, "CHIEFTAIN")
  
  Select strVerb
    Case "TALK", "SPEAK"  ;speak
      If Not iState & #STATE2  ;haven't talked to the chieftain yet
        str = "You explain to the chieftain that you are in search of the young prince of Zarburg. The chieftain responds, " + Chr(34) + "I am Belzar, high chieftain of the drow. "
        str + "I am sorrowed to hear that. The kingdom of Zarburg is a great ally to the drow." + Chr(34)
        
        ItemState(#STATESET, "CHIEFTAIN", #STATE2)
      ElseIf Not iState & #STATE3  ;have talked to chieftain only once
        str = "You ask Belzar if the drow can provide any assistance. Belzar speaks in a soft voice, " + Chr(34) + "Verily, the drow stand by Zarburg. Here, take this bracelet, and may it guard you in your journey and always." + Chr(34)
        
        ItemState(#STATESET, "CHIEFTAIN", #STATE3)
        InventoryHandler(#INVENTORYADD, "BRACELET")
        ItemState(#STATESET, "BRACELET", #STATE7 | #SPLAYERAWARE)  ;bracelet is part of player now
      Else
        str = Chr(34) + "Go now, and may the peace of the drow be with you." + Chr(34)
      EndIf
      
    Case "BOW", "KNEE", "GENU"  ;kneel, genuflect
      str = Chr(34) + "Please, rise, and speak as you will." + Chr(34)
      
    Case "FIGH", "ATTA", "KILL" ;fight, attack
      str = "You are frozen in mid movement as soon as you begin your attack. The chieftain and elders do not look concerned. You feel quite foolish as you slowly regain your ability to move."
      ChangeStateAction("FIGHT", "CHIEFTAIN")
    Default
      fRC = #False
  EndSelect
  
  AddToOutput(str)
  
  ProcedureReturn fRC
EndProcedure

;noun and verb are both valid, #PARSELEN words
Procedure.i EldersHandler(strVerb.s, strNoun.s)
  Protected iState.i, fRC.i = #True, str.s
  
  iState = ItemState(#STATEGET, "ELDERS")
  
  Select strVerb
    Case "TALK", "SPEAK"  ;speak
      If Not iState & #STATE2  ;haven't spoken to the elders yet
        str = "The elders studiously ignore you and continue their conversations with each other and the chieftain."
        ItemState(#STATESET, "ELDERS", #STATE2)
      Else
        str = "Your interruptions remain as unnoticed as they are unacknowledged."
      EndIf
      
    Case "FIGH", "ATTA", "KILL" ;fight, attack
      str = "You are frozen in mid movement as soon as you begin your attack. The chieftain and elders do not look concerned. You feel quite foolish as you slowly regain your ability to move."
      ChangeStateAction("FIGHT", "ELDERS")
      
    Default
      fRC = #False
  EndSelect
  
  AddToOutput(str)
  
  ProcedureReturn fRC
EndProcedure

;noun and verb are both valid, #PARSELEN words
Procedure.i OpeningHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True
  
  Select strVerb
    Case "GO", "ENTE", "CLIM"  ;enter, climb
      AddToOutput("Only smoke from the fire can go through the hole. It's too small for you, silly.")
      
    Default
      fRC = #False
  EndSelect
  
  ProcedureReturn fRC
EndProcedure

;called from merchant and mealbar handlers
Procedure BuyMealbar(iState.i)
  Protected str.s
  
  If GG\fHaveBackpack
    If iState & #STATE1  ; mealbar purchased yet?
      If SpendCoin()
        ChangeStateAction("BUY", "MEALBAR")
        InventoryHandler(#INVENTORYADD, "MEALBAR")
        
        str = "You put the delicious mealbar in your pack and the merchant"
        
        If ItemState(#STATEGET, "MERCHANT") & #STATE2  ;angry after fight
          str + " snootily"
        EndIf
        
        str + " thanks you."
      EndIf
    Else
      str = "Save your gold; you've already purchased the mealbar."
    EndIf
  Else
    str = "You've got nowhere to put the mealbar. You'll need your backpack in order to purchase it."
  EndIf
  
  AddToOutput(str)
EndProcedure

;noun and verb are both valid, #PARSELEN words
Procedure.i MerchantHandler(strVerb.s, strNoun.s)
  Protected iState.i, fRC.i = #True, str.s
  
  iState = ItemState(#STATEGET, "MERCHANT")
  
  Select strVerb
    Case "TALK", "SPEAK"
      If Not iState & #STATE2  ;angry at you
        If iState & #STATE1    ;has mealbars
          str = Chr(34) + "Buy a mealbar, friend. I've but one left, a single goldpiece each." + Chr(34)
        Else
          str = Chr(34) + "Sorry, I sold you my last mealbar. Good luck in your adventures." + Chr(34)
        EndIf
      ElseIf iState & (#STATE1 | #STATE5)
        str = Chr(34) + "Hurry up and buy a mealbar, or just leave, sirrah!" + Chr(34)
      Else
        str = Chr(34) + "Get out of my sight before I call the guards!" + Chr(34) + " (He's bluffing, but you might as well leave anyhow)"
      EndIf
      
    Case "PAY"
      If iState & #STATE4  ;has one mealbar left
        BuyMealbar(ItemState(#STATEGET, "MEALBAR"))
      Else
        str = Chr(34) + "Regrettably, my till is closed. Would that I could take more gold!" + Chr(34)
      EndIf
      
    Case "FIGH", "ATTA", "KILL"
      str = Chr(34) + "You filthy scum!" + Chr(34) + " The fierce-looking merchant aims a large blunderbuss at your tender, exposed head!"
      ChangeStateAction("FIGHT", "MERCHANT")
      
    Default
      fRC = #False
  EndSelect
  
  AddToOutput(str)
  
  ProcedureReturn fRC
EndProcedure

;noun and verb are both valid, #PARSELEN words
Procedure.i MealbarHandler(strVerb.s, strNoun.s)
  Protected iState.i, fRC.i = #True, str.s
  
  iState = ItemState(#STATEGET, "MEALBAR")
  
  Select strVerb
    Case "BUY", "PURC"  ;purchase
      BuyMealbar(iState)
      
    Case "EAT"
      If InventoryHandler(#INVENTORYCHECK, "MEALBAR") = #HASITEM
        str = "You may need that later and besides, you're just not hungry right now."
      Else
        str = "You dream of eating a tasty mealbar. Sigh, if only you had one."
      EndIf
      
    Case "GIVE", "USE", "SHAR"  ;share
      If GG\ptrRoom\strRoom = "PRISONCELL2"
        fRC = PrisonerHandler("FEED", "PRISONER")
      Else
        str = "There's nobody here that wants the mealbar."
      EndIf
      
    Case "STEA", "ROB"  ;steal
      If iState & #STATE1 Or strNoun = "TRAY" ;has one mealbar left
        str = "The merchant pulls out a well-used blunderbuss and aims it at your head. " + Chr(34) + "Nobody steals from me!"
        If iState & #STATE1 
          str + " Buy now or leave." 
        EndIf
        str + Chr(34)
      Else
        str = "You've already purchased the mealbar."
        
        If GG\fHaveBackpack
          str + " You deftly remove it from your pack and hide it behind your back. Sneaky. Content from your " + Chr(34) + "success" + Chr(34) + ", you place the mealbar back in your pack."
        EndIf
      EndIf
      
      ChangeStateAction("STEAL", "MEALBAR")
      
    Case "GIVE", "SHAR", "USE"  ;share
      If GG\ptrRoom\strRoom = "PRISONCELL2"
        fRC = PrisonerHandler("FEED", "PRISONER")
      EndIf
      
    Default
      fRC = #False
      
  EndSelect
  
  If str <> ""
    AddToOutput(str)
  EndIf
  
  ProcedureReturn fRC
EndProcedure

;noun and verb are both valid, #PARSELEN words
Procedure.i TrayHandler(strVerb.s, strNoun.s)
  Protected fRC.i
  
  If strVerb = "STEA"  ;steal
    fRC = MealbarHandler("STEA", "TRAY")  ;steal melbar
  EndIf
  
  ProcedureReturn fRC
EndProcedure

;noun and verb are both valid, #PARSELEN words
Procedure.i StackHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True
  
  Select strVerb
    Case "SEAR"  ;search
      AddToOutput("You discover an axe that has slipped between a gap in the stack of firewood.")
      ChangeStateAction("SEARCH", "STACK")
      
    Case "BURN", "LIGH" ;light
      If GG\fLightSource
        AddToOutput("The wood is too wet to burn. There is a brief glint of steel as you pull back the torch.")
      Else
        AddToOutput("Your red-hot personality is insufficient to light the wood ablaze. Have anything else you can try?")
      EndIf
      
    Default
    fRC = #False
  EndSelect
  
  ProcedureReturn fRC
EndProcedure

;noun and verb are both valid, #PARSELEN words
Procedure.i WatchmanHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True, iState.i, str.s
  
  iState = ItemState(#STATEGET, "WATCHMAN")
      
  Select strVerb
    Case "BRIB", "PAY" ;bribe
      If GG\fHaveBackpack
        If Not iState & #STATE1  ;already been paid
          If SpendCoin()
            ChangeAvailDirection(GG\ptrRoom\iRoomX, GG\ptrRoom\iRoomY, #NORTH, #DIROK)   ;change North to "1", i.e.; open
            ChangeStateAction("BRIBE", strNoun)
            
            AddToOutput("The watchman snatches your gold and the window in the gate slides closed. You hear him shout " + Chr(34) + "Honor the king!" + Chr(34) + " Several seconds later the gate swings open!")
          EndIf
        Else
          AddToOutput("He's too busy jibbering about how he's going to spend his gold to take the new coin you're offering.")
        EndIf
      Else
        AddToOutput("Your money is in your backpack, sorry.")
      EndIf
      
    Case "FEED"
      AddToOutput("Okay, maybe not hungry in that sense of the word. More like " + Chr(34) + "greedy." + Chr(34))
        
    Case "TALK", "SPEAK"
      If ItemState(#STATEGET, "MAINGATE") & #STATE2  ; gate open
        If Not iState & #STATE7  ;if not already talked to him
          AddToOutput("The watchman looks at you with a puzzled look. " + Chr(34) + "Um... thanks? Now go somewhere else." + Chr(34))
          ItemState(#STATESET, "WATCHMAN", #STATE7)
        ElseIf Not iState & #STATE6  ;if not already talked twice
          AddToOutput("The watchman seems shaken. " + Chr(34) + "I let you in, now leave me alone before the guards come!" + Chr(34))
          ItemState(#STATESET, "WATCHMAN", #STATE6)
        Else
          AddToOutput("The watchman turns his back and studiously ignores you.")
        EndIf
      ElseIf Not iState & #STATE5  ;talked once to watchman through window
        AddToOutput(Chr(34) + "I can't just let anybody traipse in here. Ahem." + Chr(34))
        ItemState(#STATESET, "WATCHMAN", #STATE5)
      Else
        AddToOutput(Chr(34) + "Money talks. That's all I have to say." + Chr(34))
      EndIf
      
    Case "KILL", "ATTA", "FIGH"  ;attack, fight
      If iState & #STATE1                ;mumbling after the gate is open
        str + "The watchman is very excited. " + Chr(34) + "Oooh, a game! I love games!" + Chr(34) + " He proceeds to pin you to the ground and make you eat dirt. After a minute, he giggles, then gets up and walks away."
      Else
        str = "The watchman grins and says, " + Chr(34) + "come get some." + Chr(34)
      EndIf
      
      AddToOutput(str)
      
    Default
      fRC = #False
  EndSelect
  
  ProcedureReturn fRC
EndProcedure

;noun and verb are both valid, #PARSELEN words
Procedure.i RatHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True
  
  Select strVerb
    Case "KICK", "CATC", "ATTA", "KILL", "FIGH"
      AddToOutput("Every rat in this alley is too agile, too fast, and too wary for you to catch or attack. But you get a little exercise trying!")
    Default
      fRC = #False
  EndSelect
  
  ProcedureReturn fRC
EndProcedure

;Valid noun/verb handlers. #PARSELEN verb passed in
Procedure SymbolsHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True
  
  Select strVerb
    Case "READ"
      ExamineHandler("SYMBOLS")
      
    Default
      fRC = #False
  EndSelect

  ProcedureReturn fRC
EndProcedure

;noun and verb are both valid, #PARSELEN words
Procedure.i TentHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True, str.s
  
  Select strVerb
    Case "ENTE", "SEAR", "GO"  ;enter, search
      ChangeStateAction("ENTER", "TENT")
      
      If Not ItemState(#STATEGET, "ROPE") & #STATE7  ;user hasn't removed rope from tent
        str = "You crawl into the tent and find a long climbing rope but nothing else interesting. "
        
        If GG\fHaveBackpack
          If GG\ptrInventory\iCount < #MAXINVENTORY
            str + "You grab the rope and exit the tent."
            
            ChangeItemRoom("ROPE", #INVENTORY)
            ItemState(#STATESET, "ROPE", #STATE7)   ;user has removed rope from tent
            ItemState(#STATESET, "TENT", 0, #STATE2)  ;remove "there is a rope in the tent"
          Else
            str + "You're carrying too much to get the rope. Drop something and then search the tent again. You exit the tent."
          EndIf
        Else
          str + "You'll need your backpack in order to carry the rope. You exit the tent."
        EndIf
      Else
        str = "The tent is cluttered with this and that, but there is nothing of interest inside. You complete your search and exit the tent."
      EndIf
      
    Case "PITC"  ;pitch
      str = "The tent is already quite pitched, thank you."
      
    Case "STEA", "REMO"  ;steal, remove
      str = "Ouch! As you attempt to take down the tent, you are thrown several feet away by an intense electric shock. The tent is staying put."
      
    Default
      fRC = #False
  EndSelect
  
  AddToOutput(str)
  
  ProcedureReturn fRC
EndProcedure

;noun and verb are both valid, #PARSELEN words
Procedure.i SignHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True
  
  Select strVerb
    Case "BREA", "KICK" ;break
      AddToOutput("You give the signpost a mighty kick and it breaks from its based and falls into the intersection.")
      ChangeStateAction("BREAK", strNoun)
    Case "READ"
      ExamineHandler("SIGN")
    Case "STEAL"
      AddToOutput("The signpost is too heavy to move very far. You quickly give up on the notion.")
    Default
      fRC = #False
  EndSelect
  
  ProcedureReturn fRC
EndProcedure

;noun and verb are both valid, #PARSELEN words
Procedure.i MainGateHandler(strVerb.s, strNoun.s)
  Protected sTIMER.EOTIMER, fRC.i = #True
  Protected iState.i
  
  Select strVerb
    Case "UNLO"   ;unlock
      AddToOutput("You don't have anything to unlock it with. Also, even more unfortunate, it locks from the inside.")
      
    Case "CLIM" ;climb
      AddToOutput("You can't get a foothold and are unable to climb the gate.")
      
    Case "OPEN"
      If ItemState(#STATEGET, "MAINGATE") & #STATE1  ;locked and closed
        AddToOutput("The gate is solid and heavy. Your attempt to open it is futile; it won't budge.")
      Else
        AddToOutput("The gate is already open.")
      EndIf
      
    Case "CLOS" ;closey
      If ItemState(#STATEGET, "MAINGATE") & #STATE2  ;open
        AddToOutput("The gate is secured in the open position. You're unable to close it.")
      Else
        AddToOutput("The gate can't get any more closed than it already is.")
      EndIf
      
    Case "CHOP", "CUT"  
      If InventoryHandler(#INVENTORYCHECK, "AXE") = #HASITEM
        AddToOutput("The axehead bounces off the iron, leaving the gate undamaged.")
      Else
        fRC = #False
      EndIf
        
    Case "KNOC" ;knock
      iState = ItemState(#STATEGET, "MAINGATE")
      If iState & #STATE1   ;locked and closed
        If Not iState & #STATE4  ;haven't already knocked
          AddToOutput("You knock on the gate but there doesn't seem to be any response...")
          
          With sTIMER
            \iType = #TIMERMILLISECONDS
            \iTime = 3000
            \strEvent = "KNOCKGATE"
          EndWith
          
          TimerCommand(@STIMER)
        Else
          AddToOutput("The watchman gives you an annoying glance. " + Chr(34) + "Stop that!" + Chr(34))
        EndIf
      Else
        AddToOutput("You knock on the open gate, but nobody pays attention to you.")
      EndIf
      
    Case "BURN" 
      If GG\fLightSource
        If Not ItemState(#STATEGET, "MAINGATE") & #STATE7   ;has been burned?
          AddToOutput("Before it can catch fire, several guards come through the gate and bash you soundly on the head. You pass out, rather immediately.")
          
          GU\fGray = #True
          GU\fPauseInput = #True
          
          ItemState(#STATESET, "MAINGATE", #STATE7)  ;gate has already been burned
          
          With sTIMER
            \iType = #TIMERMILLISECONDS
            \iTime = 5000
            \strEvent = "BURNGATE"
          EndWith
          
          TimerCommand(@sTIMER)
        Else
          AddToOutput("Uh-uh. We're not trying that again!")
        EndIf
      Else
        AddToOutput("You need flames to start a fire.")
      EndIf
    Case "PUSH"
      AddToOutput("You push on the gate for several seconds. Your calves are now well stretched.")
    Default
      fRC = #False
  EndSelect
  
  ProcedureReturn fRC
EndProcedure

;noun and verb are both valid, #PARSELEN words
Procedure.i CoinHandler(strVerb.s, strNoun.s)
  Protected fRC.i = #True
  
  If strVerb = "GIVE"
    Select GG\ptrRoom\strRoom
      Case "ZARBURGSOUTHGATE"
        fRC = WatchmanHandler("BRIB", "WATCHMAN")
      Case "ZARBURGCOURTYARD"
        fRC = MerchantHandler("PAY", "MERCHANT")
      Case "ZARBURGINN"
        fRC = DrowHandler("BRIB", "DROW")
      Case "ELVENBARRICADE"
        fRC = DambenHandler("BRIB", "DAMBEN")
    EndSelect
  EndIf
  
  ProcedureReturn fRC
EndProcedure

;noun is full word of found noun. Noun was always found If this Procedure is called
Procedure DropHandler(strNoun.s)
  Protected *ptrNoun.NOUN, str.s, strFullNoun.s
  
  strFullNoun = LCase(strNoun)   ;for nouns that weren't found, use what user typed For error message
  strNoun = Left(strNoun, #PARSELEN)
  
  ;special case dropping this special items
  Select strNoun
    Case "COIN"
      AddToOutput("Dropping money isn't a good idea. I can't let you do it.")
      ProcedureReturn
    Case "BAND"
      AddToOutput("The band is securely fastened. You can't remove it.")
      ProcedureReturn
    Case "BRAC"  ;bracelet
      AddToOutput("The bracelet has melded with your wrist, you are unable to remove it.")
      ProcedureReturn
  EndSelect
    
  ;find noun and see if it's in inventory
  *ptrNoun = FindMapElement(Nouns(), strNoun)
  
  If FindMapElement(GG\ptrInventory\mapNouns(), strNoun)
    strFullNoun = LCase(*ptrNoun\strNoun)   ;use full name of noun since we found it
    
    ;mark noun so that it lives in this room now, and mark that it has been dropped
    *ptrNoun\strRoom = GG\ptrRoom\strRoom
    *ptrNoun\iState | #SDROPPED
    
    ;drop it in this room
    AddMapElement(GG\ptrRoom\mapNouns(), strNoun)  ;mapkey is always #PARSELEN characters
    GG\ptrRoom\mapNouns() = *ptrNoun\strNoun       ;map value is always full word noun
    
    InventoryHandler(#INVENTORYDROP, strNoun)
    
    ;if we've dropped the backpack, remove all items from it, put in $BACKPACK room
    If strNoun = "BACK"
      GG\fHaveBackpack = #False
      PackHandler(#DROPBACKPACK)
    ElseIf strNoun = "SCEPTER"
      ChangeStateAction("DROP", "SCEPTER") ;scepter no longer in hand
    EndIf
    
    AddToOutput("You drop the " + strFullNoun + ".")
    
    Select strNoun
      Case "TORC"
        TorchHandler("DROP")
    EndSelect
    
    GU\iDirty + 1
  Else
    ;if we found the noun in Nouns() and if player is aware of it, use the correct full name
    If *ptrNoun And *ptrNoun\iState & #SPLAYERAWARE
      str = LCase(*ptrNoun\strNoun)
    Else
      str = strFullNoun
    EndIf
    
    If *ptrNoun\iState & #SFIXED
      AddToOutput("You can't even pick up the " + str + "!")
    Else
      AddToOutput("You're not carrying a " + str + ".")
    EndIf
  EndIf
EndProcedure

;for GET and TAKE and GRAB
;noun is full word of found noun. Noun was always found if this procedure is called
Procedure GetHandler(strNoun.s)
  Protected *ptrNoun.NOUN, str.s, strFullNoun.s
  
  If GG\ptrInventory\iCount = #MAXINVENTORY
    AddToOutput("You are carrying too much. You'll need to drop one or more items to pick anything else up.")
    ProcedureReturn
  EndIf
  
  If strNoun = ""
    strNoun = "ALL"
  EndIf
  
  strFullNoun = LCase(strNoun)
  strNoun = Left(strNoun, #PARSELEN)
  
  Select strNoun
    Case "ALL"
      str = "Please tell me exactly what to get."
    Default
      *ptrNoun = FindMapElement(Nouns(), strNoun)
      
      With GG\ptrRoom
        ;if item is not already in our inventory
        If *ptrNoun\strRoom <> #INVENTORY
        
          ;and it's not dark. unless it's the torch, user can always pick up the torch
          If Not \iState & #SDARK Or GG\fLightSource Or strNoun = "TORC"
          
            ;and if noun is in the current room
            If *ptrNoun\strRoom = GG\ptrRoom\strRoom  
              
              ;and if noun is available to pick up
              If *ptrNoun\iState & #SAVAIL And Not *ptrNoun\iState & #SFIXED
                
                If Not GG\fHaveBackpack And FindString("TORC,BACK", strNoun) = 0
                  str = "You have nowhere to put the " + strFullNoun + ". You need your backpack to pick up items."
                Else
                  ;verified that player is able to get the item, but first let's make sure they have enough room to carry it
                  If GG\ptrInventory\iCount = #MAXINVENTORY
                    str = "You are carrying too much. You'll need to drop one or more items to pick anything else up."
                  Else
                    ;change room state according to noun room state string
                    If *ptrNoun\strStateAction <> ""
                      ChangeStateAction("GET", strNoun)
                    EndIf
                    
                    ;add item to player's inventory
                    InventoryHandler(#INVENTORYADD, *ptrNoun\strNoun)
                    
                    ;if we've added backpack to inventory, put items from $BACKPACK room back into it
                    If strNoun = "BACK"
                      GG\fHaveBackpack = #True
                      PackHandler(#GETBACKPACK)
                    EndIf
                    
                    ;and remove it from the room
                    *ptrNoun\strRoom = #INVENTORY
                    DeleteMapElement(\mapNouns(), strNoun)
                    
                    If strNoun = "TORC" And \iState & #SDARK
                      str + "Your hand touches something! "
                    EndIf
                    
                    str + FormatString(HandleMessage("get"), strFullNoun)
                  EndIf
                  
                  GU\iDirty + 1
                EndIf
              Else
                If Not *ptrNoun\istate & #SFIXED
                  str = "You can't get the " + strFullNoun + ", yet."
                Else
                  str = "You can't take the " + strFullNoun + "."
                EndIf
              EndIf
            Else
              If strNoun = "BAND"
                str = "You can't get the band. It's fixed about your neck."
              Else
                str = "I don't see any " + strFullNoun +  " here."
              EndIf
            EndIf
          Else
            str = "It's too dark to find anything."
          EndIf
        ElseIf strNoun = "BRAC"
          str = "You can't get the bracelet. It is already embedded in your wrist."
        Else
          str = "You're already carrying the " + strFullNoun + "."
        EndIf
      EndWith
  EndSelect
  
  AddToOutput(str)          
EndProcedure

; IDE Options = PureBasic 5.70 LTS (Windows - x64)
; CursorPosition = 2257
; FirstLine = 2220
; Folding = -------------
; Markers = 564,776,1517
; EnableXP