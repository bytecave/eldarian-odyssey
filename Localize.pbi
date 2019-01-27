Macro _L(item)
  P_LoadString(quote[item]quote)
EndMacro

Define *sh_pStringTable
Define sh_iStringTableLen.i

Structure MemBytes
  Byte.a[0]
EndStructure

;
;Quick string search algoritm by pdwyer and mback2k
;mback2k unicode support - http://www.purebasic.fr/english/viewtopic.php?p=267475#p267475
;pdwyer original version - http://www.purebasic.fr/english/viewtopic.php?p=218258#p218258
;
Procedure.i QuickStringSearch(*pSearch.MemBytes, iSearchLen.i, *pPattern.MemBytes, iPatternLen.i)
  Protected i.i, iSearchEnd.i
  
  ; Build BadChr Array
  Protected Dim rgaBadChar.i(255)
  
  ; set all alphabet to max shift pos (length of find string plus 1)
  For i = 0 To 255
    rgaBadChar(i) = iPatternLen + 1
  Next
  
  ;Update chars that are in the find string to their position from the end.
  For i = 0 To iPatternLen - 1
    rgaBadChar(*pPattern\Byte[i]) = iPatternLen - i  
  Next     
  
  i = 0
  iSearchEnd = iSearchLen - (iPatternLen - 1)
  
  While i <= iSearchEnd
    If CompareMemory(*pSearch + i, *pPattern, iPatternLen) = 1
      ProcedureReturn *pSearch + i
    EndIf
    
    ;Didn't find the string so shift as per the table.
    i + rgaBadChar(*pSearch\Byte[i + iPatternLen])
  Wend
  
  ProcedureReturn #NUL
EndProcedure

Procedure.s P_InitalizeLoc(strLanguage.s)
  Shared *sh_pStringTable
  Shared sh_iStringTableLen.i
  
  ;default to english
  *sh_pStringTable = ?enu
  sh_iStringTableLen = ?end_enu - ?enu + 1
  
  ;point to requested string table
  Select strLanguage
    Case "language", "LANGUAGE"
      ;*sh_pStringTable = ?language
      ;sh_iStringTableLen = ?end_language - ?language + 1
  EndSelect
EndProcedure

Procedure.s P_LoadString(strLoadString.s)
  Shared *sh_pStringTable
  Shared sh_iStringTableLen.i
  Protected *pResID
  
  *pResID = QuickStringSearch(*sh_pStringTable, sh_iStringTableLen, @strLoadString, StringByteLength(strLoadString))
  If *pResID
    ProcedureReturn PeekS(*pResID + StringByteLength(strLoadString + " "))
  Else
    ProcedureReturn "*ERR:STRINGNOTFOUND"
  EndIf
EndProcedure

; IDE Options = PureBasic 5.61 (Windows - x64)
; CursorPosition = 66
; Folding = -
; EnableXP
; EnableUnicode