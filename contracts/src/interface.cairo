use starknet::ContractAddress;
use starkdeck_contracts::models::{Player};

#[starknet::interface]
pub trait IPlayPoker<TContractState> {
    fn join_game(ref self: TContractState, amount: u256);
    fn start_game(ref self: TContractState);
    fn get_player(self: @TContractState, player: ContractAddress) -> Player;
}
