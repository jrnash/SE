UNIT SE_QUE;

INTERFACE

USES SE_COM;

Procedure Init(VAR LL : LIST_TYPE);
Procedure Ins(New_Bug   : BUG_PTR;
              RTP : RTP_PTR);
Procedure Del_From_List(Dead_Bug : BUG_PTR;
                        RTP      : RTP_PTR);
Procedure Point_to_Next(RTP : RTP_PTR);
Function PastLast(Curr_Bug : BUG_PTR) : Boolean;

IMPLEMENTATION
{----------------------------------------------------------------------------}
Procedure Init(VAR LL : LIST_TYPE);
BEGIN
     New(LL);
     LL^.Age  := ($FFFF);{ This is not a vaild BUG and is only       }
                         { being used as a trailer\header node       }
     LL^.Next := LL;     { Header node of empty circular Linked List }
     LL^.Prev := LL;     { points to itself                          }
     LL^.mean := 100;    { mean = 100 as it is allway the last node  }

END; (* Procedure Clear *)
{----------------------------------------------------------------------------}
Procedure Ins;           { Bugs will be sorted in LL by mean }

VAR  Temp    : BUG_PTR;

BEGIN
     Temp := RTP^.LL^.next;

     { Advance Temp ptr until insertion point found }
     WHILE (New_Bug^.mean > Temp^.mean)  DO
       Temp := Temp^.next;

     New_Bug^.Next    := Temp;
     New_Bug^.Prev    := Temp^.prev;
     Temp^.Prev^.Next := New_Bug;
     Temp^.Prev       := New_Bug;
     RTP^.NumofBugs   := RTP^.NumofBugs + 1;

END; (* Procedure Ins *)
{----------------------------------------------------------------------------}
Function Empty(RTP : RTP_PTR) : Boolean;      { Internal }
BEGIN
     Empty := RTP^.LL = RTP^.LL^.Next;
END;
{----------------------------------------------------------------------------}
Procedure Point_to_Next;
BEGIN
     If RTP^.Fwd_Travrs
     Then RTP^.Curr_Bug := RTP^.Curr_Bug^.Next
     Else RTP^.Curr_Bug := RTP^.Curr_Bug^.Prev;
END;
{-----------------------------------------------------------------------------}
Function PastLast(Curr_Bug : BUG_PTR) : Boolean;
Begin
     If Curr_Bug^.Age = ($FFFF)
        Then PastLast := True
        Else PastLast := False;
End;
{----------------------------------------------------------------------------}
Procedure Del_From_List;

BEGIN
     Dead_Bug^.Next^.Prev := Dead_Bug^.Prev;
     Dead_Bug^.Prev^.Next := Dead_Bug^.Next;
     Dispose(Dead_Bug);
     RTP^.NumofBugs := RTP^.NumofBugs - 1;

END; (* Procedure Del *)
END.  (* Main *)
