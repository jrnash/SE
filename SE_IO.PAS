UNIT SE_IO;

INTERFACE

USES DOS, CRT, GRAPH, SE_GRAPH, SE_MATH, SE_QUE, SE_COM;


Procedure Process_Key(VAR Finished : Boolean;
                          RTP      : RTP_PTR);

FUNCTION CheckPass(RTP        : RTP_PTR) : BOOLEAN;

Procedure GetNewPass(RTP      : RTP_PTR);

Procedure SaveSim(RTP         : RTP_PTR);
Procedure SaveAll(RTP         : RTP_PTR);
Procedure AutoLoadSim(RTP     : RTP_PTR);
Procedure LoadSim(RTP         : RTP_PTR);
Procedure LoadAll(RTP         : RTP_PTR;
               Var tAbort     : Boolean);
Procedure GetLogName(RTP      : RTP_PTR);
Procedure Write_to_Log(RTP    : RTP_PTR);

FUNCTION GetFName(    RTP     : RTP_PTR;
                      Prompt  : STRING;
                      Default : STRING;
                  VAR TOut    : BOOLEAN) : STRING;

Procedure Modify(VAR Val      : Byte;
                     Min      : Byte;
                     Max      : Byte;
                     Y        : Integer;
                     ExCh     : Char);

Procedure EntNewValW(    RTP  : RTP_PTR;
                     VAR Valu : Word;
                         Min  : Word;
                         Max  : Word;
                         Y    : Integer);
Procedure EntNewValB(    RTP  : RTP_PTR;
                     VAR Valu : Byte;
                         Min  : Byte;
                         Max  : Byte;
                         Y    : Integer);

Procedure ModifyTF(VAR Val    : Boolean;
                       Y      : Integer;
                       ExCh   : Char);

IMPLEMENTATION

Procedure Process_Key;

Var Ch, ExCh     : Char;
    OldGardPop   : Word;
    bTimerVal    : Byte;
    wTimerVal    : Word;
    LTimerVal    : Word;
    LF           : Text;      
    FullFName    : STRING;
    FileInfo     : SearchRec; 
    Hour, Min, Sec, Sec100 : Word;

Begin
  With RTP^ Do Begin
  ExCh := #3;                 
  Ch := Readkey;
  If Ch = #0                      
  then ExCh := Readkey;	          

  If Ch=#9                        
    Then Begin
      If (IOMode>0)
        Then Begin
           IOMode := (IOMode mod CIOModes)+1;
           CASE IOMode of
              1                 : IOMenu := 1;  
              2                 : IOMenu := 2;  
              3..6,11,12,18     : IOMenu := 3;  
              7..10,15,16       : IOMenu := 4;  
              13,14             : IOMenu := 5;  
              17,19             : IOMenu := 6;  
              20                : IOMenu := 7;  

           End;
           CASE IOMode of
              1     : Begin
                         Display_Graph(RTP);
                         Display_Menu(RTP);
                      End;
              2     : Display_IO_A(RTP);
              3..12 : Begin
                        SetColor(BLACK);
                        SetLineStyle(Solidln,0,Normwidth);
                        Rectangle(wGRPHMINX+1, wGRPHMINY+((IOMode-3)*20 +3),
                                  wGRPHMAXX-1, wGRPHMINY+((IOMode-3)*20)+23);
                        SetColor(Yellow);
                        Rectangle(wGRPHMINX+1, wGRPHMINY+((IOMode-2)*20 +3),
                                  wGRPHMAXX-1, wGRPHMINY+((IOMode-2)*20)+23);
                        SetLineStyle(Solidln,0,Normwidth);
                        Display_Menu(RTP);
                        Display_Desc(RTP);
                      End;
             13     : Display_IO_B(RTP);
             14..19 : Begin
                        SetColor(BLACK);
                        SetLineStyle(Solidln,0,Normwidth);
                        Rectangle(wGRPHMINX+1, wGRPHMINY+((IOMode-14)*20 +3),
                                  wGRPHMAXX-1, wGRPHMINY+((IOMode-14)*20)+23);
                        SetColor(Yellow);
                        Rectangle(wGRPHMINX+1, wGRPHMINY+((IOMode-13)*20 +3),
                                  wGRPHMAXX-1, wGRPHMINY+((IOMode-13)*20)+23);
                        SetLineStyle(Solidln,0,Normwidth);
                        Display_Menu(RTP);
                        Display_Desc(RTP);
                      End;
           End;
        End;
    End
    Else
    BEGIN
      If ExCh=#77                        
      Then Begin
          If (IOMode>0)
            Then Begin
               CASE IOMode of
                  1          : Begin
                                 IOMenu := 2;
                                 IOMode := 2
                               End;
                  2..12      : Begin
                                 IOMenu := 5;
                                 IOMode := 13;
                               End;
                  13..19     : Begin
                                 IOMenu := 2;
                                 IOMode := 2
                               End;
               End;
               CASE IOMode of
                  2 : Display_IO_A(RTP);
                 13 : Display_IO_B(RTP);
    
               End;
            End;
      End
      Else
      Begin 
      If (IOMode > 1) AND (Ch=#27) 
        Then Begin
          IOMode := 1;
          IOMenu := 1;
          Display_Graph(RTP);
          Display_Menu(RTP);
        End
        Else
      CASE IOMode of

        0  :  If CheckPass(RTP)
                Then Begin
                   IOMode := 1;
                   Display_Menu(RTP);
                   Calc_Species(RTP);
                   Display_Species(RTP);
                   Display_Graph(RTP);
                   Update_Graph(RTP);
                   Timers[2].Interval := 20; 
          End
                Else Begin
                   SSOn(RTP);
                   Display_Graph(RTP);
                   Update_Graph(RTP);
                End;
        1  :  If ExCh <> #3           
                Then Case ExCh of
          {Alt-P} #25 : Begin
                           SimStatP;
                           Display_PauseOption(True,RTP);
                           Repeat Begin
                           
                             If Triggered(RTP^.Timers[5])
                             then Begin
                                  Inc(RTP^.tStartS);
                                  If RTP^.tStartS > 86400
                                  Then RTP^.tStartS := 0;
                             End;
                           End;
                           Until Keypressed;
                           Ch := Readkey;
                           Display_PauseOption(False,RTP);
                           SimStatR;
                        End;
          {Alt-L} #38 : Begin
                           If RTP^.Password = ''
                           Then GetNewPass(RTP);
                           If RTP^.Password <> ''
                           Then Begin
                             RTP^.Timers[3].LstTriggered :=
                                  Now - RTP^.Timers[3].Interval;
                           End;
                        End;
          {Alt-S} #31 : Begin                   
                           SaveSim(RTP);
                           IOMode := 1;        
                           IOMenu := 1;        
                           Display_Graph(RTP);
                           Display_Menu(RTP);
                        End;
          {Alt-G} #34 : Begin
                        If RTP^.GardenOn
                           Then Begin
                              RTP^.GardenOn := False;
                              RTP^.Bact_on_Screen :=
                                  RTP^.Bact_on_Screen +
                                  RTP^.Bact_in_Garden;
                              RTP^.Bact_in_Garden := 0;
                           End
                           Else Begin
                              RTP^.GardenOn := True;
                              RTP^.Bact_in_Garden := CountGarden(RTP);
                              RTP^.Bact_on_Screen :=
                                  RTP^.Bact_on_Screen -
                                  RTP^.Bact_in_Garden;
                           End;
                        Display_Side_Stats(RTP);
                        Display_Menu(RTP);
                        End;
          {Alt-Q,X} #16,#45 :  Finished := True;
                End;

        2  :  Begin
              If (Ch=#13)              {ENTER}
                Then Begin
                        GetNewPass(RTP);
                        IOMode := 1;          
                        IOMenu := 1;          
                        Display_Graph(RTP);
                        Display_Menu(RTP);
                     End
                Else Begin
                        Sound(200);
                        Delay(200);
                        NoSound;
                     End;
              End;                    

        3  :  If RTP^.GardenOn
                   Then Begin
        {ENTER}       If (Ch=#13)
                      Then EntNewValB(RTP, bGARDWID,CGARDWIDMin,CGARDWIDMax,wGRPHMINY+30)
    {ANY OTHER KEY}   Else Modify(         bGARDWID,CGARDWIDMin,CGARDWIDMax,wGRPHMINY+30,ExCh);

                      Display_Menu(RTP);
                      ReCalc_Garden(RTP);
                      OldGardPop := RTP^.Bact_in_Garden;
                      RTP^.Bact_in_Garden := CountGarden(RTP);
                      RTP^.Bact_on_Screen :=
                          RTP^.Bact_on_Screen +
                          (OldGardPop - RTP^.Bact_in_Garden);
                   End
                   Else Begin
                     Sound(200);
                     Delay(200);
                     NoSound;
                   End;

        4  :  If RTP^.GardenOn
                   Then Begin
        {ENTER}       If (Ch=#13)
                      Then EntNewValB(RTP, bGARDHIG,CGARDHIGMin,CGARDHIGMax,wGRPHMINY+50)
    {ANY OTHER KEY}   Else Modify(bGARDHIG,CGARDHIGMin,CGARDHIGMax,wGRPHMINY+50,ExCh);

                      ReCalc_Garden(RTP);
                      OldGardPop := RTP^.Bact_in_Garden;
                      RTP^.Bact_in_Garden := CountGarden(RTP);
                      RTP^.Bact_on_Screen :=
                          RTP^.Bact_on_Screen +
                          (OldGardPop - RTP^.Bact_in_Garden);
                   End
                   Else Begin
                     Sound(200);
                     Delay(200);
                     NoSound;
                   End;

        5  :  If (Ch=#13)
              Then EntNewValB(RTP, bSLIM,1,40,wGRPHMINY+70)
              Else Modify(         bSLIM,1,40,wGRPHMINY+70,ExCh);

        6  :  If (Ch=#13)
              Then EntNewValB(RTP, bGLIM,1,20,wGRPHMINY+90)
              Else Modify(         bGLIM,1,20,wGRPHMINY+90,ExCh);

        7  :  ModifyTF(tMAXAGE,wGRPHMINY+110,ExCh);

        8  :  ModifyTF(tMAXSTR,wGRPHMINY+130,ExCh);

        9  :  ModifyTF(tMATURE,wGRPHMINY+150,ExCh);

        10 :  ModifyTF(tREPROSTR,wGRPHMINY+170,ExCh);

        11 :  If (Ch=#13)
              Then EntNewValB(RTP, bMUTRATNG,1,254,wGRPHMINY+190)
              Else Modify(         bMUTRATNG,1,254,wGRPHMINY+190,ExCh);

        12 :  If (Ch=#13)
              Then EntNewValB(RTP, bMUTRATMS,1,254,wGRPHMINY+210)
              Else Modify(         bMUTRATMS,1,254,wGRPHMINY+210,ExCh);

        13 :  Begin
              If (Ch=#13)              {ENTER}
                Then Begin
                        SaveSim(RTP);
                        IOMode := 1;        
                        IOMenu := 1;        
                        Display_Graph(RTP);
                        Display_Menu(RTP);
                     End
                Else Begin
                        Sound(200);
                        Delay(200);
                        NoSound;
                     End;
              End;

        14 :  Begin
              If (Ch=#13)              {ENTER}
                Then Begin
                        LoadSim(RTP);
                        IOMode := 1;         
                        IOMenu := 1;         
                        Display_Graph(RTP);
                        Display_Menu(RTP);
                     End
                Else Begin
                        Sound(200);
                        Delay(200);
                        NoSound;
                     End;
              End;                    

        15 :  ModifyTF(tGProtect,wGRPHMINY+50,ExCh);

        16 :  Begin
                ModifyTF(tLogging,wGRPHMINY+70,ExCh);
                If (ExCh = #72) AND tLogging
                Then Begin
                  GetLogName(RTP);
                  IOMode := 1;        
                  IOMenu := 1;        
                  Display_Graph(RTP);
                  Display_Menu(RTP);
                End;
              End;

        17 :  Begin
                 If (Ch=#13)
                 Then Begin
                       LTimerVal := Timers[4].Interval div Longint(100);
                       If LTimerVal > 65535
                       Then wTimerVal := 65535
                       Else wTimerVal := Word(LTimerVal);
                       EntNewValW(RTP,wTimerVal,1,3600,wGRPHMINY+90);
                       Timers[4].Interval := Longint(wTimerVal) * Longint(100);
                 End
                 Else Begin
                        Sound(200);
                        Delay(200);
                        NoSound;
                 End;
              End;

        18 :  Begin
                 If (Ch=#13)
                 Then EntNewValB(RTP,bLogFSize100Kb,1,50,wGRPHMINY+110)
                 Else Modify(       bLogFSize100Kb,1,50,wGRPHMINY+110,ExCh);
              End;

        19 :  Begin
                 LTimerVal := Timers[6].Interval div Longint(6000);
                 If LTimerVal > 65535
                 Then wTimerVal := 65535
                 Else wTimerVal := LTimerVal;
                 If (Ch=#13)
                 Then EntNewValW(RTP,wTimerVal,0,65535,wGRPHMINY+130)
                 Else Begin
                        Sound(200);
                        Delay(200);
                        NoSound;
                 End;
                 Timers[6].Interval := Longint(wTimerVal) * Longint(6000);
              End;

      End; {CASE}
      End; {Else Begin Process all other Keys}
    End;
  End;
End;

Procedure Modify;

Var Strng : String;

Begin
    If (ExCh = #72) AND (Val < Max)                
        Then Inc(Val)
        Else If (ExCh = #80) AND (Val > Min)      
          Then Dec(Val)
          Else Begin
            Sound(200);
            Delay(200);
            NoSound;
          End;

  Color_Rectangle(VGAMAXX-40,Y, VGAMAXX-4,Y+10, Black);
  SetColor(DarkGray);
  SetTextJustify(RightText, TopText);
  Str(Val:4,Strng);
  OutTextXY(VGAMAXX-4, Y, Strng);
  SetTextJustify(LeftText, TopText);

End; 

Procedure ModifyTF;

Begin
    If ExCh = #72
        Then Val := Not(Val)
        Else Begin
          Sound(200);
          Delay(200);
          NoSound;
        End;

  Color_Rectangle(VGAMAXX-14,Y, VGAMAXX-4,Y+10, Black);
  SetColor(DarkGray);
  SetTextJustify(RightText, TopText);
  If Val
  Then OutTextXY(VGAMAXX-4, Y, 'T')
  Else OutTextXY(VGAMAXX-4, Y, 'F');
  SetTextJustify(LeftText, TopText);

End; 

Procedure EntNewValW(    RTP  : RTP_PTR;
                     VAR Valu : Word;
                         Min  : Word;
                         Max  : Word;
                         Y    : Integer);
Var
    sInput,               
    sDefault,             
    sTemp,                
    sOut       : String;  
    Ch         : Char;
    H,M,S,S100 : Word;    
    StartTime,
    DeltaTime  : Word;    
    wVal,WCode : Word;    

Begin

    SimStatUI;
    Ch := #0;
    sInput := '';
    Str(Valu,sDefault);     
    CheckBreak := FALSE;
    GetTime(H,M,S,S100);   
    StartTime := S;
    DeltaTime := 0;

    With RTP^ DO
    Color_Rectangle(0, wSMAXY+3, wSMAXX, VGAMAXY, Black);
    RTP^.IOMenu := 7;      
    Display_Menu(RTP);
    RTP^.IOMenu := 6;      

    SetColor(LightGray);
    OutTextXY(0,(RTP^.wSMAXY+7),'Enter new value: ');

    Str(Min,sTemp);                         
    sOut := 'Valid Range is '+ sTemp;       
    Str(Max,sTemp);                         
    sOut := sOut + ' - ' + sTemp;           
    OutTextXY(0,(RTP^.wSMAXY+17),sOut);

    SetFillStyle(SolidFill,LightGray);
    SetLineStyle(SolidLn, 0, Normwidth);
    Bar((17*8)+8, RTP^.wSMAXY+6,
        (17*8)+((Length(sDefault)*8)+8), RTP^.wSMAXY+14);
    SetLineStyle(SolidLn, 0, Normwidth);
    SetFillStyle(SolidFill,Black);
    SetColor(Black);
    OutTextXY((17*8+9),      
              (RTP^.wSMAXY+7),sDefault);  
    SetColor(RTP^.wTEXTF_COL);

    While (DeltaTime < RTP^.InputTimeout) AND (Ch <> #13) AND (Ch <> #27) Do
    Begin

       
       If Triggered(RTP^.Timers[5])
       then Begin
            Inc(RTP^.tStartS);
            If RTP^.tStartS > 86400
            Then RTP^.tStartS := 0;
       End;

       If Keypressed
       then Begin
          Ch := Readkey;
          If  (sInput = '') AND (Ch <> #13)
          Then Begin
                 Setcolor(Black);
                 SetLineStyle(SolidLn, 0, Normwidth);       
                 SetFillStyle(SolidFill,Black);             
                 Bar((17*8), RTP^.wSMAXY+6,
                     (17*8)+150, RTP^.wSMAXY+14);
                 SetColor(LightGray);
          End;
          Case Ch of
{BS}       #8  : Begin
               If Length(sInput) > 0
               then Begin
                 sInput := Copy(sInput,0,Length(sInput)-1);
                 Setcolor(Black);
                 SetLineStyle(SolidLn, 0, Normwidth);       
                 SetFillStyle(SolidFill,Black);             
                 Bar((17*8)+(Length(sInput)*8)+8, RTP^.wSMAXY+6,
                     (17*8)+(Length(sInput)*8)+16, RTP^.wSMAXY+14);
                 SetColor(LightGray);
               End;
           End;
          else
{DEFAULT} Begin
             If (Length(sInput) < 5)
                AND (   ((Ch > #47)       
                        AND (Ch < #58)))
             then Begin
                sInput := sInput + Ch;
                OutTextXY((17*8)+Length(sInput)*8,
                          (RTP^.wSMAXY+7), Ch);
             End;
          End;
          End;     
       End;        
       GetTime(H,M,S,S100);   
       If (S < StartTime)
       THEN DeltaTime := (S+60) - StartTime
       ELSE DeltaTime := S-StartTime;
       If DeltaTime < 0
          Then DeltaTime := DeltaTime + 60;
    End;        

    If (Ch <> #13) AND (Ch <> #27)
     Then Begin
       Color_Rectangle(0, RTP^.wSMAXY+3, 
                       RTP^.wSMAXX, VGAMAXY, Black);
       SetColor(LightRed);
       OutTextXY(0,(RTP^.wSMAXY+5),'Timeout on user input!');
       SetColor(LightGray);
       WaitaSec(RTP, RTP^.MssgTimeout,2);
     End;
    If (sInput <> '') AND (Ch = #13)
       Then Begin
            Val(sInput, wVal, wCode);

            If ((wVal >= Min) AND (wVal <= Max) AND (wCode = 0))
            Then Begin
{Return Val}  Valu := wVal;
              Color_Rectangle(VGAMAXX-40,Y, VGAMAXX-4,Y+10, Black);
              SetColor(DarkGray);
              SetTextJustify(RightText, TopText);
              Str(Valu:4,sOut);
              OutTextXY(VGAMAXX-4, Y, sOut);
              SetTextJustify(LeftText, TopText);
            End
            Else Begin
              Color_Rectangle(0, RTP^.wSMAXY+3, 
                              RTP^.wSMAXX, VGAMAXY, Black);
              SetColor(LightRed);
              OutTextXY(0,(RTP^.wSMAXY+5),'Input out of range!');
              SetColor(LightGray);
              WaitaSec(RTP, RTP^.MssgTimeout,2);

            End;
       End;
    Display_Menu(RTP);
End;

Procedure EntNewValB(    RTP  : RTP_PTR;
                     VAR Valu : Byte;
                         Min  : Byte;
                         Max  : Byte;
                         Y    : Integer);
Var
    sInput,               
    sDefault,             
    sTemp,                
    sOut       : String;  
    Ch         : Char;
    H,M,S,S100 : Word;    
    StartTime,
    DeltaTime  : Word;    
    wVal,WCode : Word;    

Begin

    SimStatUI;
    Ch := #0;
    sInput := '';
    Str(Valu,sDefault);     
    CheckBreak := FALSE;
    GetTime(H,M,S,S100);   
    StartTime := S;
    DeltaTime := 0;

    With RTP^ DO
    Color_Rectangle(0, wSMAXY+3, wSMAXX, VGAMAXY, Black);
    RTP^.IOMenu := 7;      
    Display_Menu(RTP);
    RTP^.IOMenu := 3;      

    SetColor(LightGray);
    OutTextXY(0,(RTP^.wSMAXY+7),'Enter new value: ');

    Str(Min,sTemp);                         
    sOut := 'Valid Range is '+ sTemp;       
    Str(Max,sTemp);                         
    sOut := sOut + ' - ' + sTemp;           
    OutTextXY(0,(RTP^.wSMAXY+17),sOut);

    SetFillStyle(SolidFill,LightGray);
    SetLineStyle(SolidLn, 0, Normwidth);
    Bar((17*8)+8, RTP^.wSMAXY+6,
        (17*8)+((Length(sDefault)*8)+8), RTP^.wSMAXY+14);
    SetLineStyle(SolidLn, 0, Normwidth);
    SetFillStyle(SolidFill,Black);
    SetColor(Black);
    OutTextXY((17*8+9),      
              (RTP^.wSMAXY+7),sDefault);  
    SetColor(RTP^.wTEXTF_COL);

    While (DeltaTime < RTP^.InputTimeout) AND (Ch <> #13) AND (Ch <> #27) Do
    Begin

       
       If Triggered(RTP^.Timers[5])
       then Begin
            Inc(RTP^.tStartS);
            If RTP^.tStartS > 86400
            Then RTP^.tStartS := 0;
       End;

       If Keypressed
       then Begin
          Ch := Readkey;
          If  (sInput = '') AND (Ch <> #13)
          Then Begin
                 Setcolor(Black);
                 SetLineStyle(SolidLn, 0, Normwidth);       
                 SetFillStyle(SolidFill,Black);             
                 Bar((17*8), RTP^.wSMAXY+6,
                     (17*8)+150, RTP^.wSMAXY+14);
                 SetColor(LightGray);
          End;
          Case Ch of
{BS}       #8  : Begin
               If Length(sInput) > 0
               then Begin
                 sInput := Copy(sInput,0,Length(sInput)-1);
                 Setcolor(Black);
                 SetLineStyle(SolidLn, 0, Normwidth);       
                 SetFillStyle(SolidFill,Black);             
                 Bar((17*8)+(Length(sInput)*8)+8, RTP^.wSMAXY+6,
                     (17*8)+(Length(sInput)*8)+16, RTP^.wSMAXY+14);
                 SetColor(LightGray);
               End;
           End;
          else
{DEFAULT} Begin
             If (Length(sInput) < 4)
                AND (   ((Ch > #47)       
                        AND (Ch < #58)))
             then Begin
                sInput := sInput + Ch;
                OutTextXY((17*8)+Length(sInput)*8,
                          (RTP^.wSMAXY+7), Ch);
             End;
          End;
          End;     
       End;        
       GetTime(H,M,S,S100);   
       If (S < StartTime)
       THEN DeltaTime := (S+60) - StartTime
       ELSE DeltaTime := S-StartTime;
       If DeltaTime < 0
          Then DeltaTime := DeltaTime + 60;
    End;        

    If (Ch <> #13) AND (Ch <> #27)
     Then Begin
       Color_Rectangle(0, RTP^.wSMAXY+3, 
                       RTP^.wSMAXX, VGAMAXY, Black);
       SetColor(LightRed);
       OutTextXY(0,(RTP^.wSMAXY+5),'Timeout on user input!');
       SetColor(LightGray);
       WaitaSec(RTP, RTP^.MssgTimeout,2);
     End;
    If (sInput <> '') AND (Ch = #13)
       Then Begin
            Val(sInput, wVal, wCode);

            If ((wVal >= Min) AND (wVal <= Max) AND (wCode = 0))
            Then Begin
{Return Val}  Valu := wVal;
              Color_Rectangle(VGAMAXX-40,Y, VGAMAXX-4,Y+10, Black);
              SetColor(DarkGray);
              SetTextJustify(RightText, TopText);
              Str(Valu:4,sOut);
              OutTextXY(VGAMAXX-4, Y, sOut);
              SetTextJustify(LeftText, TopText);
            End
            Else Begin
              Color_Rectangle(0, RTP^.wSMAXY+3, 
                              RTP^.wSMAXX, VGAMAXY, Black);
              SetColor(LightRed);
              OutTextXY(0,(RTP^.wSMAXY+5),'Input out of range!');
              SetColor(LightGray);
              WaitaSec(RTP, RTP^.MssgTimeout,2);

            End;
       End;
    Display_Menu(RTP);
End;

Procedure GetLogName(RTP : RTP_PTR);

Var
    bLF         : file of Byte; 
    LF          : text;      
    Line        : STRING;    
    TOut        : Boolean;   
    TempFName   : String;    
    FullFName   : String;    
    FileInfo    : SearchRec; 
    Hour, Min, Sec, Sec100 : Word;
    lFileSize   : Longint;

Begin
  RTP^.tLogging := FALSE; 
  TOut := False;
  TempFName := GetFName(RTP, 'Log File Name:', RTP^.LogFile, TOut);
  If NOT(TOut)
  Then Begin
    Color_Rectangle(0, RTP^.wSMAXY+3, RTP^.wSMAXX, VGAMAXY, Black);
    If TempFName <> ''
    Then Begin
      RTP^.LogFile := TempFName;
      FullFName := TempFName + '.LOG';
      FindFirst(FullFName, AnyFile, FileInfo);
      Sound(500);
      Delay(100);
      NoSound;
      If DosError = 0
      Then Begin
           Sound(500);
           Delay(100);
           NoSound;
           TempFName := GetFName(RTP, 'File Exists, Append to: ',
                                 RTP^.LogFile, TOut)
      End
      Else TempFName := GetFName(RTP, 'Create File? Confirm Name: ',
                                 RTP^.LogFile, TOut);
      If NOT(TOut)
      Then Begin
        Color_Rectangle(0, RTP^.wSMAXY+3, RTP^.wSMAXX, VGAMAXY, Black);
        If TempFName = RTP^.LogFile   
        Then Begin
          SetColor(LightGreen);
          RTP^.tLogging := TRUE;
          OutTextXY(0,(RTP^.wSMAXY+5),'Logging Active to '+ FullFName);
          SetColor(LightGray);

          Assign(LF, RTP^.LogFile + '.LOG');
          FullFName := RTP^.LogFile + '.LOG';
          FindFirst(FullFName, AnyFile, FileInfo);
          If DosError = 0
          Then Begin    

            Assign(bLF, RTP^.LogFile + '.LOG');
            Reset(bLF);
            lFileSize := FileSize(bLF) div 100000;

            If (RTP^.bLogFSize100Kb > byte(lFileSize))

            Then Begin
              Close(bLF);
              Assign(LF, RTP^.LogFile + '.LOG');

              Append(LF);
              Writeln(LF);
              Writeln(LF, 'Simulated Evolution Log File ' + VERSION);
              GetTime(Hour, Min, Sec, Sec100);
              Writeln(LF,'Logging re-started at ',Hour:2,':',Min:2,':',Sec:2);
              Writeln(LF);
              Write(LF,'D Time       C Pop BacS BacG  P0  P1  P2  P3  P4  P5 SD0  SD1  SD2  SD3  SD4  SD5  ');
              Writeln(LF,'MStr MAge Repr MRSt  MS  MB GH GW SL GL P');
              Close(LF);
              WaitaSec(RTP, RTP^.MssgTimeout,1);
            End
            Else Begin
              Close(bLF);
              Color_Rectangle(0, RTP^.wSMAXY+3,RTP^.wSMAXX, VGAMAXY, Black);
              SetColor(LightRed);
              OutTextXY(0,(RTP^.wSMAXY+5),
                        'File to large, adjust log file size!');
              SetColor(LightGray);
              WaitaSec(RTP, RTP^.MssgTimeout,2);
            End; 
          End;          
        End
        Else If TempFName <> ''
          Then Begin
            Color_Rectangle(0, RTP^.wSMAXY+3, 
                            RTP^.wSMAXX, VGAMAXY, Black);
            SetColor(LightRed);
            OutTextXY(0,(RTP^.wSMAXY+5),
                      'No Match, Confirmation Failed!');
            SetColor(LightGray);
            WaitaSec(RTP, RTP^.MssgTimeout,2);
          End; 
      End;   
    End;     
  End;       
  If (TOut)
  Then Begin
    Color_Rectangle(0, RTP^.wSMAXY+3, RTP^.wSMAXX, VGAMAXY, Black);
    SetColor(LightRed);
    OutTextXY(0,(RTP^.wSMAXY+5),'Timeout on user input!');
    SetColor(LightGray);
    WaitaSec(RTP, RTP^.MssgTimeout,2);
  End;
End;

Procedure SaveSim(RTP : RTP_PTR);

Var
    Line        : STRING;    
    TOut        : Boolean;   
    TempFName   : String;    
    FullFName   : String;    
    FileInfo    : SearchRec; 

Begin
  TOut := False;
  TempFName := GetFName(RTP, 'File to Save To:', RTP^.SimFile, TOut);
  If NOT(TOut)
  Then Begin
    Color_Rectangle(0, RTP^.wSMAXY+3, 
                    RTP^.wSMAXX, VGAMAXY, Black);
    If TempFName <> ''
    Then Begin
      RTP^.SimFile := TempFName;
      FullFName := TempFName + '.SIM';
      FindFirst(FullFName, AnyFile, FileInfo);
      Sound(500);
      Delay(100);
      NoSound;
      If DosError = 0
      Then Begin
         Sound(500);
         Delay(100);
         NoSound;
         TempFName := GetFName(RTP, 'File Exists, Overwrite ',
                                    RTP^.SimFile, TOut)
      End
      Else TempFName := GetFName(RTP, 'Create File? Confirm Name: ',
                                 RTP^.SimFile, TOut);
      If NOT(TOut)
      Then Begin
        Color_Rectangle(0, RTP^.wSMAXY+3, 
                        RTP^.wSMAXX, VGAMAXY, Black);
        If TempFName = RTP^.SimFile   
        Then SaveAll(RTP)
        Else
          If TempFName <> ''
          Then Begin
            Color_Rectangle(0, RTP^.wSMAXY+3, 
                            RTP^.wSMAXX, VGAMAXY, Black);
            SetColor(LightRed);
            OutTextXY(0,(RTP^.wSMAXY+5),
                      'No Match, Confirmation Failed!');
            SetColor(LightGray);
            WaitaSec(RTP, RTP^.MssgTimeout,2);
          End; 
      End;   
    End;     
  End;       
  If (TOut)
  Then Begin
    Color_Rectangle(0, RTP^.wSMAXY+3, 
                    RTP^.wSMAXX, VGAMAXY, Black);
    SetColor(LightRed);
    OutTextXY(0,(RTP^.wSMAXY+5),'Timeout on user input!');
    SetColor(LightGray);
    WaitaSec(RTP, RTP^.MssgTimeout,2);
  End;
End;

Procedure Write_to_Log(RTP : RTP_PTR);

Var
    bLF       : file of Byte; 
    LF        : text;    
    FullFName : STRING;  
    FileInfo  : SearchRec; 
    Hour, Min, Sec, Sec100 : Word;
    sVar      : STRING;  
    Cntr      : integer; 
    lFileSize : Longint;

Procedure Write_Elapsed(RTP : RTP_PTR; tElapsedS : Longint; wDays : Word);

Var Hr, Min, Sec             : Longint;
    sDays,sHours,sMins,sSecs : STRING;
    Cntr                     : Byte;

BEGIN
With RTP^ Do BEGIN

    Hr := tElapsedS div Longint(3600);
    tElapsedS := tElapsedS - (Hr * Longint(3600));

    Min:= tElapsedS div Longint(60);
    tElapsedS := tElapsedS - (Min * Longint(60));

    Str(tElapsedS:2, sSecs);
    If sSecs[1] = ' '
    Then sSecs[1] := '0';

    Str(Min:2, sMins);
    If sMins[1] = ' '
    Then sMins[1] := '0';

    Str(Hr:2, sHours);
    If sHours[1] = ' '
    Then sHours[1] := '0';

    Str(wDays, sDays);

    Write(LF,sDays,' ',sHours,':',sMins,':',sSecs,' ');
  End;
End;

Procedure Get_and_Write_Elapsed_time;

Var  tNowS, tElapsedS: Longint;

Begin

With RTP^ Do Begin

    tNowS := Now div Longint(100);

    If (tNowS < tStartS)  
    Then Begin               
      If NOT(tBS)            
      Then Begin             

        tBS := TRUE;         

                             
                             
        tElapsedS := (tNowS - tStartS) + Longint(86400);
        Write_Elapsed(RTP, tElapsedS, wDays);

      End
      Else Begin             

        tElapsedS := (tNowS - tStartS) + Longint(86400);
        Write_Elapsed(RTP, tElapsedS, wDays);

      End
    End
    Else Begin            
      If (tBS)               
      Then Begin             
                             
        Inc(wDays);          
        tBS := False;        
        tElapsedS := (tNowS - tStartS);
        Write_Elapsed(RTP, tElapsedS, wDays);

      End
      Else Begin             

        
        tElapsedS := (tNowS - tStartS);
        Write_Elapsed(RTP, tElapsedS, wDays);

      End;
    End;
End;
End;

Begin
  SimStatWL;

  With RTP^ Do Begin

    Assign(LF, LogFile + '.LOG');
    FullFName := LogFile + '.LOG';
    FindFirst(FullFName, AnyFile, FileInfo);

    If DosError = 0
    Then Begin    

        Assign(bLF, RTP^.LogFile + '.LOG');
        Reset(bLF);
        lFileSize := FileSize(bLF) div 100000;
        Close(bLF);
        If (RTP^.bLogFSize100Kb > byte(lFileSize))

        Then Begin
          Assign(LF, LogFile + '.LOG');
          Append(LF);
        End
        Else
          RTP^.tLogging := FALSE;

    End           
    Else Begin    
        Rewrite(LF);
        Writeln(LF, 'Simulated Evolution Log File ' + VERSION);
        GetTime(Hour, Min, Sec, Sec100);
        Writeln(LF,'Logging started at ',Hour:2,':',Min:2,':',Sec:2);
        Writeln(LF);
        Write(LF,'D Time       C Pop BacS BacG  P0  P1  P2  P3  P4  P5 SD0  SD1  SD2  SD3  SD4  SD5  ');
        Writeln(LF,'MStr MAge Repr MRSt  MS  MB GH GW SL GL P');
    End;

    If RTP^.tLogging
    Then Begin
      Get_and_Write_Elapsed_Time;

      Str(Cycle_Cntr:3,sVar);
      Write(LF,sVar + ' ');

      Str(NumofBugs:3,sVar);
      Write(LF,sVar + ' ');

      Str(Bact_on_Screen:4,sVar);
      Write(LF,sVar + ' ');

      Str(Bact_in_Garden:4,sVar);
      Write(LF,sVar + ' ');

      FOR Cntr := 0 to NUMOFGENES DO
          Write(LF, SpeciesID[Cntr].Pop:3,' ');

      FOR Cntr := 0 to NUMOFGENES DO
          Write(LF, SpeciesID[Cntr].StdDev:4:2,' ');

      Write(LF,Avg.MaxAge:4,' ');
      Write(LF,Avg.MaxStr:4,' ');
      Write(LF,Avg.Mature:4,' ');
      Write(LF,Avg.ReproStr:4,' ');

      Str(bMutratNG:3,sVar);
      Write(LF,sVar + ' ');

      Str(bMutratMS:3,sVar);
      Write(LF,sVar + ' ');

      Str(bGARDWID:2,sVar);
      Write(LF,sVar + ' ');

      Str(bGARDHIG:2,sVar);
      Write(LF,sVar + ' ');

      Str(bSLIM:2,sVar);
      Write(LF,sVar + ' ');

      Str(bGLIM:2,sVar);
      Write(LF,sVar + ' ');

      If (tGProtect)
      Then Write(LF,'1 ')
      Else Write(LF,'0 ');
      Writeln(LF);
      Close(LF);
    End;
  End;
End;

Procedure SaveAll(RTP : RTP_PTR);

Var OutFile   : text;    
    VarString : string;  
    VarLen    : integer; 
    Cnt       : integer; 
    c,x,y : Word;        
    lTempx : Longint;    
    lTempy : Longint;    
    i,j,k : Word;        
    Temp : GRPH_BLOCK_PTR;
    Hour,  Min,  Sec,  Sec100  : Word;

Procedure WriteStr(SimVar : STRING; VarComment : STRING);
Var Cntr      : integer; 
Begin
  Write(Outfile, SimVar);
  VarLen:=Length(SimVar);
  For Cntr := 1 to (30-VarLen) Do
     Write(Outfile,' ');
  Writeln(Outfile,VarComment);
End;

Procedure WriteVarInt(SimVar : Integer; VarComment : STRING);
Var Cntr      : integer; 
Begin
  Write(Outfile, SimVar);
  Str(SimVar, VarString);
  VarLen:=Length(VarString);
  For Cntr := 1 to (30-VarLen) Do
     Write(Outfile,' ');
  Writeln(Outfile,VarComment);
End;

Procedure WriteVarLongInt(SimVar : LongInt; VarComment : STRING);

Type
WordRec = record
        Low, High : Word;
End;

Var Cntr      : integer; 
    sVarL, sVarH : String;
Begin
  Write(Outfile, WordRec(SimVar).Low,' ');
  Write(Outfile, WordRec(SimVar).High);
  Str(WordRec(SimVar).Low, sVarL);
  Str(WordRec(SimVar).High, sVarH);
  VarLen:=Length(sVarL + sVarH);
  For Cntr := 1 to (29-(VarLen)) Do
     Write(Outfile,' ');
  Writeln(Outfile,VarComment);
End;

Procedure WriteVarReal(SimVar : Real; VarComment : STRING);
Var Cntr      : integer; 
Begin

  Write(Outfile, SimVar);
  Str(SimVar, VarString);
  VarLen:=Length(VarString);
  For Cntr := 1 to (30-VarLen) Do
     Write(Outfile,' ');
  Writeln(Outfile,VarComment);
End;

Procedure WriteVarWordorByte(SimVar : Word; VarComment : STRING);
Var Cntr      : integer; 
Begin

  Write(Outfile, SimVar);
  Str(SimVar, VarString);
  VarLen:=Length(VarString);
  For Cntr := 1 to (30-VarLen) Do
     Write(Outfile,' ');
  Writeln(Outfile,VarComment);
End;

Procedure WriteVarBoolean(SimVar : Boolean; VarComment : STRING);
Var Cntr      : integer; 
Begin

  If SimVar
  Then Write(Outfile, 1)
  Else Write(Outfile, 0);
  For Cntr := 1 to (29) Do
     Write(Outfile,' ');
  Writeln(Outfile,VarComment);
End;

Procedure WriteGrphField(SimVar : Word);
Var Cntr      : integer; 
Begin
  Write(Outfile, SimVar);
  Str(SimVar, VarString);
  VarLen:=Length(VarString);
  For Cntr := 1 to (5-VarLen) Do
     Write(Outfile,' ');
End;

Procedure Write_Elapsed(RTP : RTP_PTR; tElapsedS : Longint; wDays : Word);

Var Hr, Min, Sec             : Longint;
    sDays,sHours,sMins,sSecs : STRING;
    Cntr                     : Byte;

BEGIN
With RTP^ Do BEGIN

    Hr := tElapsedS div Longint(3600);
    tElapsedS := tElapsedS - (Hr * Longint(3600));

    Min:= tElapsedS div Longint(60);
    tElapsedS := tElapsedS - (Min * Longint(60));

    Str(tElapsedS:2, sSecs);
    If sSecs[1] = ' '
    Then sSecs[1] := '0';

    Str(Min:2, sMins);
    If sMins[1] = ' '
    Then sMins[1] := '0';

    Str(Hr:2, sHours);
    If sHours[1] = ' '
    Then sHours[1] := '0';

    Str(wDays:3, sDays);

    Write(OutFile,sDays,' ',sHours,' ',sMins,' ',sSecs);
    For Cntr := 1 to 18 Do
       Write(Outfile,' ');
    Writeln(Outfile,'Days, Hours, Mins & Secs Simulation Elapsed');
  End;
End;

Procedure Get_and_Write_Elapsed_time;

Var  tNowS, tElapsedS: Longint;

Begin

With RTP^ Do Begin

    tNowS := Now div Longint(100);

    If (tNowS < tStartS)  
    Then Begin               
      If NOT(tBS)            
      Then Begin             

        tBS := TRUE;         

                             
                             
        tElapsedS := (tNowS - tStartS) + Longint(86400);
        Write_Elapsed(RTP, tElapsedS, wDays);

      End
      Else Begin             

        tElapsedS := (tNowS - tStartS) + Longint(86400);
        Write_Elapsed(RTP, tElapsedS, wDays);

      End
    End
    Else Begin            
      If (tBS)               
      Then Begin             
                             
        Inc(wDays);          
        tBS := False;        
        tElapsedS := (tNowS - tStartS);
        Write_Elapsed(RTP, tElapsedS, wDays);

      End
      Else Begin             

        
        tElapsedS := (tNowS - tStartS);
        Write_Elapsed(RTP, tElapsedS, wDays);

      End;
    End;
End;
End;


Begin
  With RTP^ Do Begin

    SetColor(LightGray);
    OutTextXY(0,(RTP^.wSMAXY+5),'Saving Simulation...');
    SimStatWS;
    If tSave
      Then Assign(Outfile, SimFile + '.SIM')
      Else Assign(Outfile, 'TEMP.$$$');
    Rewrite(Outfile);


    Writeln(Outfile, 'Simulated Evolution Simulation Snapshot');
    Writeln(Outfile, VERSION);
    Writeln(Outfile);

    GetTime(Hour, Min, Sec, Sec100);

    Writeln(Outfile,'Simulation saved at ',Hour:2,':',Min:2,':',Sec:2);
    Writeln(Outfile);
    Writeln(Outfile, 'CAUTION: Incorrect modifications to this file could result in a runtime error!');
    Writeln(Outfile);

    Writeln(Outfile,'[GLOBAL]');
    Writeln(Outfile);

    Get_and_Write_Elapsed_Time;

    WriteVarLongInt(    Cycle_Cntr,'Cycle_Cntr, Low Word / High Word');

    WriteVarWordorByte( NumofBugs,'NumofBugs');
    WriteVarWordorByte( Bact_on_Screen,'Bact_on_Screen');
    WriteVarWordorByte( Bact_in_Garden,'Bact_in_Garden');
    WriteVarBoolean(    GardenOn,'GardenOn');

    WriteVarReal(       rSDENSITY,'rSDENSITY');
    WriteVarReal(       rGDENSITY,'rGDENSITY');

    WriteVarWordorByte( bGARDWID,'bGARDWID');
    WriteVarWordorByte( bGARDHIG,'bGARDHIG');

    WriteVarReal(       rSLIMPCT,'rSLIMPCT');
    WriteVarReal(       rGLIMPCT,'rGLIMPCT');

    WriteVarBoolean(    tMAXAGE,'tMAXAGE');
    WriteVarBoolean(    tMAXSTR,'tMAXSTR');
    WriteVarBoolean(    tMATURE,'tMATURE');
    WriteVarBoolean(    tREPROSTR,'tREPROSTR');
    WriteVarBoolean(    tGProtect,'tGProtect');
    WriteVarWordorByte( bMUTRATNG,'bMUTRATNG');
    WriteVarWordorByte( bMUTRATMS,'bMUTRATMS');

    WriteStr(           LogFile,'Log File Name');
    WriteVarBoolean(    tLogging,'tLogging');
    WriteVarLongInt(    Timers[4].Interval,'Log Period in 10s of mSec');
    WriteVarWordorByte( bLogFSize100kb,'Max Size of Log file in 100Kb');

    Writeln(Outfile);
    WriteVarLongInt(    Timers[6].Interval,'Elapsed time   at which to end program (0=NoEnd)');
    Writeln(Outfile,'                              Time in 10s of mSec in form of LowWord, HighWord');
    WriteVarLongInt(    ExpCycles,         'Elapsed Cycles at which to end program (0=NoEnd)');
    Writeln(Outfile,'                              Cycles in form of LowWord, HighWord');

    Cnt := 0;
    RTP^.Curr_Bug := RTP^.LL;
    Point_to_Next(RTP);                           
    While Not PastLast(RTP^.Curr_Bug) Do Begin    
      Inc(Cnt);
      Str(Cnt, VarString);
      With RTP^.Curr_Bug^ Do Begin
        Writeln(Outfile);
        Writeln(Outfile,'[BUG ' + VarString + ']');
        Writeln(Outfile);
        WriteVarWordorByte( age,'age');
        WriteVarWordorByte( str,'str');
        WriteVarWordorByte( dir,'dir');
        WriteVarWordorByte( posx,'posx');
        WriteVarWordorByte( posy,'posy');
        WriteVarWordorByte( colr,'colr');
        WriteVarWordorByte( MAXAGE,'MAXAGE');
        WriteVarWordorByte( MAXSTR,'MAXSTR');
        WriteVarWordorByte( MATURE,'MATURE');
        WriteVarWordorByte( REPROSTR,'REPROSTR');
        WriteVarInt( gene[0],'gene[0]');
        WriteVarInt( gene[1],'gene[1]');
        WriteVarInt( gene[2],'gene[2]');
        WriteVarInt( gene[3],'gene[3]');
        WriteVarInt( gene[4],'gene[4]');
        WriteVarInt( gene[5],'gene[5]');
      End;
      Point_to_Next(RTP);                       
    End;
  End;


  With RTP^ Do
  Begin
    c := 0;
    Writeln(Outfile);
    Writeln(Outfile,'[GRAPH CTRL]');
    Writeln(Outfile);

    WriteVarWordorByte( wGRPHDens,'wGRPHDens');
    WriteVarWordorByte( wGRPHCurs1,'wGRPHCurs1');
    WriteVarWordorByte( wGRPHCurs2,'wGRPHCurs2');

    WriteVarWordorByte( wGRPHBlok1,'wGRPHBlok1');
    WriteVarWordorByte( wGRPHBlok2,'wGRPHBlok2');

    WriteVarWordorByte( wGRPHMinX,'wGRPHMinX');
    WriteVarWordorByte( wGRPHMinY,'wGRPHMinY');
    WriteVarWordorByte( wGRPHMaxX,'wGRPHMasX');
    WriteVarWordorByte( wGRPHMaxY,'wGRPHMaxY');
  End;

  Writeln(Outfile);
  Writeln(Outfile,'[GRAPH DATA]');
  Writeln(Outfile);

  With RTP^ Do
  FOR i := 1 to CGRPHObjs Do
  Begin
    Temp := RTP^.GRPHMatrix[i].DataPtr;
    FOR k := 1 to CGRPHWid Do
      WriteGrphField(Temp^.Value[k]);
    Writeln(OutFile);            

    FOR j := 1 to CGRPHBuff Do
    Begin
      Temp := Temp^.Next;
      FOR k := 1 to CGRPHWid Do
         WriteGrphField(Temp^.Value[k]);
    Writeln(OutFile);            
    End; 
    Writeln(OutFile);              
  End; 


  With RTP^ Do
  Begin
    SimStatCB;
    c := 0;
    lTempx := Trunc(1.0*(wSMAXX-wSMINX)/bSGRIDRESx)+1;
    lTempy := Trunc(1.0*(wSMAXY-wSMINY)/bSGRIDRESy)+1;

    {<CR> Added automaticaly by [GRAPH DATA] Code above }

    Writeln(Outfile,'[BACTERIA] (x,y)');
    Writeln(Outfile);
    For x := 0 to lTempx Do
    Begin
         For y := 0 to lTempy Do
         Begin
              If GetPixel(wSMINX + (x * bSGRIDRESx),
                          wSMINY + (y * bSGRIDRESy)) = wBACT_COL
              Then Writeln(OutFile,x,' ',y);
         End;
    End;
    SimStatR;
  End;

  Writeln(Outfile);
  Close(OutFile);
End;  {Proc SaveAll() }

Procedure AutoLoadSim(RTP : RTP_PTR);

Var
    SimFile,LF  : text;      
    Line        : STRING;    
    FullFName   : String;    
    FileInfo    : SearchRec; 
    tAbort      : Boolean;   
    Hour, Min, Sec, Sec100 : Word;

Begin
  FullFName := RTP^.SimFile + '.SIM';
  FindFirst(FullFName, AnyFile, FileInfo);
  If DosError = 0
  Then Begin

        RTP^.tSave := TRUE;   
        LoadAll(RTP,tAbort);
        If (tAbort)
        Then Begin
            RTP^.tAutoload := False;         
            Color_Rectangle(0, RTP^.wSMAXY+3, 
                            RTP^.wSMAXX, VGAMAXY, Black);
            SetColor(LightRed);
            OutTextXY(0,(RTP^.wSMAXY+5),
                      'AutoLoad Failure!');
            OutTextXY(0,(RTP^.wSMAXY+20),
                      '*.Sim file is incompatible with this version!');
            SetColor(LightGray);
            WaitaSec(RTP, RTP^.MssgTimeout,2);
            RTP^.SimFile := 'DEFAULT'      
        End;
        Calc_Defaults(RTP);


  End
  Else Begin
    Color_Rectangle(0, RTP^.wSMAXY+3, 
                    RTP^.wSMAXX, VGAMAXY, Black);
    SetColor(LightRed);
    OutTextXY(0,(RTP^.wSMAXY+5),'File Not Found! '+ FullFName);
    SetColor(LightGray);
    WaitaSec(RTP, RTP^.MssgTimeout,2);
    RTP^.tAutoload := False;           
  End;

  If (RTP^.tLogging) OR (ParamCount > 1) 
  Then Begin
    RTP^.tLogging := TRUE;
    Assign(LF, RTP^.LogFile + '.LOG');
    FullFName := RTP^.LogFile + '.LOG';
    FindFirst(FullFName, AnyFile, FileInfo);
    If DosError = 0
    Then Begin    
        Append(LF);
        Writeln(LF);
        Writeln(LF, 'Simulated Evolution Log File ' + VERSION);
        GetTime(Hour, Min, Sec, Sec100);
        Writeln(LF,'Logging Auto-started at ',Hour:2,':',Min:2,':',Sec:2);
        Writeln(LF);
        Write(LF,'D Time       C Pop BacS BacG  P0 SD0   P1 SD1   P2 SD2   P3 SD3   P4 SD4   P5 SD5  ');
        Writeln(LF,'MStr MAge Repr MRSt  MS  MB GH GW SL GL P');
        Close(LF);
    End;          
  End;  
End;

Procedure LoadSim(RTP : RTP_PTR);

Var
    SimFile     : text;      
    Line        : STRING;    
    TOut        : Boolean;   
    TempFName   : String;    
    FullFName   : String;    
    FileInfo    : SearchRec; 
    tAbort      : Boolean;   

Begin
  TOut := False;
  TempFName := GetFName(RTP, 'File to Load From:', RTP^.SimFile, TOut);
  If NOT(TOut)
  Then Begin
    Color_Rectangle(0, RTP^.wSMAXY+3, 
                    RTP^.wSMAXX, VGAMAXY, Black);
    If TempFName <> ''
    Then Begin
      RTP^.SimFile := TempFName;
      FullFName := TempFName + '.SIM';
      FindFirst(FullFName, AnyFile, FileInfo);
      If DosError = 0
      Then Begin
        Sound(500);
        Delay(100);
        NoSound;
        TempFName := GetFName(RTP, 'File Found. Confirm Load:', RTP^.SimFile, TOut);
        If NOT(TOut)
        Then Begin
          Color_Rectangle(0, RTP^.wSMAXY+3, 
                          RTP^.wSMAXX, VGAMAXY, Black);
          If TempFName = RTP^.SimFile   
          Then Begin
            Color_Rectangle(0, RTP^.wSMAXY+3, 
                            RTP^.wSMAXX, VGAMAXY, Black);
            RTP^.tSave := FALSE;
            SaveAll(RTP);
            RTP^.tSave := TRUE;


     LoadAll(RTP,tAbort);
     If (tAbort)
       Then Begin
         Color_Rectangle(0, RTP^.wSMAXY+3, 
                         RTP^.wSMAXX, VGAMAXY, Black);
         SetColor(LightRed);
         OutTextXY(0,(RTP^.wSMAXY+5),
                   '*.Sim file is incompatible with this version!');
         OutTextXY(0,(RTP^.wSMAXY+20),
                   'Restoring original simulation');
         SetColor(LightGray);
         WaitaSec(RTP, RTP^.MssgTimeout,2);
         RTP^.SimFile := 'TEMP.$$$';
         LoadAll(RTP,tAbort);           
         RTP^.SimFile := 'DEFAULT'      
       End;
     Calc_Defaults(RTP);


            SetColor(LightGray);
          End
          Else If TempFName <> ''
            Then Begin
              Color_Rectangle(0, RTP^.wSMAXY+3, 
                              RTP^.wSMAXX, VGAMAXY, Black);
              SetColor(LightRed);
              OutTextXY(0,(RTP^.wSMAXY+5),
                        'No Match, Confirmation Failed!');
              SetColor(LightGray);
              WaitaSec(RTP, RTP^.MssgTimeout,2);
            End; 
        End;     
      End        
      Else Begin
        Color_Rectangle(0, RTP^.wSMAXY+3, 
                        RTP^.wSMAXX, VGAMAXY, Black);
        SetColor(LightRed);
        OutTextXY(0,(RTP^.wSMAXY+5),'File Not Found! '+ FullFName);
        SetColor(LightGray);
        WaitaSec(RTP, RTP^.MssgTimeout,2);
      End;
    End;   
  End;      
  If (TOut)
  Then Begin
    Color_Rectangle(0, RTP^.wSMAXY+3, 
                    RTP^.wSMAXX, VGAMAXY, Black);
    SetColor(LightRed);
    OutTextXY(0,(RTP^.wSMAXY+5),'Timeout on user input!');
    SetColor(LightGray);
    WaitaSec(RTP, RTP^.MssgTimeout,2);
  End;
End;

Procedure LoadAll(RTP : RTP_PTR; Var tAbort : Boolean);

Var InFile    : text;    
    bIn       : Integer; 
    Cnt       : integer; 
    x,y       : Word;    
    lTempx    : Longint; 
    lTempy    : Longint; 
    New_Bug   : BUG_PTR; 
    Dead_Bug  : BUG_PTR; 
    Pixel     : Byte;    
    TempBugs  : Integer; 
    i,j,k     : Word;    
    Temp      : GRPH_BLOCK_PTR;
    Days, Hour, Min, Sec : Word;
    sLogFile  : STRING;  
    sVer      : STRING;  

Procedure Calc_new_start_time(Days, Hour, Min, Sec : Word);

Var  tNowS, tElapsedS: Longint;

Begin

With RTP^ Do Begin

    tNowS := Now div Longint(100);

    tElapsedS :=   (Longint(Hour) * Longint(3600)
                  + Longint(Min)  * Longint(60)
                  + Longint(Sec));

    wDays := Days;
    LDays := 500;  
    LHr   := 100;  
    LMin  := 100;  
    LSec  := 100;  

    If (tNowS > tElapsedS)   
    Then Begin               
      tStartS := tNowS - tElapsedS;
      tBS := FALSE;
    End
    Else
    Begin
      tStartS := tNowS - tElapsedS + Longint(86400);
      tBS := TRUE;
    End;
    Timers[6].LstTriggered := Now;
End;
End;


Begin
  With RTP^ Do Begin
    Color_Rectangle(0, wSMAXY+3, 
                    wSMAXX, VGAMAXY, Black);
    SetColor(LightGreen);
    OutTextXY(0,(RTP^.wSMAXY+5),'Loading Simulation...');
    SimStatWS;
  End;

  If RTP^.tSave
    Then Assign(Infile, RTP^.SimFile + '.SIM')
    Else Assign(Infile, 'TEMP.$$$');
  Reset(Infile);

  Readln(InFile);               
  Readln(InFile, sVer);         
  Readln(InFile);

  If sVer = VERSION
  Then BEGIN

    tAbort := FALSE;
    
    Cnt := 0;
    RTP^.Curr_Bug := RTP^.LL;
    Point_to_Next(RTP);                         
    While Not PastLast(RTP^.Curr_Bug) Do Begin  
        Dead_Bug := RTP^.Curr_Bug;
        Point_to_Next(RTP);
        Erase_All_Of(Dead_Bug^.posx, Dead_Bug^.posy, RTP);
        Del_From_List(Dead_Bug,RTP);
      Point_to_Next(RTP);                       
    End; 
    RTP^.Curr_Bug := Nil;
    Init(RTP^.LL);

    Display_Screen(RTP);                

    Readln(InFile);              
    Readln(InFile);
    Readln(InFile);              
    Readln(InFile);
    Readln(InFile);              
    Readln(InFile);

    With RTP^ Do Begin

      Readln(InFile, Days, Hour, Min, Sec);
      Calc_new_start_time(Days, Hour, Min, Sec);
      Readln(InFile, WordRec(Cycle_Cntr).Low,WordRec(Cycle_Cntr).High);
      Readln(InFile, TempBugs);
      NumofBugs := 0;                     
      Readln(InFile, Bact_on_Screen);
      Readln(InFile, Bact_in_Garden);
      Readln(InFile, Bin);
      GardenOn := Bin = 1;
      Readln(InFile, rSDENSITY);
      Readln(InFile, rGDENSITY);
      Readln(InFile, bGARDWID);
      Readln(InFile, bGARDHIG);
      Readln(InFile, rSLIMPCT);
      Readln(InFile, rGLIMPCT);
      Readln(InFile, bIn);
      tMAXAGE := bIn = 1;
      Readln(InFile, bIn);
      tMAXSTR := bIn = 1;
      Readln(InFile, bIn);
      tMATURE := bIn = 1;
      Readln(InFile, bIn);
      tREPROSTR := bIn = 1;
      Readln(InFile, bIn);
      tGProtect := bIn = 1;
      Readln(InFile, bMUTRATNG);
      Readln(InFile, bMUTRATMS);

      Readln(InFile, sLogFile);       
      If ParamCount < 2
      Then LogFile := sLogFile;
      

      Readln(InFile, bIn);
      tLogging := bIn = 1;           
      Readln(InFile, Timers[4].Interval);     
      Readln(InFile, bLogFSize100kb);

      
      
      
      
      
      

      Readln(InFile);
      Readln(InFile, WordRec(Timers[6].Interval).Low,WordRec(Timers[6].Interval).High);
      Readln(InFile);
      Readln(InFile, WordRec(ExpCycles).Low,WordRec(ExpCycles).High);
      Readln(InFile);
    End; 
  End 
  Else tAbort := TRUE;


  If Not(tAbort)
  Then Begin
    For Cnt := 1 to TempBugs Do Begin
      New(New_Bug);
      With New_Bug^ Do Begin
        Readln(InFile);
        Readln(InFile);    
        Readln(InFile);
        Readln(InFile, age);
        Readln(InFile, str);
        Readln(InFile, dir);
        Readln(InFile, posx);
        Readln(InFile, posy);
        Readln(InFile, colr);
        Readln(InFile, MAXAGE);
        Readln(InFile, MAXSTR);
        Readln(InFile, MATURE);
        Readln(InFile, REPROSTR);
        Readln(InFile, gene[0]);
        Readln(InFile, gene[1]);
        Readln(InFile, gene[2]);
        Readln(InFile, gene[3]);
        Readln(InFile, gene[4]);
        Readln(InFile, gene[5]);
      End;
    Calc_Prob(New_Bug);
    Ins(New_Bug,RTP);
    Display_All_Of(New_Bug);
    End;


  
    With RTP^ Do
    Begin
      Readln(InFile);
      Readln(InFile);    
      Readln(InFile);

      Readln(InFile,wGRPHDens);
      Readln(InFile,wGRPHCurs1);
      Readln(InFile,wGRPHCurs2);

      Readln(InFile,wGRPHBlok1);
      Readln(InFile,wGRPHBlok2);

      Readln(InFile,wGRPHMinX);
      Readln(InFile,wGRPHMinY);
      Readln(InFile,wGRPHMaxX);
      Readln(InFile,wGRPHMaxY);
    End;

    Readln(InFile);
    Readln(InFile);    
    Readln(InFile);

    With RTP^ Do
    FOR i := 1 to CGRPHObjs Do
    Begin
      Temp := RTP^.GRPHMatrix[i].DataPtr;
      FOR k := 1 to CGRPHWid Do
        Read(InFile, Temp^.Value[k]);
      Readln(InFile);                

      FOR j := 1 to CGRPHBuff Do
      Begin
        Temp := Temp^.Next;
        FOR k := 1 to CGRPHWid Do
          Read(InFile, Temp^.Value[k]);
      Readln(InFile);                     
      End; 
      Readln(InFile);          
    End; 

  
    With RTP^ Do Begin

      SimStatPB;

      lTempx := Trunc(1.0*(wSMAXX-wSMINX)/bSGRIDRESx)+1;
      lTempy := Trunc(1.0*(wSMAXY-wSMINY)/bSGRIDRESy)+1;

      Readln(InFile);    
      Readln(InFile);
      For Cnt := 0 to Bact_on_Screen + Bact_in_Garden Do Begin
        Readln(InFile,x,y);
        Pixel := GetPixel(x,y);
        If (Pixel = wSBK_COL) AND (Not (OnAnyBug(x,y,LL)))
        Then PutPixel(wSMINX + (x * bSGRIDRESx),
                      wSMINY + (y * bSGRIDRESy),wBACT_COL)
        Else If In_Garden(x,y,RTP)
             Then Dec(Bact_in_Garden)
             Else Dec(Bact_on_Screen);

      End;
    End;
  End;          
  SimStatR;
  Close(InFile);
End;  {Proc SaveAll() }

FUNCTION GetFName(    RTP    : RTP_PTR;
                      Prompt : STRING;
                      Default: STRING;
                  VAR TOut   : BOOLEAN) : STRING;

Var
    FName      : String;  
    Ch         : Char;
    H,M,S,S100 : Word;    
    StartTime,
    DeltaTime  : Word;    

Begin

    SimStatUI;
    Ch := #0;
    Fname := '';
    CheckBreak := FALSE;
    GetTime(H,M,S,S100);   
    StartTime := S;
    DeltaTime := 0;

    With RTP^ DO
    Color_Rectangle(0, wSMAXY+3, wSMAXX, VGAMAXY, Black);
    RTP^.IOMenu := 7;      
    Display_Menu(RTP);
    RTP^.IOMenu := 5;      

    SetColor(LightGray);
    OutTextXY(0,(RTP^.wSMAXY+7),Prompt);
    If Default <> ''  
    Then Begin
        SetFillStyle(SolidFill,LightGray);
        SetLineStyle(SolidLn, 0, Normwidth);
        Bar((Length(Prompt)*8)+8, RTP^.wSMAXY+6,
            (Length(Prompt)*8)+((Length(Default)*8)+8), RTP^.wSMAXY+14);
        SetLineStyle(SolidLn, 0, Normwidth);
        SetFillStyle(SolidFill,Black);
        SetColor(Black);
        OutTextXY((Length(Prompt)*8+9),      
                  (RTP^.wSMAXY+7),Default);  
        SetColor(RTP^.wTEXTF_COL);
    End;

    While (DeltaTime < RTP^.InputTimeout) AND (Ch <> #13) AND (Ch <> #27) Do
    Begin

       
       If Triggered(RTP^.Timers[5])
       then Begin
            Inc(RTP^.tStartS);
            If RTP^.tStartS > 86400
            Then RTP^.tStartS := 0;
       End;

       If Keypressed
       then Begin
          Ch := Readkey;
          If  (FName = '') AND (Ch <> #13)
          Then Begin
                 Setcolor(Black);
                 SetLineStyle(SolidLn, 0, Normwidth);       
                 SetFillStyle(SolidFill,Black);             
                 Bar((Length(Prompt)*8), RTP^.wSMAXY+6,
                     (Length(Prompt)*8)+150, RTP^.wSMAXY+14);
                 SetColor(LightGray);
          End;
          Case Ch of
{BS}       #8  : Begin
               If Length(FName) > 0
               then Begin
                 FName := Copy(FName,0,Length(FName)-1);
                 Setcolor(Black);
                 SetLineStyle(SolidLn, 0, Normwidth);       
                 SetFillStyle(SolidFill,Black);             
                 Bar((Length(Prompt)*8)+(Length(FName)*8)+8, RTP^.wSMAXY+6,
                     (Length(Prompt)*8)+(Length(FName)*8)+16, RTP^.wSMAXY+14);
                 SetColor(LightGray);
               End;
           End;
{ESC}      #27 : Begin        
                 FName := ''; 
           End
          else
{DEFAULT} Begin
             If (Length(FName) < 8)
                AND (   ((Ch > #47)       
                        AND (Ch < #58))
                     OR ((Ch > #64)       
                        AND (Ch < #91))
                     OR ((Ch > #96)       
                        AND (Ch < #123))
                     OR (Ch = #95))       
             then Begin
                FName := FName + UpCase(Ch);
                OutTextXY((Length(Prompt)*8)+Length(FName)*8,
                          (RTP^.wSMAXY+7), UpCase(Ch));
             End;
          End;
          End;     
       End;        
       GetTime(H,M,S,S100);   
       If (S < StartTime)
       THEN DeltaTime := (S+60) - StartTime
       ELSE DeltaTime := S-StartTime;
       If DeltaTime < 0
          Then DeltaTime := DeltaTime + 60;
    End;        

    If (Ch <> #13) AND (Ch <> #27)
       Then  TOut := TRUE
       Else  TOut := FALSE;
    If (FName <> '') AND (Ch = #13)
       Then GetFName    := FName;
    If (FName = '') AND (Ch = #13)
       Then GetFName    := Default;
    If (Ch = #27)
       Then GetFName    := '';
    CheckBreak := FALSE;
End;

FUNCTION GetPass(    RTP    : RTP_PTR;
                     Prompt : STRING;
                 VAR TOut   : BOOLEAN) : STRING;

Var
    Pass       : String;
    Ch         : Char;
    H,M,S,S100 : Word; 
    StartTime,DeltaTime      : Word; 

Begin

    SimStatUI;
    Ch := #0;
    Pass := '';
    CheckBreak := FALSE;
    GetTime(H,M,S,S100);   
    StartTime := S;
    DeltaTime := 0;

    With RTP^ DO
    Color_Rectangle(0, wSMAXY+3, wSMAXX, VGAMAXY, Black);

    SetColor(LightGray);
    OutTextXY(0,(RTP^.wSMAXY+5),Prompt);
    While (DeltaTime < RTP^.InputTimeout) AND (Ch <> #13) Do
    Begin

       
       If Triggered(RTP^.Timers[5])
       then Begin
            Inc(RTP^.tStartS);
            If RTP^.tStartS > 86400
            Then RTP^.tStartS := 0;
       End;

       If Keypressed
       then Begin
          Ch := Readkey;
          Case Ch of
{BS}       #8  : Begin
               If Length(Pass) > 0
               then Begin
                 Pass := Copy(Pass,0,Length(Pass)-1);

                 Setcolor(Black);
                 SetLineStyle(SolidLn, 0, Normwidth);
                 SetFillStyle(SolidFill,Black);
                 Bar(160 +Length(Pass)*10, RTP^.wSMAXY+5,
                     170+Length(Pass)*10, RTP^.wSMAXY+13);  
                 SetColor(LightGray);
               End;
          End
          else
{DEFAULT} Begin
             If Length(Pass) < 8
             then Begin
                Pass := Pass + Ch;
                OutTextXY(150+(Length(Pass)*10),
                          (RTP^.wSMAXY+5),'*');
             End;
          End;
          End;     
       End;        
       GetTime(H,M,S,S100);   
       If (S < StartTime)
       THEN DeltaTime := (S+60) - StartTime
       ELSE DeltaTime := S-StartTime;
       If DeltaTime < 0
          Then DeltaTime := DeltaTime + 60;
    End;        
    If (Ch <> #13)
       Then TOut := TRUE
       Else TOut := FALSE;

    GetPass    := Copy(Pass,0,Length(Pass)-1);
    CheckBreak := FALSE;
End;

FUNCTION CheckPass(RTP : RTP_PTR) : BOOLEAN;

Var Ch   : Char;
    TOut : Boolean;

Begin

   If RTP^.Password <> ''
   Then Begin
        If RTP^.Password = GetPass(RTP,'Password:',TOut)
        Then CheckPass := True
        Else CheckPass := False;
   End             
   Else CheckPass := True;

   SSOn(RTP);
End;

Procedure GetNewPass(RTP : RTP_PTR);

Var
    Pass       : String;
    Valid      : Boolean;
    TOut       : Boolean;

Begin
   If RTP^.Password <> ''
   Then Begin
   If RTP^.Password = GetPass(RTP,'Old Password:',TOut)
     Then Valid := TRUE
     Else Begin
       Color_Rectangle(0, RTP^.wSMAXY+3, RTP^.wSMAXX, VGAMAXY, Black);
       SetColor(LightRed);
       OutTextXY(0,(RTP^.wSMAXY+5),'Password Incorrect!');
       SetColor(LightGray);
       WaitaSec(RTP, RTP^.MssgTimeout,2);
       Valid := FALSE
     End
   End
   ELSE Begin
   If Not(RTP^.tHaveKey) Then Begin {tHaveKey set to True in Initialize_All}
   If RTP^.Key = GetPass(RTP,'Bypass Key:  ',TOut)
     Then Begin
          Valid := TRUE;
          RTP^.tHaveKey := TRUE;
     End
     Else Begin
       Color_Rectangle(0, RTP^.wSMAXY+3, RTP^.wSMAXX, VGAMAXY, Black);
       SetColor(LightRed);
       OutTextXY(0,(RTP^.wSMAXY+5),'Sorry, invalid key');
       OutTextXY(0,(RTP^.wSMAXY+20),'(Contact author to enable this function)');
       SetColor(LightGray);
       WaitaSec(RTP, RTP^.MssgTimeout,2);
       Valid := FALSE
     End
   End;
   End;

   If Valid
   Then Begin

    Pass := GetPass(RTP,'New Password:',TOut);
    If NOT(TOut)
    Then Begin

     If Pass = GetPass(RTP,'Verify Password:',TOut)
     Then Begin

     If Pass = '<CR>'                
       THEN RTP^.Password := ''      
       ELSE RTP^.Password := Pass;   
                                     

     Color_Rectangle(0, RTP^.wSMAXY+3, RTP^.wSMAXX, VGAMAXY, Black);
     SetColor(LightGreen);
     If Pass = ''
        THEN OutTextXY(0,(RTP^.wSMAXY+5),'Password Removed!')
        ELSE OutTextXY(0,(RTP^.wSMAXY+5),'Password Changed!');
     SetColor(LightGray);
     WaitaSec(RTP, RTP^.MssgTimeout,1);

     End
     Else Begin

     Color_Rectangle(0, RTP^.wSMAXY+3, RTP^.wSMAXX, VGAMAXY, Black);
     SetColor(LightRed);
     OutTextXY(0,(RTP^.wSMAXY+5),'Passwords Do Not Match!');
     SetColor(LightGray);
     WaitaSec(RTP, RTP^.MssgTimeout,2);

     End;
    End
    Else Begin
     Color_Rectangle(0, RTP^.wSMAXY+3, RTP^.wSMAXX, VGAMAXY, Black);
     SetColor(LightRed);
     OutTextXY(0,(RTP^.wSMAXY+5),'Password Timeout!');
     SetColor(LightGray);
     WaitaSec(RTP, RTP^.MssgTimeout,2);
    End;
   End;
   Display_Menu(RTP);
End;
end. 
