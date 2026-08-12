# Synchronous producers export (design §6.4/§13 S7 -- F1 ships no exports
# table, no ActiveStorage, no async job; the caller is responsible for
# capping the relation at ChatwootApp.max_limit, see
# Api::V1::Accounts::Coop::ProducersController#export). Locale-neutral data
# contract (design §6.3): ISO-8601 timestamps, E.164 phone (already how
# Producer#primary_phone is stored), 11-digit cuit plus the cuit_formatted
# convenience column -- the same row shape backs both the CSV and JSON
# export formats so an ERP integration gets identical values either way.
#
# Placed under custom/app/models/coop_core/export/ (an implicit Zeitwerk
# namespace -- there is no export.rb sibling file, same pattern as
# custom/app/models/custom/concerns/) rather than custom/app/services/,
# because that directory doesn't exist yet in this fork and the locked
# design §2 directory tree already puts `export/{producers,...}_csv.rb`
# under coop_core/, not under a not-yet-existing services root.
class CoopCore::Export::ProducersCsv
  HEADERS = %w[
    id business_name trade_name producer_type cuit cuit_formatted
    primary_phone email status branch_id contact_id external_ref
    created_at updated_at
  ].freeze

  def initialize(producers)
    @producers = producers
  end

  def call
    CSV.generate do |csv|
      csv << HEADERS
      rows.each { |row| csv << HEADERS.map { |header| row[header] } }
    end
  end

  def rows
    @producers.map { |producer| row_for(producer) }
  end

  private

  def row_for(producer)
    HEADERS.index_with { |header| value_for(producer, header) }
  end

  def value_for(producer, header)
    case header
    when 'created_at', 'updated_at'
      producer.public_send(header)&.iso8601
    else
      producer.public_send(header)
    end
  end
end
