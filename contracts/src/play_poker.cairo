#[starknet::contract]
mod PlayPoker {
    use starknet::ContractAddress;
    use openzeppelin::access::ownable::OwnableComponent;
    use starkdeck_contracts::events::game_events::{
        GameStarted, PlayerLeft, PlayerJoined, PlayerFolded, Shuffled, HandDealt, PlayerCommitted,
        PlayerRevealed, BetPlaced, PotUpdated, PotDistributed,
    };
    use starkdeck_contracts::models::{GamePhase, Player, Hand};
    use starkdeck_contracts::impls::{StoreFelt252Array};
    use starkdeck_contracts::constants::{NUM_CARDS, NUM_PLAYERS, NUM_BOARD_CARDS};

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;


    #[storage]
    struct Storage {
        small_blind: u256,
        big_blind: u256,
        current_phase: GamePhase,
        players: LegacyMap<ContractAddress, Player>,
        current_hand: Hand,
        player_commitments: LegacyMap::<u64, (ContractAddress, u256)>, // workaround for LegacyMap
        player_revealed: LegacyMap::<u64, (ContractAddress, bool)>, // workaround for LegacyMap
        shuffle_deck: Array<felt252>,
        current_bet: u256,
        pot: u256,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    #[event]
    #[derive(Drop, PartialEq, starknet::Event)]
    enum Event {
        GameStarted: GameStarted,
        PlayerLeft: PlayerLeft,
        PlayerJoined: PlayerJoined,
        PlayerFolded: PlayerFolded,
        Shuffled: Shuffled,
        HandDealt: HandDealt,
        #[flat]
        PhaseAdvanced: GamePhase,
        PlayerCommitted: PlayerCommitted,
        PlayerRevealed: PlayerRevealed,
        BetPlaced: BetPlaced,
        PotUpdated: PotUpdated,
        PotDistributed: PotDistributed,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
    }
}
