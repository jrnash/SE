UNIT SE_MATH;

INTERFACE

{$D+}

USES GRAPH, SE_QUE, SE_COM, SE_ERROR, CRT, DOS;
{-----------------------------------------------------------------------------}
Function Power(b,e : Integer) : Real;   { Returns B to the E power Notsoquick }
Function toY(e : Integer) : Real;       { Returns 2 to the E power (Quick)    }
Procedure Calc_Prob(New_Bug : BUG_PTR); { Calculate Probabilities of movement }
Procedure Calc_Move_for(RTP : RTP_PTR); { Calulate new pos and direction      }
Procedure Initialize_All(RTP : RTP_PTR);{ Set Default values for RTP          }
Procedure Calc_Defaults(RTP : RTP_PTR); { Calc's values for dependent RTP Vars}
Procedure ReCalc_Garden(RTP : RTP_PTR); { Calc's new values for adjusted Gard.}
Procedure Clear_Timers(RTP : RTP_PTR);
Function  Triggered(Var Timer : TIME_RCD) : Boolean;
Function  Now : LongInt;
Procedure Init_Graph_Buff(RTP : RTP_PTR);
Procedure Update_Graph(RTP : RTP_PTR);  { Roll Graph objects to left          }
Procedure Update_Graph_Data(RTP : RTP_PTR);{ Place new value in each Data Cell}
Procedure Display_Graph_Data(RTP : RTP_PTR; Left : Boolean);
                                        { Display each active graph object    }
Procedure Calc_Species(RTP : RTP_PTR);

{-----------------------------------------------------------------------------}
IMPLEMENTATION
{----------------------------------------------------------------------------}
Function Triggered;

VAR Hour, Min, Sec, Sec100 : Word;
    tNow       : Longint;

Begin

  GetTime(Hour, Min, Sec, Sec100);

  tNow    :=   Now;

  If (Timer.LstTriggered > tNow)     { Clock just moved past midnight so  }
  Then Timer.LstTriggered := tNow;   { Everything triggers at midnight    }

  If (tNow - Timer.LstTriggered) > Timer.Interval
  Then Begin
       Triggered := TRUE;
       Timer.LstTriggered := tNow;
  End
  Else Begin
       Triggered := FALSE;
  End;
End;
{-----------------------------------------------------------------------------}
Function Now;

VAR Hour,  Min,  Sec,  Sec100  : Word;
    tLH,   tLM,  tLS,  tLS100  : Longint;

Begin

  GetTime(Hour, Min, Sec, Sec100);

  tLH    := Hour;
  tLH    := tLH * Longint(360000);
  tLM    := Min;
  tLM    := tLM * Longint(6000);
  tLS    := Sec;
  tLS    := tLS * Longint(100);
  tLS100 := Longint(Sec100);

  Now := tLH + tLM + tLS + tLS100;

End;
{-----------------------------------------------------------------------------}
Procedure Clear_Timers;
VAR Array_index : integer;

Begin
  With RTP^ Do Begin
     For Array_index := 1 to NUMOFTIMERS Do
        Timers[Array_Index].LstTriggered := Now;

     tStartS:= Now;
     tStartS:= tStartS div Longint(100);
                           { Time simulation started in sec's past 24:00       }
     wDays       := 0;     { Number of days simulation has been running        }
     tBS         := FALSE; { Indicates if curr time before sim start time      }
     LHr         := 0;     {                                                 }
     LMin        := 0;     { Hour, Min & Second last displayd as elapsed time}
     LSec        := 0;     {                                                 }
  End;
End;
{-----------------------------------------------------------------------------}
Procedure Initialize_All;

Var i,j,k     : Word;    { Array Indicies }
    sCLArg1,
    sCLArg2   : String;  { Command line arg's }

Begin

Clear_Timers(RTP);
Init(RTP^.LL);

With RTP^ Do Begin

    If ParamCount > 0
       then Begin
            sCLArg1 := ParamStr(1);
            If (Pos('.',sCLArg1) < 9) AND (Pos('.',sCLArg1) <> 0)
              Then SimFile := Copy(sCLArg1, 1, Pos('.',sCLArg1)-1)
              Else SimFile := Copy(sCLArg1,1,8);
            tAutoLoad := TRUE;
       End
       Else Begin
            SimFile := 'DEFAULT';
            tAutoLoad := FALSE;
       End;

    If ParamCount > 1
       then Begin
            sCLArg2 := ParamStr(2);
            If (Pos('.',sCLArg2) < 9) AND (Pos('.',sCLArg2) <> 0)
              Then LogFile := Copy(sCLArg2, 1, Pos('.',sCLArg2)-1)
              Else LogFile := Copy(sCLArg2,1,8);
       End
       Else LogFile := 'DEFAULT';

    Curr_Bug    := Nil;   { Temp pointer to current bug                       }
    Bact_on_Screen := 0;  { Counter of the # of bacteria outside Garden       }
    Bact_in_Garden := 0;  { Counter of the # of bacteria inside Garden        }
    BugMoves    := 0;     { Number of Bug moves since last cycle              }
    Cycle_Cntr  := 0;     { Number of Cycles (Generations) so far             }
    NumofBugs   := 0;     { Counter of the number of live bugs on screen      }
    Dead_Bug    := FALSE; { True if current Bug has died                      }
    GardenOn    := TRUE;  { Flag for Garden of Eden  Default = False          }
    tGProtect   := TRUE;  { Flag for protecting Garden from Veritcal Bugs     }
    Fwd_Travrs  := TRUE;  { Flag indicating LL traversel direction            }
    tLogging    := FALSE; { Causes updates to log file per Logging Timer      }
    tSave       := TRUE;  { When FALSE causes SaveAll() to write to TEMP.$$$  }
    InputTimeout:= 15;    { Timeout value for Password entry (in seconds )    }
    IntroTime   := 8;     { Time to display credit screen in seconds          }
    MssgTimeout := 4;     { Timer used to display user messages in seconds )  }
    Password    :='';     { Password string for Screen Saver                  }
    Key         :='key'; { Holds Registration Key Needed to enable Password}
    tHaveKey    := True; { Indicates if Registered                           }
    IOMode      := 1;     { Value indicates mode of IO windows                }
    IOMenu      := 1;     { Value indicates mode of IO menu                   }
    bLogFSize100Kb := 1;  { Max Size of Logging file in 100 Kilo Bytes        }
    rStdDevLim  := 0.75;  { Limit value a bug must pass to be a viable        }
                          { member of a species.                              }
    tStartS:= Now div Longint(100);{Time simulation started in secs past 24:00}
    wDays       := 0;     { Number of days simulation has been running        }
    tBS         := FALSE; { Indicates if curr time before sim start time      }
    LHr         := 0;     {                                                   }
    LMin        := 0;     { Hour, Min & Second last displayd as elapsed time  }
    LSec        := 0;     {                                                   }

    wSMINX := MINX;       { The left   edge of the simulation screen          }
    wSMINY := MINY;       { The top    edge of the simulation screen          }
    wSMAXX := MAXX;       { The right  edge of the simulation screen          }
    wSMAXY := MAXY;       { The bottom edge of the simulation screen          }

    rSDENSITY := 1.20;    { Bacteria density on the Screen = 1.25 %           }
    rGDENSITY := 6.25;    { Bacteria density in the Garden = 6.25 %           }

    bGARDWID  := 70;{ 72    The width of the Garden of Eden (thick bacteria)  }
    bGARDHIG  := 70;{ 72    The hight of the Garden of Eden (thick bacteria)  }

    rSLIMPCT :=0.002;     { The max % of screen of bact to place/call         }
                          { when trying maintain ScreenBact, (0.006 =Aprox 12)}

    rGLIMPCT :=0.174;     { The max % of garden of bact to place/call         }
                          { when trying maintain ScreenBact, (0.174 =Aprox 9) }

    bGGRIDRESx := 4;      { Bacteria X Grid Resolution in Garden              }
    bGGRIDRESy := 4;      { Bacteria Y Grid Resolution in Garden              }
    bSGRIDRESx := 4;      { Bacteria X Grid Resolution on Screen              }
    bSGRIDRESy := 4;      { Bacteria Y Grid Resolution on Screen              }

    wBC_WEAK    := Red;          { Bug Color when weak                        }
    wBC_NORM    := LightGray;    { Bug Color when Normal                      }
    wBC_STR_Y   := LightBlue;    { Bug Color when Strong and Young            }
    wBC_STR_O   := LightMagenta; { Bug when Strong and almost Mature          }
    wBC_Vry_O   := LightCyan;    { Bug when Old but almost of Mature Strength }
    wBACT_COL   := Green;        { Bacteria Color                             }
    wSBK_COL    := Black;        { Background Color of Bug Screen             }
    wGBK_COL    := Black;        { Background Color of Graph Window           }
    wBORDER_COL := Brown;        { Color of border around simulation area     }
    wHILIT_COL  := LightGray;    { Color of highlighted text                  }
    wTEXTF_COL  := DarkGray;     { Forground color for text                   }
    wTEXTB_COL  := Black;        { Backgound color for text                   }

    wMAXBUGS  := 170;     { The maximum number of bugs allowed                }
    bMINBUGS  := 3;       { The minimum number the bug population can drop to }
                          { Must be <= Bact_State_Lo% of MaxBugs!             }
    bBACTERIA := 40;      { Units of energy supplied by eating 1 bacteria     }

    tMAXAGE   := FALSE;   { TRUE activates possible mutation of gene MAXAGE   }
    tMAXSTR   := FALSE;   { TRUE activates possible mutation of gene MAXSTR   }
    tMATURE   := FALSE;   { TRUE activates possible mutation of gene MATURE   }
    tREPROSTR := FALSE;   { TRUE activates possible mutation of gene REPROSTR }
    bMUTRATNG := 42;      { Number of genes mutated during reproduction       }
                          { On a scale of 0-255 (42 being Avg of 1 gene)      }
    bMUTRATMS := 42;      { Avg. Mutation Severity for each gene mutated      }
                          { On a scale of 0-255 (42 being Avg change of 1)    }


    wGRPHDens  := 75;     { # of turns that a pixel on graph represents       }
    wGRPHCurs1 := 0;      { Marker for adding values to Block Curr1           }
    wGRPHCurs2 := 0;      { Marker for displaying values in Block Curr2       }
    wGRPHBlok1 := CGRPHBuff;{ Pointer to Current Graph Block to Add Values    }
    wGRPHBlok2 := CGRPHBuff;{ Pointer to first Graph Block to be displayed    }

    ExpCycles   := 0;     { Specifies Bug Cycles  before AutoExit (0=NoExit)  }

    Timers[1].Interval:= 100;   { Update Statistics on screen                 }
    Timers[2].Interval:= 20;{UNUSED ! Keys are processed this fast until SSon }
    Timers[3].Interval:= 30000; { Timeout for ScreenSaver                     }
    Timers[4].Interval:= 1000;  { Save to Log File if Logging On              }
    Timers[5].Interval:= 100;   { Update Elapsed Time                         }
    Timers[6].Interval:= 0;     { Time to Run before AutoExit (0=NoExit)      }
  {                                                                           }
  { tTimers[7].tInterval:= 0;           Unused        Inc NUM_OF_TIMERS       }
  { tTimers[8].tInterval:= 0;           Unused        in SE_COM.PAS           }
  { tTimers[9].tInterval:= 0;           Unused        when more are used      }
  { tTimers[10].tInterval:=0;           Unused                                }

    wErrorNum1  := 0;        { Clear our current runtime error code 1         }
    wErrorNum2  := 0;        { Clear our current runtime error code 2         }

{    For i := 1 to Length(id_Email_c)
    Do EMail[i]:= Chr((byte(id_Email_c[i]) xor $80));
    EMail[0] := id_EMail_c[0];

    For i := 1 to Length(Name_c)
    Do Name[i]:= Chr((byte(Name_c[i]) xor $80));
    Name[0] := Name_c[0];
}
End; { With RTP               }

Calc_Defaults(RTP);
Init_Graph_Buff(RTP);

End; { Procedure Initialize_All }
{-----------------------------------------------------------------------------}

Procedure ReCalc_Garden;

VAR
   lTemp : LongInt;      { Temp holder for values during calculation          }
   rTemp : Real;         { Temp holder for valued during calculation          }
   rX1, rY1, rA2, rMsc : Real;

BEGIN
With RTP^ Do Begin
  {...........................................................................}
    rTemp      := 0.01 * bGARDWID * bGARDHIG * rGDensity;
    lTemp      := Trunc(rTemp);
    wGBACTMAX := WordRec(lTemp).low;
  { # of bacteria to try and maintain in garden, Last Num = % of total pixels }

  {...........................................................................}
    wGMAXTRYS := Trunc(bGLIM * 1.5);{ Maximum attempts to place bact/trigger  }

  {...........................................................................}
     rX1 := (wSMAXX-wSMINX);
     rY1 := (wSMAXY-wSMINY);
     rA2 := (bGARDHIG * bGARDWID);
     rMsc:= (0.01*rSDensity);
     rTemp := (rX1 * rY1 - rA2) *rMsc;

    lTemp := Trunc(rTemp);
    wSBACTWG := WordRec(lTemp).low;

  { The total # of bacteria to try and maintain on screen with garden enabled }
  { (# of bacteria on Screen (outside Garden) when Garden enabled)            }
  {...........................................................................}

    { Calculate 4 corners of the Garden       }

    lTemp := Trunc((wSMAXX-wSMINX-bGARDWID) / (2 * bSGRIDRESx));
    wGARDNEARX := WordRec(lTemp).low * bSGRIDRESx + wSMINX;

    lTemp := Trunc((wSMAXY-wSMINY-bGARDHIG) / (2 * bSGRIDRESy));
    wGARDNEARY := WordRec(lTemp).low * bSGRIDRESy + wSMINY;

    wGARDFARX  := wGARDNEARX + bGARDWID;
    wGARDFARY  := wGARDNEARY + bGARDHIG;

  End;
End;
{-----------------------------------------------------------------------------}
Procedure Calc_Defaults;

VAR
   lTemp : LongInt;      { Temp holder for values during calculation          }
   rTemp : Real;         { Temp holder for valued during calculation          }
   rX1, rY1, rA2, rMsc : Real;

BEGIN
With RTP^ Do Begin
  {...........................................................................}
    rTemp      := 0.01 * (wSMAXX-wSMINX) * (wSMAXY-wSMINY) * rSDensity;
    lTemp      := Trunc(rTemp);
    wSBACTMAX := WordRec(lTemp).low;
  { # of bacteria to try and maintain on screen, Last Num = % of total pixels }

  {...........................................................................}
    rTemp      := 0.01 * bGARDWID * bGARDHIG * rGDensity;
    lTemp      := Trunc(rTemp);
    wGBACTMAX := WordRec(lTemp).low;
  { # of bacteria to try and maintain in garden, Last Num = % of total pixels }

  {...........................................................................}
    lTemp  := Trunc(rSLIMPCT * 0.01 * (wSMAXX-wSMINX) * (wSMAXY-wSMINY));
    bSLIM := ByteRec(WordRec(lTemp).low).low;
    lTemp  := Trunc(rGLIMPCT * 0.01 * bGardWid * bGardHig);
    bGLIM := ByteRec(WordRec(lTemp).low).low;

    If bSLIM = 0 THEN bSLIM :=1;  { All these values should be at least one   }
    If bGLIM = 0 THEN bGLIM :=1;  { else no bacteria would be place on screen }

  {...........................................................................}
    wGMAXTRYS := Trunc(bGLIM * 1.5);{ Maximum attempts to place bact/trigger  }
    wSMAXTRYS := bSLIM * 1;         { Maximum attempts to place bact/trigger  }

  {...........................................................................}
     rX1 := (wSMAXX-wSMINX);
     rY1 := (wSMAXY-wSMINY);
     rA2 := (bGARDHIG * bGARDWID);
     rMsc:= (0.01*rSDensity);
     rTemp := (rX1 * rY1 - rA2) *rMsc;

    lTemp := Trunc(rTemp);
    wSBACTWG := WordRec(lTemp).low;

  { The total # of bacteria to try and maintain on screen with garden enabled }
  { (# of bacteria on Screen (outside Garden) when Garden enabled)            }
  {...........................................................................}

    { Calculate 4 corners of the Garden       }

    lTemp := Trunc((wSMAXX-wSMINX-bGARDWID) / (2 * bSGRIDRESx));
    wGARDNEARX := WordRec(lTemp).low * bSGRIDRESx + wSMINX;

    lTemp := Trunc((wSMAXY-wSMINY-bGARDHIG) / (2 * bSGRIDRESy));
    wGARDNEARY := WordRec(lTemp).low * bSGRIDRESy + wSMINY;

    wGARDFARX  := wGARDNEARX + bGARDWID;
    wGARDFARY  := wGARDNEARY + bGARDHIG;

  {...........................................................................}
    { Calculate 4 corners of the Graph Window }
                                                {one for border, one for      }
    wGRPHMINX  := VGAMAXX  - (CGRPHWid -1) - 1; {VGAMAXX-CGRPHWid inclusive   }
    wGRPHMAXX  := VGAMAXX  - 1;
    wGRPHMINY  := SPCSIDSTART + 62;
    wGRPHMAXY  := VGAMAXY - 38;

  {...........................................................................}
End; { With RTP }

END;

{-----------------------------------------------------------------------------}
Procedure Init_Graph_Buff(RTP : RTP_PTR);

Var i,j,k : Word;  { Array Indicies }
    Temp : GRPH_BLOCK_PTR;
    lTemp : LongInt;      { Temp holder for values during calculation          }
    rTemp : Real;         { Temp holder for valued during calculation          }
    rX1, rY1, rA2, rMsc : Real;

Begin
  With RTP^ Do
  FOR i := 1 to CGRPHObjs Do Begin
    GRPHMatrix[i].DataPtr := New(GRPH_BLOCK_PTR);
    Temp := RTP^.GRPHMatrix[i].DataPtr;
    FOR k := 1 to CGRPHWid Do
      Temp^.Value[k] := 0;
    Temp^.Next := Nil;
    Temp^.Prev := Nil;
    FOR j := 1 to CGRPHBuff Do Begin
      Temp^.Next := New(GRPH_BLOCK_PTR);
      Temp^.Next^.Next := Nil;
      Temp^.Next^.Prev := Temp;
      Temp := Temp^.Next;
      FOR k := 1 to CGRPHWid Do
        Temp^.Value[k] := 0;
    End; { FOR j }
  End; { FOR i }

  With RTP^ Do Begin
    GRPHMatrix[1].Color  := wBACT_COL;
  {...........................................................................}
     rTemp      := 0.01 * CGARDWIDMax * CGARDHIGMax * rGDensity;
     lTemp      := Trunc(rTemp);
     wGBACTMAX := WordRec(lTemp).low;

     rX1 := (wSMAXX-wSMINX);
     rY1 := (wSMAXY-wSMINY);
     rA2 := (CGARDHIGMax * CGARDWIDMax);
     rMsc:= (0.01*rSDensity);
     rTemp := (rX1 * rY1 - rA2) *rMsc;

    lTemp := Trunc(rTemp);
    wSBACTWG := WordRec(lTemp).low;

  { The Maximum possible # of bacteria to try and maintain on screen with }
  { garden enabled and Maxed out                                          }
  {...........................................................................}
    GRPHMatrix[1].Max    := wSBACTMAX + wGBACTMAX;
    GRPHMatrix[1].Active := True;

    GRPHMatrix[2].Color  := wBC_NORM;
    GRPHMatrix[2].Max    := wMAXBUGS;
    GRPHMatrix[2].Active := True;

{   GRPHMatrix[3].Color  := Blue;
    GRPHMatrix[3].Max    := wGBACTMAX;
    GRPHMatrix[3].Active := False;
}
  End; { With }
End; { Procedure Init_Graph_Buff }

{-----------------------------------------------------------------------------}
Procedure Update_Graph;
Begin
     Update_Graph_Data(RTP);
     Display_Graph_Data(RTP,TRUE); { TRUE meaning move graph to left }
End; { Procedure Update_Graph }

{-----------------------------------------------------------------------------}
Procedure Display_Graph_Data;

VAR AbsValue  : Word;    { Absolute Value calculated for display                       }
    RelValue  : Word;    { Relative Value calculated for display                       }
    i,j       : Integer; { Array indexes/loop indicies                        }
    TempCurs  : Word;    { Temporary cursor for indexing graph values         }
    Adjacent  : Integer; { Value of 1/(-1) reflecting movement right/left     }
    OffsetX   : Word;    { # of Pels offset from right of graph to display    }
    AdjacentCell : Boolean; { FALSE: No Adjacent block, last pass through loop}
    UseNextBlock : Boolean; { TRUE: cell in next block used to calc Value     }

Begin
   With RTP^ Do Begin
   If Left
      Then Adjacent := -1
      Else Adjacent := 1;
   With RTP^.GRPHMatrix[1] Do CurrPtr := DataPtr;  { Point to first block in first Obj }
   For j := 1 to RTP^.wGRPHBlok2 Do                { Point to block to display         }
       RTP^.GRPHMatrix[1].CurrPtr := RTP^.GRPHMatrix[1].CurrPtr^.Next; 
   TempCurs := RTP^.wGRPHCurs2;                    { Point to value to disp 1st        }

   For i := 1 to CGRPHObjs Do Begin             { Loop through each graph obj }
      GRPHMatrix[i].CurrPtr := GRPHMatrix[i].DataPtr;  { Point to first block in Obj }
      For j := 1 to RTP^.wGRPHBlok2 Do
         GRPHMatrix[i].CurrPtr := GRPHMatrix[i].CurrPtr^.Next;   { Point to block to display}
   End;
   {////////////////////// START MAIN LOOP ////////////////////// }
   For OffsetX := 0 to CGRPHWid-1 Do Begin         { Display each cell of Graph Object }
   
     UseNextBlock := FALSE; { WE WILL BEGIN WITH OPTOMISIM }
     AdjacentCell := TRUE;  { WE WILL BEGIN WITH OPTOMISIM }

     {IF GRAPH MOVING LEFT AND AT LOW END THEN END OR USE NEXT BLOCK IF THERE }
     If Left AND (TempCurs = 1)
        Then If GRPHMatrix[1].CurrPtr^.Next = Nil
                Then AdjacentCell := FALSE         { Last time through loop }
                Else UseNextBlock := TRUE;

     {IF GRAPH MOVING RIGHT AND AT HI END THEN USE NEXT BLOCK }
     If Not(Left) AND (TempCurs = CGRPHWid)
        Then UseNextBlock := TRUE;

{    If     (Not(Left)
        AND (TempCurs = CGRPHWid)
        AND    ((GRPHMatrix[1].CurrPtr^.Prev = Nil)
            OR (GRPHMatrix[1].CurrPtr^.Prev^.Value[CGRPHWid] = 0)))
        Then AdjacentCell := FALSE
        Else UseNextBlock := TRUE;
}
     For i := 1 to CGRPHObjs Do Begin           { Loop through each graph obj }
       If GRPHMatrix[i].Active
          Then Begin
             If AdjacentCell
                Then Begin
                  If NOT(UseNextBlock) { THEN USE ADJACENT CELL TO CALC VALUE }
                     Then RelValue := GRPHMatrix[i].CurrPtr^.Value[TempCurs+Adjacent]
                     Else If Left      { THEN USE CELL IN NEXT BLOCK }
                        Then RelValue := GRPHMatrix[i].CurrPtr^.Next^.Value[CGRPHWid]
                        Else RelValue := GRPHMatrix[i].CurrPtr^.Prev^.Value[1];

                  { USE ADJACENT CELL TO CALCULATE VALUE FOR ERASURE OF POINT }
                  AbsValue := Trunc(wGRPHMaxY-(RelValue/GRPHMatrix[i].Max)
                               *(wGRPHMaxY-wGRPHMinY));

                  { USE VALUE TO ERASE POINT FROM CURRENT COLUMN }
                  PutPixel(wGRPHMaxX-OffsetX,AbsValue,wGBK_COL);
                End;

             { USE CURRENT CELL TO CALCULATE VALUE TO DISPLAY POINT }
             AbsValue := Trunc(wGRPHMaxY-
                      (GRPHMatrix[i].CurrPtr^.Value[TempCurs]/GRPHMatrix[i].Max)
                      *(wGRPHMaxY-wGRPHMinY));

             If GRPHMatrix[i].CurrPtr^.Value[TempCurs] < 3
                Then Delay(1);

             { USE VALUE TO PLOT POINT IN CURRENT COLUMN }
             PutPixel(wGRPHMaxX-OffsetX,AbsValue,GRPHMatrix[i].Color);
          End; { If Active }
     End; { CGRPHObjs }
     Dec(TempCurs);
     If TempCurs = 0
        Then If GRPHMatrix[i].CurrPtr^.Next = Nil
           Then OffsetX := CGRPHWid-1 {End Loop, GRPH not full }
           Else BEGIN
                  TempCurs := CGRPHWid;
                  For i := 1 to CGRPHObjs Do
                    GRPHMatrix[i].CurrPtr := GRPHMatrix[i].CurrPtr^.Next;
           END; { Else }
   End; { For OffsetX }
   {////////////////////// END MAIN LOOP ////////////////////// }
   End; { With RTP }
End; { Procedure Display_Graph_Data }
{-----------------------------------------------------------------------------}
Procedure FirstBlocktoLast(VAR StartPtr : GRPH_BLOCK_PTR);  { Internal }

VAR TempPtr : GRPH_BLOCK_PTR;

Begin
  TempPtr := StartPtr;

  While TempPtr^.Next <> Nil Do
        TempPtr := TempPtr^.Next;  { TempPtr now pointing to 1st Disp Block   }
  StartPtr^.Prev := TempPtr;       { Old list head has new list head as prev  }
  TempPtr^.Next := StartPtr;       { New list head has old list head as next  }
  TempPtr^.Prev^.Next := Nil;      { New list end has NIL as next             }
  TempPtr^.Prev := Nil;            { New list head has no previous block      }
  StartPtr := TempPtr;             { Make list ptr point to new list head     }
End;

{-----------------------------------------------------------------------------}
Procedure Update_Graph_Data;   { For each Data Cell Inc Curs, place new value }

Var i : Word;  { Array Indicies }
    Temp1 : GRPH_BLOCK_PTR;

Begin
  With RTP^ Do Begin
  If (wGRPHCurs1 = CGRPHWID)
  Then If (wGRPHBlok1 = 1)
       Then Begin
         { Place code to Write First block of each graph object to disk here  }
         For i := 1 to CGRPHObjs Do
            FirstBlocktoLast(GRPHMatrix[i].DataPtr);
         wGRPHCurs1 := 1;
         wGRPHCurs2 := 1;
       End
       Else Begin  { At last cursor position but not last block }
         Dec(wGRPHBlok1);   { Make next block active upadate block }
         Dec(wGRPHBlok2);   { Make next block active display block }
         wGRPHCurs1 := 1;   { Place block cursor at front }
         wGRPHCurs2 := 1;   { Place block cursor at front }
       End
  Else Begin   { Not at last cursor position }
       Inc(wGRPHCurs1);
       Inc(wGRPHCurs2);
  End; { Else Begin }

  Temp1 := GRPHMatrix[1].DataPtr;          { Store Bacteria Population        }
  For i := 1 to wGRPHBlok1 Do
      Temp1 := Temp1^.Next;                { Temp now at block to update      }
  Temp1^.Value[wGRPHCurs1] :=  Bact_on_Screen;

  Temp1 := GRPHMatrix[2].DataPtr;          { Store Bug population             }
  For i := 1 to wGRPHBlok1 Do
      Temp1 := Temp1^.Next;                { Temp now at block to update      }
  Temp1^.Value[wGRPHCurs1] :=  NumofBugs;

{  Temp1 := GRPHMatrix[3].DataPtr;           Store Cursor Position
  For i := 1 to wGRPHBlok1 Do
      Temp1 := Temp1^.Next;                  Temp now at block to update
  Temp1^.Value[wGRPHCurs1] :=  Bact_in_Garden;
}
  End; { With }
End; { Procedure Update_Graph_Data}
{-----------------------------------------------------------------------------}
Function Power(b,e : Integer) : Real;
VAR neg    : Boolean;
    index  : integer;
    answer : real;
Begin
     answer := 1;
     neg := False;
     If e <> 0
        Then Begin
             If e < 0
                then Begin
                   neg := True;
                   e := (- e);
                End;
             For index := 1 to e Do
                   answer := answer * b;
             If neg
                then answer := 1/answer;
        End;
     Power := answer;
End; { Power }
{-----------------------------------------------------------------------------}
Function toY(e : Integer) : Real;
VAR neg    : Boolean;
    answer : real;
Begin
     answer := 1;
     If e = 0
        then
        else Begin
             If e < 0
                then Begin
                   neg := True;
                   e := (- e);
                End;
                answer := 1 shl e;
                If neg
                   then answer := 1/answer;
             End;
     toY := answer;
End;
{-----------------------------------------------------------------------------}
Procedure Calc_Species;

VAR Currmean : Integer;   { Used to hold value of mean being searched for     }

Begin
  FOR Currmean:=0 to NUMOFGENES DO Begin
      RTP^.SpeciesID[Currmean].Stddev := 0.0;
      RTP^.SpeciesID[Currmean].Pop := 0;
  END;

  RTP^.Avg.MaxAge   := 0;
  RTP^.Avg.MaxStr   := 0;
  RTP^.Avg.Mature   := 0;
  RTP^.Avg.ReproStr := 0;

  RTP^.Curr_Bug := RTP^.LL;
  RTP^.Fwd_Travrs := TRUE;
  Point_to_Next(RTP);
  Currmean := 0;
  While Not PastLast(RTP^.Curr_Bug) Do Begin    { Process LL }
        IF RTP^.Curr_Bug^.mean < (Currmean + 0.5)
           THEN BEGIN
                {IF bugs stddev is tighter than limit count as species member }
                IF (RTP^.Curr_Bug^.stddev < RTP^.rStdDevLim)
                   THEN BEGIN
                       RTP^.SpeciesID[Currmean].Stddev :=
                           RTP^.SpeciesID[Currmean].Stddev
                         + RTP^.Curr_Bug^.stddev;
                       Inc(RTP^.SpeciesID[Currmean].Pop);
                    END;
                { Regardless of whether it's counted, point to next bug       }

                RTP^.Avg.MaxAge   := RTP^.Avg.MaxAge +
                                     RTP^.Curr_Bug^.MaxAge;
                RTP^.Avg.MaxStr   := RTP^.Avg.MaxStr +
                                     RTP^.Curr_Bug^.MaxStr;
                RTP^.Avg.Mature   := RTP^.Avg.Mature +
                                     RTP^.Curr_Bug^.Mature;
                RTP^.Avg.ReproStr := RTP^.Avg.ReproStr +
                                     RTP^.Curr_Bug^.ReproStr;

                Point_to_Next(RTP);
           END
           ELSE Inc(Currmean);
  END; { While }

  RTP^.Avg.MaxAge   := RTP^.Avg.MaxAge div RTP^.NumofBugs;
  RTP^.Avg.MaxStr   := RTP^.Avg.MaxStr div RTP^.NumofBugs;
  RTP^.Avg.Mature   := RTP^.Avg.Mature div RTP^.NumofBugs;
  RTP^.Avg.ReproStr := RTP^.Avg.ReproStr div RTP^.NumofBugs;

  FOR Currmean:=0 to NUMOFGENES DO Begin
      IF RTP^.SpeciesID[Currmean].Pop > 0
         THEN RTP^.SpeciesID[Currmean].Stddev :=
                 RTP^.SpeciesID[Currmean].Stddev/
                 RTP^.SpeciesID[Currmean].Pop
         ELSE RTP^.SpeciesID[Currmean].Stddev := 0.0;
    { A species with 0 pop is not displayed so stddev is irrelevnet }
  END;

END; { Procedure Calc_Species }
{-----------------------------------------------------------------------------}
Procedure Calc_Prob; { Calculate Probabilities of movement }

VAR SumOfPowers : Real;
   temp : ARRAY[0..NUMOFGENES] of real;

BEGIN
   With New_Bug^ Do Begin

{ All movement probability variables will represent a unique threshold   }
{ between 0.0 and 1.0.  These thresholds are used in Procedure           }
{ Calc_move_for(Curr_Bug) to determine any change in direction.          }

      SumOfPowers := (power(2,gene[0])  +power(2,gene[1])
                     +power(2,gene[2])  +power(2,gene[3])
                     +power(2,gene[4])  +power(2,gene[5]));

      temp[0] := power(2,gene[0]) /SumOfPowers;
      temp[1] := power(2,gene[1]) /SumOfPowers;
      temp[2] := power(2,gene[2]) /SumOfPowers;
      temp[3] := power(2,gene[3]) /SumOfPowers;
      temp[4] := power(2,gene[4]) /SumOfPowers;
      temp[5] := power(2,gene[5]) /SumOfPowers;

      prob[0] := temp[0];
      prob[1] := temp[1] + prob[0];
      prob[2] := temp[2] + prob[1];
      prob[3] := temp[3] + prob[2];
      prob[4] := temp[4] + prob[3];
      prob[5] := 1;

{ 2nd part of procedure calculates mean of movement probabilities to     }
{ give an average number for bugs direction.  This value along with Std- }
{ Deviation is used to identify species.                                 }

{ Strangely enough, the number of samples is 1.0 since we are dealing    }
{ with probabilities who's sum is always 1.0.  Note that gene[0] is      }
{ represented by it's absence. }

      mean :=  (temp[1] * 1
               +temp[2] * 2
               +temp[3] * 3
               +temp[4] * 4
               +temp[5] * 5);

{ Since the calculation for Standard Deviation cannot have a sample size }
{ of 1 we must multiply each sample by a number > 1, in this case 100, in}
{ order to simulate a sample size greater than 1.  Note: the higher the  }
{ sample size the greater number of floating point calculations required.}

      stddev := sqrt(((temp[0] * 100 * sqr(0-mean))
                     +(temp[1] * 100 * sqr(1-mean))
                     +(temp[2] * 100 * sqr(2-mean))
                     +(temp[3] * 100 * sqr(3-mean))
                     +(temp[4] * 100 * sqr(4-mean))
                     +(temp[5] * 100 * sqr(5-mean)))/99);
   END;
END;
{-----------------------------------------------------------------------------}
Procedure Calc_Move_for;

VAR Rnd_Dir : Real;

Begin
     Rnd_Dir := Random;
     With RTP^.Curr_Bug^ Do Begin
        If Rnd_Dir < prob[0]
           then Dir := Dir                           { No change in direction }
           else If Rnd_Dir < prob[1]
              then Dir := (Dir + 1) mod 6            { Turn right             }
              else If Rnd_Dir < prob[2]
                 then Dir := (Dir + 2) mod 6         { Turn hard right        }
                 else If Rnd_Dir < prob[3]
                    then Dir := (Dir + 3) mod 6      { Turn around (reverse)  }
                    else If Rnd_Dir < prob[4]
                       then Dir := (Dir + 4) mod 6   { Turn hard left         }
                       else Dir := (Dir + 5) mod 6;  { Turn left              }

      { Change bugs X/Y coordinates according to direction of movement }

        If Dir = 0 then
           posy := posy - 2;
        If Dir = 1 then Begin
           posy := posy - 1;
           posx := posx + 2;
        End;
        If Dir = 2 then Begin
           posy := posy + 1;
           posx := posx + 2;
        End;
        If Dir = 3 then
           posy := posy + 2;
        If Dir = 4 then Begin
           posy := posy + 1;
           posx := posx - 2;
        End;
        If Dir = 5 then Begin
           posy := posy - 1;
           posx := posx - 2;
        End;

      { If a bug has moved past edge of screen boundry then place bug }
      { on other side of screen                                       }

        If posx > (RTP^.wSMaxX-2) THEN
                          posx := RTP^.wSMinX + 2;

        If posy > (RTP^.wSMaxY-2) THEN BEGIN
                          posy := RTP^.wSMinY + 2;

                          { If bug is moving verticaly in the path of }
                          { the garden and if garden is on then turn  }
        If RTP^.tGProtect
        Then if (((Dir = 0) OR (Dir = 3))
             AND (posx > RTP^.wGARDNEARx)
             AND (posx < RTP^.wGARDFARx)
             AND (RTP^.GardenOn))
                THEN Dir := (Dir + 1) mod 6
                     END;

        If posx < (RTP^.wSMinX+2) THEN
                          posx := RTP^.wSMaxX - 2;

        If posy < (RTP^.wSMinY+2) THEN BEGIN
                          posy := RTP^.wSMaxY - 2;

        { If bug is moving verticaly in the path of }
        { the garden and if garden is on then turn  }
        If RTP^.tGProtect
        Then if (((Dir = 0) OR (Dir = 3))
             AND (posx > RTP^.wGARDNEARx)
             AND (posx < RTP^.wGARDFARx)
             AND (RTP^.GardenOn))
                THEN Dir := (Dir + 1) mod 6;
                                       END;

     End;
End;
{-----------------------------------------------------------------------------}
END. { UNIT MATH_BUG }
