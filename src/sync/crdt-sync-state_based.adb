package body CRDT.Sync.State_Based is

   function Create (Config : Sync_Config) return Replica_State is
   begin
      return Replica_State'
        (Max_Replicas => Config.Max_Replicas,
         HLC_Clock    => CRDT.HLC.Create (Config.HLC_Node),
         SV           => (others => 0));
   end Create;

   procedure Merge (Local : in out Replica_State; Remote : Replica_State) is
   begin
      CRDT.Core.VTime_Merge (Local.SV, Remote.SV);
   end Merge;

   function Compute_Delta (Local : Replica_State;
                           Remote_SV : Core.VTime) return Natural is
   begin
      return 0;
   end Compute_Delta;

   function Is_Ahead (SV : Core.VTime; TS : Core.Lamport_Time) return Boolean is
   begin
      if TS.Stamp = 0 then
         return False;
      end if;
      for I in SV'Range loop
         if Natural (SV (I)) >= TS.Stamp then
            return True;
         end if;
      end loop;
      return False;
   end Is_Ahead;

end CRDT.Sync.State_Based;
