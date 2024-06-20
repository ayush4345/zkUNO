#[starknet::interface]
trait IPlayPoker<TContractState> {
    fn join_game(ref self: TContractState, amount: u256);
    fn start_game(ref self: TContractState);
    fn leave_game(ref self: TContractState);
    fn shuffle_deck(ref self: TContractState);
    fn deal_hand(ref self: TContractState);
    fn deal_community_cards(ref self: TContractState);
    fn commit_hand(ref self: TContractState, commitment: felt252);
    fn reveal_hand(ref self: TContractState, hand: [felt252; 2], proof: Proof);
    fn place_bet(ref self: TContractState, amount: u256);
    fn fold(ref self: TContractState);
    fn next_round(ref self: TContractState);
    fn end_hand(ref self: TContractState);
    fn get_game_phase(self: @TContractState) -> GamePhase;
    fn get_player(self: @TContractState, player_address: ContractAddress) -> Player;
    fn get_player_addresses(self: @TContractState) -> Array<ContractAddress>;
    fn get_current_bet(self: @TContractState) -> u256;
    fn get_pot(self: @TContractState) -> u256;
}

#[starknet::contract]
mod PlayPoker {
    use starknet::{
        ContractAddress,
        get_caller_address,
        storage_access::{StorageAccess, LegacyMap},
    };
    use core::array::ArrayTrait;
    use core::serde::Serde;
    use core::hash::{HashStateTrait, HashStateExTrait, Hash};
    use openzeppelin::access::ownable::OwnableComponent;
    use pragma_lib::types::Proof;
    use pragma_lib::verify_tx;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        small_blind: u256,
        big_blind: u256,
        current_phase: GamePhase,
        players: LegacyMap<ContractAddress, Player>,
        player_addresses: Array<ContractAddress>,
        current_hand: Hand,
        shuffled_deck: Array<felt252>,
        current_bet: u256,
        pot: u256,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        GameStarted,
        PlayerLeft(ContractAddress),
        PlayerJoined(ContractAddress),
        PlayerFolded(ContractAddress),
        Shuffled,
        HandDealt,
        PhaseAdvanced(GamePhase),
        PlayerCommitted(ContractAddress),
        PlayerRevealed(ContractAddress, [felt252; 2]),
        BetPlaced(ContractAddress, u256),
        PotUpdated(u256),
        PotDistributed(u256, Array<ContractAddress>, usize),
    }

    #[derive(Drop, Serde, Copy, PartialEq, starknet::Store)]
    enum GamePhase { PreFlop, Flop, Turn, River, Showdown }

    #[derive(Drop, Serde, Copy, PartialEq, starknet::Store)]
    struct Player {
        address: ContractAddress,
        balance: u256,
        is_playing: bool,
        has_folded: bool,
    }

    #[derive(Drop)]
    struct Hand {
        hole_cards: Array<[felt252; 2]>,
        community_cards: [felt252; 5],
        player_commitments: LegacyMap<ContractAddress, felt252>,
        revealed: LegacyMap<ContractAddress, bool>,
        revealed_hands: LegacyMap<ContractAddress, [felt252; 2]>,
        is_valid_proof: LegacyMap<ContractAddress, bool>,
        hand_strength: LegacyMap<ContractAddress, u256>,
    }

    #[constructor]
    fn constructor(ref self: ContractState, small_blind: u256, big_blind: u256, owner: ContractAddress) {
        self.small_blind.write(small_blind);
        self.big_blind.write(big_blind);
        self.ownable.initializer(owner);
    }

    #[abi(embed_v0)]
    impl IPlayPokerImpl of IPlayPoker<ContractState> {
        fn join_game(ref self: ContractState, amount: u256) {
            require(amount >= self.big_blind.read(), 'Insufficient buy-in amount');
            let caller_address = get_caller_address();
            self.players.write(caller_address, Player {
                address: caller_address,
                balance: amount,
                is_playing: true,
                has_folded: false,
            });
            self.player_addresses.append(caller_address);
            self.emit(Event::PlayerJoined(caller_address));
        }

        fn start_game(ref self: ContractState) {
            self.ownable.assert_only_owner();
            require(self.player_addresses.len() >= 2, 'Not enough players to start the game');
            self.current_phase.write(GamePhase::PreFlop);
            self.emit(Event::GameStarted);
        }

        fn leave_game(ref self: ContractState) {
            let caller_address = get_caller_address();
            let player = self.get_player(caller_address);
            assert(player.is_playing, 'Not a player in the game');

            // TODO: Transfer balance back to the player (implementation depends on how balances are managed)

            self.players.write(caller_address, Player {
                is_playing: false,
                ..player
            });
            self.emit(Event::PlayerLeft(caller_address));
        }

        fn shuffle_deck(ref self: ContractState) {
            self.ownable.assert_only_owner();
            assert(self.get_game_phase() == GamePhase::PreFlop, 'Function cannot be called at this phase');

            let mut deck: Array<felt252> = ArrayTrait::new();
            let mut index = 0;

            for suit in 0..4 {
                for value in 0..13 {
                    let card_hash = poseidon_hash_span(array![suit, value, index].span());
                    deck.append(card_hash);
                    index += 1;
                }
            }

            for i in (1..deck.len()).rev() {
                let j = (block_timestamp() * block_number() + i) % deck.len();
                deck.swap(i, j);
            }

            self.shuffled_deck.write(deck);
            self.emit(Event::Shuffled);
        }

        fn deal_hand(ref self: ContractState) {
            self.ownable.assert_only_owner();
            assert(self.get_game_phase() == GamePhase::PreFlop, 'Function cannot be called at this phase');
            require(self.player_addresses.len() >= 2, 'Not enough players to deal hand');

            let mut deck_index = 0;
            let mut hole_cards = ArrayTrait::new();

            for _ in 0..2 {
                for player_address in self.player_addresses.iter() {
                    let player = self.get_player(*player_address);
                    if player.is_playing {
                        hole_cards.append(array![*self.shuffled_deck.read(deck_index), *self.shuffled_deck.read(deck_index + 1)]);
                        deck_index += 2;
                    } else {
                        hole_cards.append(array![0, 0]); // Placeholder for non-playing players
                    }
                }
            }

            self.current_hand
                hole_cards,
                community_cards: [0; 5],
                player_commitments: Default::default(),
                revealed: Default::default(),
                revealed_hands: Default::default(),
                is_valid_proof: Default::default(),
                hand_strength: Default::default(),
            });

            self.current_phase.write(GamePhase::Flop);
            self.emit(Event::HandDealt);
            self.emit(Event::PhaseAdvanced(GamePhase::Flop));
        }

        fn deal_community_cards(ref self: ContractState) {
            self.ownable.assert_only_owner();
            let hole_cards_dealt = self.player_addresses.len() * 2;
            let mut deck_index = hole_cards_dealt;

            match self.get_game_phase() {
                GamePhase::Flop => {
                    self.current_hand.read().community_cards[0] = *self.shuffled_deck.read(deck_index);
                    self.current_hand.read().community_cards[1] = *self.shuffled_deck.read(deck_index + 1);
                    self.current_hand.read().community_cards[2] = *self.shuffled_deck.read(deck_index + 2);
                    self.current_phase.write(GamePhase::Turn);
                },
                GamePhase::Turn => {
                    self.current_hand.read().community_cards[3] = *self.shuffled_deck.read(deck_index + 3);
                    self.current_phase.write(GamePhase::River);
                },
                GamePhase::River => {
                    self.current_hand.read().community_cards[4] = *self.shuffled_deck.read(deck_index + 4);
                    self.current_phase.write(GamePhase::Showdown);
                },
                _ => panic!("Invalid game phase for dealing community cards"),
            }

            self.emit(Event::PhaseAdvanced(self.get_game_phase()));
        }

        fn commit_hand(ref self: ContractState, commitment: felt252) {
            let caller_address = get_caller_address();
            let player = self.get_player(caller_address);
            assert(player.is_playing, 'Not a player in the game');
            assert(self.get_game_phase() == GamePhase::PreFlop, 'Function cannot be called at this phase');

            self.current_hand.read().player_commitments.write(caller_address, commitment);
            self.emit(Event::PlayerCommitted(caller_address));
        }

        fn reveal_hand(ref self: ContractState, hand: [felt252; 2], proof: Proof) {
            let caller_address = get_caller_address();
            let player = self.get_player(caller_address);
            assert(player.is_playing, 'Not a player in the game');
            assert(self.get_game_phase() == GamePhase::Showdown, 'Function cannot be called at this phase');

            let is_valid = verify_tx(proof, hand[0], hand[1]);
            assert(is_valid, 'Invalid ZK proof');

            self.current_hand.read().revealed.write(caller_address, true);
            self.current_hand.read().revealed_hands.write(caller_address, hand);
            self.current_hand.read().is_valid_proof.write(caller_address, is_valid);
            self.emit(Event::PlayerRevealed(caller_address, hand));
        }

        fn place_bet(ref self: ContractState, amount: u256) {
            let caller_address = get_caller_address();
            let player = self.get_player(caller_address);
            assert(player.is_playing, 'Not a player in the game');
            require(amount >= self.current_bet.read(), 'Bet amount must be at least the current bet');
            require(player.balance >= amount, 'Insufficient balance to place bet');

            self.players.write(caller_address, Player {
                balance: player.balance - amount,
                ..player
            });
            self.pot.write(self.pot.read() + amount);
            self.current_bet.write(amount);

            self.emit(Event::BetPlaced(caller_address, amount));
            self.emit(Event::PotUpdated(self.pot.read()));
        }

        fn fold(ref self: ContractState) {
            let caller_address = get_caller_address();
            let player = self.get_player(caller_address);
            assert(player.is_playing, 'Not a player in the game');

            self.players.write(caller_address, Player {
                has_folded: true,
                ..player
            });
            self.emit(Event::PlayerFolded(caller_address));
        }

        fn next_round(ref self: ContractState) {
            self.ownable.assert_only_owner();
            match self.get_game_phase() {
                GamePhase::Flop | GamePhase::Turn | GamePhase::River => self.deal_community_cards(),
                _ => panic!("Invalid game phase for next round"),
            }
        }

        fn end_hand(ref self: ContractState) {
            self.ownable.assert_only_owner();
            assert(self.get_game_phase() == GamePhase::Showdown, 'Function cannot be called at this phase');
          // TODO
        }
        // TODO
        fn get_game_phase(self: @ContractState) -> GamePhase {
            self.current_phase.read()
        }

        fn get_player(self: @ContractState, player_address: ContractAddress) -> Player {
            self.players.read(player_address)
        }

        fn get_player_addresses(self: @ContractState) -> Array<ContractAddress> {
            self.player_addresses.span().to_array()
        }

        fn get_current_bet(self: @ContractState) -> u256 {
            self.current_bet.read()
        }

        fn get_pot(self: @ContractState) -> u256 {
            self.pot.read()
        }
    }
