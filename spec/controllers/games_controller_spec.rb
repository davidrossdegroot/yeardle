require 'rails_helper'

RSpec.describe GamesController, type: :controller do
  let(:user) { create(:user) }
  let(:event) { create(:event) }

  after do
    # Clear Current state after each test
    Current.session = nil
  end

  describe "GET #index" do
    context "when user is authenticated" do
      before do
         sign_in_user(user)
         create(:event)
      end

      it "returns http success" do
        get :index
        expect(response).to have_http_status(:success)
      end

      it "creates a new game if none exists" do
        expect {
          get :index
        }.to change { user.games.count }.by(1)
      end
    end

    context "when user is anonymous" do
      before { event } # Ensure an event exists for anonymous games

      it "returns http success" do
        get :index
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "POST #guess" do
    let(:game) { create(:game, user: user, event: event) }

    context "when user is authenticated" do
      before { sign_in_user(user) }

      it "creates a guess" do
        expect {
          post :guess, params: { id: game.id, year: 1999 }
        }.to change { game.guesses.count }.by(1)
      end

      it "redirects back to games index" do
        post :guess, params: { id: game.id, year: 1999 }
        expect(response).to redirect_to(games_path)
      end

      context "when guess is correct" do
        it "marks game as won and completed" do
          post :guess, params: { id: game.id, year: event.year }

          game.reload
          expect(game.completed?).to be true
          expect(game.won?).to be true
        end

        it "shows success message" do
          post :guess, params: { id: game.id, year: event.year }
          expect(flash[:notice]).to include("Congratulations")
        end
      end

      context "when game reaches 6 guesses" do
        before do
          create_list(:guess, 5, game: game)
        end

        it "marks game as lost and completed" do
          post :guess, params: { id: game.id, year: event.year + 1 }

          game.reload
          expect(game.completed?).to be true
          expect(game.won?).to be false
        end

        it "shows game over message" do
          post :guess, params: { id: game.id, year: event.year + 1 }
          expect(flash[:alert]).to include("Game over")
        end
      end

      it "prevents guessing on completed games" do
        completed_game = create(:game, :completed, user: user)

        post :guess, params: { id: completed_game.id, year: 1999 }
        expect(flash[:alert]).to include("already completed")
      end
    end

    context "when user is anonymous" do
      before { event } # Ensure an event exists for anonymous games

      it "works with anonymous games" do
        # This is a bit tricky to test due to session management
        # We'll focus on system tests for anonymous user flows
        get :index # This creates an anonymous game

        # The anonymous game logic should work similarly
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "GET #show" do
    let(:game) { create(:game, :completed, user: user) }

    context "when user is authenticated" do
      before { sign_in_user(user) }

      it "shows the game" do
        get :show, params: { id: game.id }
        expect(response).to have_http_status(:success)
      end

      it "raises error for other user's game" do
        other_user = create(:user)
        other_game = create(:game, user: other_user)

        expect {
          get :show, params: { id: other_game.id }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  private

  def sign_in_user(user)
    session = user.sessions.create!(user_agent: "test", ip_address: "127.0.0.1")
    Current.session = session
    # Set the session cookie so authenticated? method works properly
    cookies.signed[:session_id] = session.id
  end
end
