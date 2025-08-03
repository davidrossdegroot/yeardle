class GamesController < ApplicationController
  allow_unauthenticated_access # Allow anonymous users to play

  def index
    # Ensure we only have one incomplete game per user (for authenticated users)
    if authenticated?
      incomplete_games = current_user.games.where(completed_at: nil)

      if incomplete_games.count > 1
        # If somehow there are multiple incomplete games, complete the old ones
        incomplete_games.order(created_at: :asc).limit(incomplete_games.count - 1).update_all(completed_at: Time.current, won: false)
      end
    end

    @current_game = current_user.current_game

    # Only create a new game if there's no current game AND no completed game to show
    if @current_game.nil?
      @current_game = create_new_game_for_user
    elsif @current_game.completed? && params[:new_game]
      # If user explicitly requests a new game, clear the completed one and create new
      @current_game = create_new_game_for_user
    end

    @previous_games = authenticated? ? current_user.games.completed.recent.limit(10) : []
  end

  def show
    @game = find_game_for_user(params[:id])
  end

  def guess
    @game = find_game_for_user(params[:id])
    year = params[:year].to_i

    if @game.completed?
      if authenticated?
        redirect_to @game, alert: "This game is already completed."
      else
        redirect_to games_path, alert: "This game is already completed."
      end
      return
    end

    guess = @game.guesses.create!(year: year)

    if guess.correct?
      @game.update!(completed_at: Time.current, won: true)
      if authenticated?
        redirect_to @game, notice: "Congratulations! You guessed correctly!"
      else
        redirect_to games_path, notice: "Congratulations! You guessed correctly!"
      end
    elsif @game.guesses.count >= 6
      @game.update!(completed_at: Time.current, won: false)
      if authenticated?
        redirect_to @game, alert: "Game over! The correct year was #{@game.event.year}."
      else
        redirect_to games_path, alert: "Game over! The correct year was #{@game.event.year}."
      end
    else
      redirect_to games_path
    end
  end

  private

  def create_new_game_for_user
    # For anonymous users, clear any existing completed game first
    if !authenticated? && current_user.current_game&.completed?
      Rails.cache.delete("anonymous_game_#{current_user.session_id}")
    end

    if authenticated?
      Game.create_new_game(current_user)
    else
      current_user.games.create_new_game
    end
  end

  def find_game_for_user(id)
    if authenticated?
      current_user.games.find(id)
    else
      current_user.games.find(id)
    end
  end

  def game_params
    params.require(:game).permit(:year)
  end
end
