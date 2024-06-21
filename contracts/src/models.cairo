use starknet::ContractAddress;
use starkdeck_contracts::events::game_events::game_phase::{PreFlop, Flop, Turn, River, Showdown};
use starkdeck_contracts::impls::{StoreHoleCardsArray, StoreCommunityCardsArray};

#[derive(Drop, Serde, Copy, PartialEq, starknet::Event, starknet::Store)]
pub enum GamePhase {
    PreFlop: PreFlop,
    Flop: Flop,
    Turn: Turn,
    River: River,
    Showdown: Showdown
}

#[derive(Drop, Serde, Copy, PartialEq, starknet::Store)]
pub struct Player {
    address: ContractAddress,
    balance: u256,
    is_playing: bool,
    has_folded: bool,
}

#[derive(Drop, Serde, Copy, PartialEq, starknet::Store)]
pub struct HoleCards {
    player_address: ContractAddress,
    card1: u256,
    card2: u256,
}

#[derive(Drop, Serde, Copy, PartialEq, starknet::Store)]
pub struct CommunityCards {
    card1: u256,
    card2: u256,
    card3: u256,
    card4: u256,
    card5: u256,
}

#[derive(Drop, Serde, PartialEq, starknet::Store)]
pub struct Hand {
    hole_cards: Array<HoleCards>,
    community_cards: Array<CommunityCards>,
    index: u256,
}
