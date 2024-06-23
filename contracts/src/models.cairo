use starknet::ContractAddress;
use starkdeck_contracts::events::game_events::game_phase::{PRE_FLOP, FLOP, TURN, RIVER, SHOWDOWN};
use starkdeck_contracts::impls::{StoreHoleCardsArray, StoreCommunityCardsArray};

#[derive(Drop, Serde, Copy, PartialEq, starknet::Event, starknet::Store)]
pub enum GamePhase {
    PRE_FLOP: PRE_FLOP,
    FLOP: FLOP,
    TURN: TURN,
    RIVER: RIVER,
    SHOWDOWN: SHOWDOWN
}

#[derive(Drop, Serde, Copy, PartialEq, starknet::Store)]
pub struct Player {
    pub address: ContractAddress,
    pub balance: u256,
    pub is_playing: bool,
    pub has_folded: bool,
}

#[derive(Drop, Serde, Copy, PartialEq, starknet::Store)]
pub struct HoleCards {
    pub player_address: ContractAddress,
    pub card1: u256,
    pub card2: u256,
}

#[derive(Drop, Serde, Copy, PartialEq, starknet::Store)]
pub struct CommunityCards {
    pub card1: u256,
    pub card2: u256,
    pub card3: u256,
    pub card4: u256,
    pub card5: u256,
}

#[derive(Drop, Serde, PartialEq, starknet::Store)]
pub struct Hand {
    pub hole_cards: Array<HoleCards>,
    pub community_cards: Array<CommunityCards>,
    pub index: u256,
}
