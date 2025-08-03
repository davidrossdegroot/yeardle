require 'rails_helper'

RSpec.describe Guess, type: :model do
  let(:event) { create(:event, year: 2000) }
  let(:game) { create(:game, event: event) }

  describe "validations" do
    it "is valid with valid attributes" do
      guess = build(:guess, game: game)
      expect(guess).to be_valid
    end

    it "requires a year" do
      guess = build(:guess, year: nil, game: game)
      expect(guess).not_to be_valid
      expect(guess.errors[:year]).to include("can't be blank")
    end

    it "requires a positive year" do
      guess = build(:guess, year: -1, game: game)
      expect(guess).not_to be_valid
      expect(guess.errors[:year]).to include("must be greater than 0")
    end

    it "doesn't allow years in the future" do
      guess = build(:guess, year: Date.current.year + 1, game: game)
      expect(guess).not_to be_valid
      expect(guess.errors[:year]).to include("must be less than or equal to #{Date.current.year}")
    end
  end

  describe "associations" do
    it "belongs to game" do
      association = described_class.reflect_on_association(:game)
      expect(association.macro).to eq :belongs_to
    end
  end

  describe "#difference" do
    it "returns the absolute difference between guess and actual year" do
      guess = create(:guess, year: 1995, game: game)
      expect(guess.difference).to eq(5) # |2000 - 1995|
    end

    it "returns 0 when guess is correct" do
      guess = create(:guess, year: 2000, game: game)
      expect(guess.difference).to eq(0)
    end

    it "works with future guesses" do
      guess = create(:guess, year: 2005, game: game)
      expect(guess.difference).to eq(5) # |2000 - 2005|
    end
  end

  describe "#correct?" do
    it "returns true when year matches event year" do
      guess = create(:guess, year: 2000, game: game)
      expect(guess.correct?).to be true
    end

    it "returns false when year doesn't match event year" do
      guess = create(:guess, year: 1999, game: game)
      expect(guess.correct?).to be false
    end
  end

  describe "#direction" do
    it "returns 'correct' when guess is correct" do
      guess = create(:guess, year: 2000, game: game)
      expect(guess.direction).to eq("correct")
    end

    it "returns 'higher' when guess is too low" do
      guess = create(:guess, year: 1995, game: game)
      expect(guess.direction).to eq("higher")
    end

    it "returns 'lower' when guess is too high" do
      guess = create(:guess, year: 2005, game: game)
      expect(guess.direction).to eq("lower")
    end
  end

  describe "#feedback" do
    it "returns celebration for correct guess" do
      guess = create(:guess, year: 2000, game: game)
      expect(guess.feedback).to eq("🎉 Correct!")
    end

    it "returns 'So close!' for 1 year off" do
      guess = create(:guess, year: 1999, game: game)
      expect(guess.feedback).to include("🔥 So close! 1 year off")
    end

    it "returns 'Very close!' for 2-5 years off" do
      guess = create(:guess, year: 1997, game: game)
      expect(guess.feedback).to include("🎯 Very close! 3 years off")
    end

    it "returns 'Close!' for 6-10 years off" do
      guess = create(:guess, year: 1992, game: game)
      expect(guess.feedback).to include("📅 Close! 8 years off")
    end

    it "returns 'Getting warmer!' for 11-25 years off" do
      guess = create(:guess, year: 1985, game: game)
      expect(guess.feedback).to include("📆 Getting warmer! 15 years off")
    end

    it "returns years off for 26+ years off" do
      guess = create(:guess, year: 1950, game: game)
      expect(guess.feedback).to include("🗓️ 50 years off")
    end
  end
end
