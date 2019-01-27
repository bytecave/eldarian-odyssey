Declare MakePlayerAware()
  
;declare as floats so float math is used. These are taken directly from the areas layed out in original background artwork
#ARTWIDTH = 3840.0    ;actual width of maximum sized artwork stored in resource file
#ARTHEIGHT = 2160.0   ;actual height
#XSTART = 320.0       ;left column for all text to start
#XCOMMAND = 265       ;left column for command input
#XEND = 3530.0        ;right-hand side for all text to end
#YSTART_O = 475.0     ;top of area to draw in for output area
#YEND_O = 1705.0      ;bottom of output area
#YSTART_C = 1850.0    ;top of area to draw in for command input
#YEND_C = 2030.0      ;bottom of command input
#XDIRSTART = 2350.0   ;left column for printing directions
#DIALOGX = 190.0      ;x, y, width, height of dialogs
#DIALOGY = 415.0
#DIALOGW = 3450.0
#DIALOGH = 1670.0
#LOGOX = 3140.0
#LOGOY = 500.0
#FLAMEX = 3250.0      ;left edge foe flame image
#FLAMEY = 1815.0
    
#TALLCHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYgjpqy" ;Used in test for tallest glyph in font
#WIDECHAR = "W"           ;widest glyph in the font goes here, for command line width calculation

#FONT_COMMAND = 1
#FONT_OUTPUT = 2

#THEME1 = 1
#THEME2 = 2
#COLOR_OUTPUTTEXT1 = $00FF00     ;PureBasic colors are $[AA]BBGGRR - green
#COLOR_OUTPUTTEXT2 = $000000     ;PureBasic colors are $[AA]BBGGRR - black

#WINDOWID = 0
#MINWIDTH = 1366
#MINHEIGHT = 768

#COMMAREPLACE = "\@"
#ENDOFDATA = "<x>"

#START_NEWITEM = "}"
#START_COMMENT = ";"
#START_COORD = "("
#START_MOVE = "^"
#START_SYNONYM = "^"
#START_UNATTACHEDSYNONYM = "&"
#START_VERB = "!"
#START_ROOM = "$"
#START_STATEACTION = "@"
#START_ONETIMETEXT = "%"

#ALWAYSVERBS = ",HELP,HINT,INV,INVENTORY,DROP,EXAMINE,INSPECT,GET,GRAB,TAKE,LOOK,QUIT,EXIT,SAVE,LOAD,NEW,GO,MOVE,NORTH,SOUTH,EAST,WEST,N,S,E,W,I,L,DIR,LS"

Procedure SetTheme(iTheme.i)
  Protected iImageStart.i, iColor.i
  
  If IsImage(GU\imgBackground)
    FreeImage(GU\imgBackground)
  EndIf
  
  If iTheme = #THEME1
    iImageStart = ?img_main_background1
    iColor = #COLOR_OUTPUTTEXT1
  Else
    iImageStart = ?img_main_background2
    iColor = #COLOR_OUTPUTTEXT2
  EndIf
  
  GG\iTheme = iTheme
    
  With GU
    ;get background image
    \imgBackground = CatchImage(#PB_Any, iImageStart)
    ResizeImage(\imgBackground, \iMaxResX, \iMaxResY, #PB_Image_Smooth)
  EndWith
  
  GU\RGBOutputColor = iColor
EndProcedure

Procedure InitializeScreen()
  Protected hWindow.i
  
  If InitSprite() = 0 Or InitKeyboard() = 0
    MessageRequester(_L(ERROR), _L(CANTINITGRAPHICS), 0)
    End
  EndIf
  
  ;Open a minimum sized resizeable window, but maximize it on open (#PB_Window_Maximize)
  If OpenWindow(#WINDOWID, 0, 0, #MINWIDTH, #MINHEIGHT, _L(apptitle), #PB_Window_SizeGadget | #PB_Window_SizeGadget | #PB_Window_MaximizeGadget | #PB_Window_Invisible | #PB_Window_Maximize)
    
    With GU
      ;Get maximum window client area size -- window was created maximized above
      \iMaxResX = WindowWidth(#WINDOWID, #PB_Window_InnerCoordinate)
      \iMaxResY = WindowHeight(#WINDOWID, #PB_Window_InnerCoordinate)
      
      ;Scale starting positions, width and height depending upon max screen resolution when we open window.
      \iXStart = #XSTART * \iMaxResX / #ARTWIDTH
      \iXWidth = #XEND * \iMaxResX / #ARTWIDTH - \iXStart
      \iYStartO = #YSTART_O * \iMaxResY / #ARTHEIGHT
      \iYHeightO = #YEND_O * \iMaxResY / #ARTHEIGHT - \iYStartO
      \iYStartC = #YSTART_C * \iMaxResY / #ARTHEIGHT
      \iYHeightC = #YEND_C * \iMaxResY / #ARTHEIGHT - \iYStartC
      \iXCommand = #XCOMMAND * \iMaxResX / #ARTWIDTH
      \iXDir = #XDIRSTART * \iMaxResX / #ARTWIDTH
      
      ;scale bounding area of dialogs - right=width, bottom=height
      \rDialog\left = #DIALOGX * \iMaxResX / #ARTWIDTH
      \rDialog\right = #DIALOGW * \iMaxResX / #ARTWIDTH
      \rDialog\top = #DIALOGY * \iMaxResY / #ARTHEIGHT
      \rDialog\bottom = #DIALOGH * \iMaxResY / #ARTHEIGHT

      ;Set minimum window size when resizing
      WindowBounds(#WINDOWID, #MINWIDTH, #MINHEIGHT, #PB_Ignore, #PB_Ignore)
      
      ;get torch images
      \imgFlameOn = CatchImage(#PB_Any, ?img_flameon)
      ResizeImage(\imgFlameOn, ImageWidth(\imgFlameOn) * \iMaxResX / #ARTWIDTH, ImageHeight(\imgFlameOn) * \iMaxResY / #ARTHEIGHT, #PB_Image_Smooth)
      \imgFlameOff = CatchImage(#PB_Any, ?img_flameoff)
      ResizeImage(\imgFlameOff, ImageWidth(\imgFlameOff) * \iMaxResX / #ARTWIDTH, ImageHeight(\imgFlameOff) * \iMaxResY / #ARTHEIGHT, #PB_Image_Smooth)
      
      \ixFlame = #FLAMEX * \iMaxResX / #ARTWIDTH
      \iyFlame = #FLAMEY * \iMaxResY / #ARTHEIGHT
      
      SetTheme(#THEME1)
    EndWith
  
    ;Open an auto-stretched (PureBasic) screen the size of the parent window client area
    If OpenWindowedScreen(WindowID(#WINDOWID), 0, 0, GU\iMaxResX, GU\iMaxResY, #True, 0, 0, #PB_Screen_SmartSynchronization)
      
      ;Create image that we'll use for all drawing except final output to screen
      If CreateImage(#IMAGEBUFID, GU\iMaxResX, GU\iMaxResY, ScreenDepth())
    
        ;all window initialization worked, exit now
        ProcedureReturn
      EndIf
    EndIf
  EndIf
  
  MessageRequester(_L(ERROR), _L(CANTINITSCREEN), 0)
  End
EndProcedure

Procedure InitializeFont(iWhichFont.i)
  Protected iTestFont.i, iTestHeight.i
  Protected iBestHeight.i, iFontSize.i, iMaxHeight.i, iBestFontSize.i
  Protected hFont.i
  
  Protected strFontFile.s, strFontFace.s, iFontStart.i, iFontLen.i, iMaxLines.i
  
  Select iWhichFont
    Case #FONT_COMMAND
      If IsFont(GU\hCommandFont)
        FreeFont(GU\hCommandFont)
      EndIf
      
      iMaxHeight = GU\iYHeightC
      strFontFile = _L(command_font_filename)
      strFontFace = _L(command_font)
      iFontStart = ?start_command_font
      iFontLen = ?end_command_font - ?start_command_font
      iMaxLines = 2   ;need to check height of both lines for command input area
    Case #FONT_OUTPUT
      If IsFont(GU\hOutputFont)
        FreeFont(GU\hOutputFont)
      EndIf
      
      iMaxHeight = GU\iYHeightO
      strFontFile = _L(output_font_filename)
      strFontFace = _L(output_font)
      iFontStart = ?start_output_font
      iFontLen = ?end_output_font - ?start_output_font
      iMaxLines = #MAXOUTPUTLINES   ;Always want #MAXOUTPUTLINES lines in the output area
  EndSelect
    
  iFontSize = 10   ;start with 10 point font
  
  Repeat
    hFont = LoadPrivateFont(strFontFile, strFontFace, iFontStart, iFontLen, iFontSize)
    
    ;no drawing commands here, just need context for TextHeight() call
    StartDrawing(ScreenOutput())
    DrawingMode(#PB_2DDrawing_Transparent)
    DrawingFont(FontID(hFont))
    
    iTestHeight = iMaxLines * TextHeight(#TALLCHARS)
    StopDrawing()
    
    If iTestHeight < iMaxHeight
      iBestHeight = iTestHeight
      iBestFontSize = iFontSize
      iFontSize + 1
    EndIf
      
    FreeFont(hFont)
  Until iTestHeight >= iMaxHeight
  
  hFont = LoadPrivateFont(strFontFile, strFontFace, iFontStart, iFontLen, iBestFontSize)
  
  If hFont
    Select iWhichFont
      Case #FONT_COMMAND
        GU\hCommandFont = FontID(hFont)
        GU\iCommandFontHeight = iMaxHeight / iMaxLines  ;use iMaxHeight instead of iBestHeight to spread lines evenly in area
        
        ;create a font double the size of the command font for use in printing direction (NSEW)
        hFont = LoadPrivateFont(strFontFile, strFontFace, iFontStart, iFontLen, iBestFontSize * 2)
        GU\hDirectionsFont = FontID(hFont)
        
      Case #FONT_OUTPUT
        GU\hOutputFont = FontID(hFont)
        GU\iOutputFontHeight = iMaxHeight / iMaxLines
        
        ;create a title font for the dialogs
        hFont = LoadPrivateFont(strFontFile, strFontFace, iFontStart, iFontLen, iBestFontSize * 2)
        GU\hTitleFont = FontID(hFont)
    EndSelect
  Else
    MessageRequester(_L(ERROR), _L(CANTINITFONT) + strFontFace + _L(FILE) + strFontFile, 0)
    End
  EndIf
EndProcedure

Procedure InitializeRooms(fReinitialize.i = #False)
  Protected strLine.s, strRoom.s, strToken.s, strWord.s
  Protected *ptrNew.ROOM
  Protected i.i, j.i
  Protected iRoomX.i = -1, iRoomY.i = -1
  Protected strDirections.s, strDelim.s
  Dim tokens.s(0)
  
  ;Initialize reading rooms file from memory
  ReadFileFromMemory(?start_rooms)

  Repeat
    strLine = ReadFileFromMemory()
    
    If strLine <> #ENDOFDATA
      Select Left(strLine, 1)
        Case #START_COMMENT
          strLine = ""   ;SplitString will return 0 now
          
        Case #START_DESC, #START_ONETIMETEXT
          ;don't split the line if it's a description line, that way we can use commas in description text
          strDelim = Chr(0)

        Default
          strDelim = ","
      EndSelect
      
      If SplitString(strLine, strDelim, tokens())
        With *ptrNew
          For i = 0 To ArraySize(tokens())
            
            strToken = tokens(i)
            strWord = Mid(strToken, 2)
            
            Select Left(strToken, 1)
              Case #START_NEWITEM
                strRoom = UCase(strWord)
                
                If Not fReinitialize
                  
CompilerIf #PB_Compiler_Debugger
;when debugging only, check word list to see if we have a duplicate noun after shortening to first #PARSELEN characters
  If FindMapElement(Rooms(), strRoom)
    Debug "Duplicate room found! " + Rooms()\strRoom
    End
  EndIf
CompilerEndIf

                  *ptrNew = AddMapElement(Rooms(), strRoom)
                Else
                  *ptrNew = FindMapElement(Rooms(), strRoom)
                  
                  ;During re-initialize, this will remove all nouns from room.
                  ResetMap(\mapNouns())
                  While NextMapElement(\mapNouns())
                    DeleteMapElement(\mapNouns())
                  Wend
                EndIf
                
                \strRoom = strRoom
                \iState = 0
                  
              Case #START_COORD
                \iRoomX = Val(Left(strWord,1))
                \iRoomY = Val(Mid(strWord, 3, 1))
              
  CompilerIf #PB_Compiler_Debugger
  ;when debugging only, check to see if x,y are valid coordinates
    If iRoomX > #ROOMX Or iRoomY > #ROOMY
      Debug "Bad room coordinates: (" + Str(iRoomX) + "," + Str(iRoomY) + ")"
      End
    EndIf
  CompilerEndIf
    
              Case #START_MOVE
                rgMove(\iRoomX, \iRoomY)\strAvail = strWord    ;initialize available directions in movement array
                rgMove(\iRoomX, \iRoomY)\strRoom = strRoom     ;name of room for lookup in Rooms() MAP
                
              Case #START_STATE      ;state string in format of  *[dark bit][state 0][state 1][state ...][state 7]", ex: *110100000 = dark, state 0, state 2 all set
                \iState | (#SDARK * Val(Left(strWord, 1)))   ;dark state if starts with non-numeric
                
                ;Our state bits are EnumerationBinary, so each power of 2 is a separate bit
                For j = 0 To 7
                  If Mid(strWord, j + 2, 1) = "1"
                    \iState | Int(Pow(2, j))
                  EndIf
                Next
                
              Case #START_DESC
                \strDescription = ReplaceString(strToken, #COMMAREPLACE, ",")      ;use strToken as we want to keep the beginning '['
                
              Case #START_STATEACTION
                \strStateAction + "," + UCase(strWord)

              Case #START_ONETIMETEXT
                \strOneTime = ReplaceString(strToken, #COMMAREPLACE, ",")
                \iState | #SONETIME
                
              Default
                Debug strToken + " <<<***IN Default Case For ADD ROOM>>>"
            EndSelect
          Next
        EndWith
      EndIf
    EndIf
  Until strLine = #ENDOFDATA
EndProcedure

Procedure InitializeThingsAndActions(fReinitialize.i = #False)
  Protected strLine.s, strNoun.s, strToken.s, strWord.s
  Protected *ptrNew.NOUN, *ptrRoom.ROOM
  Protected i.i, j.i, strDelim.s
  Dim tokens.s(0)
  
  ;Initialize reading rooms file from memory
  ReadFileFromMemory(?start_nouns)

  Repeat
    strLine = ReadFileFromMemory()
    
    If strLine <> #ENDOFDATA
      Select Left(strLine, 1)
        Case #START_COMMENT
          strLine = ""   ;SplitString will return 0 now
          
        Case #START_DESC
          ;don't split the line if it's a description line, that way we can use commas in description text
          strDelim = Chr(0)

        Default
          strDelim = ","
      EndSelect
      
      If SplitString(strLine, strDelim, tokens())
        With *ptrNew
          For i = 0 To ArraySize(tokens())
            strToken = tokens(i)
            strWord = Mid(strToken, 2)
            
            Select Left(strToken, 1)
              Case #START_NEWITEM
                strNoun = UCase(strWord)
                
                If Not fReinitialize
                  
CompilerIf #PB_Compiler_Debugger
;when debugging only, check word list to see if we have a duplicate noun after shortening to first #PARSELEN characters
  If FindMapElement(Nouns(), strNoun)
    Debug "Duplicate noun found! " + Nouns()\strNoun
    End
  EndIf
CompilerEndIf

                  *ptrNew = AddMapElement(Nouns(), Left(strNoun, #PARSELEN))
                Else
                  *ptrNew = FindMapElement(Nouns(), Left(strNoun, #PARSELEN))
                EndIf
                
                \strNoun = strNoun
                \iState = 0
                \strStateAction = ""
                  
              Case #START_SYNONYM, #START_UNATTACHEDSYNONYM    ;this is a synonym for a noun
                
                If Not fReinitialize
                
  CompilerIf #PB_Compiler_Debugger
  ;when debugging only, check word list to see if we have a duplicate synonym after shortening to first #PARSELEN characters
    If Left(strToken, 1) = #START_SYNONYM And FindMapElement(Nouns(), Left(strWord, #PARSELEN))
      Debug "Duplicate synonym found! Existing: " + Nouns()\strNoun + ", New: " + strWord
      End
    EndIf
  CompilerEndIf
      
                  AddMapElement(Nouns(), Left(strWord, #PARSELEN))
                  Nouns()\strNoun = strWord
                  
                  If Left(strToken, 1) = #START_SYNONYM
                    Nouns()\strBaseNoun = *ptrNew\strNoun
                  Else
                    Nouns()\strBaseNoun = #START_UNATTACHEDSYNONYM  ;special sentinel to indicate unattached synonym for parser
                  EndIf
                EndIf
    
              Case #START_VERB
                If Not fReinitialize
                  AddMapElement(Verbs(), Left(strWord, #PARSELEN))
                  Verbs() = strWord
                  
                  \strVerbs + _COMMAS(strWord)
                EndIf
                
              Case #START_STATE    
                ;state string in format of  *[available][fixed][dropped][playeraware][state 0][state 1][state ...][state 7]", ex: *11010100000 = fixed, available, not dropped, player aware, and state 1 set
                \iState | (#SAVAIL * Val(Left(strWord, 1)))
                \iState | (#SFIXED * Val(Mid(strWord, 2, 1)))
                \iState | (#SDROPPED * Val(Mid(strWord, 3, 1)))
                
                ;Playeraware state uses "1" for aware, and "9" for only made aware by special code. 
                Select Val(Mid(strWord, 4, 1))
                  Case 1
                    \iState | #SPLAYERAWARE
                  Case 9
                    \iState | #SCODEAWARE
                EndSelect
                
                ;Our state bits are EnumerationBinary, so each power of 2 is a separate bit
                For j = 0 To 7
                  If Mid(strWord, j + 6, 1) = "1"   ;Start at pos j + SIX to skip over '-' in definition
                    \iState | Int(Pow(2,j))
                  EndIf
                Next
                
              Case #START_ROOM
                \strRoom = UCase(strWord)
                *ptrRoom = FindMapElement(Rooms(), \strRoom)
                
  CompilerIf #PB_Compiler_Debugger
  ;when debugging only
    If Not *ptrRoom
      Debug "Can't find room to put noun. Noun=" + \strNoun + ", Room=" + \strDescription
    EndIf
  CompilerEndIf
  
                ;Add item to list of items in room. Key is #PARSELEN of noun, value is whole noun
                AddMapElement(*ptrRoom\mapNouns(), Left(strNoun, #PARSELEN))
                *ptrRoom\mapNouns() = strNoun
                
                If *ptrRoom\strRoom = #INVENTORY
                  GG\ptrInventory\iCount + 1
                EndIf
                
              Case #START_STATEACTION
                \strStateAction + "," + UCase(strWord)
                
              Case #START_DESC
                \strDescription = strToken    ;use strToken as we want to keep the beginning '['
                
              Default
                Debug strToken + " <<<***IN Default Case For ADD NOUN***>>>"
            EndSelect
          Next
        EndWith
      EndIf
    EndIf
  Until strLine = #ENDOFDATA
  
  If Not fReinitialize
    ;Add verbs in #ALWAYSVERBs to Verb Map
    SplitString(#ALWAYSVERBS, ",", tokens())
    For i = 0 To ArraySize(tokens())
      strWord = tokens(i)
      
      ;if verb doesn't arleady exist
      If Not FindMapElement(Verbs(), Left(strWord, #PARSELEN))
        AddMapElement(Verbs(), Left(strWord, #PARSELEN))
        Verbs() = strWord
      EndIf
    Next
  EndIf
EndProcedure

Procedure InitializeGame()
  P_InitalizeLoc("enu")
  InitializeScreen()
  
  HideWindow(#WINDOWID, #False)
  
  InitializeFont(#FONT_COMMAND)
  InitializeFont(#FONT_OUTPUT)
  InitializeRooms()
  
  ;starting room and special "room" reserved for inventory
  GG\ptrInventory = FindMapElement(Rooms(), #INVENTORY)
  GG\ptrInventory\iRoomX = -1     ;flag this as special "inventory" room, used in SAVE/LOAD GAME
  
  ;set starting room
  GG\ptrRoom = FindMapElement(Rooms(), #STARTINGROOM)
  GG\ptrPrevRoom = GG\ptrInventory   ;any room that's not starting room, "inventory" will work
  
  InitializeThingsAndActions()
  
  ;Make players aware of items in starting room
  MakePlayerAware()
  
  ;light source for game
  GG\ptrTorch = FindMapElement(Nouns(), Left(#TORCH, #PARSELEN))
  GG\iTorchBurnTime = #TORCHTURNS
  
  GG\iCoins = 1
  GG\fHaveBackpack = #True
  GG\fLightPermanent = #False
  GG\fInTree = #False
  GG\fLightSource = #False
  GU\strENTRYPROMPT = _L(entryprompt)
EndProcedure

Procedure ReinitializeGame()
  InitializeRooms(#True)
  InitializeThingsAndActions(#True)
  
  GG\iCoins = 1
  GG\fLightSource = #False
  GG\fHaveBackpack = #True
  GG\fLightPermanent = #False
  GG\fInTree = #False
  GG\strLastSaveFile = ""
  GG\strLoadFileName = ""
  
  GU\iDirty = 0
  GG\iTorchBurnTime = #TORCHTURNS
  
  ;set starting room
  GG\ptrRoom = FindMapElement(Rooms(), #STARTINGROOM)
  GG\ptrPrevRoom = GG\ptrInventory   ;any room that's not starting room, "inventory" will work
  
  ;Make players aware of items in starting room
  MakePlayerAware()
EndProcedure  

; IDE Options = PureBasic 5.70 LTS beta 1 (Windows - x64)
; CursorPosition = 533
; FirstLine = 462
; Folding = P6-
; Markers = 418
; EnableXP