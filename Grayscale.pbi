;
;Grayscale Module by Wilbert
;http://www.purebasic.fr/english/viewtopic.php?p=482418
;
DeclareModule Grayscale
  Declare Grayscale(Image)
EndDeclareModule

Module Grayscale
  DisableDebugger
  EnableExplicit
  EnableASM
  
  Global Dim SqrTable.a(65025)
  Global *SqrTable = @SqrTable()
  Define i.i
  
  For i = 0 To 65025
    SqrTable(i) = Sqr(i)
  Next
  
  CompilerIf #PB_Compiler_Processor = #PB_Processor_x86
    Macro rax : eax : EndMacro
    Macro rbx : ebx : EndMacro
    Macro rcx : ecx : EndMacro
    Macro rsi : esi : EndMacro
    Macro rdi : edi : EndMacro  
  CompilerEndIf 
  
  Macro M_Grayscale(bgr, st)
    mov reg_bx, rbx
    mov reg_si, rsi
    mov reg_di, rdi
    mov rsi, *SqrTable
    mov rdi, *db
    mov rcx, h
    !grayscale.l_conv#bgr#st#_l0:
    mov rbx, dp
    !grayscale.l_conv#bgr#st#_l1:
    CompilerIf bgr = 0
      movzx eax, byte [rdi]
      !imul eax, eax
      !imul eax, 0x3ae1
      movzx edx, byte [rdi + 1]
      !imul edx, edx
      !imul edx, 0xb333
      !add eax, edx
      movzx edx, byte [rdi + 2]
      !imul edx, edx
      !imul edx, 0x11ec
    CompilerElse
      movzx eax, byte [rdi]
      !imul eax, eax
      !imul eax, 0x11ec
      movzx edx, byte [rdi + 1]
      !imul edx, edx
      !imul edx, 0xb333
      !add eax, edx
      movzx edx, byte [rdi + 2]
      !imul edx, edx
      !imul edx, 0x3ae1
    CompilerEndIf
    !lea eax, [eax + edx + 0x8000]
    !shr eax, 16   
    movzx eax, byte [rsi + rax]  
    mov [rdi], al
    mov [rdi + 1], al
    mov [rdi + 2], al
    add rdi, st
    sub rbx, st
    cmp rbx, st
    !jge grayscale.l_conv#bgr#st#_l1
    add rdi, rbx
    sub rcx, 1
    !jnz grayscale.l_conv#bgr#st#_l0
    mov rbx, reg_bx
    mov rsi, reg_si
    mov rdi, reg_di
  EndMacro
  
  Procedure Grayscale(Image)
    Protected reg_bx, reg_di, reg_si
    Protected *db, dp, h
    
    *db = DrawingBuffer() : dp = DrawingBufferPitch()
    h = OutputHeight()
    If DrawingBufferPixelFormat() & (#PB_PixelFormat_32Bits_BGR | #PB_PixelFormat_24Bits_BGR)
      If OutputDepth() = 32
        M_Grayscale(1, 4)
      Else
        M_Grayscale(1, 3)
      EndIf
    Else
      If OutputDepth() = 32
        M_Grayscale(0, 4)
      Else
        M_Grayscale(0, 3)
      EndIf
    EndIf
  EndProcedure
EndModule

; IDE Options = PureBasic 5.62 (Windows - x64)
; CursorPosition = 42
; FirstLine = 24
; Folding = --
; EnableXP