class AnonymousUser
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :session_id

  def initialize(session_id = nil)
    @session_id = session_id || SecureRandom.hex(16)
    super()
  end

  def session_id
    @session_id
  end

  def id
    "anonymous_#{@session_id}"
  end

  def games
    @games ||= AnonymousUserGames.new(self)
  end

  def current_game
    games.current_game
  end

  def persisted?
    false
  end

  def anonymous?
    true
  end
end

class AnonymousUserGames
  def initialize(anonymous_user)
    @anonymous_user = anonymous_user
    @session_id = anonymous_user.session_id
  end

  def current_game
    # Store current game in session
    if Rails.cache.exist?("anonymous_game_#{@session_id}")
      game_data = Rails.cache.read("anonymous_game_#{@session_id}")
      # For anonymous users, return completed games so they can see the result
      # The controller/view will handle creating a new game when needed

      # Reconstruct the game object
      begin
        event = Event.find(game_data[:event_id])
        AnonymousGame.new(
          id: game_data[:id],
          event: event,
          guesses_data: game_data[:guesses] || [],
          completed_at: game_data[:completed_at],
          won: game_data[:won],
          session_id: @session_id
        )
      rescue ActiveRecord::RecordNotFound
        # If the event doesn't exist, return nil
        nil
      end
    else
      nil
    end
  end

  def create_new_game
    event = Event.random_event
    game_id = SecureRandom.hex(8)

    game_data = {
      id: game_id,
      event_id: event.id,
      guesses: [],
      completed_at: nil,
      won: false
    }

    Rails.cache.write("anonymous_game_#{@session_id}", game_data, expires_in: 24.hours)

    AnonymousGame.new(
      id: game_id,
      event: event,
      guesses_data: [],
      completed_at: nil,
      won: false,
      session_id: @session_id
    )
  end

  def completed
    AnonymousUserGamesScope.new(@session_id, :completed)
  end

  def find(id)
    # For anonymous users, we'll just return the current game if the ID matches
    current = current_game
    if current && current.id.to_s == id.to_s
      current
    else
      raise ActiveRecord::RecordNotFound
    end
  end
end

class AnonymousUserGamesScope
  def initialize(session_id, scope)
    @session_id = session_id
    @scope = scope
  end

  def recent
    self
  end

  def limit(count)
    [] # For simplicity, anonymous users don't see previous games
  end
end
