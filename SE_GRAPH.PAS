UNIT SE_GRAPH;

INTERFACE

{$D+}

USES DOS, CRT, GRAPH,    SE_QUE,   SE_MATH, SE_COM;

CONST
{-----------------------------------------------------------------------------}
GraphDriver = DETECT; { Uses the Auto Detect feature of Turbo Pascal    }
GraphMode   = VGA;    { Uses VGA mode                                   }

VAR
{-----------------------------------------------------------------------------}
GDriver, GMode, ErrorCode   : integer;

{-----------------------------------------------------------------------------}
Procedure Do_Graphics;
Procedure Display_Intro(RTP : RTP_PTR);
Procedure SSOn(RTP : RTP_PTR);
Procedure Display_Desc(RTP : RTP_PTR);
Procedure Display_Menu(RTP : RTP_PTR);
Procedure Display_Text(RTP : RTP_PTR);
Procedure Display_Screen(RTP : RTP_PTR);
Procedure Display_Graph(RTP : RTP_PTR);
Procedure Display_Species(RTP : RTP_PTR);
Procedure ClearScreen;
Procedure Populate_Garden(RTP : RTP_PTR);
Procedure Populate_Screen(Need_Refresh : Boolean;
                          RTP          : RTP_PTR);
Procedure Update_All_Bug_Col(RTP : RTP_PTR);
Procedure End_Graphics;
Procedure Display_In_New_Pos(RTP : RTP_PTR);
Procedure Display_all_of(Curr_Bug : BUG_PTR);
Procedure Erase_Previous_Pos(OldX : Word;
                             OldY : Word;
                             RTP  : RTP_PTR);
Procedure Erase_All_Of(posx : Word;
                       posy : Word;
                       RTP  : RTP_PTR);
Procedure Check_for_Food(RTP : RTP_PTR);
Procedure Display_Value(Cntr : LongInt;
                        Row  : Integer;
                        RTP  : RTP_PTR);
Procedure Display_Side_Stats(RTP : RTP_PTR);
Function  CountGarden(RTP : RTP_PTR) : Word;
Procedure SimStatPB;
Procedure SimStatUI;
Procedure SimStatR;
Procedure SimStatP;
Procedure SimStatCB;
Procedure SimStatRS;
Procedure SimStatWS;
Procedure SimStatSA;
Procedure SimStatWL;
Procedure SimStatUG;
Procedure Display_PauseOption(On  : Boolean;
                              RTP : RTP_PTR);
Procedure Color_Rectangle(X1, Y1, X2, Y2 : Word; Color : Word);
Procedure Display_IO_A(RTP : RTP_PTR);
Procedure Display_IO_B(RTP : RTP_PTR);
Function OnAnyBug(x,y : integer; LL : BUG_PTR) : Boolean;
Function In_Garden(x,y : integer; RTP : RTP_PTR) : Boolean;
Procedure Display_Elapsed(RTP : RTP_PTR; tElapsedS : Longint);
Procedure Calc_and_Display_Elapsed_Time(RTP : RTP_PTR);
Procedure WaitaSec(RTP: RTP_PTR;TimetoWait : LongInt; Beep : Byte);
Procedure DisplayCredits;

IMPLEMENTATION

{----------------------------------------------------------------------------}
Procedure Display_Elapsed;

Var Hr, Min, Sec     : Longint;
    sElapsed         : STRING;

BEGIN


With RTP^ Do BEGIN

    Hr := tElapsedS div Longint(3600);
    tElapsedS := tElapsedS - (Hr * Longint(3600));

    Min:= tElapsedS div Longint(60);
    tElapsedS := tElapsedS - (Min * Longint(60));

    if (tElapsedS <> LSec)
    Then Begin

      { Update Sec }
      Str(tElapsedS:2, sElapsed);
      If sElapsed[1] = ' '
      Then sElapsed[1] := '0';
      Color_Rectangle(MaxX-16,5,MaxX, MinY-3,Black);
      SetColor(RTP^.wTextF_Col);
      OutTextXY(MaxX-16,5,sElapsed);
      LSec := tElapsedS;

      If Min <> LMin
      Then Begin

        { Update Min }
        Str(Min:2, sElapsed);
        If sElapsed[1] = ' '
        Then sElapsed[1] := '0';
        Color_Rectangle(MaxX-40,5,MaxX-24, MinY-3,Black);
        SetColor(RTP^.wTextF_Col);
        OutTextXY(MaxX-40,5,sElapsed);
        LMin := Min;

        If Hr <> LHr
        Then Begin

          { Update Hours }
          Str(Hr:2, sElapsed);
          If sElapsed[1] = ' '
          Then sElapsed[1] := '0';
          Color_Rectangle(MaxX-64,5,MaxX-48, MinY-3,Black);
          SetColor(RTP^.wTextF_Col);
          OutTextXY(MaxX-64,5,sElapsed);
          LHr := Hr;

          If wDays <> LDays
          Then Begin

            { Update Days }
            Str(wDays:3, sElapsed);
            Color_Rectangle(MaxX-104,5,MaxX-81, MinY-3,Black);
            SetColor(RTP^.wTextF_Col);
            OutTextXY(MaxX-104,5,sElapsed);
            LDays := wDays;

          End; { If wDays     }
        End;   { If Hr        }
      End;     { If Min       }
    End;       { If TElapsedS }
  End;
END;
{-----------------------------------------------------------------------------}
Procedure Calc_and_Display_Elapsed_Time(RTP : RTP_PTR);

Var tNowS, tElapsedS : Longint;

Begin

With RTP^ Do Begin
   tNowS := Now div Longint(100);

   If (tNowS < tStartS)  { #1 If Currently BEFORE Sim started        }
   Then Begin               { THEN                                   }
     If NOT(tBS)            { If it's NOT OK to have condition #1    }
     Then Begin             {   Must be Just past midnight           }

       tBS := TRUE;         {   It's NOW OK to have condition #1     }

                            {   Calculation will result in a negative}
                            {   number so add 24 hours worth of sec's}
       tElapsedS := (tNowS - tStartS) + Longint(86400);
       Display_Elapsed(RTP, tElapsedS);

     End
     Else Begin             {   ELSE it's OK to have condition #1    }

       tElapsedS := (tNowS - tStartS) + Longint(86400);
       Display_Elapsed(RTP, tElapsedS);

     End
   End
   Else Begin            { #2 Current time is after (or =) sim start }
     If (tBS)               { If condition #2 is unacceptable        }
     Then Begin             {   Must be just past sim start time on  }
                            {   a subsequent day                        }
       Inc(wDays);          {   Day has passed so Inc Day counter    }
       tBS := False;        {   It is NOW OK to have Condition #2    }
       tElapsedS := (tNowS - tStartS);
       Display_Elapsed(RTP, tElapsedS);

     End
     Else Begin             {   ELSE Condition # 2 is ok             }

       {   Normal for sim start day !!!!!!      }
       tElapsedS := (tNowS - tStartS);
       Display_Elapsed(RTP, tElapsedS);

     End;
   End;
End;
End;
{----------------------------------------------------------------------------}
Procedure Display_IO_A;

VAR  Strng   : STRING;

BEGIN
  With RTP^ Do BEGIN
     Color_Rectangle(wGRPHMINX, wGRPHMINY, wGRPHMAXX, wGRPHMAXY,wGBK_COL);
     SetColor(Brown);

     OutTextXY(wGRPHMINX+3, wGRPHMINY+10, 'Change Password');
     OutTextXY(wGRPHMINX+3, wGRPHMINY+30, 'G Width');
     OutTextXY(wGRPHMINX+3, wGRPHMINY+50, 'G Hight');
     OutTextXY(wGRPHMINX+3, wGRPHMINY+70, 'S Rate');
     OutTextXY(wGRPHMINX+3, wGRPHMINY+90, 'G Rate');
     OutTextXY(wGRPHMINX+3, wGRPHMINY+110,'M Age');
     OutTextXY(wGRPHMINX+3, wGRPHMINY+130,'M Strength');
     OutTextXY(wGRPHMINX+3, wGRPHMINY+150,'M Mature');
     OutTextXY(wGRPHMINX+3, wGRPHMINY+170,'M ReproStr');
     OutTextXY(wGRPHMINX+3, wGRPHMINY+190,'Severity(B)');
     OutTextXY(wGRPHMINX+3, wGRPHMINY+210,'Severity(G)');

     SetColor(RTP^.wTEXTF_COL);
     SetTextJustify(RightText, TopText);

     Str(bGARDWID:4,Strng);
     OutTextXY(VGAMAXX-4, wGRPHMINY+30, Strng);

     Str(bGARDHIG:4,Strng);
     OutTextXY(VGAMAXX-4, wGRPHMINY+50, Strng);

     Str(bSLIM:2,Strng);
     OutTextXY(VGAMAXX-4, wGRPHMINY+70, Strng);

     Str(bGLIM:2,Strng);
     OutTextXY(VGAMAXX-4, wGRPHMINY+90, Strng);

     If (tMAXAGE)
     Then Strng := 'T'
     Else Strng := 'F';
     OutTextXY(VGAMAXX-4, wGRPHMINY+110,Strng);

     If (tMAXSTR)
     Then Strng := 'T'
     Else Strng := 'F';
     OutTextXY(VGAMAXX-4, wGRPHMINY+130,Strng);

     If (tMATURE)
     Then Strng := 'T'
     Else Strng := 'F';
     OutTextXY(VGAMAXX-4, wGRPHMINY+150,Strng);

     If (tREPROSTR)
     Then Strng := 'T'
     Else Strng := 'F';
     OutTextXY(VGAMAXX-4, wGRPHMINY+170,Strng);

     Str(bMUTRATNG:3,Strng);
     OutTextXY(VGAMAXX-4, wGRPHMINY+190,Strng);

     Str(bMUTRATMS:3,Strng);
     OutTextXY(VGAMAXX-4, wGRPHMINY+210,Strng);

     SetTextJustify(LeftText, TopText);

     SetColor(Yellow);
     SetLineStyle(Solidln,0,Normwidth);
     Rectangle(wGRPHMINX+1, wGRPHMINY+((IOMode-2)*20 +3),
               wGRPHMAXX-1, wGRPHMINY+((IOMode-2)*20)+23);
     SetLineStyle(Solidln,0,Normwidth);

     Display_Menu(RTP);
     Display_Desc(RTP);
  End;
END;
{----------------------------------------------------------------------------}
Procedure Display_IO_B;

VAR  Strng   : STRING;

BEGIN
  With RTP^ Do BEGIN
     Color_Rectangle(wGRPHMINX, wGRPHMINY, wGRPHMAXX, wGRPHMAXY,wGBK_COL);
     SetColor(Brown);

     OutTextXY(wGRPHMINX+3, wGRPHMINY+10, 'Save Simulation');
     OutTextXY(wGRPHMINX+3, wGRPHMINY+30, 'Load Simulation');
     OutTextXY(wGRPHMINX+3, wGRPHMINY+50, 'Protect Garden');
     OutTextXY(wGRPHMINX+3, wGRPHMINY+70, 'Logging');
     OutTextXY(wGRPHMINX+3, wGRPHMINY+90, 'Log Period');
     OutTextXY(wGRPHMINX+3, wGRPHMINY+110,'M File Size');
     OutTextXY(wGRPHMINX+3, wGRPHMINY+130,'Min To Run');

     SetColor(RTP^.wTEXTF_COL);
     SetTextJustify(RightText, TopText);

     If (tGProtect)
     Then Strng := 'T'
     Else Strng := 'F';
     OutTextXY(VGAMAXX-4, wGRPHMINY+50,Strng);

     If (tLOGGING)
     Then Strng := 'T'
     Else Strng := 'F';
     OutTextXY(VGAMAXX-4, wGRPHMINY+70,Strng);

     Str((Timers[4].Interval div 100):5,Strng);
     OutTextXY(VGAMAXX-4, wGRPHMINY+90, Strng);

     Str(bLogFSize100Kb:2,Strng);
     OutTextXY(VGAMAXX-4, wGRPHMINY+110, Strng);

     Str((Timers[6].Interval div 6000):5,Strng);
     OutTextXY(VGAMAXX-4, wGRPHMINY+130, Strng);

     SetTextJustify(LeftText, TopText);

     SetColor(Yellow);
     SetLineStyle(Solidln,0,Normwidth);
     Rectangle(wGRPHMINX+1, wGRPHMINY+((IOMode-13)*20 +3),
               wGRPHMAXX-1, wGRPHMINY+((IOMode-13)*20)+23);
     SetLineStyle(Solidln,0,Normwidth);

     Display_Menu(RTP);
     Display_Desc(RTP);
  End;
END;
{----------------------------------------------------------------------------}
Procedure Display_Menu;

VAR  j,k     : Integer;

BEGIN

   IF RTP^.GardenOn
      THEN Menu[1,3,2] := 'Disable'
      ELSE Menu[1,3,2] := 'Enable';

 With RTP^ Do Begin
   Color_Rectangle(0, wSMAXY+3, VGAMAXX, VGAMAXY, wSBK_COL);
   SetTextJustify(CenterText, CenterText);
   SetColor(wTEXTF_COL);
   For j := 1 to 5 Do
     For k := 1 to 3 Do
     Begin
       If k = 1
          Then SetColor(Brown)
          Else SetColor(wTextF_COL);
       OutTextXY(BColwid*j-BOffset,VGAMAXY-(35-10*k), Menu[RTP^.IOMenu,j,k]);
     End;
   SetTextJustify(LeftText, TopText);
   Display_Desc(RTP);
 End;

END;
{----------------------------------------------------------------------------}
Procedure WaitaSec(RTP: RTP_PTR; TimetoWait : LongInt; Beep : Byte);

Var
    H,M,S,S100           : Word; { Get all values from Gettime }
    StartTime, DeltaTime : Word; { Timers 1 & 2                }

BEGIN
  GetTime(H,M,S,S100);   { Get current time (seconds) }
  StartTime := S;
  DeltaTime := 0;

  If Beep = 1
  Then Begin
     Sound(500);           { Notification BEEP! }
     Delay(100);
     NoSound;
  End;

  If Beep = 2
  Then Begin
     Sound(200);           { Error BEEP! }
     Delay(200);
     NoSound;
  End;

  While (DeltaTime < TimetoWait)
  DO Begin
     If Triggered(RTP^.Timers[5])   { Freeze Elapsed Time since sim Paused}
     then Begin
          Inc(RTP^.tStartS);
          If RTP^.tStartS > 86400
          Then RTP^.tStartS := 0;
     End;

     GetTime(H,M,S,S100);   { Get current time (seconds) }
       If (S < StartTime)
       THEN DeltaTime := (S+60) - StartTime
       ELSE DeltaTime := S-StartTime;
       If DeltaTime < 0
          Then DeltaTime := DeltaTime + 60;
  End;        { WHILE}
END;
{----------------------------------------------------------------------------}
Procedure Color_Rectangle(X1, Y1, X2, Y2 : Word; Color : Word);
BEGIN
     Setcolor(Color);
     SetLineStyle(SolidLn, 0, Normwidth);
     SetFillStyle(SolidFill,Color);
     Bar(X1, Y1, X2, Y2);          { Paint area with color }
END;
{----------------------------------------------------------------------------}
Procedure SSOn(RTP : RTP_PTR);
BEGIN
With RTP^ Do Begin
      Color_Rectangle(0, wSMAXY+3, wSMAXX, VGAMAXY, Black);{ Clear Bottom }
      SetColor(Blue);
      SetTextJustify(CenterText,TopText);
      OutTextXY(wGARDNEARX+Trunc(bGARDWID/2+1),(RTP^.wSMAXY+16),'Password Locked');
      SetColor(DarkGray);
      OutTextXY(wGARDNEARX+Trunc(bGARDWID/2),(RTP^.wSMAXY+15),'Password Locked');
      SetTextJustify(LeftText, TopText);
      SetColor(wTEXTF_COL);
End; {WITH}
END;
{----------------------------------------------------------------------------}
Procedure Clear_Status;            { Internal }
Begin
    Color_Rectangle(StatHdrLen,0,StatHdrLen+170, MinY-3,Black);
End;
{----------------------------------------------------------------------------}
Procedure SimStatUI;
BEGIN
    Clear_Status;
    SetColor(DarkGray);
    OutTextXY(StatHdrLen,5,'WAITING FOR INPUT');
END;
{----------------------------------------------------------------------------}
Procedure SimStatPB;
BEGIN
    Clear_Status;
    SetColor(DarkGray);
    OutTextXY(StatHdrLen,5,'PLACING BACTERIA');
END;
{----------------------------------------------------------------------------}
Procedure SimStatR;
BEGIN
    Clear_Status;
    SetColor(DarkGray);
    OutTextXY(StatHdrLen,5,'RUNNING');
END;
{----------------------------------------------------------------------------}
Procedure SimStatP;
BEGIN
    Clear_Status;
    SetColor(DarkGray);
    OutTextXY(StatHdrLen,5,'PAUSED');
END;
{----------------------------------------------------------------------------}
Procedure SimStatCB;
BEGIN
    Clear_Status;
    SetColor(DarkGray);
    OutTextXY(StatHdrLen,5,'COUNTING BACTERIA');
END;
{----------------------------------------------------------------------------}
Procedure SimStatRS;
BEGIN
    Clear_Status;
    SetColor(DarkGray);
    OutTextXY(StatHdrLen,5,'READING SIM FROM FILE');
END;
{----------------------------------------------------------------------------}
Procedure SimStatWS;
BEGIN
    Clear_Status;
    SetColor(DarkGray);
    OutTextXY(StatHdrLen,5,'WRITING SIM FROM FILE');
END;
{----------------------------------------------------------------------------}
Procedure SimStatSA;
BEGIN
    Clear_Status;
    SetColor(DarkGray);
    OutTextXY(StatHdrLen,5,'SPECIES ANALYSIS');
END;
{----------------------------------------------------------------------------}
Procedure SimStatWL;
BEGIN
    Clear_Status;
    SetColor(DarkGray);
    OutTextXY(StatHdrLen,5,'WRITING TO LOG FILE');
END;
{----------------------------------------------------------------------------}
Procedure SimStatUG;
BEGIN
    Clear_Status;
    SetColor(DarkGray);
    OutTextXY(StatHdrLen,5,'UPDATING GRAPH');
END;
{----------------------------------------------------------------------------}
Function CountGarden;

VAR c,x,y : Word;
    lTempx : Longint;
    lTempy : Longint;

Begin
  With RTP^ Do
  Begin
    SimStatCB;
    c := 0;
    lTempx := Trunc(1.0*bGARDWID/bGGRIDRESx)+1;
    lTempy := Trunc(1.0*bGARDHIG/bGGRIDRESy)+1;
    For x := 0 to lTempx Do
    Begin
         For y := 0 to lTempy Do
         Begin
              If GetPixel(wGARDNEARX + (x * bGGRIDRESx),
                          wGARDNEARY + (y * bGGRIDRESy)) = wBACT_COL
                 then Inc(c);
         End;
    End;
    CountGarden := c;
    SimStatR;
  End; { With RTP }
End;
{----------------------------------------------------------------------------}
Procedure Do_Graphics;
     Begin
     GDriver := GraphDriver;
     GMode   := GraphMode;
     InitGraph(GDriver,GMode,'');  { Looks for EGAVGA.BGI in current dir }
     ErrorCode := GraphResult;
     if ErrorCode <> grOk then
     begin
          Writeln('Grapics error:', GraphErrorMsg(ErrorCode));
          Writeln('Program Aborted...');
          Halt(1);
     end;
     end;
{----------------------------------------------------------------------------}
Procedure Display_Intro;

Var
    H,M,S,S100           : Word; { Get all values from Gettime }
    StartTime, DeltaTime : Word; { Timers 1 & 2                }

   BEGIN
     SetColor(DarkGray);
     SetLineStyle(Solidln,0,Normwidth);
     Rectangle(180, 150, 460, 330);
     SetColor(Brown);
     SetLineStyle(Solidln,0,Thickwidth);
     Rectangle(170, 140, 470, 340);
     SetTextJustify(CenterText, CenterText);
     SetColor(LightGray);
     OutTextXY(320,190,'SIMULATED EVOLUTION');
     SetColor(DarkGray);
     OutTextXY(320,210,VERSION);
     SetColor(LightGray);
     OutTextXY(320,230,' By John R. Nash');
{     OutTextXY(320,240,'www.simulatedEvolution.com');                       }
     SetColor(DarkGray);
     OutTextXY(320,270,'This is FREE software under');
     OutTextXY(320,290,'the terms of the GNU GPL');
{     OutTextXY(320,280,'See LICENSE.txt for terms');                        }
{     OutTextXY(320,300,'See README.txt for instructions');}

     WaitaSec(RTP, RTP^.IntroTime,0);    { during program intro.             }
     SetColor(RTP^.wTextF_Col);

   END;
{----------------------------------------------------------------------------}
Procedure Display_Screen;
BEGIN
     SetColor(RTP^.wBORDER_COL);
     SetLineStyle(Solidln,0,Normwidth);
     With RTP^ Do
           Rectangle(wSMINX-2, wSMINY-2, wSMAXX+2, wSMAXY+2);
     With RTP^ Do
     Color_Rectangle(wSMINX-1, wSMINY-1, wSMAXX+1, wSMAXY+1, wSBK_COL);
END;
{----------------------------------------------------------------------------}
Procedure Display_Text;

VAR
      CursorX : Word;
      CursorY : Word;

BEGIN

     CursorX := Trunc(MaxX +(VGAMAXX-MaxX)/2); { Center text in area on right }
     CursorY := 5;                             { Start 5 pixels down from top }
     SetTextStyle(DefaultFont, HorizDir, 1);
     SetTextJustify(CenterText, CenterText);

     SetColor(Blue);
     OutTextXY(CursorX+1, CursorY+1, 'SIMULATED');
     Inc(CursorY,10);                                   { Move Cursor down 10 }
     OutTextXY(CursorX+1, CursorY+1, 'EVOLUTION    ');
     SetColor(RTP^.wTEXTF_COL);
     Dec(CursorY,10);                                   { Move Cursor up 10   }
     OutTextXY(CursorX, CursorY, 'SIMULATED');
     Inc(CursorY,10);                                   { Move Cursor down 10 }
     OutTextXY(CursorX, CursorY, 'EVOLUTION.com');


     Inc(CursorY,15);                               {     Move Cursor down 15 }
     OutTextXY(CursorX, CursorY, VERSION);
     Inc(CursorY,10);                               {     Move Cursor down 10 }
     OutTextXY(CursorX, CursorY, REGSTAMP1);        {      Registration Stamp }
     Inc(CursorY,10);                               {     Move Cursor down 10 }
     OutTextXY(CursorX, CursorY, REGSTAMP2);        {      Registration Stamp }
     Inc(CursorY,10);                               {     Move Cursor down 10 }
{    OutTextXY(CursorX, CursorY, REGSTAMP3);               Registration Stamp }


     Display_Menu(RTP);

     SetTextJustify(LeftText, TopText);
     OutTextXY(5,5,'SIMULATION STATUS:');

     CursorX := MAXX + 5 ;         { Set CursorX 5 pixels right of Bug Window }
     CursorY := 70;                { Move CursorY to pixel 70                 }
     OutTextXY(CursorX, CursorY, 'Cycle   :');
     Inc(CursorY,10);                                   { Move Cursor down 10 }
     OutTextXY(CursorX, CursorY,'Bugs    :');
     Inc(CursorY,10);                                   { Move Cursor down 10 }
     OutTextXY(CursorX, CursorY,'Bacteria:');

     CursorY := SPCSIDSTART-10;
     SetColor(Blue);
     OutTextXY(CursorX+1, CursorY+1,'Species Pop/StDv');
     SetColor(DarkGray);
     OutTextXY(CursorX, CursorY,'Species Pop/StDv');
     Inc(CursorY,10);                                   { Move Cursor down 10 }
     SetColor(RTP^.wTEXTF_COL);
     OutTextXY(CursorX, CursorY,'Forward:');
     Inc(CursorY,10);                                   { Move Cursor down 10 }
     OutTextXY(CursorX, CursorY,'Soft-R :');
     Inc(CursorY,10);                                   { Move Cursor down 10 }
     OutTextXY(CursorX, CursorY,'Hard-R :');
     Inc(CursorY,10);                                   { Move Cursor down 10 }
     OutTextXY(CursorX, CursorY,'Reverse:');
     Inc(CursorY,10);                                   { Move Cursor down 10 }
     OutTextXY(CursorX, CursorY,'Hard-L :');
     Inc(CursorY,10);                                   { Move Cursor down 10 }
     OutTextXY(CursorX, CursorY,'Soft-L :');
     OutTextXY(MaxX-88,5,'0d 00:00:00');

END;
{----------------------------------------------------------------------------}
Procedure Display_PauseOption;
Begin
   SetTextJustify(CenterText, CenterText);
   Color_Rectangle(BColwid*3,BMenuRow1-4,BColwid*4,BMenuRow2+4,RTP^.wTEXTB_COL);
   SetColor(RTP^.wTEXTF_COL);
   IF ON
     THEN BEGIN
        SetColor(Brown);
        OutTextXY(BColwid*4-BOffset,BMenuRow1,'-Any Key-');
        SetColor(RTP^.wTextF_COL);
        OutTextXY(BColwid*4-BOffset,BMenuRow2,'Continue');
     END
     ELSE BEGIN
        SetColor(Brown);
        OutTextXY(BColwid*4-BOffset,BMenuRow1,'Alt-P');
        SetColor(RTP^.wTextF_COL);
        OutTextXY(BColwid*4-BOffset,BMenuRow2,'Pause');
     END;
   SetTextJustify(LeftText, TopText);
End;
{----------------------------------------------------------------------------}
Procedure Display_Desc;

VAR
      CursorX : Word;
      CursorY : Word;
      j,k     : Integer;

BEGIN

  With RTP^ DO Begin
     SetTextJustify(CenterText, CenterText);
     SetColor(RTP^.wTEXTF_COL);
     For j := 1 to 3 Do
       Begin
       OutTextXY(wGRPHMAXX-Trunc((wGRPHMAXX-wGRPHMINX)/2),
       VGAMAXY-(35-10*j), Desc[RTP^.IOMode,j]);
       End;
     SetTextJustify(LeftText, TopText);
  End;

END;
{----------------------------------------------------------------------------}
Procedure Display_Graph;

BEGIN
  With RTP^ Do BEGIN
     SetColor(wBORDER_COL);
     SetLineStyle(Solidln,0,Normwidth);
     With RTP^ Do
           Rectangle(wGRPHMINX-1, wGRPHMINY-1, wGRPHMAXX+1, wGRPHMAXY+1);
     With RTP^ Do
     Color_Rectangle(wGRPHMINX, wGRPHMINY, wGRPHMAXX, wGRPHMAXY,wGBK_COL);
  End;

END;
{----------------------------------------------------------------------------}
Procedure ClearScreen;
BEGIN
   ClearDevice
END;
{----------------------------------------------------------------------------}
Function OnAnyBug(x  : Integer;               { Used by LoadAll in SE_IO.PAS }
                  y  : Integer;
                  LL : BUG_PTR) : Boolean;

VAR OnBug : Boolean;

BEGIN
     OnBug := False; { Optomistic }
     LL := LL^.next;
     While (LL^.age <> ($FFFF)) AND Not(OnBug) Do
           With LL^ Do                      { If choosen coordinate falls on }
           Begin                            { any bug in the linked list     }
                                            { then the while loop is broken  }
             IF          (((x = posx + 1)   { and TRUE is returned           }
                        OR (x = posx    )
                        OR (x = posx - 1))
                     AND  ((y = posy + 1)
                        OR (y = posy    )
                        OR (y = posy -1 )))
                     Then OnBug := True;

             LL := LL^.next;
           End;
     OnAnyBug := OnBug;

END; { OnAnyBug }
{----------------------------------------------------------------------------}
Function In_Garden(X   : Integer;             { Used by LoadAll in SE_IO.PAS }
                   Y   : Integer;
                   RTP : RTP_PTR) : Boolean;
BEGIN
     If  (((X < RTP^.wGARDNEARX)
       OR  (X > RTP^.wGARDFARX))
       OR ((Y < RTP^.wGARDNEARY)
       OR  (Y > RTP^.wGARDFARY)))
       THEN In_Garden := FALSE
       ELSE In_Garden := TRUE;
END;
{----------------------------------------------------------------------------}
Procedure Populate_Garden;

VAR Add_to_Garden   : Word;
    Pixel,i         : Word;
    x,y             : Integer;
    Attempts        : Word;
    lTemp           : Longint;

Begin

   SimStatPB;
   If RTP^.wGBACTMAX < RTP^.Bact_in_Garden
      Then Add_to_Garden := 0
      Else Add_to_Garden := RTP^.wGBACTMAX - RTP^.Bact_in_Garden;
   If Add_to_Garden > RTP^.bGLIM
      then Add_to_Garden := RTP^.bGLIM;

   Attempts := 0;
   i := 0;

   While ((i < Add_to_Garden) AND (Attempts < RTP^.wGMAXTRYS)) Do
   Begin
   With RTP^ Do Begin
       Repeat
       Begin
         Inc(Attempts);
         lTemp := Trunc(1.0*bGARDWID/bGGRIDRESx)+1;
         x := (Random(WordRec(lTemp).low) * bGGRIDRESx + wGARDNEARX);
         lTemp := Trunc(1.0*bGARDHIG/bGGRIDRESy)+1;
         y := (Random(WordRec(lTemp).low) * bGGRIDRESy + wGARDNEARY);
         Pixel := GetPixel(x,y);
       End;
       Until (Pixel = wSBK_COL)
          OR (Attempts > wGMAXTRYS);

       If    ((Attempts <= wGMAXTRYS)
          AND (Not(OnAnyBug(x,y,LL))))

          Then Begin
               PutPixel(x,y, wBACT_COL);
               Inc(Bact_in_Garden);
          End;
   End; { With RTP }
   Inc(i);
   End; { While    }
   SimStatR;

END; { Populate_Garden }
{----------------------------------------------------------------------------}
Procedure Populate_Screen;

VAR Add_to_Screen     : Word;
    Pixel,i           : Word;
    x,y               : Integer;
    Attempts          : Word;
    MaxAttempts       : Word;
    lTemp             : Longint;

Begin
   SimStatPB;
   With RTP^ Do Begin

   If GardenOn   { Set variable Add_to_Screen (# of Bacteria) }
      Then Begin
           If Bact_on_Screen > wSBACTWG
              Then Add_to_Screen := 0
              Else Add_to_Screen := wSBACTWG - Bact_on_Screen;
           End
      Else If Bact_on_Screen > wSBACTMAX
              Then Add_to_Screen := 0
              Else Add_to_Screen := wSBACTMAX - Bact_on_Screen;

   If Add_to_Screen > bSLIM
      then Add_to_Screen := bSLIM;
   MaxAttempts := wSMAXTRYS;
   If Need_Refresh  { Screen requires refresh }
      then Begin
           If GardenOn
              Then Add_to_Screen := wSBACTWG
              Else Add_to_Screen := wSBACTMAX;
           MaxAttempts := Add_to_Screen * 2;
           Bact_on_Screen := 0;
      End;

   Attempts := 0;
   i := 0;

   While ((i < Add_to_Screen) AND (Attempts < MaxAttempts)) Do
   Begin

     If GardenOn
       Then Repeat { Garden active so deposit NO bact in Garden }
             Begin
               Inc(Attempts);
               lTemp := Trunc(1.0*(RTP^.wSMAXX-RTP^.wSMINX)/bSGRIDRESx)+1;
               x     := Random(WordRec(lTemp).low) * bSGRIDRESx + RTP^.wSMINX;
               lTemp := Trunc(1.0*(RTP^.wSMAXY-RTP^.wSMINY)/bSGRIDRESy)+1;
               y     := Random(WordRec(lTemp).low) * bSGRIDRESy + RTP^.wSMINY;
               Pixel := GetPixel(x,y);
             End;
       Until          (((Pixel = wSBK_COL)
                 AND  Not(In_Garden(x,y,RTP)))
             OR       (Attempts > MaxAttempts))


       Else Repeat { No Garden so deposit all across Screen }
             Begin
               Inc(Attempts);
               lTemp := Trunc(1.0*(RTP^.wSMAXX-RTP^.wSMINX)/bSGRIDRESx)+1;
               x     := Random(WordRec(lTemp).low) * bSGRIDRESx + RTP^.wSMINX;
               lTemp := Trunc(1.0*(RTP^.wSMAXY-RTP^.wSMINY)/bSGRIDRESy)+1;
               y     := Random(WordRec(lTemp).low) * bSGRIDRESy + RTP^.wSMINY;
               Pixel := GetPixel(x,y);
             End;
       Until (Pixel = wSBK_COL)
          OR (Attempts > MaxAttempts);

     If     ((Attempts <= MaxAttempts)
        AND (Not(OnAnyBug(x,y,LL))))

        Then Begin
             PutPixel(x,y, wBACT_COL);
             Inc(Bact_on_Screen);
        End;

   Inc(i);
   End; { While }
   End; { With RTP }
   SimStatR;
END;
{----------------------------------------------------------------------------}
Procedure Update_All_Bug_Col;
Begin
While RTP^.Curr_Bug^.Next^.Age < ($FFFF) Do
With RTP^ Do Begin
     Curr_Bug := Curr_Bug^.Next;
     With Curr_Bug^ do Begin
          If (age < Mature-50)

             Then If (Str < 4*bBacteria)               { Adolecent }
                     then Colr := wBC_Weak
                     else If (Str < ReproStr)
                             then Colr := wBC_Norm
                             else Colr := wBC_Str_Y

             Else If (age < MaxAge-50)          { Adult (Not yet elderly) }
                  then If (Str < 4*bBacteria)
                          then Colr := wBC_Weak
                          else If (Str < ReproStr-4*bBacteria)
                                  then Colr := wBC_Norm
                                  else Colr := wBC_Str_O

                  Else                                 { Old Fart }
                       If (Str < ReproStr-4*bBacteria)
                          then Colr := wBC_Weak
                          else Colr := wBC_Vry_O;
     End;
End;
End; {Update_Bug_Col}
{-----------------------------------------------------------------------------}
Procedure Erase_Previous_Pos;

Begin
   With RTP^.Curr_Bug^ Do Begin

       If  ((posx = (RTP^.wSMinX+2))
         OR (posx = (RTP^.wSMaxX-2))
         OR (posy = (RTP^.wSMinY+2))
         OR (posy = (RTP^.wSMaxY-2)))

         Then Erase_All_Of(OldX, OldY, RTP)

         Else With RTP^ Do Begin

              {-------------- Paint over Bug to be moved ---------------}
              Case dir of

                        0 : Begin
                          PutPixel(posx-1,   posy+2, wSBK_COL);
                          PutPixel(posx,     posy+2, wSBK_COL);
                          PutPixel(posx+1,   posy+2, wSBK_COL);
                          PutPixel(posx-1,   posy+3, wSBK_COL);
                          PutPixel(posx,     posy+3, wSBK_COL);
                          PutPixel(posx+1,   posy+3, wSBK_COL);
                        End;

                        1 : Begin
                          PutPixel(posx-2,   posy,   wSBK_COL);
                          PutPixel(posx-2,   posy+1, wSBK_COL);
                          PutPixel(posx-2,   posy+2, wSBK_COL);
                          PutPixel(posx-3,   posy,   wSBK_COL);
                          PutPixel(posx-3,   posy+1, wSBK_COL);
                          PutPixel(posx-3,   posy+2, wSBK_COL);
                          PutPixel(posx-1,   posy+2, wSBK_COL);
                        End;

                        2 : Begin
                          PutPixel(posx-2,   posy,   wSBK_COL);
                          PutPixel(posx-2,   posy-1, wSBK_COL);
                          PutPixel(posx-2,   posy-2, wSBK_COL);
                          PutPixel(posx-3,   posy,   wSBK_COL);
                          PutPixel(posx-3,   posy-1, wSBK_COL);
                          PutPixel(posx-3,   posy-2, wSBK_COL);
                          PutPixel(posx-1,   posy-2, wSBK_COL);
                        End;

                        3 : Begin
                          PutPixel(posx-1,   posy-2, wSBK_COL);
                          PutPixel(posx,     posy-2, wSBK_COL);
                          PutPixel(posx+1,   posy-2, wSBK_COL);
                          PutPixel(posx-1,   posy-3, wSBK_COL);
                          PutPixel(posx,     posy-3, wSBK_COL);
                          PutPixel(posx+1,   posy-3, wSBK_COL);
                        End;

                        4 : Begin
                          PutPixel(posx+2,   posy,   wSBK_COL);
                          PutPixel(posx+2,   posy-1, wSBK_COL);
                          PutPixel(posx+2,   posy-2, wSBK_COL);
                          PutPixel(posx+3,   posy,   wSBK_COL);
                          PutPixel(posx+3,   posy-1, wSBK_COL);
                          PutPixel(posx+3,   posy-2, wSBK_COL);
                          PutPixel(posx+1,   posy-2, wSBK_COL);
                        End;

                        5 : Begin
                          PutPixel(posx+2,   posy,   wSBK_COL);
                          PutPixel(posx+2,   posy+1, wSBK_COL);
                          PutPixel(posx+2,   posy+2, wSBK_COL);
                          PutPixel(posx+3,   posy,   wSBK_COL);
                          PutPixel(posx+3,   posy+1, wSBK_COL);
                          PutPixel(posx+3,   posy+2, wSBK_COL);
                          PutPixel(posx+1,   posy+2, wSBK_COL);
                   End;

            End; { Case }
       End; { If }
   End; { With }
End; { Erase_Previous_Pos }
{-----------------------------------------------------------------------------}
Procedure Erase_All_Of;

Begin

With RTP^ Do Begin
       {-------- Paint over Bug --------}
       PutPixel(posx-1, posy-1, wSBK_COL);
       PutPixel(posx-1, posy,   wSBK_COL);
       PutPixel(posx-1, posy+1, wSBK_COL);
       PutPixel(posx,   posy-1, wSBK_COL);
       PutPixel(posx,   posy,   wSBK_COL);
       PutPixel(posx,   posy+1, wSBK_COL);
       PutPixel(posx+1, posy-1, wSBK_COL);
       PutPixel(posx+1, posy,   wSBK_COL);
       PutPixel(posx+1, posy+1, wSBK_COL);
End; { With RTPG    }

End; { Erase_All_Of }
{----------------------------------------------------------------------------}
Procedure Display_all_of(Curr_Bug  : BUG_PTR);

BEGIN

     With Curr_Bug^ Do Begin

       {-------------- Redraw Bug in New location ---------------}

             PutPixel(posx-1,   posy-1, colr);
             PutPixel(posx-1,   posy,   colr);
             PutPixel(posx-1,   posy+1, colr);
             PutPixel(posx,     posy-1, colr);
             PutPixel(posx,     posy,   colr);
             PutPixel(posx,     posy+1, colr);
             PutPixel(posx+1,   posy-1, colr);
             PutPixel(posx+1,   posy,   colr);
             PutPixel(posx+1,   posy+1, colr);

     End; { With }

END; (* Procedure Display_all_of *)
{-----------------------------------------------------------------------------}
Procedure Display_In_New_Pos;

BEGIN

     With RTP^.Curr_Bug^ Do

       If  ((posx = (RTP^.wSMinX+2))
         OR (posx = (RTP^.wSMaxX-3))
         OR (posy = (RTP^.wSMinY+2))
         OR (posy = (RTP^.wSMaxY-3)))

       {-------------- Redraw Bug in New location ---------------}

         Then Display_all_of(RTP^.Curr_Bug)

       {---- Redraw Only Needed parts of Bug in New location ----}

         Else Case dir of

           0 : Begin
             PutPixel(posx-1,   posy-1, colr);
             PutPixel(posx-1,   posy,   colr);
             PutPixel(posx,     posy-1, colr);
             PutPixel(posx,     posy,   colr);
             PutPixel(posx+1,   posy-1, colr);
             PutPixel(posx+1,   posy,   colr);
           End;

           1 : Begin
             PutPixel(posx-1,   posy-1, colr);
             PutPixel(posx,     posy-1, colr);
             PutPixel(posx,     posy,   colr);
             PutPixel(posx,     posy+1, colr);
             PutPixel(posx+1,   posy-1, colr);
             PutPixel(posx+1,   posy,   colr);
             PutPixel(posx+1,   posy+1, colr);
           End;

           2 : Begin
             PutPixel(posx-1,   posy+1, colr);
             PutPixel(posx,     posy-1, colr);
             PutPixel(posx,     posy,   colr);
             PutPixel(posx,     posy+1, colr);
             PutPixel(posx+1,   posy-1, colr);
             PutPixel(posx+1,   posy,   colr);
             PutPixel(posx+1,   posy+1, colr);
           End;

           3 : Begin
             PutPixel(posx-1,   posy,   colr);
             PutPixel(posx-1,   posy+1, colr);
             PutPixel(posx,     posy,   colr);
             PutPixel(posx,     posy+1, colr);
             PutPixel(posx+1,   posy,   colr);
             PutPixel(posx+1,   posy+1, colr);
           End;

           4 : Begin
             PutPixel(posx-1,   posy-1, colr);
             PutPixel(posx-1,   posy,   colr);
             PutPixel(posx-1,   posy+1, colr);
             PutPixel(posx,     posy-1, colr);
             PutPixel(posx,     posy,   colr);
             PutPixel(posx,     posy+1, colr);
             PutPixel(posx+1,   posy+1, colr);
           End;

           5 : Begin
             PutPixel(posx-1,   posy-1, colr);
             PutPixel(posx-1,   posy,   colr);
             PutPixel(posx-1,   posy+1, colr);
             PutPixel(posx,     posy-1, colr);
             PutPixel(posx,     posy,   colr);
             PutPixel(posx,     posy+1, colr);
             PutPixel(posx+1,   posy-1, colr);
           End;

     End; { Case }

END; (* Procedure Display_in_new_Pos *)
{-----------------------------------------------------------------------------}
Procedure Check_Column_for_Food(    Column         : Word;
                                    StartY         : Word;
                                    EndY           : Word;
                                VAR str            : Word;
                                VAR Bact_on_Screen : Word;
                                VAR Bact_in_Garden : Word;
                                    GardenOn       : Boolean;
                                    RTP            : RTP_PTR);

                                    { Internal }
VAR x,y : Integer;

Begin
    x := Column;
    For y := StartY to EndY Do
          With RTP^ Do Begin
               If (GetPixel(x,y) = wBACT_COL)
                 then Begin
                      PutPixel(x,y,wSBK_COL);
                      str := str + RTP^.bBacteria;
                      If (GardenOn AND In_Garden(x,y,RTP))
                          then Dec(Bact_in_Garden)
                          else Dec(Bact_on_Screen);
                 End;
          End;
End; { Check_Column_for_Food }
{-----------------------------------------------------------------------------}
Procedure Check_Row_for_Food(    Row            : Word;
                                 StartX         : Word;
                                 EndX           : Word;
                             VAR Str            : Word;
                             VAR Bact_on_Screen : Word;
                             VAR Bact_in_Garden : Word;
                                 GardenOn       : Boolean;
                                 RTP            : RTP_PTR);
VAR x,y : Integer;

Begin
    y := Row;
    For x := StartX to EndX Do
          With RTP^ Do Begin
               If (GetPixel(x,y) = wBACT_COL)
                 then Begin
                      PutPixel(x,y,wSBK_COL);
                      str := str + bBacteria;
                      If (GardenOn AND In_Garden(x,y,RTP))
                          then Dec(Bact_in_Garden)
                          else Dec(Bact_on_Screen);
                 End;
          End;
End; { Check_Row_for_Food }
{----------------------------------------------------------------------------}
Procedure Check_for_Food;

VAR x,y : Word;
    S   : Word;

Begin
     With RTP^.Curr_Bug^ Do
     Begin

       If  ((posx = (RTP^.wSMinX+1))    { If TRUE then bug moved from one side }
         OR (posx = (RTP^.wSMaxX-2))    { of the screen boundry to the other   }
         OR (posy = (RTP^.wSMinY+1))
         OR (posy = (RTP^.wSMaxY-2)))

         Then With RTP^ Do Begin { Check for food in a 4 x 4 grid }

             For x := (posx-2) to (posx+2) Do
                For y := (posy-2) to (posy+2) Do
                   Begin

                      If (GetPixel(x, y) = wBACT_COL)
                        then Begin
                             PutPixel(x, y, wSBK_COL);
                             str := str + bBacteria;
                             If (GardenOn AND In_Garden(x,y,RTP))
                                then Dec(Bact_in_Garden)
                                else Dec(Bact_on_Screen);
                        End;

                   End;

         End { Check for foodin 4 x 4 grid }

         Else With RTP^ Do Begin { Check for food only in new direction }

             S := Str;

             Case dir of

                  0 : Begin { Case 0 --------------------------------- }

                      Check_Column_for_Food(   posx-2, posy-2, posy+2,
                         S,Bact_On_Screen, Bact_in_Garden, GardenOn, RTP);

                      Check_Column_for_Food(   posx-1, posy-2, posy,
                         S,Bact_On_Screen, Bact_in_Garden, GardenOn, RTP);

                      Check_Column_for_Food(   posx,   posy-2, posy,
                         S,Bact_On_Screen, Bact_in_Garden, GardenOn, RTP);

                      Check_Column_for_Food(   posx+1, posy-2, posy,
                         S,Bact_On_Screen, Bact_in_Garden, GardenOn, RTP);

                      Check_Column_for_Food(   posx+2, posy-2, posy+2,
                         S,Bact_On_Screen, Bact_in_Garden, GardenOn, RTP);

                  End; { Case 0 }

                  1 : Begin { Case 1 --------------------------------- }

                      Check_Row_for_Food(     posy-2, posx-2, posx+2,
                         S,Bact_On_Screen, Bact_in_Garden, GardenOn, RTP);

                      Check_Row_for_Food(     posy-1, posx-2, posx+2,
                         S,Bact_On_Screen, Bact_in_Garden, GardenOn, RTP);

                      Check_Row_for_Food(     posy,   posx,   posx+2,
                         S,Bact_On_Screen, Bact_in_Garden, GardenOn, RTP);

                      Check_Row_for_Food(     posy+1, posx,   posx+2,
                         S,Bact_On_Screen, Bact_in_Garden, GardenOn, RTP);

                      Check_Row_for_Food(     posy+2, posx,   posx+2,
                         S,Bact_On_Screen, Bact_in_Garden, GardenOn, RTP);

                  End; { Case 1 }

                  2 : Begin { Case 2 --------------------------------- }

                      Check_Row_for_Food(     posy-2, posx,   posx+2,
                         S,Bact_On_Screen, Bact_in_Garden, GardenOn, RTP);

                      Check_Row_for_Food(     posy-1, posx,   posx+2,
                         S,Bact_On_Screen, Bact_in_Garden, GardenOn, RTP);

                      Check_Row_for_Food(     posy,   posx,   posx+2,
                         S,Bact_On_Screen, Bact_in_Garden, GardenOn, RTP);

                      Check_Row_for_Food(     posy+1, posx-2, posx+2,
                         S,Bact_On_Screen, Bact_in_Garden, GardenOn, RTP);

                      Check_Row_for_Food(     posy+2, posx-2, posx+2,
                         S,Bact_On_Screen, Bact_in_Garden, GardenOn, RTP);

                  End; { Case 2 }

                  3 : Begin { Case 3 --------------------------------- }

                      Check_Column_for_Food(   posx-2, posy-2, posy+2,
                         S,Bact_On_Screen, Bact_in_Garden, GardenOn, RTP);

                      Check_Column_for_Food(   posx-1, posy, posy+2,
                         S,Bact_On_Screen, Bact_in_Garden, GardenOn, RTP);

                      Check_Column_for_Food(   posx,   posy, posy+2,
                         S,Bact_On_Screen, Bact_in_Garden, GardenOn, RTP);

                      Check_Column_for_Food(   posx+1, posy, posy+2,
                         S,Bact_On_Screen, Bact_in_Garden, GardenOn, RTP);

                      Check_Column_for_Food(   posx+2, posy-2, posy+2,
                         S,Bact_On_Screen, Bact_in_Garden, GardenOn, RTP);

                  End; { Case 3 }

                  4 : Begin { Case 4 --------------------------------- }

                      Check_Row_for_Food(     posy-2, posx-2, posx,
                         S,Bact_On_Screen, Bact_in_Garden, GardenOn, RTP);

                      Check_Row_for_Food(     posy-1, posx-2, posx,
                         S,Bact_On_Screen, Bact_in_Garden, GardenOn, RTP);

                      Check_Row_for_Food(     posy,   posx-2, posx,
                         S,Bact_On_Screen, Bact_in_Garden, GardenOn, RTP);

                      Check_Row_for_Food(     posy+1, posx-2, posx+2,
                         S,Bact_On_Screen, Bact_in_Garden, GardenOn, RTP);

                      Check_Row_for_Food(     posy+2, posx-2, posx+2,
                         S,Bact_On_Screen, Bact_in_Garden, GardenOn, RTP);

                  End; { Case 4 }

                  5 : Begin { Case 5 --------------------------------- }

                      Check_Row_for_Food(     posy-2, posx-2, posx+2,
                         S,Bact_On_Screen, Bact_in_Garden, GardenOn, RTP);

                      Check_Row_for_Food(     posy-1, posx-2, posx+2,
                         S,Bact_On_Screen, Bact_in_Garden, GardenOn, RTP);

                      Check_Row_for_Food(     posy,   posx-2, posx,
                         S,Bact_On_Screen, Bact_in_Garden, GardenOn, RTP);

                      Check_Row_for_Food(     posy+1, posx-2, posx,
                         S,Bact_On_Screen, Bact_in_Garden, GardenOn, RTP);

                      Check_Row_for_Food(     posy+2, posx-2, posx,
                         S,Bact_On_Screen, Bact_in_Garden, GardenOn, RTP);

                  End; { Case 5 }

             End; { Case }

         Str := S;
         End; { Check for food only in new direction }

     End; { With }
     With RTP^.Curr_Bug^ Do
          If str > MaxStr then str := MaxStr;

End; { Check_for_food }
{----------------------------------------------------------------------------}
Procedure Display_Value;

VAR CursorX,
    CursorY : Word;
    Strng   : STRING;

BEGIN
     CursorX := VGAMAXX-4;
     CursorY := StatStart+Row;
     Color_Rectangle(CursorX -8*4,CursorY,CursorX,CursorY+8,RTP^.wTEXTB_Col);
     SetColor(RTP^.wTEXTF_COL);
     SetTextJustify(RightText, TopText);
     Str(Cntr:4,Strng);
     OutTextXY(CursorX,CursorY,Strng);
     SetTextJustify(LeftText, TopText);
END;
{----------------------------------------------------------------------------}
Procedure Display_Side_Stats;
BEGIN
With RTP^ Do Begin
     Display_Value(Cycle_Cntr, 0, RTP);                       { Cycles }
     Display_Value(NumofBugs, 10, RTP);                       { Bugs   }
     Display_Value(Bact_on_Screen+Bact_in_Garden, 20, RTP);   { Bact   }
End; { With }
END;
{----------------------------------------------------------------------------}
Procedure Display_Species;

VAR CursorX,
    CursorY : Word;
    Strng   : STRING;
    mean    : Integer; { Loop indices indicating current mean to process     }

BEGIN
     CursorX := VGAMAXX-4;
     CursorY := SPCSIDSTART;

FOR mean := 0 to NUMOFGENES DO
   BEGIN
     Color_Rectangle(CursorX -8*8,CursorY,CursorX,CursorY+8,RTP^.wTEXTB_Col);
     SetColor(RTP^.wTEXTF_COL);
     SetTextJustify(RightText, TopText);

     IF (RTP^.SpeciesID[mean].Pop < 2)
        THEN BEGIN
             Strng := '-/-.--';
             OutTextXY(CursorX,CursorY,Strng);
        END
        ELSE BEGIN
             Str(RTP^.SpeciesID[mean].Stddev:4:2,Strng);
             OutTextXY(CursorX,CursorY,Strng);
             Str(RTP^.SpeciesID[mean].Pop:3,Strng);
             Strng := Strng + '/';
             OutTextXY(CursorX-32,CursorY,Strng);
        END;
     Inc(CursorY,10);
   END;
   SetTextJustify(LeftText, TopText);
END;
{----------------------------------------------------------------------------}
Procedure End_Graphics;
Begin
   CloseGraph;
End;
{----------------------------------------------------------------------------}
Procedure DisplayCredits;

Var
    SF        : text;
    DF        : text;
    Ch        : Char;
    bCh       : byte;
    sCh       : STRING;
    LCh       : Longint;
    Line, cnt : integer;

Begin
TextBackground(0);
Textcolor(7);
ClrScr;

Writeln('');
Writeln('');
Writeln('                             Simulated  Evolution');
Writeln('');
Writeln('                                      by');
Writeln('');
Writeln('                                 John R. Nash');
writeln('');
Writeln('                          www.SimulatedEvolution.com');
Writeln('');
Writeln('          Based on a program by Michael Palmiter, Temple City, Cal.');
Writeln('    As described in Scientific American, May 1989 (Computer Recreations).');
Writeln('');
Writeln('This program is free software; you can redistribute it and/or modify it under');
Writeln('the terms of the GNU GPL at www.gnu.org and included in the distribution');
Writeln('file: LICENSE.txt');
Writeln('');
Writeln('This program is distributed in the hope that it will be useful, but WITHOUT');
Writeln('ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS');
Writeln('FOR A PARTICULAR PURPOSE. ');
Writeln('');
Writeln('');

TextBackground(0);
TextColor(128+8);
WRITE('                                -PRESS ANY KEY-');
Repeat;
Until Keypressed;

TextBackground(0);
Textcolor(7);
ClrScr;

End;

END.
