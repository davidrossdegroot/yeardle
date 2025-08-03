require 'rails_helper'

RSpec.describe Game, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      game = build(:game)
      expect(game).to be_valid
    end

    it "requires a user" do
      game = build(:game, user: nil)
      expect(game).not_to be_valid
      expect(game.errors[:user]).to include("can't be blank")
    end

    it "requires an event" do
      game = build(:game, event: nil)
      expect(game).not_to be_valid
      expect(game.errors[:event]).to include("can't be blank")
    end
  end

  describe "associations" do
    it "belongs to user" do
      association = described_class.reflect_on_association(:user)
      expect(association.macro).to eq :belongs_to
    end

    it "belongs to event" do
      association = described_class.reflect_on_association(:event)
      expect(association.macro).to eq :belongs_to
    end

    it "has many guesses" do
      association = described_class.reflect_on_association(:guesses)
      expect(association.macro).to eq :has_many
    end

    it "destroys associated guesses when deleted" do
      game = create(:game)
      create(:guess, game: game)

      expect { game.destroy }.to change { Guess.count }.by(-1)
    end
  end

  describe "scopes" do
    let!(:completed_game) { create(:game, :completed) }
    let!(:active_game) { create(:game) }

    it "finds completed games" do
      completed_games = Game.completed
      expect(completed_games).to include(completed_game)
      expect(completed_games).not_to include(active_game)
    end

    it "finds current game" do
      user = create(:user)
      current_game = create(:game, user: user)
      create(:game, :completed, user: user)

      expect(user.games.current_game).to eq(current_game)
    end

    it "orders by recent" do
      # Clear any existing games to avoid interference
      Game.delete_all

      old_game = create(:game)
      old_game.update_column(:created_at, 1.day.ago)

      new_game = create(:game)
      new_game.update_column(:created_at, 1.hour.ago)

      recent_games = Game.recent
      expect(recent_games.first).to eq(new_game)
      expect(recent_games.second).to eq(old_game)
    end
  end

  describe "#completed?" do
    it "returns true when completed_at is present" do
      game = create(:game, :completed)
      expect(game.completed?).to be true
    end

    it "returns false when completed_at is nil" do
      game = create(:game)
      expect(game.completed?).to be false
    end
  end

  describe "#won?" do
    it "returns true when won is true" do
      game = create(:game, :won)
      expect(game.won?).to be true
    end

    it "returns false when won is false" do
      game = create(:game, :lost)
      expect(game.won?).to be false
    end

    it "returns false when won is nil" do
      game = create(:game)
      expect(game.won?).to be false
    end
  end

  describe "#attempts_remaining" do
    it "returns 6 minus the number of guesses" do
      game = create(:game)
      create_list(:guess, 3, game: game)

      expect(game.attempts_remaining).to eq(3)
    end

    it "returns 6 when no guesses have been made" do
      game = create(:game)
      expect(game.attempts_remaining).to eq(6)
    end

    it "returns 0 when 6 guesses have been made" do
      game = create(:game)
      create_list(:guess, 6, game: game)

      expect(game.attempts_remaining).to eq(0)
    end
  end

  describe ".create_new_game" do
    let(:user) { create(:user) }

    it "creates a new game for the user" do
      create(:event) # Ensure there's an event to choose from

      expect {
        Game.create_new_game(user)
      }.to change { user.games.count }.by(1)
    end

    it "assigns a random event to the game" do
      create(:event)

      game = Game.create_new_game(user)
      expect(game.event).to_not be_nil
    end

    it "creates an incomplete game" do
      create(:event)

      game = Game.create_new_game(user)
      expect(game.completed?).to be false
      expect(game.won?).to be false
    end
  end
end
