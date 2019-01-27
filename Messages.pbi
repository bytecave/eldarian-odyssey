;Return a random string from the specified Data section
Procedure.s RandomMessageString(*ptrStart, *ptrEnd, strFind.s, bNumChoices.i)  
  Protected fTryAgain.i, *pString
  Protected strMsg.s, strID.s
  
  Repeat
    fTryAgain = #False
    
    strID = "[" + strFind + RSet(Str(Random(bNumChoices, 1)), 2, "0") + "]"
    *pString = QuickStringSearch(*ptrStart, *ptrEnd - *ptrStart + 1, @strID, StringByteLength(strID))
    
    strMsg = PeekS(*pString + StringByteLength(strID + " "))
    
    If Val(strMsg)
      If Random(100) <= Val(strMsg)
        strMsg = Mid(strMsg, FindString(strMsg, ",") + 1)
      Else
        fTryAgain = #True
      EndIf
    EndIf
  Until Not fTryAgain
  
  ProcedureReturn strMsg
EndProcedure

Procedure.s HandleMessage(strTag.s)
  Protected bNum.b, iStart.i, iEnd.i
  
  Select strTag
    Case "noexit"
      iStart = ?noexit
      iEnd = ?noexitend
      Restore noexit:
    Case "lockedexit"
      iStart = ?lockedexit
      iEnd = ?lockedexitend
      Restore lockedexit:
    Case "dontknow"
      iStart = ?dontknow
      iEnd = ?dontknowend
      Restore dontknow:
    Case "inventory"
      iStart = ?inventory
      iEnd = ?inventoryend
      Restore inventory:
    Case "badget"
      iStart = ?badget
      iEnd = ?badgetend
      Restore badget:
    Case "baddrop"
      iStart = ?baddrop
      iEnd = ?baddropend
      Restore baddrop:
    Case "get"
      iStart = ?get
      iEnd = ?getend
      Restore get:
    Case "badword"
      iStart = ?badword
      iEnd = ?badwordend
      Restore badword:
    Case "dirtree"
      iStart = ?dirtree
      iEnd = ?dirtreeend
      Restore dirtree:
    Case "cannotdo"
      iStart = ?cannotdo
      iEnd = ?cannotdoend
      Restore cannotdo:
    Case "nounverberr"
      iStart = ?nounverberr
      iEnd = ?nounverberrend
      Restore nounverberr:
    Case "toomanynv"
      iStart = ?toomanynv
      iEnd = ?toomanynvend
      Restore toomanynv:
    Case "toomanyn"
      iStart = ?toomanyn
      iEnd = ?toomanynend
      Restore toomanyn:
    Case "noverb"
      iStart = ?noverb
      iEnd = ?noverbend
      Restore noverb:
    Default
      Debug "BAD MESSAGE HANDLER, should never see this."
      ProcedureReturn ""
  EndSelect
      
  Read.b bNum
  ProcedureReturn RandomMessageString(iStart + SizeOf(byte), iEnd, strTag, bNum)
EndProcedure

; IDE Options = PureBasic 5.62 (Windows - x64)
; CursorPosition = 87
; FirstLine = 44
; Folding = -
; EnableXP