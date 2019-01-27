#IMAGEBUFID = 1

#PARSELEN = 4

#MAXPERROOM = 10    ;maximum number of items per room
#MAXINVENTORY = 13  ;12 + 1 for the bracelet

#ROOMX = 8
#ROOMY = 8
#STARTINGROOM = "ZARBURGSOUTHGATE"
#INVENTORY = "INVENTORY"
#ITEMGONE = "ITEMGONE"
#TEMPSTORAGE = "TEMPSTORAGE"
#TORCH = "TORCH"

#START_STATE = "*"
#START_DESC = "["

#TORCHTURNS = 100    ;how long torch burns

#TIMERMILLISECONDS = 1
#TIMERCOMMANDS = 2
#TIMERROOM = 3

#STATESET = 1
#STATEGET = 2

#INVENTORYADD = 1
#INVENTORYDROP = 2
#INVENTORYDISPLAY = 3
#INVENTORYCHECK = 4
#HASITEM = "HAS"
#NOTHASITEM = "NOT"

EnumerationBinary
#STATE0 = 1
#STATE1
#STATE2
#STATE3
#STATE4
#STATE5
#STATE6
#STATE7
#SAVAIL
#SDARK
#SFIXED
#SDROPPED
#SPLAYERAWARE
#SCODEAWARE
#SONETIME
EndEnumeration

Enumeration
  #DIALOG_NONE
  #DIALOG_REFRESH
  #DIALOG_ABOUT
  #DIALOG_CREDITS
  #DIALOG_QUESTION
  #DIALOG_HELP
EndEnumeration

Structure EOTIMER
  strEvent.s
  iType.i
  iStart.i
  StructureUnion
    iTime.i
    iCount.i
  EndStructureUnion
  strRoom.s
  strMetadata.s
EndStructure

CompilerIf #PB_Compiler_OS = #PB_OS_Linux
  Structure RECT
    left.i
    top.i
    right.i
    bottom.i
  EndStructure
CompilerEndIf

Structure globalvars
  hCommandFont.i
  iCommandFontHeight.i
  hDirectionsFont.i
  hOutputFont.i
  hTitleFont.i
  iOutputFontHeight.i
  RGBOutputColor.i
  imgBackground.i
  iMaxResX.i
  iMaxResY.i
  imgFlameOn.i
  imgFlameOff.i
  iXStart.i
  iXWidth.i
  iYHeightO.i
  iYStartO.i
  iYStartC.i
  iYHeightC.i
  iXDir.i
  iXCommand.i
  iXFlame.i
  iYFlame.i
  rDialog.RECT
  fGray.i 
  iDialog.i
  iPageKey.i
  fPauseInput.i
  iDirty.i          ;state changes since last SAVE?
  strENTRYPROMPT.s  ;a static value that contains the prompt for the command entry area
EndStructure

Structure gameinfo
  strCommand.s      ;command returned from GetCommand() when ENTER is pressed
  *ptrInventory.ROOM
  *ptrRoom.ROOM
  *ptrPrevRoom.ROOM
  *ptrTorch.NOUN
  Map Timers.EOTIMER()
  iNumCommands.i
  iCoins.i
  iTorchBurnTime.i    ;how many moves has torch been burning
  strLastSaveFile.s
  fLightSource.i
  fLightPermanent.i
  fInTree.i
  iTheme.i
  fHaveBackpack.i
  strDialogVerb.s
  strLoadFileName.s
EndStructure

Structure NOUN
  strNoun.s
  strVerbs.s        ;verbs are stored as full words
  iState.i          ;#STATE[0-7], #SAVAIL, #SFIXED, #SDROPPED, #SPLAYERAWARE. Set during init from DataSection and by code
  strDescription.s
  strRoom.s
  strStateAction.s
  strBaseNoun.s     ;reference to instance of base noun for synonyms
  strMetadata.s     ;handle whatever data needed, if any
EndStructure

Structure ROOM
  StructureUnion
    iState.i    ;#STATE[0-7], #SDARK. Set during init from DataSection and by code
    iCount.i    ;Used only for inventory "room", holds count of items in inventory
  EndStructureUnion
  iRoomX.i    ;X coordinate in movement array
  iRoomY.i    ;Y coordinate in movement Array
  strRoom.s
  strDescription.s
  strStateAction.s
  strOneTime.s
  Map mapNouns.s(#MAXPERROOM)    ;list of nouns (objects) in room. mapkey is #PARSELEN chars of noun. Full noun is map value
EndStructure

Structure MOVE
  strAvail.s        ;NSEW positions: 0=no,1=yes,2=locked,3=closed,5=blocked,6=teleport,9=codehandler
  strRoom.s         ;Name of this room for lookup in Rooms() MAP
EndStructure

;
;Global variables
;
Global GU.globalvars         ;game utility variables
Global GG.gameinfo           ;gameplay variables
Global NewMap Nouns.NOUN()   ;mapkey is #PARSELEN characters of noun. Full noun name in \strNoun
Global NewMap Verbs.s()      ;mapkey is #PARSELEN characters of verb. Full verb is map value
Global NewMap Rooms.ROOM()   ;find map elements by full room name
Global Dim rgMove.MOVE(#ROOMX, #ROOMY)

; IDE Options = PureBasic 5.70 LTS beta 1 (Windows - x64)
; CursorPosition = 9
; Folding = -
; EnableXP