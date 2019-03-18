;ENU (english) string table
DataSection
enu:
  Data.s "[command_font_filename]", "Glass_TTY_VT220.ttf"
  Data.s "[command_font]", "Glass TTY VT220"
  Data.s "[output_font_filename]", "SVBasicManual.ttf"  
  Data.s "[output_font]", "SV Basic Manual"
  
  Data.s "[apptitle]", "Eldarian Odyssey"
  Data.s "[copyright]", "(c) 2018 - ByteCave, Inc."
  Data.s "[entryprompt]", "ENTER COMMAND:"
  Data.s "[ERROR]", "Error"
  Data.s "[CANTINITGRAPHICS]", "Can't initialize graphics screen"
  Data.s "[CANTINITFONT]", "Can't initialize font: "
  Data.s "[FILE]", ", File: "
  Data.s "[closedialog]", "[ESC to close]"
  Data.s "[pageup]", "[PgUp]"
  Data.s "[pagedn]", "[PgDn]"
  Data.s "[credits]", "[Press F2 for Credits]"
  Data.s "[about]", "[Press F1 for About]"
  Data.s "[theme]", "[Press F5 to toggle theme]"
  
  Data.s "[genericlockedexit]", "The passage is locked."
  
  ;
  ;%1, %2 etc. replaced with tokens at run time
  ;%a replaced with a/an/any
  ;%o replaced with one/any
  ;%i replaced with is/are
  ;"<random chance>,string"

  noexit:
  ;no exit in the desired direction. If it starts with a number, that's the percentage change the message will appear
  Data.b 6  ;number of message available. have to hand count and change this value
  Data.s "[noexit01]", "You can't go that way."
  Data.s "[noexit02]", "There's no exit in that direction."
  Data.s "[noexit03]", "5,Uh-oh. Be careful, you might run into a wall or something."
  Data.s "[noexit04]", "Thou shalt not pass."
  Data.s "[noexit05]", "5,Your feet move but you go nowhere."
  Data.s "[noexit06]", "Sorry, that's not a valid direction."
  noexitend:
  
  lockedexit:  
  Data.b 4
  Data.s "[lockedexit01]", "20,The passage is locked."
  Data.s "[lockedexit02]", "The %1 is locked."
  Data.s "[lockedexit03]", "60,You haven't unlocked the %1."
  Data.s "[lockedexit04]", "10,You can't pass through the %1, it's locked."
  lockedexitend:
  
  inventory:
  Data.b 3
  Data.s "[inventory01]", "50,You are carrying: "
  Data.s "[inventory02]", "25,You've got: "
  Data.s "[inventory03]", "25,Items: "
  inventoryend:
  
  dontknow:
  Data.b 4
  Data.s "[dontknow01]", "40,I don't know how to %2%1.%2"
  Data.s "[dontknow02]", "40,I'm not sure how to %2%1.%2"
  Data.s "[dontknow03]", "20,I wish I could help you %2%1.%2"
  Data.s "[dontknow04]", "75,Try something else. I don't know how to %2%1.%2"
  dontknowend:
  
  badget:
  Data.b 4
  Data.s "[badget01]", "40,I don't see %A1 %1 to get."
  Data.s "[badget02]", "25,I'd get the %1, but there isn't %O1 around."
  Data.s "[badget03]", "10,I can't get the %1; I haven't see %O1 of those before."
  Data.s "[badget04]", "60,There %I1 no %1 here."
  badgetend:
  
  baddrop:
  Data.b 3
  Data.s "[baddrop01]", "70,I'm not carrying %A1 %1."
  Data.s "[baddrop02]", "40,I don't have %A1 %1 to drop."
  Data.s "[baddrop03]", "15,If you ever pick %T1 up, I'll be able to drop the %1!"
  baddropend:
  
  nounverberr:
  Data.b 3
  Data.s "[nounverberr01]", "I recognize the words but I'm not sure how to make sense of them. Try a different command."
  Data.s "[nounverberr02]", "I see an object and an action, but not sure how to combine them."
  Data.s "[nounverberr03]", "20,Valid thing, valid action. Invalid sequence; I can't figure it out."
  nounverberrend:
  
  toomanynv:
  Data.b 3
  Data.s "[toomanynv01]", "There are too many things to do and too many things to do them to. I don't understand."
  Data.s "[toomanynv02]", "25,Too many things and actions to process. I'm stymied."
  Data.s "[toomanynv03]", "50,That's a lot of action and a lot of things packed in one command. Please make it simpler."
  toomanynvend:
  
  toomanyn:
  Data.b 3
  Data.s "[toomanyn01]", "I don't know how to deal with more than one thing at a time, sorry."
  Data.s "[toomanyn02]", "50,That's way too many things for me to deal with."
  Data.s "[toomanyn03]", "50,Give me just one thing and one action per command, please."
  toomanynend:
  
  noverb:
  Data.b 3
  Data.s "[noverb01]", "I know the thing but I can't understand the what. Try something different."
  Data.s "[noverb02]", "40,Object understood. I just don't know what to do with it."
  Data.s "[noverb03]", "20,I need to know what to do with the thing you specified."
  noverbend:
  
  get:
  Data.b 4
  Data.s "[get01]", "You pick up the %1."
  Data.s "[get02]", "You are now carrying the %1."
  Data.s "[get03]", "The %1 %I1 added to your inventory."
  Data.s "[get04]", "You take the %1."
  getend:
  
  badword:
  Data.b 5
  Data.s "[badword01]", "Certain small words confused me to no end. You found one of them: %1."
  Data.s "[badword02]", "Simple commands are better for me. You used a word I can't deal with: %1."
  Data.s "[badword03]", "Words like '%1' trip me up."
  Data.s "[badword04]", "I reject your use of the word '%1!'"
  Data.s "[badword05]", "Um... I've no idea how to process that: %1?"
  badwordend:
  
  dirtree:
  Data.b 3
  Data.s "[dirtree01]", "You'll have to get out of this tree first."
  Data.s "[dirtree02]", "You're unable to move that direction while up here."
  Data.s "[dirtree03]", "You can't move along the ground while you're in a tree."
  dirtreeend:
  
  cannotdo:
  Data.b 5
  Data.s "[cannotdo01]", "You can't do that."
  Data.s "[cannotdo02]", "Sorry, I can't figure out how to do that."
  Data.s "[cannotdo03]", "10,Um... no, that's not possible."
  Data.s "[cannotdo04]", "25,I understand what you're asking, but it can't be done."
  Data.s "[cannotdo05]", "That doesn't make sense."
  cannotdoend:
  
end_enu:
EndDataSection



; IDE Options = PureBasic 5.70 LTS (Windows - x64)
; CursorPosition = 83
; FirstLine = 36
; EnableXP