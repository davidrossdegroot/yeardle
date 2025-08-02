require 'rails_helper'

RSpec.describe Event, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      event = build(:event)
      expect(event).to be_valid
    end

    it "requires a name" do
      event = build(:event, name: nil)
      expect(event).not_to be_valid
      expect(event.errors[:name]).to include("can't be blank")
    end

    it "requires a year" do
      event = build(:event, year: nil)
      expect(event).not_to be_valid
      expect(event.errors[:year]).to include("can't be blank")
    end

    it "requires a positive year" do
      event = build(:event, year: -1)
      expect(event).not_to be_valid
      expect(event.errors[:year]).to include("must be greater than 0")
    end

    it "doesn't allow years in the future" do
      event = build(:event, year: Date.current.year + 1)
      expect(event).not_to be_valid
      expect(event.errors[:year]).to include("must be less than or equal to #{Date.current.year}")
    end

    it "requires a category" do
      event = build(:event, category: nil)
      expect(event).not_to be_valid
      expect(event.errors[:category]).to include("can't be blank")
    end
  end

  describe "associations" do
    it "has many games" do
      association = described_class.reflect_on_association(:games)
      expect(association.macro).to eq :has_many
    end

    it "destroys associated games when deleted" do
      event = create(:event)
      game = create(:game, event: event)

      expect { event.destroy }.to change { Game.count }.by(-1)
    end
  end

  describe "scopes" do
    let!(:tech_event) { create(:event, category: "Tech") }
    let!(:sports_event) { create(:event, category: "Sports") }

    it "filters by category" do
      tech_events = Event.by_category("Tech")
      expect(tech_events).to include(tech_event)
      expect(tech_events).not_to include(sports_event)
    end

    it "returns random events" do
      # This is hard to test, but we can check it returns events
      random_events = Event.random.limit(2)
      expect(random_events.count).to eq(2)
    end
  end

  describe ".random_event" do
    it "returns a random event" do
      create_list(:event, 3)

      random_event = Event.random_event
      expect(random_event).to be_an(Event)
    end

    it "returns nil when no events exist" do
      expect(Event.random_event).to be_nil
    end
  end

  describe "constants" do
    it "defines valid categories" do
      expect(Event::CATEGORIES).to eq(%w[Tech Sports History Culture])
    end
  end
end
