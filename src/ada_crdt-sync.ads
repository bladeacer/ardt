with Ada_CRDT.Core;
with Ada_CRDT.Sequences;

package Ada_CRDT.Sync is

   -- State Vector for tracking seen updates per replica
   type State_Vector is array (Positive range <>) of Natural with
     Default_Component_Value => 0;

   -- Compute which items in Source need to be sent to a peer
   -- based on the peer's state vector
   generic
      type Element_Type is private;
      with function Has_Seq (E : Element_Type; Replica : Core.Replica_Id; Seq : Natural) return Boolean;
   function Compute_Delta (Source_Total : Natural; Remote_SV : State_Vector) return Natural;

end Ada_CRDT.Sync;
