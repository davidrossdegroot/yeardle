require 'rails_helper'

RSpec.describe "Yeardle Game", type: :system do
  before do
    # Create some test events
    @tech_event = create(:tech_event)
    @sports_event = create(:sports_event)
    @history_event = create(:history_event)
  end

  describe "Anonymous User Gameplay" do
    context "when visiting the game as a guest" do
      it "shows the guest welcome message" do
        visit root_path

        expect(page).to have_content("🗓️ Yeardle")
        expect(page).to have_content("playing as a guest")
        expect(page).to have_content("Sign in to save your progress")
      end

      it "displays a random event to guess" do
        visit root_path

        expect(page).to have_content("Current Event")
        expect(page).to have_css(".bg-blue-50") # Event container
        expect(page).to have_field("What year did this happen?")
      end

      it "allows making guesses and shows feedback" do
        visit root_path

        # Find the current event year from the page (it's hidden but we can extract it)
        event_name = find(".bg-blue-50 p.text-blue-700").text
        current_event = Event.find_by(name: event_name)

        # Make an incorrect guess
        wrong_year = current_event.year + 10
        fill_in "What year did this happen?", with: wrong_year
        click_button "Guess"

        # Should show feedback
        expect(page).to have_content("years off")
        expect(page).to have_content("Attempts remaining: 5")
      end

      # xit this cause i don't think it works.
      it "completes the game when guessing correctly", js: true do
        visit root_path

        # Extract the event details
        event_name = find(".bg-blue-50 p.text-blue-700").text
        current_event = Event.find_by(name: event_name)

        # Make the correct guess
        fill_in "What year did this happen?", with: current_event.year, wait: 5
        click_button "Guess"

        # Should show success message
        expect(page).to have_content("🎉 Congratulations!")
        expect(page).to have_content("You guessed correctly")
        expect(page).to have_button("Play Again")
      end

      it "ends the game after 6 incorrect guesses" do
        visit root_path

        # Extract the event details
        event_name = find(".bg-blue-50 p.text-blue-700").text
        current_event = Event.find_by(name: event_name)
        # Make 6 incorrect guesses
        6.times do |i|
          wrong_year = current_event.year + (i + 1) * 10
          fill_in "What year did this happen?", with: wrong_year
          click_button "Guess"
          expect(page).to have_content("#{(i + 1) * 10} years off")
          expect(page).to have_content("Attempts remaining: #{5 - i}")
        end

        # Should show game over message
        expect(page).to have_content("😔 Game Over")
        expect(page).to have_content("The correct answer was")
        expect(page).to have_button("Play Again")
      end

      it "starts a new game when clicking Play Again" do
        visit root_path

        # Complete a game first
        event_name = find(".bg-blue-50 p.text-blue-700").text
        current_event = Event.find_by(name: event_name)

        fill_in "What year did this happen?", with: current_event.year
        click_button "Guess"

        expect(page).to have_button("Play Again")
        click_button "Play Again"

        # Should show a new game
        expect(page).to have_content("Current Event")
        expect(page).to have_field("What year did this happen?")
      end
    end
  end

  describe "Authenticated User Gameplay" do
    let(:user) { create(:user) }

    before do
      # Sign in the user
      visit new_session_path
      fill_in "email_address", with: user.email_address
      fill_in "password", with: user.password
      click_button "Sign in"
    end

    it "shows authenticated user interface" do
      visit root_path

      expect(page).to have_content("Hello, #{user.email_address}!")
      expect(page).to have_button("Sign out")
      expect(page).not_to have_content("Playing as a guest")
    end

    it "saves game progress for authenticated users" do
      visit root_path

      # Make a guess
      event_name = find(".bg-blue-50 p.text-blue-700").text
      current_event = Event.find_by(name: event_name)

      wrong_year = current_event.year + 5
      fill_in "What year did this happen?", with: wrong_year
      click_button "Guess"

      # Verify the game was saved to database
      expect(user.games.count).to eq(1)
      expect(user.games.first.guesses.count).to eq(1)
    end

    it "shows previous games for authenticated users" do
      # Create a completed game
      completed_game = create(:game, :won, user: user)
      create(:guess, :correct, game: completed_game)

      visit root_path

      expect(page).to have_content("Recent Games")
      expect(page).to have_content("✅") # Won indicator
    end

    it "can view detailed game results" do
      # Create a completed game with multiple guesses
      completed_game = create(:game, :won, user: user)
      create(:guess, game: completed_game, year: completed_game.event.year - 5)
      create(:guess, :correct, game: completed_game)

      visit game_path(completed_game)

      expect(page).to have_content("Game Results")
      expect(page).to have_content("🎉 You Won!")
      expect(page).to have_content("Completed in 2 guesses!")
      expect(page).to have_content("Your Guesses")
    end
  end

  describe "Navigation and Authentication" do
    let(:user) { create(:user) }

    it "allows guest users to sign in mid-game" do
      visit root_path

      # Start a game as guest
      event_name = find(".bg-blue-50 p.text-blue-700").text
      current_event = Event.find_by(name: event_name)

      wrong_year = current_event.year + 5
      fill_in "What year did this happen?", with: wrong_year
      click_button "Guess"

      # Sign in
      click_link "Sign in"
      fill_in "email_address", with: user.email_address
      fill_in "password", with: user.password
      click_button "Sign in"

      # Should be redirected back to game
      expect(page).to have_content("🗓️ Yeardle")
      expect(page).to have_content("Hello, #{user.email_address}!")
    end

    it "allows users to sign out" do
      # Sign in first
      visit new_session_path
      fill_in "email_address", with: user.email_address
      fill_in "password", with: user.password
      click_button "Sign in"

      # Sign out
      click_button "Sign out"

      expect(page).to have_content("Playing as Guest")
      expect(page).to have_link("Sign in")
    end
  end

  describe "Game Feedback and Mechanics" do
    it "provides appropriate feedback based on guess accuracy" do
      visit root_path

      event_name = find(".bg-blue-50 p.text-blue-700").text
      current_event = Event.find_by(name: event_name)
      correct_year = current_event.year

      # Test different levels of accuracy
      test_cases = [
        { guess: correct_year + 1, expected: "So close! 1 year off" },
        { guess: correct_year + 3, expected: "Very close! 3 years off" },
        { guess: correct_year + 8, expected: "Close! 8 years off" },
        { guess: correct_year + 20, expected: "Getting warmer! 20 years off" },
        { guess: correct_year + 50, expected: "50 years off" }
      ]

      test_cases.each do |test_case|
        # Start fresh game for each test
        visit root_path

        fill_in "What year did this happen?", with: test_case[:guess]
        click_button "Guess"

        expect(page).to have_content(test_case[:expected])
      end
    end

    it "shows direction hints (higher/lower)" do
      visit root_path

      event_name = find(".bg-blue-50 p.text-blue-700").text
      current_event = Event.find_by(name: event_name)

      # Guess too low
      fill_in "What year did this happen?", with: current_event.year - 10
      click_button "Guess"

      expect(page).to have_content("Try higher")

      # Start new game and guess too high
      visit root_path
      fill_in "What year did this happen?", with: current_event.year + 10
      click_button "Guess"

      expect(page).to have_content("Try lower")
    end
  end

  describe "Event Categories" do
    it "displays event categories" do
      visit root_path

      # Should show a category badge
      expect(page).to have_css(".bg-blue-100") # Category badge
      expect(page).to have_content(/Tech|Sports|History|Culture/)
    end
  end

  describe "Mobile Responsiveness" do
    it "works on mobile viewport", js: true do
      page.driver.browser.manage.window.resize_to(375, 667) # iPhone size

      visit root_path

      expect(page).to have_content("🗓️ Yeardle")
      expect(page).to have_field("What year did this happen?")
      expect(page).to have_button("Guess")
    end
  end
end
