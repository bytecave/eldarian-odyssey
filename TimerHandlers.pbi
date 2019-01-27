Procedure TimerCommandHandler(strEvent.s)
  Protected sTimer.EOTIMER
  Protected strMetadata.s, iPos.i
  
  iPos = FindString(strEvent, ",")
  If iPos
    strMetadata = Mid(strEvent, iPos + 1)
    strEvent = Left(strEvent, iPos - 1)
  EndIf
  
  Select strEvent
    Case "BURNGATE"
      AddToOutput("^*** You awake a few minutes later with an astonishingly painful headache and an equally bruised ego. Your torch has gone out.")
      
      GU\fPauseInput = #False
      GU\fGray = #False
      
      GG\fLightSource = #False
      CheckTorch(GU\iDirty)
      
    Case "KNOCKGATE"
      If GG\ptrRoom\strRoom = "ZARBURGSOUTHGATE"
        If strMetadata = "CHOP"
          AddToOutput("^*** A watchman, startled awake by the crash of the oak, slams open a small window in the gate and yells, " + Chr(34) + "What in tarnation?!" + Chr(34) + " His burning gaze fixes on you... expectantly.")
        Else
          AddToOutput("^*** A watchman, awakened by your knock, opens a small window in the gate and gazes at you... expectantly.")
        EndIf
        
        ChangeStateAction("KNOCK", "MAINGATE")
        ItemState(#STATESET, "WATCHMAN", #SPLAYERAWARE)
      Else
        ;add room timer if player not at Zarburg gate when timer expired
        With sTimer
          \strEvent = "KNOCKGATE"
          \iType = #TIMERROOM
          \strRoom = "ZARBURGSOUTHGATE"
        EndWith
        
        TimerCommand(@sTimer)
      EndIf
      
    Case "JUMPCLIFF"
      AddToOutput("^*** Wow! A well-timed updraft shoots you back up from the fatal depths and you land, shaken, back at the top of the cliff.")
      
      GU\fPauseInput = #False
      GU\fGray = #False
      GG\fLightSource = #False
      CheckTorch(GU\iDirty)
      
    Case "JUMPCHASM"
      AddToOutput("^*** Well, dang. That hurt ever so much for ever so little time. You awaken aching and bruised, but otherwise sound, in the Elven woods. The band around your neck fades from green back to blue.^^")
      
      GU\fPauseInput = #False
      GU\fGray = #False
      GG\fLightSource = #False
      CheckTorch(GU\iDirty)
      
      ChangeStateAction("PLAYERDIED", "BAND")
      ChangeCurrentRoom(0, 0, "ELVENWOODS")

    Case "FIGHTGUARD", "FIGHTKING", "FIGHTCLERK", "FIGHTBARMAID", "FIGHTDROW"
      If Random(100) < 50
        AddToOutput("^*** You awake with a painful gasp outside the south gate of Zarburg. The band around your neck sparkles a bright green for several seconds before resuming its blue glow.^^")
      Else
        AddToOutput("^*** You are sore all over as you awake, and your chest burns. Green lights sparkling from the band around your neck dance before your eyes as the band slowly fades back to blue.^^")
      EndIf
      
      GU\fPauseInput = #False
      GU\fGray = #False
      GG\fLightSource = #False
      CheckTorch(GU\iDirty)
      
      ChangeStateAction("PLAYERDIED", "BAND")
      ChangeCurrentRoom(0, 0, "ZARBURGSOUTHGATE")
      
    Case "FIGHTDAMBEN1"
      AddToOutput("^*** You free yourself from the tree. " + Chr(34) + "Don't try that again, adventurer! Else you will pay, but not with gold." + Chr(34) + "^^")
      
      GU\fPauseInput = #False
      GU\fGray = #False
      
    Case "FIGHTDAMBEN2"
      AddToOutput("^*** You awake with your head pounding and your vision blurred. You're able to make out a rythmic blue-green blob around your neck for the first several seconds. Eventually your vision clears, but you'll have a tremendous headache for quite some time.^^")
      
      GU\fPauseInput = #False
      GU\fGray = #False
      GG\fLightSource = #False
      CheckTorch(GU\iDirty)
      
      ChangeStateAction("PLAYERDIED", "BAND")
      ChangeCurrentRoom(0, 0, "ELVENWOODS")
      
    Case "BURNBUILDING"
      AddToOutput("^*** You feel very hot when you awaken, as if cursed. Your neck band fades from green back to a blue glow. In a little while, the heat within you subsides.^^")
      
      GU\fPauseInput = #False
      GU\fGray = #False
      GG\fLightSource = #False
      CheckTorch(GU\iDirty)
      
      ChangeStateAction("PLAYERDIED", "BAND")
      ChangeCurrentRoom(0, 0, "ELVENWOODS")
      
    Case "FIGHTVILLAGERS"
      AddToOutput("^*** It feels like every bone in your body has been broken, twice. You would never have guessed you could hurt this much. The band about your neck throbs a silent green, in time to the rhythmic aching of your being. Within a few minutes, you're able to move about again, the band on your neck once again a steady blue.^^")
      
      GU\fPauseInput = #False
      GU\fGray = #False
      GG\fLightSource = #False
      CheckTorch(GU\iDirty)
      
      ChangeStateAction("PLAYERDIED", "BAND")
      ChangeCurrentRoom(0, 0, "ELVENWOODS")
      
    Case "DRAGONFIRE"
      AddToOutput("^*** Your crispened flesh transforms to normal in front of your eyes as you awaken with an agonized gasp! Your neck band dances a washed out green before resuming its blue glow.^^")
      
      GU\fPauseInput = #False
      GU\fGray = #False
      GG\fLightSource = #False
      CheckTorch(GU\iDirty)
      
      ChangeStateAction("PLAYERDIED", "BAND")
      ChangeCurrentRoom(0, 0, "BURROW")
      
    Case "SKELETONDEATH"
      AddToOutput("^*** You awaken slowly in the dark burrow! The only light is the rapid green flashing of the band on your neck, before it fades to a soft, blue glow.^^")
      
      GU\fPauseInput = #False
      GU\fGray = #False
      GG\fLightSource = #False
      CheckTorch(GU\iDirty)
      
      ChangeStateAction("PLAYERDIED", "BAND")
      ChangeCurrentRoom(0, 0, "BURROW")
      
    Case "LICHINSTANT"
      AddToOutput("^*** You awaken, shivering, in the burrow near entrace to the dungeon. Your icy heart warms and beats to the rhythm of the green pulsing on the band about you neck. Your band returns to a light blue and you sit up, ready for more.^^")
      
      GU\fPauseInput = #False
      GU\fGray = #False
      GG\fLightSource = #False
      CheckTorch(GU\iDirty)
      
      ChangeStateAction("PLAYERDIED", "BAND")
      ChangeCurrentRoom(0, 0, "BURROW")
      
    Case "LICHINSTANT", "LICHDEATH"
      DoLichTimer(strEvent)
      
  EndSelect
EndProcedure
; IDE Options = PureBasic 5.70 LTS beta 1 (Windows - x64)
; CursorPosition = 34
; FirstLine = 24
; Folding = -
; EnableXP