UNIT SE_BUG;

INTERFACE

USES SE_GRAPH, SE_MATH, SE_QUE, SE_COM, SE_ERROR;

{-----------------------------------------------------------------------------}
Procedure Create_StartBugs(RTP : RTP_PTR);
Procedure New_Genes_for(RTP : RTP_PTR);
Procedure Make_Mature(RTP : RTP_PTR);
Procedure Check_For_Sex(RTP : RTP_PTR);
Function  Dead(RTP : RTP_PTR) : Boolean;
Procedure Remove_Dead(RTP : RTP_PTR);
Procedure Age(Curr_Bug : BUG_PTR);

IMPLEMENTATION
{----------------------------------------------------------------------------}
Function Create_BUG(RTP : RTP_PTR) : BUG_PTR;          { Internal }

VAR New_Bug : BUG_PTR;
    i       : Word;
    WordTemp: Word;

BEGIN
   New(New_Bug);
   With New_Bug^ Do
   Begin
       age := Random(50)+1;
       str := Random(200) + 350;
       dir := Random(6);
       posx := Random(RTP^.wSMaxX-RTP^.wSMinX-1) + RTP^.wSMinX;
       posy := Random(RTP^.wSMaxY-RTP^.wSMinY-1) + RTP^.wSMinY;
       Colr := RTP^.wBC_Norm;
       MaxAge   := CMAXAGE;
       MaxStr   := CMAXSTR;
       Mature   := CMATURE;
       ReproStr := CREPROSTR;
       For i := 0 to NUMOFGENES Do
           Begin
                WordTemp := (Random(5) - 2);
                gene[i]  := ShortIntRec(WordTemp).low;
           End;
   End;
   Calc_Prob(New_Bug);
   Create_Bug := New_Bug;

END;
{-----------------------------------------------------------------------------}
Procedure New_Genes_for;

VAR  i : Word;
     WordTemp: Word;

Begin
   With RTP^.Curr_Bug^ Do     { direction and X/Y coordinates are unchanged }
   Begin
       age := Random(50)+1;
       str := Random(200) + 350;
       Colr := RTP^.wBC_Norm;
       For i := 0 to NUMOFGENES Do
           Begin
                WordTemp := (Random(5) - 2);
                gene[i]  := ShortIntRec(WordTemp).low;
           End;
   End;
   Calc_Prob(RTP^.Curr_Bug);
End; { New_Genes_for }

{-----------------------------------------------------------------------------}
Procedure Make_Mature;

Begin
     With RTP^.Curr_Bug^ Do Age := Mature;
End;

{-----------------------------------------------------------------------------}
Procedure Create_StartBugs;

{ Create 10 bugs at the start of the program (Ancestors of all other bugs)  }

VAR index   : Integer; { counter }
    New_Bug : BUG_PTR;

BEGIN
     For index := 1 to STARTBUGS Do Begin
         New_Bug := Create_BUG(RTP);
         Ins(New_Bug, RTP);
         Display_All_of(New_Bug);
     End;
END;
{-----------------------------------------------------------------------------}
Procedure Mutate(Bug : BUG_PTR;          { Internal }
                 RTP : RTP_PTR);

{ This function mutates the genes and/or attributes of a new bug.  It uses}
{ RTP^.bMUTRATNG to determine the number of genes and/or attributes to    }
{ mutate.  RTP^.bMUTRATNG holds a number from 0-255 and is used to        }
{ generate a number from 0 - 5.  The value RTP^.bMUTRATMS holds a number  }
{ from 0 - 255 also and is used to determine the mutation severity of the }
{ genes and/or attributes choosen for mutation.  The range a gene may be  }
{ mutated is from 0 - 5.                                                  }

Var Gene      : Integer; { Which gene to effect? }
    GeneError : Integer; { Set to a non-negative number if a gene exceeds }
                         { either GENEMAX or GENEMIN Limits               }
    loop1     : Integer; { Loop index                                     }
    loop2     : Integer; { Loop index                                     }
    i         : Integer; { Array index                                    }
    Mutated   : Boolean; { Indicator if gene successfuly mutated          }
    GeneCount : Integer; { Number of Genes and/or attributes to mutate    }
    GeneChange: Integer; { Mutation change in a Gene and/or attribute     }

Begin
   GeneError := -1; { No Error }

 { Following six lines sum four random numbers from 1 to RTP^.bMUTRATNG,  }
 { divide the sum by 42.666... (256/6 = 42.666...) and again by 1/2 the   }
 { number of random numbers being summed.  If result is greater           }
 { than 5 it is reduced to 5.                                             }

   GeneCount := 0;
   For loop1 := 1 to 4 Do
       Inc(GeneCount,Random(RTP^.bMUTRATNG));
   { Note: the last number in the following line must be the loop count   }
   { above multiplied by 42.666... truncated to an integer. The more      }
   { loops then the tighter bell curve and the smaller the deviation.     }
   GeneCount := Trunc(GeneCount/85);
   If GeneCount > 5 THEN GeneCount := 5;

   For loop1:= 0 to GeneCount Do
   Begin
     mutated := false;
     While Not(mutated) Do
       With Bug^ Do
         Begin
           i := Random(20);
           If i < 6
             Then Begin                   { Range of i is 0 - 5 }
               GeneChange := 0;
               For loop2 := 1 to 4 Do
                   Inc(GeneChange,Random(RTP^.bMUTRATMS));
               GeneChange := Trunc(GeneChange/85);
               If GeneChange > 5 THEN GeneChange := 5;
               Inc(gene[i],GeneChange);
               Mutated := True;
               If gene[i] > GENEMAX
                  Then GeneError := i;
             End;
           If (5 < i) AND (i < 12)
             Then Begin
               Dec(i,6);                  { Range i was 6-11, now 0 - 5 }
               GeneChange := 0;
               For loop2 := 1 to 4 Do
                   Inc(GeneChange,Random(RTP^.bMUTRATMS));
               GeneChange := Trunc(GeneChange/85);
               If GeneChange > 5 THEN GeneChange := 5;
               Dec(gene[i],GeneChange);
               Mutated := True;
               If gene[i] < GENEMIN
                  Then GeneError := i;
             End;
           If i = 12
             Then If RTP^.tMAXAGE
                    Then Begin
                       GeneChange := 0;
                       For loop2 := 1 to 4 Do
                           Inc(GeneChange,Random(RTP^.bMUTRATMS));
                       GeneChange := Trunc(GeneChange/85);
                       If GeneChange > 5 THEN GeneChange := 5;
                       Inc(MaxAge,GeneChange);
                       Mutated := True;
                       If MaxAge > MAXAGELIMP
                          Then MaxAge := MAXAGELIMP;
                    End;
           If i = 13
             Then If RTP^.tMAXSTR
                    Then Begin
                       GeneChange := 0;
                       For loop2 := 1 to 4 Do
                           Inc(GeneChange,Random(RTP^.bMUTRATMS));
                       GeneChange := Trunc(GeneChange/85);
                       If GeneChange > 5 THEN GeneChange := 5;
                       Inc(MaxStr,GeneChange);
                       Mutated := True;
                       If MaxStr > MAXSTRLIMP
                          Then MaxStr := MAXSTRLIMP;
                    End;
           If i = 14
             Then If RTP^.tMATURE
                    Then Begin
                       GeneChange := 0;
                       For loop2 := 1 to 4 Do
                           Inc(GeneChange,Random(RTP^.bMUTRATMS));
                       GeneChange := Trunc(GeneChange/85);
                       If GeneChange > 5 THEN GeneChange := 5;
                       Inc(Mature,GeneChange);
                       Mutated := True;
                       If Mature > MATURELIMP
                          Then Mature := MATURELIMP;
                    End;
           If i = 15
             Then If RTP^.tREPROSTR
                    Then Begin
                       GeneChange := 0;
                       For loop2 := 1 to 4 Do
                           Inc(GeneChange,Random(RTP^.bMUTRATMS));
                       GeneChange := Trunc(GeneChange/85);
                       If GeneChange > 5 THEN GeneChange := 5;
                       Inc(ReproStr,GeneChange);
                       Mutated := True;
                       If ReproStr > REPROSTRLIMP
                          Then ReproStr := REPROSTRLIMP;
                    End;
           If i = 16
             Then If RTP^.tMAXAGE
                    Then Begin
                       GeneChange := 0;
                       For loop2 := 1 to 4 Do
                           Inc(GeneChange,Random(RTP^.bMUTRATMS));
                       GeneChange := Trunc(GeneChange/85);
                       If GeneChange > 5 THEN GeneChange := 5;
                       Dec(MaxAge,GeneChange);
                       Mutated := True;
                       If MaxAge < MAXAGELIMN
                          Then MaxAge := MAXAGELIMN;
                    End;
           If i = 17
             Then If RTP^.tMAXSTR
                    Then Begin
                       GeneChange := 0;
                       For loop2 := 1 to 4 Do
                           Inc(GeneChange,Random(RTP^.bMUTRATMS));
                       GeneChange := Trunc(GeneChange/85);
                       If GeneChange > 5 THEN GeneChange := 5;
                       Dec(MaxStr,GeneChange);
                       Mutated := True;
                       If MaxStr < MAXSTRLIMN
                          Then MaxStr := MAXSTRLIMN;
                    End;
           If i = 18
             Then If RTP^.tMATURE
                    Then Begin
                       GeneChange := 0;
                       For loop2 := 1 to 4 Do
                           Inc(GeneChange,Random(RTP^.bMUTRATMS));
                       GeneChange := Trunc(GeneChange/85);
                       If GeneChange > 5 THEN GeneChange := 5;
                       Dec(Mature,GeneChange);
                       Mutated := True;
                       If Mature < MATURELIMN
                          Then Mature := MATURELIMN;
                    End;
           If i = 19
             Then If RTP^.tREPROSTR
                    Then Begin
                       GeneChange := 0;
                       For loop2 := 1 to 4 Do
                           Inc(GeneChange,Random(RTP^.bMUTRATMS));
                       GeneChange := Trunc(GeneChange/85);
                       If GeneChange > 5 THEN GeneChange := 5;
                       Dec(ReproStr,GeneChange);
                       Mutated := True;
                       If ReproStr < REPROSTRLIMN
                          Then ReproStr := REPROSTRLIMN;
                    End;
         End; { With Bug Do }
   End;       { For loop Do }

   If GeneError >= 0
     Then If Bug^.gene[GeneError] > 0
         THEN Bug^.gene[GeneError] := GENEMAX
         ELSE Bug^.gene[GeneError] := GENEMIN;
End;

{-----------------------------------------------------------------------------}
Function Child_Bug(RTP : RTP_PTR) : BUG_PTR;     { Internal }

Var Gene      : Integer; { Which gene to effect? }
    GeneError : Integer; { Set to a non-negative number if a gene exceeds }
                         { either GENEMAX or GENEMIN Limits               }
    New_Bug   : BUG_PTR;
    loop      : Integer; { Loop index                                     }
    i         : Integer; { Array index                                    }
    mutated   : Boolean; { Indicator if gene successfuly mutated          }

BEGIN
With RTP^ Do Begin
   New(New_Bug);
   New_Bug^.age := Random(50)+1;
   Curr_Bug^.age :=Random(50)+1;
   New_Bug^.str := Trunc(Curr_Bug^.str/2);
   Curr_Bug^.str := New_Bug^.str;
   New_Bug^.dir := Random(6);
   New_Bug^.posx := Curr_Bug^.posx;
   New_Bug^.posy := Curr_Bug^.posy;
   New_Bug^.Colr := RTP^.wBC_Norm;
   Curr_Bug^.Colr := RTP^.wBC_Norm;
   New_Bug^.MaxAge   := Curr_Bug^.MaxAge;
   New_Bug^.MaxStr   := Curr_Bug^.MaxStr;
   New_Bug^.Mature   := Curr_Bug^.Mature;
   New_Bug^.ReproStr := Curr_Bug^.ReproStr;
   For i := 0 to NUMOFGENES Do
       New_Bug^.gene[i] := Curr_Bug^.gene[i];
   Child_Bug  := New_Bug;

   Mutate(New_Bug, RTP);
   Mutate(Curr_Bug,RTP);

   Calc_Prob(New_Bug);
   Calc_Prob(RTP^.Curr_Bug);

End; { With }
END; { Child Bug }
{-----------------------------------------------------------------------------}
Procedure Check_For_Sex;

VAR New_Bug : BUG_PTR;

Begin
If RTP^.Curr_Bug^.Age >= RTP^.Curr_Bug^.Mature
   then If RTP^.Curr_Bug^.Str >= RTP^.Curr_Bug^.ReproStr
      then Begin
              New_Bug := Child_Bug(RTP);
              If (RTP^.NumofBugs < RTP^.wMaxBugs)
                 then Ins(New_Bug, RTP)
                 else Dispose(New_Bug);
           End;
End; { CheckforSex }
{-----------------------------------------------------------------------------}
Function Dead;

Begin
     With RTP^.Curr_Bug^ Do
     If (Str = 0) or (Age = MaxAge)
          Then DEAD := True
          Else DEAD := False;
End; { Dead }
{-----------------------------------------------------------------------------}
Procedure Remove_Dead;

VAR Dead_Bug : BUG_PTR;

Begin
     Dead_Bug := RTP^.Curr_Bug;
     Point_to_Next(RTP);
     Erase_All_Of(Dead_Bug^.posx, Dead_Bug^.posy, RTP);
     Del_From_List(Dead_Bug,RTP);
End; { Remove_Dead }
{-----------------------------------------------------------------------------}
Procedure Age(Curr_Bug : BUG_PTR);
Begin
     Inc(Curr_Bug^.Age);
     Dec(Curr_Bug^.Str);
End;
{-----------------------------------------------------------------------------}
End. { SE_BUGS }
