FactoryBot.define do
  factory :guess do
    game
    year { rand(1900..2024) }
  end

  trait :correct do
    year { game.event.year }
  end

  trait :close do
    year { game.event.year + rand(-5..5) }
  end

  trait :far do
    year { game.event.year + rand(-50..-10) }
  end
end
