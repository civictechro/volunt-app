FactoryGirl.define do
  factory :volunteer, class: User do
    email 'volunteer@example.com'
    flags LoginConcern::USER_LEVEL_VOLUNTEER

    after(:create) do |volunteer|
      create(:profile, email: volunteer.email, flags: Profile::PROFILE_FLAG_VOLUNTEER)
    end
  end
end