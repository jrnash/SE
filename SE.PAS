PROGRAM SE(Input, Output, SimFile, LogFile, EXEfile);

{###############################################################################

                           Simulated Evolution

                       www.SimulatedEvolution.com

This program demonstrates the concept of computer evolution of bugs which move
in any of six directions on a two dimensional grid populated with food. Each
successive generation of bugs inherits slightly mutated genes from their parents
and are in constant competition to stumble across the most efficient movement
pattern for the given environment.

    Copyright (C) 1990-2007  John R. Nash [jrnash@gmail.com]

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

    See file LICENSE.txt for full GNU GPL license.

This program is written in Turbo Pascal 5.5 http://dn.codegear.com/article/20803

###############################################################################}

{$D+}

USES CRT, SE_COM,   SE_MATH,  SE_QUE,   SE_GRAPH,
          SE_BUG,   SE_IO,  SE_ERROR, DOS;

VAR
    Finished    : Boolean;  { Flag set to True if user to end program         }
    xOld	: Word;     { x-coordinate of bug before move                 }
    yOld	: Word;     { y-coordinate of bug before move                 }
    RTP         : RTP_PTR;  { Pointer to record containing ALL runtime Params }
    EXETimeS    : Longint;  { For GetFTime                                    }
    EXETimeL    : DateTime; { For UnpackTime                                  }
    EXEFile     : File;
{-----------------------------------------------------------------------------}
Procedure Process_Timers(VAR Finished        : Boolean;
                             RTP             : RTP_PTR);
VAR tNowS, tElapsedS : Longint;

Begin
With RTP^ Do Begin
   {.......................................................}
   If (BugMoves mod 5) = 0 { Replentish Bacteria every 5th bug move }
      then Begin
         Update_All_Bug_Col(RTP);
         If GardenOn
             Then Populate_Garden(RTP);
         Populate_Screen(FALSE, RTP);
      End;

   {.......................................................}
   If BugMoves > CCYCLE  { Another Generation done  }
      then Begin
         Inc(Cycle_Cntr);
         Display_Value(Cycle_Cntr, 0, RTP);
         Calc_Species(RTP);
         Display_Species(RTP);
         BugMoves := 0;   { Clear Timer              }
      End
      Else Inc(BugMoves);

   {.......................................................}
   If Triggered(Timers[1])  { Update Screen Statistics }
      then Display_Side_Stats(RTP);

   {.......................................................}
   If Keypressed     { Handle Keystrokes If Any }
        then Begin
             Timers[3].LstTriggered := Now;
             Process_Key(Finished, RTP);
        End;
   {.......................................................}
   If (BugMoves mod wGRPHDens) = 0  { Update Graph }
      Then Begin
        If IOMode <= 1       { Graph mode or SSOn }
        Then Begin
           SimStatUG;
           Update_Graph(RTP);
           SimStatR;
        End
        Else Update_Graph_Data(RTP);
      End;
   {.......................................................}
   If Triggered(Timers[3])   { Secure Screen }
      then Begin
      If Not(tHaveKey)
      Then Begin
        If IOMode > 1         { Display Text "Population Graph }
        Then Begin
          IOMode := 1;
          Color_Rectangle(0, wSMAXY+3, VGAMAXX, VGAMAXY, wSBK_COL);
          Display_Desc(RTP);
          Display_Graph(RTP);
        End;
      End
      Else Begin
        If (Password <> '')
        then Begin
           If IOMode > 1         { Display Text "Population Graph }
           Then Begin
             IOMode := 1;
             Color_Rectangle(0, wSMAXY+3, VGAMAXX, VGAMAXY, wSBK_COL);
             Display_Desc(RTP);
             Display_Graph(RTP);
           End;
           If IOMode > 0
           Then Begin
              SSOn(RTP);
              IOMode := 0;
              Timers[2].Interval := 100; { 2 Seconds }
           End;
        End;
      End;
      End;
   {.......................................................}

   If Triggered(Timers[5])   { Update Elapsed Time }
      then Calc_and_Display_Elapsed_Time(RTP);

   {.......................................................}
   If (tLogging) AND Triggered(Timers[4])
      then Write_To_Log(RTP);          { Write to Log file }

   {.......................................................}

   If ((Timers[6].Interval > 0) AND Triggered(Timers[6]))
      then StoreException(RTP,100,1);
      { Exit if Specified Time to Run Exceeded }

   {.......................................................}

   If (Cycle_Cntr > 0) AND (Cycle_Cntr = ExpCycles)
      then StoreException(RTP,100,2);
      { Exit if ExpCycles reached }

   {.......................................................}

End; { With RTP                 }
End; { Procedure Process_Timers }

{#############################################################################
 #############################    M A I N   ##################################
 #############################################################################}
BEGIN { Main }
   RTP := New(RTP_PTR);
   Initialize_All(RTP);
   Randomize;               { Guarentees psuedo random #'s }
   Do_Graphics;
   Display_Intro(RTP);      { Has built in delay or RTP^.IntroTimeout }

   Finished       := False;
   CheckBreak     := True;

   ClearScreen;
   Display_Screen(RTP);
   Display_Graph(RTP);
   Display_Text(RTP);

   If RTP^.tAutoLoad
   Then AutoLoadSim(RTP);

   If (RTP^.tAutoLoad)           { If Successfull Autoload }
   Then Begin
      Calc_Species(RTP);
      Display_Species(RTP);
      Display_Menu(RTP);
   End
   Else Begin                    { If No Autoload (Or Autoload Failure) }
      Display_Menu(RTP);
      Create_StartBugs(RTP);
      Populate_Screen(TRUE, RTP);   { TRUE causes Function to exceed bSLIM }
      Display_Side_Stats(RTP);
      Calc_Species(RTP);
      Display_Species(RTP);
      Clear_Timers(RTP);
   End;
   Update_Graph(RTP);


{------------------ Start of Main Loop -----------------}

While Not(Finished) AND Not(ExceptionExists(RTP)) Do
Begin
  RTP^.Curr_Bug := RTP^.LL;
  RTP^.Fwd_Travrs := RTP^.Fwd_Travrs = FALSE;   { Toggle value of Fwd_Travrs  }
  Point_to_Next(RTP);                           { Point to Next Bug           }
  While Not PastLast(RTP^.Curr_Bug) Do Begin    { Process LL                  }

      Age(RTP^.Curr_Bug);                       { Make Bug one move older     }
      xOld := RTP^.Curr_Bug^.posx;              { Save Bug's current location }
      yOld := RTP^.Curr_Bug^.posy;
      Calc_Move_For(RTP);                       { Use Bug's genes to calculate next move }
      Erase_Previous_Pos(xOld, yOld, RTP);      { Erase Bug from old position }
      Check_For_Food(RTP);                      { Check for food at new location }
      Display_In_New_Pos(RTP);                  { Draw Bug in new location    }
      Check_For_Sex(RTP);                       { Process reproduction if nesc. }

      If (Dead(RTP))
         Then Begin
           If (RTP^.NumofBugs <= RTP^.bMINBUGS)
              Then Begin
                If (RTP^.Cycle_Cntr <= EARLYGENERATIONS)
                   Then Begin
                     New_Genes_for(RTP); { Cause old one's were bad }
                     Point_to_Next(RTP);
                   End
                Else Make_Mature(RTP); { Keep genes and make mature }
              End
              Else Remove_Dead(RTP);
         End
         Else Point_to_Next(RTP);

  End;
  Process_Timers(Finished, RTP);

End;
{------------------- End of Main Loop ------------------}
End_Graphics;
If (ExceptionExists(RTP))
   Then WriteException(RTP)
   Else DisplayCredits;
{Writeln('Simulated Evolution ' + Version);}
Writeln;
{-----------------------------------------------------------------------------}
End. { BUGS }
