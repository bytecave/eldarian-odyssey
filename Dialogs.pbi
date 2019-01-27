#LEGENDCOLOR = $00FF00
#DIALOGTEXTCOLOR = $FFFFFF
#DIALOGBACKGROUND = $F1010101  ;includes alpha channel
#CHROMAKEY = $DC00FF

Structure ABOUTPAGE
  iPageStart.i
  iPageChars.i
EndStructure

;top Y coordinate and max lines of about text
Define sh_fSetupDialog.i, sh_iMaxDialogLines.i
Define sh_iLine.i, sh_iPage.i
Define sh_iYStartD.i, sh_iNumPages.i
Dim sh_rgPages.ABOUTPAGE(1)    ;will use base=1 for first element, so need 2 elements (0 and 1)
Define sh_iCharacters.i, sh_iDialogTextLen.i

Procedure OkayToAct(strAnswer.s, strOverrideVerb.s = "")
  GU\fGray = #False
  GU\iDialog = #DIALOG_NONE
  
  If strOverrideVerb <> ""
    GG\strDialogVerb = strOverrideVerb
  EndIf
  
  If strAnswer = "Y"
    Select GG\strDialogVerb
      Case "EXIT"
        End        
      Case "LOAD"
        LoadGame(GG\strLoadFileName, #True)
      Case "QUIT", "NEW"
        ClearOutputBuffer()
        AddToOutput("*** You quit the previous game. New game started.^^")
        ReinitializeGame()
    EndSelect
  Else
    AddToOutput("Ok, no action taken.")
  EndIf
EndProcedure

Procedure DrawAboutText(strText.s)
  Shared sh_iLine.i, sh_fSetupDialog.i
  Shared sh_iYStartD.i, sh_iMaxDialogLines.i
  Shared sh_iNumPages.i, sh_iPage.i
  Shared sh_iCharacters.i, sh_iDialogTextLen.i
  Shared sh_rgPages.ABOUTPAGE()
  
  If sh_fSetupDialog
    sh_iCharacters + Len(strText)
    ;got characters + length of string, but string isn't going on this page if it's nam nec
        
    If sh_iCharacters = sh_iDialogTextLen
      sh_fSetupDialog = #False
    EndIf
    
    ;We won't print blank lines at the top of the page
    If Trim(strText) > "" Or sh_iLine > 0
      
      ;if too many lines for this page, create a new one and note which character it starts at
      If sh_iLine = sh_iMaxDialogLines
        sh_iNumPages + 1
        
        sh_iLine = 1
        
        ReDim sh_rgPages.ABOUTPAGE(sh_iNumPages)
        sh_rgPages(sh_iNumPages)\iPageStart = sh_iCharacters - Len(strText) + 1
      Else
        sh_iLine + 1
      EndIf
    EndIf
    
    ;count of characters on current page
    With sh_rgPages(sh_iNumPages)
      \iPageChars = sh_iCharacters - \iPageStart + 1
    EndWith
  Else
    FrontColor(#DIALOGTEXTCOLOR)
    
    ;Don't print blank lines at the top of the page
    If Trim(strText) > "" Or sh_iLine > 0
      
      ;#SPECIALSPACE characters allow forcing spaces at the beginning of a line
      DrawText(GU\iXStart, sh_iYStartD + GU\iOutputFontHeight * sh_iLine, ReplaceString(Trim(strText), #SPECIALSPACE, " "))
      
      If sh_iLine = sh_iMaxDialogLines 
        sh_iLine = 1
      Else
        sh_iLine + 1
      EndIf
    EndIf
  EndIf
EndProcedure

Procedure FixUpText(str.s)
  ReplaceString(str, #SPECIALSPACE, " ")
EndProcedure


Procedure DialogBox(nDialogMode.i, strQuestion.s = "", strVerb.s = "")
  Static imgLogo.i, iXLogo.i
  Static strClose.s, iXClose.i, strTitle.s
  Static iYLine.i, iYText.i
  Static strDialog.s, iYLegend.i
  Static iXPageUp.i, iXPageDn.i, strPageUp.s, strPageDn.s
  Static iXWhichDialog.i, strPressFor.s
  Static fUIInitialized.i, iXTheme.i, strTheme.s
  
  Shared sh_iYStartD.i, sh_iMaxDialogLines.i
  Shared sh_rgPages.ABOUTPAGE(), sh_iLine.i, sh_iNumPages.i, sh_iPage.i
  Shared sh_iCharacters.i, sh_iDialogTextLen.i, sh_fSetupDialog.i
  
  Protected fInitializeText
  
  If (nDialogMode <> #DIALOG_REFRESH)
    GU\fGray = #True
    
    ;only have to do this one time ever during execution of the program; all variables are static
    If Not fUIInitialized
      imgLogo = CatchImage(#PB_Any, ?img_logo)
      iXLogo = GU\rDialog\left + GU\rDialog\right - ImageWidth(imgLogo) * 1.2
      iYLine = GU\iYStartO + ImageHeight(imgLogo) * 1.1
      
      ;top of drawing area for dialog text, and maximum # of lines per page
      sh_iYStartD = iYLine + TextHeight(#TALLCHARS)
      sh_iMaxDialogLines = (GU\rDialog\top + GU\rDialog\bottom - sh_iYStartD) / TextHeight(#TALLCHARS) - 3
      
      strTitle = _L(apptitle) + " - " + _L(copyright)
      
      strClose = _L(closedialog)
      iXClose = GU\rDialog\left + GU\rDialog\right - TextWidth(strClose) * 1.2
      iYLegend = GU\rDialog\top + GU\rDialog\bottom - TextHeight(strClose) * 1.5
      
      strPageDn = _L(pagedn)
      iXPageDn = iXClose - TextWidth(strClose) * 1
      strPageUp = _L(pageup)
      iXPageUp = iXPageDn - TextWidth(strPageDn) * 1.5
      
      strPressFor = _L(credits)
      iXWhichDialog = ixPageUp - TextWidth(strPressFor) * 1.3
      
      iXTheme = GU\rDialog\left + 20
      
      fUIInitialized = #True
    EndIf
    
    Select nDialogMode
      Case #DIALOG_ABOUT
        If GU\iDialog <> #DIALOG_ABOUT
          GU\iDialog = #DIALOG_ABOUT
          strPressFor = _L(credits)
          strTheme = _L(theme)
        
          strDialog = PeekS(?start_text_about, ?end_text_about - ?start_text_about, #PB_Ascii)
          fInitializeText = #True
        EndIf
        
      Case #DIALOG_CREDITS
        If GU\iDialog <> #DIALOG_CREDITS
          GU\iDialog = #DIALOG_CREDITS
          strPressFor = _L(about)
          strTheme = _L(theme)
        
          strDialog = PeekS(?start_text_credits, ?end_text_credits - ?start_text_credits, #PB_Ascii)
          fInitializeText = #True
        EndIf
        
      Case #DIALOG_QUESTION
        If GU\iDialog <> #DIALOG_QUESTION
          GU\iDialog = #DIALOG_QUESTION
          
          ;When dialog closes, appropriate action will be taken based on answer and this verb
          GG\strDialogVerb = strVerb
          
          strTheme = ""
          strPressFor = ""
          strDialog = strQuestion + "^^     [Y or N]"
          fInitializeText = #True
        EndIf
        
      Case #DIALOG_HELP
        If GU\iDialog <> #DIALOG_HELP
          GU\iDialog = #DIALOG_HELP
          strPressFor = ""
          strTheme = _L(theme)
        
          strDialog = PeekS(?start_text_help, ?end_text_help - ?start_text_help, #PB_Ascii)
          fInitializeText = #True
        EndIf
    EndSelect
    
    If fInitializeText
      ;set up for iniital text draw callback pass
      sh_iDialogTextLen = Len(strDialog)
      
      sh_fSetupDialog = #True
      sh_iCharacters = 0
      sh_iNumPages = 1
      sh_iPage = 1
      
      sh_rgPages(1)\iPageStart = 1
      sh_rgPages(1)\iPageChars = sh_iDialogTextLen
          
      fInitializeText = #False
    EndIf
  EndIf
  
  ;Overlay the screen with a dark background
  DrawingMode(#PB_2DDrawing_AlphaBlend)
  FrontColor(#DIALOGBACKGROUND)
  
  With GU\rDialog
    Box(\left, \top, \right, \bottom)
  EndWith
  
  ;draw logo
  DrawAlphaImage(ImageID(imgLogo), iXLogo, GU\iYStartO)
  
  DrawingMode(#PB_2DDrawing_Transparent | #PB_2DDrawing_AlphaBlend | #PB_2DDrawing_Gradient)
  DrawingFont(GU\hTitleFont)
  
  ;draw dialog title in rainbow gradient
  LinearGradient(GU\iXStart, GU\iYStartO, GU\iXStart + TextWidth(strTitle), GU\iYStartO + TextHeight(strTitle))
  GradientColor(0.0,  $80FF0000)
  GradientColor(0.25, $FF00FF00)
  GradientColor(0.50, $8000FFFF)
  GradientColor(0.75, $FF0000FF)
  GradientColor(1.0,  $80FF0000)
  
  DrawText(GU\iXStart, GU\iYStartO, strTitle)
  
  ;draw line underneath dialog title
  ResetGradientColors()
  GradientColor(0.0, $FF00FF00)   ;full green
  GradientColor(1.0, $FF005000)   ;to mid green
  Box(GU\iXStart, iYLine, GU\iXWidth, 5)
  
  DrawingMode(#PB_2DDrawing_Transparent)
  DrawingFont(GU\hOutputFont)
  
  Select GU\iPageKey
    Case #PB_Key_PageDown
      If sh_iPage < sh_iNumPages
        sh_iPage + 1
      EndIf
    Case #PB_Key_PageUp
      If sh_iPage > 1      ;first page is page 1
        sh_iPage - 1
      EndIf
  EndSelect
  
  GU\iPageKey = #PB_Key_0   ;as long as it's not PgDn or PgUp

  ;Send the current page's lines to the dialog for display
  sh_iLine = 0
  With sh_rgPages(sh_iPage)
    AddToOutput(Mid(strDialog, \iPageStart, \iPageChars), #True)
  EndWith
  
  ;draw close, pgup, pgdn prompts
  FrontColor(#LEGENDCOLOR)
  DrawText(iXClose, iYLegend, strClose)
  DrawText(iXWhichDialog, iYLegend, strPressFor)
  DrawText(iXTheme, iYLegend, strTheme)
  
  If sh_iPage < sh_iNumPages
    DrawText(iXPageDn, iYLegend, strPageDn)
  EndIf
  If sh_iPage > 1
    DrawText(iXPageUp, iYLegend, strPageUp)
  EndIf
EndProcedure
; IDE Options = PureBasic 5.70 LTS beta 1 (Windows - x64)
; CursorPosition = 31
; FirstLine = 27
; Folding = -
; EnableXP