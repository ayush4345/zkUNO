#[starknet::contract]
pub(crate) mod PlayPoker {
    use starknet::{
        ContractAddress, get_caller_address, get_contract_address, contract_address_const
    };
    use starkdeck_contracts::events::game_events::game_phase::{PRE_FLOP, FLOP, TURN, RIVER, SHOWDOWN};
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::upgrades::UpgradeableComponent;
    use openzeppelin::upgrades::interface::IUpgradeable;
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use starkdeck_contracts::events::game_events::{
        GameStarted, PlayerLeft, PlayerJoined, PlayerFolded, Shuffled, HandDealt, PlayerCommitted,
        PlayerRevealed, BetPlaced, PotUpdated, PotDistributed,
    };
    use starknet::ClassHash;
    use starkdeck_contracts::models::{GamePhase, Player, Hand};
    use starkdeck_contracts::impls::{StoreFelt252Array};
    use starkdeck_contracts::constants::{NUM_CARDS, NUM_PLAYERS, NUM_BOARD_CARDS};
    use starkdeck_contracts::interface::{IPlayPoker};

    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        small_blind: u256,
        big_blind: u256,
        current_phase: GamePhase,
        players: LegacyMap<ContractAddress, Player>,
        total_players: u256,
        current_hand: Hand,
        player_commitments: LegacyMap::<u64, (ContractAddress, u256)>, // workaround for LegacyMap
        player_revealed: LegacyMap::<u64, (ContractAddress, bool)>, // workaround for LegacyMap
        shuffle_deck: Array<felt252>,
        current_bet: u256,
        pot: u256,
        token: IERC20Dispatcher,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
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
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        token: ContractAddress,
        _small_blind: felt252,
        _big_blind: felt252,
    ) {
        self.ownable.initializer(owner);
        self.small_blind.write(_small_blind.into());
        self.big_blind.write(_big_blind.into());
        self.token.write(IERC20Dispatcher { contract_address: token });
        self.total_players.write(0);
    }


    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable.upgrade(new_class_hash);
        }
    }

    #[abi(embed_v0)]
    pub impl PlayPokerImpl of IPlayPoker<ContractState> {
        fn join_game(ref self: ContractState, amount: u256) {
            assert!(
                self.token.read().balance_of(get_caller_address()) >= amount,
                "Insufficient balance to join the game"
            );
            self.token.read().transfer_from(get_caller_address(), get_contract_address(), amount);
            let player = Player {
                balance: amount, address: get_caller_address(), is_playing: true, has_folded: false
            };
            self.players.write(player.address, player);
            let total_players = self.total_players.read();
            self.total_players.write(total_players + 1);
            self.emit(PlayerJoined { player: get_caller_address() });
        }

        fn start_game(ref self: ContractState) {
            let total_players = self.total_players.read();
            assert!(total_players >= 2, "Minimum 2 players required to start the game");
            self.current_phase.write(GamePhase::PRE_FLOP(PRE_FLOP {}));
            self.emit(GameStarted {});
            
        }

        fn get_player(self: @ContractState, player: ContractAddress) -> Player {
            self.players.read(player)
        }
    }
}
