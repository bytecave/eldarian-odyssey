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
StopDrawing()
PrintN(Str(checks) + " checks; " + Str(failures) + " failures")
End Bool(failures > 0)
