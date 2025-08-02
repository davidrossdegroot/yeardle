require 'rails_helper'

RSpec.describe AnonymousUser, type: :model do
  describe "initialization" do
    it "creates a session_id when none provided" do
      user = AnonymousUser.new
      expect(user.session_id).to be_present
      expect(user.session_id.length).to eq(32) # SecureRandom.hex(16) produces 32 chars
    end

    it "uses provided session_id" do
      custom_id = "custom_session_123"
      user = AnonymousUser.new(custom_id)
      expect(user.session_id).to eq(custom_id)
    end
  end

  describe "#id" do
    it "returns anonymous prefixed id" do
      user = AnonymousUser.new("test123")
      expect(user.id).to eq("anonymous_test123")
    end
  end

  describe "#anonymous?" do
    it "returns true" do
      user = AnonymousUser.new
      expect(user.anonymous?).to be true
    end
  end

  describe "#persisted?" do
    it "returns false" do
      user = AnonymousUser.new
      expect(user.persisted?).to be false
    end
  end

  describe "#games" do
    it "returns AnonymousUserGames instance" do
      user = AnonymousUser.new
      expect(user.games).to be_an(AnonymousUserGames)
    end

    it "memoizes the games instance" do
      user = AnonymousUser.new
      games1 = user.games
      games2 = user.games
      expect(games1).to be(games2)
    end
  end

  describe "#current_game" do
    it "delegates to games.current_game" do
      user = AnonymousUser.new
      expect(user.games).to receive(:current_game)
      user.current_game
    end
  end
end

RSpec.describe AnonymousUserGames, type: :model do
  let(:session_id) { "test_session_123" }
  let(:anonymous_user) { AnonymousUser.new(session_id) }
  let(:games) { AnonymousUserGames.new(anonymous_user) }
  let(:event) { create(:event) }

  before do
    Rails.cache.clear
  end

  describe "#current_game" do
    it "returns nil when no cached game exists" do
      expect(games.current_game).to be_nil
    end

    it "returns AnonymousGame when cached game is completed" do
      # Create event explicitly before storing its ID
      event = create(:event)

      completed_game_data = {
        id: "game123",
        event_id: event.id,
        guesses: [],
        completed_at: Time.current,
        won: false
      }
      Rails.cache.write("anonymous_game_#{session_id}", completed_game_data)

      current_game = games.current_game
      expect(current_game).to be_an(AnonymousGame)
      expect(current_game.id).to eq("game123")
      expect(current_game.event).to eq(event)
      expect(current_game.completed?).to be true
    end

    it "returns AnonymousGame when incomplete game exists" do
      # Create event explicitly before storing its ID
      event = create(:event)

      game_data = {
        id: "game123",
        event_id: event.id,
        guesses: [],
        completed_at: nil,
        won: false
      }
      Rails.cache.write("anonymous_game_#{session_id}", game_data)

      current_game = games.current_game
      expect(current_game).to be_an(AnonymousGame)
      expect(current_game.id).to eq("game123")
      expect(current_game.event).to eq(event)
    end
  end

  describe "#create_new_game" do
    it "creates a new anonymous game" do
      # Ensure there's an event available for random selection
      create(:event)

      new_game = games.create_new_game

      expect(new_game).to be_an(AnonymousGame)
      expect(new_game.event).to be_an(Event)
      expect(new_game.completed?).to be false
    end

    it "saves the game to cache" do
      # Ensure there's an event available for random selection
      create(:event)

      new_game = games.create_new_game

      cached_data = Rails.cache.read("anonymous_game_#{session_id}")
      expect(cached_data).to be_present
      expect(cached_data[:event_id]).to eq(new_game.event.id)
    end
  end

  describe "#find" do
    it "returns current game when ID matches" do
      # Create event explicitly before storing its ID
      event = create(:event)

      game_data = {
        id: "game123",
        event_id: event.id,
        guesses: [],
        completed_at: nil,
        won: false
      }
      Rails.cache.write("anonymous_game_#{session_id}", game_data)

      found_game = games.find("game123")
      expect(found_game.id).to eq("game123")
    end

    it "raises ActiveRecord::RecordNotFound when ID doesn't match" do
      expect {
        games.find("nonexistent")
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "#completed" do
    it "returns AnonymousUserGamesScope" do
      scope = games.completed
      expect(scope).to be_an(AnonymousUserGamesScope)
    end
  end
end

RSpec.describe AnonymousGame, type: :model do
  let(:event) { create(:event, year: 2000) }
  let(:session_id) { "test_session" }

  let(:game) do
    AnonymousGame.new(
      id: "game123",
      event: event,
      session_id: session_id
    )
  end

  describe "#completed?" do
    it "returns false when completed_at is nil" do
      expect(game.completed?).to be false
    end

    it "returns true when completed_at is present" do
      game.completed_at = Time.current
      expect(game.completed?).to be true
    end
  end

  describe "#won?" do
    it "returns false by default" do
      expect(game.won?).to be false
    end

    it "returns true when won is true" do
      game.won = true
      expect(game.won?).to be true
    end
  end

  describe "#attempts_remaining" do
    it "returns 6 minus guesses count" do
      game.guesses_data = [ { year: 1999 }, { year: 1998 } ]
      expect(game.attempts_remaining).to eq(4)
    end
  end

  describe "#guesses" do
    it "returns AnonymousGuesses instance" do
      expect(game.guesses).to be_an(AnonymousGuesses)
    end
  end

  describe "#save_to_cache" do
    it "saves game data to Rails cache" do
      game.save_to_cache

      cached_data = Rails.cache.read("anonymous_game_#{session_id}")
      expect(cached_data[:id]).to eq("game123")
      expect(cached_data[:event_id]).to eq(event.id)
    end
  end

  describe "#update!" do
    it "updates attributes and saves to cache" do
      game.update!(completed_at: Time.current, won: true)

      expect(game.completed_at).to be_present
      expect(game.won?).to be true

      cached_data = Rails.cache.read("anonymous_game_#{session_id}")
      expect(cached_data[:won]).to be true
    end
  end
end

RSpec.describe AnonymousGuess, type: :model do
  let(:event) { create(:event, year: 2000) }
  let(:game) do
    AnonymousGame.new(
      id: "game123",
      event: event,
      session_id: "test_session"
    )
  end

  let(:guess) do
    AnonymousGuess.new(
      year: 1995,
      game: game,
      created_at: Time.current
    )
  end

  describe "#difference" do
    it "returns absolute difference between guess and event year" do
      expect(guess.difference).to eq(5) # |2000 - 1995|
    end
  end

  describe "#correct?" do
    it "returns true when year matches event year" do
      correct_guess = AnonymousGuess.new(year: 2000, game: game)
      expect(correct_guess.correct?).to be true
    end

    it "returns false when year doesn't match" do
      expect(guess.correct?).to be false
    end
  end

  describe "#direction" do
    it "returns 'higher' when guess is too low" do
      expect(guess.direction).to eq("higher")
    end

    it "returns 'lower' when guess is too high" do
      high_guess = AnonymousGuess.new(year: 2005, game: game)
      expect(high_guess.direction).to eq("lower")
    end

    it "returns 'correct' when guess is right" do
      correct_guess = AnonymousGuess.new(year: 2000, game: game)
      expect(correct_guess.direction).to eq("correct")
    end
  end

  describe "#feedback" do
    it "provides appropriate feedback based on accuracy" do
      # Test various levels of accuracy
      test_cases = [
        { year: 2000, expected: "🎉 Correct!" },
        { year: 1999, expected: "🔥 So close! 1 year off" },
        { year: 1997, expected: "🎯 Very close! 3 years off" },
        { year: 1992, expected: "📅 Close! 8 years off" },
        { year: 1980, expected: "📆 Getting warmer! 20 years off" },
        { year: 1950, expected: "🗓️ 50 years off" }
      ]

      test_cases.each do |test_case|
        guess = AnonymousGuess.new(year: test_case[:year], game: game)
        expect(guess.feedback).to eq(test_case[:expected])
      end
    end
  end
end
