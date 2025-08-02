FactoryBot.define do
  factory :event do
    sequence(:name) { |n| "Test Event #{n}" }
    year { rand(1900..2024) }
    category { %w[Tech Sports History Culture].sample }
    description { "A description of the test event" }
  end

  factory :tech_event, parent: :event do
    name { "iPhone Release" }
    year { 2007 }
    category { "Tech" }
    description { "Apple releases the first iPhone" }
  end

  factory :sports_event, parent: :event do
    name { "First World Cup" }
    year { 1930 }
    category { "Sports" }
    description { "The first FIFA World Cup held in Uruguay" }
  end

  factory :history_event, parent: :event do
    name { "Moon Landing" }
    year { 1969 }
    category { "History" }
    description { "Apollo 11 lands on the moon" }
  end
end
