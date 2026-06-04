with CRDT.Test_Support; use CRDT.Test_Support;
with CRDT.Core;
with CRDT.Sequences.Yjs;
with CRDT.Sequences.Naive;
with CRDT.Sync;
with CRDT.Sync.State_Based;
with CRDT.Sync.Op_Based;
with Ada.Text_IO; use Ada.Text_IO;

package body Test_Engines is

   procedure Run (RunR : in out Runner) is

   procedure Test_Iterators is
      Max_RGA : constant Positive := 20;
      Seq     : Natural := 0;

      package RGA_Str is new CRDT.Sequences.Yjs (Character, Max_RGA);

      R : RGA_Str.RGA (Max_RGA);

      function Next_Id return RGA_Str.Node_Id is
      begin
         Seq := Seq + 1;
         return (Replica => 1, Seq => Seq);
      end Next_Id;

   begin
      New_Line;
      Put_Line ("[Iterators]");

      RGA_Str.Insert (R, 1, Next_Id, 'A');
      RGA_Str.Insert (R, 2, Next_Id, 'B');
      RGA_Str.Insert (R, 3, Next_Id, 'C');
      RunR.Check(RGA_Str.Size (R) = 3, "Iterator prep: size = 3");

      -- Test cursor-based iteration
      declare
         Pos  : RGA_Str.Cursor := RGA_Str.First (R);
         C    : Character;
         Cnt  : Natural := 0;
      begin
         while RGA_Str.Has_Element (Pos) loop
            C := RGA_Str.Element (R, Pos);
            Cnt := Cnt + 1;
            if Cnt = 1 then
               RunR.Check(C = 'A', "Iterator element 1 = 'A'");
            elsif Cnt = 2 then
               RunR.Check(C = 'B', "Iterator element 2 = 'B'");
            elsif Cnt = 3 then
               RunR.Check(C = 'C', "Iterator element 3 = 'C'");
            end if;
            exit when Cnt >= 3;
            RGA_Str.Next (R, Pos);
         end loop;
         RunR.Check(Cnt = 3, "Iterator traversed all 3 elements");
      end;

      Put_Line ("[Iterators] done.");
   end Test_Iterators;

   procedure Test_Naive_Engine is
      Max_RGA : constant Positive := 20;
      Seq     : Natural := 0;

      package RGA_Str is new CRDT.Sequences.Naive (Character, Max_RGA);

      R : RGA_Str.RGA (Max_RGA);

      function Next_Id return RGA_Str.Node_Id is
      begin
         Seq := Seq + 1;
         return (Replica => 1, Seq => Seq);
      end Next_Id;

   begin
      New_Line;
      Put_Line ("[Naive Engine]");

      RunR.Check(RGA_Str.Size (R) = 0, "Naive initial size = 0");

      RGA_Str.Insert (R, 1, Next_Id, 'a');
      RunR.Check(RGA_Str.Size (R) = 1, "Naive Insert 'a': size = 1");
      RunR.Check(RGA_Str.Get (R, 1) = 'a', "Naive Get (1) = 'a'");

      RGA_Str.Insert (R, 2, Next_Id, 'b');
      RGA_Str.Insert (R, 3, Next_Id, 'c');
      RunR.Check(RGA_Str.Size (R) = 3, "Naive Insert 'b','c': size = 3");
      RunR.Check(RGA_Str.Get (R, 1) = 'a', "Naive Get (1) = 'a'");
      RunR.Check(RGA_Str.Get (R, 2) = 'b', "Naive Get (2) = 'b'");
      RunR.Check(RGA_Str.Get (R, 3) = 'c', "Naive Get (3) = 'c'");

      RGA_Str.Delete (R, 2);
      RunR.Check(RGA_Str.Size (R) = 3, "Naive Delete (2): size still 3 (tombstone)");

      -- Test cursor iteration
      declare
         Pos  : RGA_Str.Cursor := RGA_Str.First (R);
         C    : Character;
         Cnt  : Natural := 0;
      begin
         while RGA_Str.Has_Element (Pos) loop
            C := RGA_Str.Element (R, Pos);
            Cnt := Cnt + 1;
            if Cnt = 1 then
               RunR.Check(C = 'a', "Naive iterator element 1 = 'a'");
            elsif Cnt = 2 then
               RunR.Check(C = 'b', "Naive iterator element 2 = 'b'");
            elsif Cnt = 3 then
               RunR.Check(C = 'c', "Naive iterator element 3 = 'c'");
            end if;
            exit when Cnt >= 3;
            RGA_Str.Next (R, Pos);
         end loop;
         RunR.Check(Cnt = 3, "Naive iterator traversed all 3 elements");
      end;

      -- Merge test
      declare
         R2 : RGA_Str.RGA (Max_RGA);
      begin
         RGA_Str.Insert (R2, 1, (Replica => 2, Seq => 1), 'x');
         RGA_Str.Merge (R, R2);
         RunR.Check(RGA_Str.Size (R) >= 3, "Naive Merge: size >= 3");
      end;

      Put_Line ("[Naive Engine] done.");
   end Test_Naive_Engine;

   procedure Test_Sync_Layer is
      use type CRDT.Sync.Op_Based.Op_Kind;
   begin
      New_Line;
      Put_Line ("[Sync Layer]");

      declare
         Config : CRDT.Sync.State_Based.Sync_Config :=
           (Max_Replicas => 4, Delta_Sync => True, HLC_Node => 1);
         Local  : CRDT.Sync.State_Based.Replica_State :=
           CRDT.Sync.State_Based.Create (Config);
         Remote : CRDT.Sync.State_Based.Replica_State :=
           CRDT.Sync.State_Based.Create (Config);
      begin
         CRDT.Sync.State_Based.Merge (Local, Remote);
         RunR.Check(True, "State-based sync: merge completed without error");
      end;

      declare
         Log : CRDT.Sync.Op_Based.Op_Log (Capacity => 100);
      begin
         CRDT.Sync.Op_Based.Append (Log,
           (Kind => CRDT.Sync.Op_Based.Op_Insert, Seq => 1, Node => 1, Position => 1));
         CRDT.Sync.Op_Based.Append (Log,
           (Kind => CRDT.Sync.Op_Based.Op_Delete, Seq => 2, Node => 1, Del_Position => 1));
         RunR.Check(CRDT.Sync.Op_Based.Size (Log) = 2,
                "Op-based sync: log size = 2");

         CRDT.Sync.Op_Based.Acknowledge (Log, 1);
         RunR.Check(CRDT.Sync.Op_Based.Size (Log) = 1,
                "Op-based sync: after ack up to seq 1, size = 1");

         CRDT.Sync.Op_Based.Compact (Log);
         RunR.Check(CRDT.Sync.Op_Based.Size (Log) = 1,
                "Op-based sync: after compact, size = 1");

         declare
            Op : constant CRDT.Sync.Op_Based.Operation :=
              CRDT.Sync.Op_Based.Get (Log, 1);
         begin
            RunR.Check(Op.Kind = CRDT.Sync.Op_Based.Op_Delete,
                   "Op-based sync: Get remaining op = Delete");
         end;
      end;

      Put_Line ("[Sync Layer] done.");
   end Test_Sync_Layer;

begin
   Test_Iterators;
   Test_Naive_Engine;
   Test_Sync_Layer;
end Run;
end Test_Engines;
