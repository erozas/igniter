FactoryBot.define do
  factory :user do
    sequence(:username) { |n| "username#{n}" }
    sequence(:email) { |n| "person#{n}@example.com" }
    sequence(:first_name) { FFaker::Name.first_name }
    sequence(:last_name) { FFaker::Name.last_name }
    password  { Devise.friendly_token.first(10) }
    admin {false}

    trait :admin do
	   admin {true}    	
    end
  end
end