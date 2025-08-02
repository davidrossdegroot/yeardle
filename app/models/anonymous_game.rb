class AnonymousGame
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :id, :string
  attribute :event
  # ✅ Each instance gets its own fresh array because the default is a lambda
  # attribute :guesses_data, :string, array: true, default: -> { [] }
  # untyped, still fine for in-memory objects
  attribute :guesses_data, array: true, default: -> { [] }
  attribute :completed_at, :datetime
  attribute :won, :boolean, default: false
  attribute :session_id, :string

  def initialize(attributes = {})
    super
    @guesses = nil
  end

  def guesses
    @guesses ||= AnonymousGuesses.new(self)
  end

  def completed?
    completed_at.present?
  end

  def won?
    won
  end

  def attempts_remaining
    6 - guesses.count
  end

  def update!(attributes)
    assign_attributes(attributes)
    save_to_cache
  end

  def save_to_cache
    game_data = {
      id: id,
      event_id: event.id,
      guesses: guesses_data,
      completed_at: completed_at,
      won: won
    }

    Rails.cache.write("anonymous_game_#{session_id}", game_data, expires_in: 24.hours)
  end

  def persisted?
    true
  end

  def to_param
    id
  end
end

class AnonymousGuesses
  def initialize(game)
    @game = game
  end

  def count
    @game.guesses_data.length
  end

  def any?
    @game.guesses_data.any?
  end

  def create!(attributes)
    guess_data = {
      year: attributes[:year],
      created_at: Time.current
    }

    @game.guesses_data << guess_data
    @game.save_to_cache

    AnonymousGuess.new(guess_data.merge(game: @game))
  end

  def order(field)
    # Return ordered guesses
    @game.guesses_data.map { |data| AnonymousGuess.new(data.merge(game: @game)) }
  end

  def each_with_index
    @game.guesses_data.each_with_index do |data, index|
      yield AnonymousGuess.new(data.merge(game: @game)), index
    end
  end
end

class AnonymousGuess
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :year, :integer
  attribute :created_at, :datetime
  attribute :game

  def difference
    (game.event.year - year).abs
  end

  def correct?
    year == game.event.year
  end

  def direction
    return "correct" if correct?
    year < game.event.year ? "higher" : "lower"
  end

  def feedback
    return "🎉 Correct!" if correct?

    years_off = difference
    if years_off <= 1
      "🔥 So close! #{years_off} year off"
    elsif years_off <= 5
      "🎯 Very close! #{years_off} years off"
    elsif years_off <= 10
      "📅 Close! #{years_off} years off"
    elsif years_off <= 25
      "📆 Getting warmer! #{years_off} years off"
    else
      "🗓️ #{years_off} years off"
    end
  end
end
