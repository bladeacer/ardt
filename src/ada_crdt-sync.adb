package body Ada_CRDT.Sync is

   function Compute_Delta (Source_Total : Natural; Remote_SV : State_Vector) return Natural is
   begin
      -- Placeholder: return total items (full sync) if no delta info
      return Source_Total;
   end Compute_Delta;

end Ada_CRDT.Sync;
