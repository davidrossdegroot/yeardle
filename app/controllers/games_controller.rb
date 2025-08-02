class GamesController < ApplicationController
  allow_unauthenticated_access # Allow anonymous users to play

  def index
    @current_game = current_user.current_game || create_new_game_for_user
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
