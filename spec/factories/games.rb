FactoryBot.define do
  factory :game do
    user
    event
    completed_at { nil }
    won { false }

    trait :completed do
      completed_at { Time.current }
    end

    trait :won do
      completed_at { Time.current }
      won { true }
    end

    trait :lost do
      completed_at { Time.current }
      won { false }
    end
  end
end
