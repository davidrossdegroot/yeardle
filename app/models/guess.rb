class Guess < ApplicationRecord
  belongs_to :game

  validates :year, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: Date.current.year }

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
