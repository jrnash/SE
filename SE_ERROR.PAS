UNIT SE_ERROR;

INTERFACE

USES SE_COM, CRT;
{-----------------------------------------------------------------------------}
Procedure StoreException(RTP       : RTP_PTR;
                            Error1 : Word;
                            Error2 : Word);

Procedure WriteException(RTP : RTP_PTR);

Function ExceptionExists(RTP : RTP_PTR) : Boolean;


IMPLEMENTATION
{----------------------------------------------------------------------------}
Procedure StoreException;
Begin
   RTP^.wErrorNum1 := Error1;
   RTP^.wErrorNum2 := Error2;
End; { StoreError }

{----------------------------------------------------------------------------}
Procedure WriteException;
Begin
   If RTP^.wErrorNum1 <> 0
      Then Begin
         Writeln('EXCEPTION OCCURED DURRING EXECUTION OF SE.EXE!');
         Writeln;
         Case RTP^.wErrorNum1 of
            1: Begin
                    Writeln('Insufficient memory avaliable.');
                    Writeln('Try Freeing more DOS conventional memory.');
                    Writeln('CRC Execption Code : ',RTP^.wErrorNum2);
            End;
            2: Begin
                    Writeln('Num of Bugs fell below minimum.');
                    Writeln('Contact original author for replacement.');
                    Writeln('CRC Execption Code : ',RTP^.wErrorNum2);
            End;
            3: Begin
                    Writeln('Quality of this executable has been compromised.');
                    Writeln('Contact original author for replacement.');
                    Writeln('CRC Execption Code : ',RTP^.wErrorNum2);
            End;
           100: Begin
                    Writeln('Termination condition matched.');
                    Writeln('Execution stopped because of user specified conditional.');
                    If RTP^.wErrorNum2 = 1
                    Then Writeln('Termination Value (Time)  : ',RTP^.Timers[6].Interval)
                    Else Writeln('Termination Value (Cycles): ',RTP^.ExpCycles);
                    Writeln;
                    Writeln('If this was an unexpected termination, check last loaded *.SIM file.');
                    Writeln;
            End;
            End; { Case RTP^.wErrorNum1 of }
      End;
      Delay(2500);
End; { WriteException }

{----------------------------------------------------------------------------}
Function ExceptionExists;

Begin
   If RTP^.wErrorNum1 = 0
      Then ExceptionExists := False
      Else ExceptionExists := True;
End; { ExceptionExists }

{----------------------------------------------------------------------------}
End.
