FactoryBot.define do
  factory :coop_core_cooperative_profile, class: 'CoopCore::CooperativeProfile' do
    account
    sequence(:legal_name) { |n| "Cooperativa Agropecuaria #{n}" }
  end
end
