class ValidateCoopCoreProducersContactIdForeignKey < ActiveRecord::Migration[7.1]
  def change
    # coop_core_producers is empty at deploy time (brand-new table), so
    # validating here is instant -- but keeping it as its own migration
    # documents the two-step pattern for the next time this FK touches
    # `contacts` on a populated table (design §4.1).
    validate_foreign_key :coop_core_producers, :contacts
  end
end
