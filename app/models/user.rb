class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :games, dependent: :destroy

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, allow_nil: true, length: { minimum: 12 }

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  generates_token_for :password_reset, expires_in: 20.minutes do
    password_salt&.last(10)
  end

  def current_game
    games.current_game
  end

  def anonymous?
    false
  end
end
