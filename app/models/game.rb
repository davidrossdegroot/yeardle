class Game < ApplicationRecord
  belongs_to :user
  belongs_to :event
  has_many :guesses, dependent: :destroy

  validates :user, presence: true
  validates :event, presence: true

  scope :completed, -> { where.not(completed_at: nil) }
  scope :current_game, -> { where(completed_at: nil).first }
  scope :recent, -> { order(created_at: :desc) }

  def completed?
    completed_at.present?
  end

  def won?
    won
  end

  def attempts_remaining
    6 - guesses.count
  end

  def self.create_new_game(user)
    event = Event.random_event
    create!(user: user, event: event)
  end
end
