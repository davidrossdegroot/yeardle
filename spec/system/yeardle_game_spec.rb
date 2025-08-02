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

      it "ends the game after 6 incorrect guesses" do
        visit root_path

        # Extract the event details
        event_name = find(".bg-blue-50 p.text-blue-700").text
        current_event = Event.find_by(name: event_name)

        # Make first 5 incorrect guesses
        5.times do |i|
          wrong_year = current_event.year + (i + 1) * 10

          fill_in "What year did this happen?", with: wrong_year
          click_button "Guess"

          expect(page).to have_content("#{(i + 1) * 10} years off")
          expect(page).to have_content("Attempts remaining: #{5 - i}")
        end

        # Make the 6th (final) incorrect guess
        wrong_year = current_event.year + 6 * 10

        fill_in "What year did this happen?", with: wrong_year
        click_button "Guess"

        # Should show game over message (no attempts remaining feedback since game is over)
        expect(page).to have_content("😔 Game Over")
        expect(page).to have_content("The correct answer was")
        expect(page).to have_link("Play Again")
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
      expect(page).to have_link("Sign out")
      expect(page).not_to have_content("Playing as a guest")
    end

    it "saves game progress for authenticated users" do
      # Make a guess
      event_name = find(".bg-blue-50 p.text-blue-700").text
      current_event = Event.find_by(name: event_name)

      wrong_year = current_event.year + 5
      fill_in "What year did this happen?", with: wrong_year
      click_button "Guess"

      # Verify the game and guess were saved to database
      user.reload
      game_with_guess = user.games.joins(:guesses).first
      expect(game_with_guess).to be_present
      expect(game_with_guess.guesses.count).to eq(1)
      expect(game_with_guess.guesses.first.year).to eq(wrong_year)
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

    it "ends the game after 6 incorrect guesses" do
      visit root_path

      # Extract the event details
      event_name = find(".bg-blue-50 p.text-blue-700").text
      current_event = Event.find_by(name: event_name)

      # Make first 5 incorrect guesses (using years that won't exceed validation limits)
      5.times do |i|
        # Use years before the event to avoid exceeding 2025 limit
        wrong_year = current_event.year - (i + 1) * 10

        fill_in "What year did this happen?", with: wrong_year
        click_button "Guess"

        expect(page).to have_content("#{(i + 1) * 10} years off")
        expect(page).to have_content("Attempts remaining: #{5 - i}")
      end

      # Make the 6th (final) incorrect guess
      wrong_year = current_event.year - 6 * 10

      fill_in "What year did this happen?", with: wrong_year
      click_button "Guess"

      # Should show game over message (no attempts remaining feedback since game is over)
      expect(page).to have_content("😔 Game Over")
      expect(page).to have_content("The correct answer was")
      expect(page).to have_link("Play Again")
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
      click_link "Sign in", match: :first
      fill_in "email_address", with: user.email_address
      fill_in "password", with: user.password
      click_button "Sign in", match: :first

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
      click_link "Sign out"

      expect(page).to have_content("Playing as Guest")
      expect(page).to have_link("Sign in")
    end

    describe "User Registration" do
      it "allows guest users to create a new account" do
        visit root_path

        # Click sign up from the navigation
        click_link "Sign up"

        expect(page).to have_content("Sign up")
        expect(page).to have_field("user_email_address")
        expect(page).to have_field("user_password")
        expect(page).to have_field("user_password_confirmation")
      end

      it "creates a new account with valid information" do
        visit new_user_path

        fill_in "user_email_address", with: "newuser@example.com"
        fill_in "user_password", with: "securepassword123"
        fill_in "user_password_confirmation", with: "securepassword123"
        click_button "Create Account"

        # Should be signed in automatically and redirected
        expect(page).to have_content("Welcome! Your account has been created.")
        expect(page).to have_content("Hello, newuser@example.com!")
        expect(page).to have_link("Sign out")

        # Verify user was created in database
        expect(User.find_by(email_address: "newuser@example.com")).to be_present
      end

      it "shows validation errors for invalid input" do
        visit new_user_path

        # Try to create account with invalid data
        fill_in "user_email_address", with: "invalid-email"
        fill_in "user_password", with: "short"
        fill_in "user_password_confirmation", with: "different"
        click_button "Create Account"

        # Should show errors
        expect(page).to have_content("Email address is invalid")
        expect(page).to have_content("Password is too short")
        expect(page).to have_content("Password confirmation doesn't match")
      end

      it "prevents duplicate email addresses" do
        create(:user, email_address: "taken@example.com")

        visit new_user_path

        fill_in "user_email_address", with: "taken@example.com"
        fill_in "user_password", with: "validpassword123"
        fill_in "user_password_confirmation", with: "validpassword123"
        click_button "Create Account"

        expect(page).to have_content("Email address has already been taken")
      end

      it "allows navigation between sign up and sign in" do
        visit new_user_path

        click_link "Sign in", match: :first
        expect(page).to have_content("Sign in")
        expect(page).to have_button("Sign in")

        click_link "Sign up", match: :first
        expect(page).to have_content("Sign up")
        expect(page).to have_button("Create Account")
      end

      it "preserves game progress when signing up mid-game" do
        visit root_path

        # Start a game as guest
        event_name = find(".bg-blue-50 p.text-blue-700").text
        current_event = Event.find_by(name: event_name)

        wrong_year = current_event.year + 5
        fill_in "What year did this happen?", with: wrong_year
        click_button "Guess"

        expect(page).to have_content("years off")

        # Sign up
        click_link "Sign up"
        fill_in "user_email_address", with: "newgamer@example.com"
        fill_in "user_password", with: "securepassword123"
        fill_in "user_password_confirmation", with: "securepassword123"
        click_button "Create Account"

        # Should be redirected back to game
        expect(page).to have_content("🗓️ Yeardle")
        expect(page).to have_content("Hello, newgamer@example.com!")

        # Game should still be in progress
        expect(page).to have_content("Current Event")
        expect(page).to have_field("What year did this happen?")
      end
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
