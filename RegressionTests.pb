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
Command("KNEEL KING")
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
StopDrawing()
PrintN(Str(checks) + " checks; " + Str(failures) + " failures")
End Bool(failures > 0)
