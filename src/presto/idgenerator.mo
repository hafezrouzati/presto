import UUID "mo:uuid/UUID";
import Source "mo:uuid/Source";
import AsyncSource "mo:uuid/async/SourceV4";
import XorShift "mo:rand/XorShift";

class IDGenerator()
{
    private let ae = AsyncSource.Source();
    private let rr = XorShift.toReader(XorShift.XorShift64(null));
    private let c : [Nat8] = [0, 0, 0, 0, 0, 0]; // Replace with identifier of canister f.e.
    private let se = Source.Source(rr, c);

    public func getUUID() : Text
    {
        //let id = await ae.new();
        let id = se.new();
        let newID = UUID.toText(id);
        return newID;
    };
};