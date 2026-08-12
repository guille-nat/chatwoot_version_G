FactoryBot.define do
  factory :coop_core_plot, class: 'CoopCore::Plot' do
    account
    field { association :coop_core_field, account: account }
    sequence(:name) { |n| "Lote #{n}" }
  end
end
