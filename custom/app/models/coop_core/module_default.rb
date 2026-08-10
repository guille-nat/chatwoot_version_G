# Installation-scope default for a module (design §5.2, tier 6) -- the ONE
# CoopCore table with no account_id (design §4), since it applies to every
# cooperative on this deployment. Super-admin editable with no deploy
# (CLAUDE.md super-admin requirement); see lib/tasks/coop_core_modules.rake.
class CoopCore::ModuleDefault < CoopCore::ApplicationRecord
  audited

  validates :module_key, presence: true, uniqueness: true
  validates :enabled, inclusion: { in: [true, false] }

  CACHE_KEY = 'coop_core/v1/module_defaults'.freeze

  after_commit :expire_cache

  class << self
    # module_key => enabled, for every row that has ever been set. A module
    # with no row here falls through to the code default (tier 7).
    def cached_all
      Rails.cache.fetch(CACHE_KEY, expires_in: 5.minutes) { all.pluck(:module_key, :enabled).to_h }
    end

    def expire_cache
      Rails.cache.delete(CACHE_KEY)
    end
  end

  private

  def expire_cache
    self.class.expire_cache
  end
end
