module nfttest::cap;

public struct MintCap has key,store {
  id: UID,
}


// === Initializer ===
fun init(ctx: &mut TxContext){
let cap = MintCap{
  id: object::new(ctx),
};
transfer::public_transfer(cap,ctx.sender());
}

// === Public Functions ===
public fun burn (cap:MintCap){
  let MintCap{id} = cap;
  id.delete();
}



