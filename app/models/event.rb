class Event < ApplicationRecord
  has_many :games, dependent: :destroy

  validates :name, presence: true
  validates :year, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: Date.current.year }
  validates :category, presence: true

  CATEGORIES = %w[Tech Sports History Culture].freeze

  scope :by_category, ->(category) { where(category: category) }
  scope :random, -> { order("RANDOM()") }

  def self.random_event
    order("RANDOM()").first
  end
end
