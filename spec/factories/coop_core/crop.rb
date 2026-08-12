FactoryBot.define do
  factory :coop_core_crop, class: 'CoopCore::Crop' do
    account
    plot { association :coop_core_plot, account: account }
    species { 'soja' }
    campaign { '2025/26' }
  end
end
