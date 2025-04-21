/// Module: nfttest
module nfttest::nfttest;


// === Imports ===
use std::string::String;
use sui::{package,display,balance::{Self,Balance},sui::SUI,coin::Coin,event};
use nfttest::cap::MintCap;
// === Errors ===
const EINSUFFICIENT_BALANCE: u64 = 0;


// === Constants ===
const MINT_NFT_COST:u64 = 100_000_000;

// === Structs ===

/// A struct representing an NFT.
public struct NFT has key,store{
  /// The unique identifier of the NFT.
  id: UID,
  /// The name of the NFT.
  name: String,
  /// The description of the NFT.
  description: String,
  /// The URL of the NFT.
  url:String
}

/// A struct representing a treasury.
public struct Treasury <phantom T> has key,store{
  /// The unique identifier of the treasury.
  id:UID,
  /// The balance of the treasury.
  balance: Balance<T>,
  /// The mint cost of the NFT.
  mint_cost:u64,
}

// ===OTW ===

/// A struct representing the NFT test.
public struct NFTTEST has drop{} 

// === Events ===

/// An event representing a mint.
public struct MintEvent has copy, drop {
  /// The unique identifier of the NFT.
  id: ID,
  /// The name of the NFT.
  name: String,
  /// The description of the NFT.
  description: String,
  /// The URL of the NFT.
  url:String
}


// === Public Functions ===
fun init(otw: NFTTEST, ctx: &mut TxContext){
  // Claim a publisher for the module.
  let publisher = package::claim(otw,ctx);
  // Create a display for the NFT.
  let mut display = display::new<NFT>(&publisher,ctx);

    display.add( b"name".to_string(),
  b"Nft #{name}".to_string(),
  );

  // Add the description of the NFT to the display.
  display.add( b"description".to_string(),
  b"{description}".to_string(),
  );

  // Add the image URL of the NFT to the display.
  display.add(b"image_url".to_string(), b"{url}".to_string());

  // Update the version of the display.
  display.update_version();


  let treasury = Treasury<SUI>{
    id: object::new(ctx),
    balance: balance::zero<SUI>(),
    mint_cost: MINT_NFT_COST,
  };

  // Transfer the publisher, display, and treasury to the sender.
  transfer::public_transfer(publisher,ctx.sender());
  transfer::public_transfer(display,ctx.sender());
  transfer::share_object(treasury);

}


#[allow(lint(self_transfer))]

public fun mint(treasury:&mut Treasury<SUI>,mut coin:Coin<SUI>, name:String,description:String,url:String,ctx: &mut TxContext):NFT{
  // Assert that the coin value is greater than or equal to the mint cost.
  assert!(coin.value() >= treasury.mint_cost, EINSUFFICIENT_BALANCE);

  // Join the coin into the treasury.
  treasury.balance.join(coin.split(treasury.mint_cost,ctx).into_balance());

  // If the coin value is 0, destroy the coin.
  if(coin.value()==0){
    coin.destroy_zero();
  }else{
    // Transfer the coin to the sender.
    transfer::public_transfer(coin,ctx.sender());
  };

  // Create a new NFT.
  let nft = NFT{
    id: object::new(ctx),
    name:name,
    description:description,
    url:url,
  };

  // Emit a mint event.
  event::emit (MintEvent{
    id:object::id(&nft),
    name:name,
    description:description,
    url:url,
  });

  nft
}


// === Admin Functions ===
/// A function to set the mint cost of the NFT.
public fun set_mint_cost(_: &mut MintCap,treasury: &mut Treasury<SUI>,new_mint_cost:u64){
  // Set the mint cost of the NFT.
  treasury.mint_cost = new_mint_cost;
}

/// A function to withdraw all funds from the treasury. 
#[allow(lint(self_transfer))]
public fun withdraw_all_funds(_: &mut MintCap,treasury: &mut Treasury<SUI>,ctx: &mut TxContext){
  // Get the value of the treasury.
  let value = treasury.balance.value();
  // Split the treasury into a coin.
  let coin = treasury.balance.split(value).into_coin(ctx);
  // Transfer the coin to the sender.
  transfer::public_transfer(coin, ctx.sender());
}



