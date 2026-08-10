# Auto-included into ::Account by the existing Account.include_mod_with('Concerns::Account')
# call (app/models/account.rb) -- zero core edits required (design D4).
module Custom::Concerns::Account
  extend ActiveSupport::Concern

  included do
    # No :dependent option yet -- coop_core_producers doesn't exist until S4a's
    # migration lands (CoopCore::Producer is a table-less S1 stub). Adding
    # :destroy/:destroy_async now would make every Account#destroy touch a
    # table that doesn't exist. Revisit the cascade behavior when S4a ships.
    # rubocop:disable Rails/HasManyOrHasOneDependent
    has_many :coop_producers, class_name: 'CoopCore::Producer'
    # rubocop:enable Rails/HasManyOrHasOneDependent

    # coop_core_cooperative_profiles and coop_core_branches land in S2, so
    # :destroy_async is safe here (matches the has_many convention used
    # throughout this file -- see app/models/account.rb).
    has_one :coop_cooperative_profile, class_name: 'CoopCore::CooperativeProfile', dependent: :destroy_async
    has_many :coop_branches, class_name: 'CoopCore::Branch', dependent: :destroy_async

    # coop_core_module_settings lands in S3, alongside the tables above.
    has_many :coop_module_settings, class_name: 'CoopCore::ModuleSetting', dependent: :destroy_async
  end
end
