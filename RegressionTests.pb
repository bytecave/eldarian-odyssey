; Run from the repository root; uses the real engine and embedded game data.
EnableExplicit
#COMMANDINDICATOR = "> "
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

Global failures.i, checks.i
Global wrapped.s
Procedure CaptureLine(line.s)
  wrapped + line
EndProcedure
Procedure Assert(ok.i, message.s)
  checks + 1
  If Not ok
    failures + 1
    PrintN("FAIL: " + message)
  EndIf
EndProcedure

Procedure Crash()
  PrintN("RUNTIME ERROR: " + ErrorMessage() + " at " + ErrorFile() + ":" + Str(ErrorLine()))
  End 2
EndProcedure

Procedure Command(command.s)
  GG\strCommand = UCase(command)
  ProcessCommand()
  AddRoomDescription(#False)
EndProcedure

Procedure Visit(room.s)
  ChangeCurrentRoom(0, 0, room)
  AddRoomDescription(#False)
EndProcedure

Procedure Give(noun.s)
  Protected *noun.NOUN = FindMapElement(Nouns(), Left(noun, #PARSELEN))
  ChangeItemRoom(noun, #INVENTORY, *noun\strRoom)
EndProcedure

Procedure AssertResponse(command.s, expected.s)
  Protected output.s, i.i
  ClearOutputBuffer()
  Command(command)
  For i = 0 To #MAXOUTPUTLINES - 1
    output + g_Output\strLine[i]
  Next
  Assert(Bool(FindString(output, expected, 1, #PB_String_NoCase)), command + " responds with: " + expected)
EndProcedure

Procedure RunCommands(script.s, expectedRoom.s)
  Protected i.i, command.s, *room.ROOM, consistent.i
  For i = 1 To CountString(script, "|") + 1
    command = StringField(script, i, "|")
    Command(command)
    consistent = Bool(GG\ptrInventory\iCount = MapSize(GG\ptrInventory\mapNouns()))
    ForEach Rooms()
      *room = Rooms()
      ForEach *room\mapNouns()
        If FindMapElement(Nouns(), MapKey(*room\mapNouns()))
          If Nouns()\strRoom <> *room\strRoom : consistent = #False : EndIf
        Else
          consistent = #False
        EndIf
      Next
    Next
    Assert(consistent, "world membership after " + command)
  Next
  Assert(Bool(GG\ptrRoom\strRoom = expectedRoom), "walkthrough checkpoint " + expectedRoom + " (actual " + GG\ptrRoom\strRoom + ")")
EndProcedure

Procedure Fresh()
  ReinitializeGame()
  ClearOutputBuffer()
  AddRoomDescription(#False)
EndProcedure

OpenConsole()
OnErrorCall(@Crash())
P_InitalizeLoc("enu")
Assert(Bool(_L(apptitle) = "Eldarian Odyssey"), "localized title")
InitializeRooms()
GG\ptrInventory = FindMapElement(Rooms(), #INVENTORY)
GG\ptrInventory\iRoomX = -1
InitializeThingsAndActions()
GG\ptrTorch = FindMapElement(Nouns(), "TORC")
CreateImage(#IMAGEBUFID, 1366, 768, 32)
LoadFont(0, "Arial", 12)
GU\hOutputFont = FontID(0)
GU\iXWidth = 1000
StartDrawing(ImageOutput(#IMAGEBUFID))
Fresh()
Assert(Bool(GG\ptrInventory\iCount = MapSize(GG\ptrInventory\mapNouns())), "initial inventory count")
Command("LIGHT TORCH")
Command("CLIMB TREE")
Command("CLIMB DOWN")
Assert(Bool(GG\ptrRoom\strRoom = #STARTINGROOM And Not GG\fInTree), "climb oak and descend")
Command("KNOCK GATE")
TimerCommandHandler("KNOCKGATE")
ClearMap(GG\Timers())
Command("PAY WATCHMAN")
Assert(Bool(GG\iCoins = 0 And InventoryHandler(#INVENTORYCHECK, "COIN") = #NOTHASITEM), "gate payment spends final coin")
Command("N")
Command("N")
Command("TALK KING")
Command("TALK KING")
AssertResponse("TALK GUARD", "Kneel before the king, knave!")
AssertResponse("SPEAK GUARDS", "Kneel before the king, knave!")
Assert(Bool(Not GG\fLightPermanent), "guard clue does not grant the blessing")
Command("KNEEL KING")
Assert(Bool(GG\fLightPermanent), "following guard clue blesses the carried torch")
AssertResponse("TALK GUARD", "Good day. We hope your petition to the king goes well.")
Command("W")
Command("TALK CLERK")
Assert(Bool(GG\iCoins = 5), "clerk pays five coins")
Assert(Bool(GG\ptrInventory\iCount = MapSize(GG\ptrInventory\mapNouns())), "clerk exchange preserves inventory count")
Command("E")
Command("S")
Command("BUY MEALBAR")
Assert(Bool(GG\iCoins = 4 And InventoryHandler(#INVENTORYCHECK, "MEALBAR") = #HASITEM), "mealbar purchase")
Assert(Bool(Not FindMapElement(GG\ptrRoom\mapNouns(), "MEAL")), "purchased mealbar leaves courtyard")
Command("W")
Command("PAY DROW")
Assert(Bool(GG\iCoins = 3 And InventoryHandler(#INVENTORYCHECK, "MAP") = #HASITEM), "map purchase")
Command("DROP MAP")
Command("PAY DROW")
Assert(Bool(GG\iCoins = 3 And InventoryHandler(#INVENTORYCHECK, "MAP") = #NOTHASITEM), "dropped map cannot be sold twice")
Command("GET MAP")
Visit("ELVENBARRICADE")
Command("DROP BACKPACK")
Command("PAY DAMBEN")
Assert(Bool(GG\iCoins = 3 And Not ItemState(#STATEGET, "DAMBEN") & #STATE5), "packed coins cannot pay Damben")
Command("GET BACKPACK")
Command("PAY DAMBEN")
Command("PAY DAMBEN")
Assert(Bool(GG\iCoins = 1 And ItemState(#STATEGET, "DAMBEN") & #STATE5), "Damben paid exactly once")
Command("DROP COINS")
Assert(Bool(InventoryHandler(#INVENTORYCHECK, "COIN") = #HASITEM), "independent coin drop remains prohibited")
Visit("ELVENTOWNHALL")
Command("TALK BELZAR")
Command("TALK BELZAR")
Command("DROP BACKPACK")
Assert(Bool(InventoryHandler(#INVENTORYCHECK, "BRACELET") = #HASITEM), "worn ward remains with player when pack dropped")
Command("GET BACKPACK")
Assert(Bool(GG\ptrInventory\iCount = MapSize(GG\ptrInventory\mapNouns())), "pack restore preserves inventory count")
Command("GET")
Command("GET ALL")
Command("GET TORCH")
Assert(Bool(GG\ptrInventory\iCount = MapSize(GG\ptrInventory\mapNouns())), "get shortcuts and already-carried item are safe")
Fresh()
GG\fLightSource = #True
ItemState(#STATESET, "BRACELET", #STATE7)
Visit("CRYPT")
Command("FIGHT LICH")
Assert(Bool(GU\fPauseInput And GU\fGray), "unprepared fight pauses during death")
Assert(Bool(FindMapElement(GG\Timers(), "LICHDEATH")), "unprepared fight schedules death timer")
GG\Timers()\iStart = ElapsedMilliseconds() - GG\Timers()\iTime
TimerCommandHandler(TimerCommand())
Assert(Bool(GG\ptrRoom\strRoom = "BURROW" And Not GU\fPauseInput And Not GU\fGray), "lich death revives at burrow")
Assert(Bool(Not GG\fLightSource And ItemState(#STATEGET, "BAND") & #STATE7), "revival extinguishes torch and updates neck band")
Fresh()
GG\fLightSource = #True
GG\fLightPermanent = #True
ItemState(#STATESET, "BRACELET", #STATE7)
Give("DAGGER")
Give("SCEPTER")
Give("POTION")
Visit("CRYPT")
Command("EXTINGUISH TORCH")
Command("LOOK")
Assert(Bool(Not GU\fPauseInput And Not GG\ptrRoom\iState & #SDARK), "blessed crypt remains lit without torch")
Command("FIGHT LICH")
Assert(Bool(ItemState(#STATEGET, "LICH") & #STATE5 And Not ItemState(#STATEGET, "LICH") & #STATE7), "prepared first attack weakens player")
Command("FIGHT LICH")
Assert(Bool(Not ItemState(#STATEGET, "LICH") & #STATE7), "second attack requires potion")
Command("DRINK POTION")
Command("FIGHT LICH")
Assert(Bool(ItemState(#STATEGET, "LICH") & #STATE7), "potion enables final blow")
Visit("ZARBURGTHRONEROOM")
Command("TALK KING")
Assert(Bool(GG\iCoins = 1 And Not ItemState(#STATEGET, "KING") & #KING_REWARD_PAID), "lich defeat alone does not win")
GG\fLightSource = #True
Visit("CRYPT")
Command("USE DAGGER")
Assert(Bool(Not GU\fPauseInput), "dead lich cannot kill player through dagger handler")
Command("SEARCH SARCOPHAGUS")
Command("PRESS BUTTON")
Command("N")
Assert(Bool(GG\ptrRoom\strRoom = "PRINCE" And GG\ptrRoom\iState & #PRINCE_RESCUED), "secret room rescue records completion")
Assert(Bool(InventoryHandler(#INVENTORYCHECK, "SCEPTER") = #NOTHASITEM), "prince takes scepter")
Visit("ZARBURGTHRONEROOM")
Command("TALK KING")
Command("TALK KING")
Assert(Bool(GG\iCoins = 10001 And ItemState(#STATEGET, "KING") & #KING_REWARD_PAID), "victory reward paid exactly once")
Assert(Bool(InventoryHandler(#INVENTORYCHECK, "COIN") = #HASITEM And GG\ptrInventory\iCount = MapSize(GG\ptrInventory\mapNouns())), "victory reward has consistent inventory")
Define testDirectory.s = GetTemporaryDirectory() + "EORegression-" + Str(GetCurrentProcessId_()) + "\"
Define originalDirectory.s = GetCurrentDirectory(), roomActions.s, event.s
Define timer.EOTIMER
CreateDirectory(testDirectory)
SetCurrentDirectory(testDirectory)
SaveGame("VICTORY")
Assert(Bool(GU\iDirty = 0), "successful save clears dirty flag")
Fresh()
LoadGame("VICTORY", #True)
Assert(Bool(GG\iCoins = 10001 And RoomState(#STATEGET, "PRINCE") & #PRINCE_RESCUED), "save restores rescued prince and coins")
Command("TALK KING")
Assert(Bool(GG\iCoins = 10001), "loaded victory does not repeat reward")
Fresh()
timer\strEvent = "KNOCKGATE"
timer\iType = #TIMERROOM
timer\strRoom = #STARTINGROOM
timer\strMetadata = "CHOP"
TimerCommand(@timer)
Visit("ZARBURGCLIFF")
SaveGame("TIMERS")
timer\strEvent = "JUMPCLIFF"
timer\iType = #TIMERMILLISECONDS
timer\iTime = 5000
TimerCommand(@timer)
LoadGame("TIMERS", #True)
Assert(Bool(MapSize(GG\Timers()) = 1 And FindMapElement(GG\Timers(), "KNOCKGATE")), "load replaces live timers")
Assert(Bool(GG\Timers()\strRoom = #STARTINGROOM And GG\Timers()\strMetadata = "CHOP"), "room timer target and metadata round trip")
Visit(#STARTINGROOM)
event = TimerCommand()
Assert(Bool(event = "KNOCKGATE,CHOP"), "restored room timer fires with its own metadata")
TimerCommandHandler(event)
GU\iDirty = 9
SaveGame("MISSING\SAVE")
Assert(Bool(GU\iDirty = 9), "failed save retains dirty flag")
CreatePreferences(testDirectory + "INVALID.EOS")
PreferenceGroup("G:GameGlobals")
WritePreferenceString("current", "NONEXISTENT")
ClosePreferences()
LoadGame("INVALID", #True)
Assert(Bool(GG\ptrRoom\strRoom = #STARTINGROOM And GU\iDirty = 9), "invalid save rejected without changing world")
roomActions = GG\ptrRoom\strStateAction
TimerCommand(@timer)
Fresh()
Fresh()
Assert(Bool(MapSize(GG\Timers()) = 0 And Not GU\fPauseInput And GG\iNumCommands = 0), "new game clears timers and command count")
Assert(Bool(GG\ptrRoom\strStateAction = roomActions), "new game does not append duplicate room actions")
DeleteFile(testDirectory + "VICTORY.EOS")
DeleteFile(testDirectory + "TIMERS.EOS")
DeleteFile(testDirectory + "INVALID.EOS")
SetCurrentDirectory(originalDirectory)
DeleteDirectory(testDirectory, "")
Fresh()
Visit("ZARBURGTHRONEROOM")
Command("PETITION KING")
Assert(Bool(ItemState(#STATEGET, "KING") & #STATE6), "petition reaches king dialog")
Command("SPEAK KING")
Visit("ZARBURGCOURTYARD")
Command("GIVE NOTE")
Assert(Bool(InventoryHandler(#INVENTORYCHECK, "NOTE") = #HASITEM), "note cannot be redeemed away from clerk")
Visit("ELVENVILLAGE")
AssertResponse("LOOK LOG", "craftsmanship")
AssertResponse("LOOK LOGS", "craftsmanship")
Visit("ELVENTOWNHALL")
AssertResponse("LOOK LOG", "supporting")
AssertResponse("LOOK LOGS", "supporting")
AssertResponse("LOOK CEILING", "smoke escape")
AssertResponse("LOOK CIRCLET", "sign of his office")
AssertResponse("GET CIRCLET", "can't take")
Command("SPEAK BELZAR")
Command("SPEAK BELZAR")
Assert(Bool(ItemState(#STATEGET, "BRACELET") & #STATE7), "speak uses same chieftain dialog as talk")
GG\fLightSource = #True
Visit("WOODSBURIED")
Command("DIG BOTTLE")
Assert(Bool(Not FindMapElement(GG\ptrRoom\mapNouns(), "BOTT")), "dug bottle removed from room")
Command("GET POTION")
Assert(Bool(InventoryHandler(#INVENTORYCHECK, "POTION") = #HASITEM), "dug potion available")
Visit("FISHPOND")
AssertResponse("LOOK WATER", "pond glows")
Visit("HALLWAY2")
Command("UNLOCK DOOR")
Assert(Bool(ItemState(#STATEGET, "CELLDOOR") & #STATE1), "cell cannot unlock without carried key")
Give("KEY")
Command("UNLOCK DOOR")
Assert(Bool(ItemState(#STATEGET, "CELLDOOR") & #STATE2), "key unlocks cell")
Visit("PRISONCELL2")
Give("MEALBAR")
Command("FEED PRISONER")
Assert(Bool(Not RoomState(#STATEGET, "RADIANTPOOL") & #STATE7), "feeding alone does not open granite gate")
Command("TALK PRISONER")
Command("TALK PRISONER")
Assert(Bool(RoomState(#STATEGET, "RADIANTPOOL") & #STATE7), "freed prisoner can open granite gate")
Define search.s = "ABCD", pattern.s = "CD"
Assert(Bool(QuickStringSearch(@search, StringByteLength(search), @pattern, StringByteLength(pattern)) = @search + StringByteLength("AB")), "bounded search finds last valid offset")
pattern = "ZZ"
Assert(Bool(QuickStringSearch(@search, StringByteLength(search), @pattern, StringByteLength(pattern)) = 0), "bounded search rejects absent pattern")
Assert(Bool(QuickStringSearch(@search, 1, @pattern, StringByteLength(pattern)) = 0), "bounded search rejects oversized pattern")
DrawTextProc = @CaptureLine()
wrapped = ""
AddToOutput("A" + #CR$, #True)
Assert(Bool(wrapped = "A "), "trailing CR terminates wrapping")
wrapped = ""
AddToOutput("A" + #CR$ + "B" + #LF$ + "C" + #CRLF$ + "D", #True)
Assert(Bool(wrapped = "A B C  D"), "CR LF and CRLF preserve text")
GU\iXWidth = 1
wrapped = ""
AddToOutput("....LongWord", #True)
Assert(Bool(wrapped = "....LongWord"), "narrow wrapping always advances")
GU\iXWidth = 1000
DrawTextProc = @DrawAboutText()
Fresh()
Command("LIGHT TORCH")
Assert(Bool(GG\iTorchBurnTime = #TORCHTURNS - 1), "lighting torch counts one turn")
Define burnTime.i = GG\iTorchBurnTime
Command("EXAMINE TORCH")
Assert(Bool(GG\iTorchBurnTime = burnTime), "read-only examine does not consume torch")
CreateDirectory(testDirectory)
SetCurrentDirectory(testDirectory)
Command("SAVE COMMANDSAVE")
Assert(Bool(GU\iDirty = 0), "SAVE command stays clean after torch synchronization")
DeleteFile(testDirectory + "COMMANDSAVE.EOS")
SetCurrentDirectory(originalDirectory)
DeleteDirectory(testDirectory, "")
Fresh()
Visit("ELVENBARRICADE")
RoomState(#STATESET, "ELVENBARRICADE", #STATE2, #STATE1)
AssertResponse("PAY DAMBEN", "already open")
Assert(Bool(GG\iCoins = 1), "legacy open barricade cannot charge again")
Fresh()
Visit("ZARBURGCLIFF")
Command("JUMP CLIFF")
Assert(Bool(Not GU\fPauseInput And ItemState(#STATEGET, "CLIFF") & #CLIFF_JUMP_WARNED), "first cliff jump warns")
CreateDirectory(testDirectory)
SetCurrentDirectory(testDirectory)
SaveGame("JUMP")
Fresh()
Visit("ZARBURGCLIFF")
Command("JUMP CLIFF")
Assert(Bool(Not GU\fPauseInput), "new game resets cliff warning")
LoadGame("JUMP", #True)
Command("JUMP CLIFF")
Assert(Bool(GU\fPauseInput And FindMapElement(GG\Timers(), "JUMPCLIFF")), "saved cliff warning restores second jump death")
DeleteFile(testDirectory + "JUMP.EOS")
SetCurrentDirectory(originalDirectory)
DeleteDirectory(testDirectory, "")
Fresh()
Visit("DEEPCHASM")
Command("JUMP CHASM")
Assert(Bool(Not GU\fPauseInput And ItemState(#STATEGET, "CHASM") & #CHASM_JUMP_WARNED), "first chasm jump warns")
Command("JUMP CHASM")
Assert(Bool(GU\fPauseInput And FindMapElement(GG\Timers(), "JUMPCHASM")), "second chasm jump schedules death")
Fresh()
Assert(Bool(Not ItemState(#STATEGET, "CHASM") & #CHASM_JUMP_WARNED), "new game resets chasm warning")
Fresh()
RunCommands("LIGHT TORCH|KNOCK GATE", #STARTINGROOM)
FindMapElement(GG\Timers(), "KNOCKGATE")
GG\Timers()\iStart = ElapsedMilliseconds() - GG\Timers()\iTime
TimerCommandHandler(TimerCommand())
RunCommands("PAY WATCHMAN|N|N|TALK KING|TALK KING|KNEEL KING|W|TALK CLERK|E|S|BUY MEALBAR|W|PAY DROW|E|E|S|GET DAGGER|N|N|N|E|S|DIG BOTTLE|GET POTION|E|S", "WOODSTREE")
RunCommands("CLIMB TREE|CLIMB TREE|CLIMB DOWN|CLIMB DOWN|W|S|E|SEARCH TENT|S|PAY DAMBEN|W|W|W|TALK BELZAR|TALK BELZAR", "ELVENTOWNHALL")
RunCommands("E|E|E|E|TIE ROPE|CLIMB DOWN|GET MUSHROOM|N|GET STONE|SWIM RIVER|SMASH BOX|GET KEY|SWIM RIVER|S|E|LIGHT TORCH|N|N", "FISHPOND")
RunCommands("DROP KEY|GET POLE|BAIT POLE|DROP MUSHROOM|CATCH FISH|N|THROW FISH|GET SCEPTER|S|GET KEY|S|S|S|USE KEY|S|W|UNLOCK DOOR|W|W|FEED PRISONER|TALK PRISONER|TALK PRISONER", "PRISONCELL2")
RunCommands("E|E|S|W|FIGHT SKELETON|W|W|W|W|FIGHT LICH|DRINK POTION|FIGHT LICH|SEARCH SARCOPHAGUS|PRESS BUTTON|N", "PRINCE")
Assert(Bool(GG\ptrRoom\iState & #PRINCE_RESCUED), "complete parser walkthrough rescues Rynn")
RunCommands("S|E|E|E|E|E|N|E|N|N|W|CLIMB UP|W|W|W|W|W|N|E|N|N|TALK KING|TALK KING", "ZARBURGTHRONEROOM")
Assert(Bool(GG\iCoins = 10001 And ItemState(#STATEGET, "KING") & #KING_REWARD_PAID), "complete parser walkthrough wins exactly once")
StopDrawing()
Define depth.i, pixel.i
For depth = 24 To 32 Step 8
  CreateImage(2, 7, 3, depth)
  StartDrawing(ImageOutput(2))
  Box(0, 0, 7, 3, RGB(10, 100, 200))
  Grayscale::Grayscale(2)
  pixel = Point(6, 2)
  Assert(Bool(Red(pixel) = Green(pixel) And Green(pixel) = Blue(pixel) And pixel = Point(0, 0)), "ASM grayscale handles " + Str(depth) + " bit image including final pixel")
  StopDrawing()
  FreeImage(2)
Next
PrintN(Str(checks) + " checks; " + Str(failures) + " failures")
End Bool(failures > 0)
