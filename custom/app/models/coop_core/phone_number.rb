# Argentine phone number matching helper (design §8.3, R11). The WhatsApp
# Business API routinely drops the mobile `9` marker (+54 9 AAA NNNNNNN), so
# ContactLinkable matches producers against both forms rather than a single
# stored form. A PORO, same shape as CoopCore::Producer::Cuit -- trivially
# unit-testable and reusable outside a model context.
class CoopCore::PhoneNumber
  AR_PREFIX = '+54'.freeze
  AR_MOBILE_MARKER = '9'.freeze
  AR_MARKED_PREFIX = "#{AR_PREFIX}#{AR_MOBILE_MARKER}".freeze
  AR_PREFIX_REGEXP = /\A#{Regexp.escape(AR_PREFIX)}/
  AR_MARKED_PREFIX_REGEXP = /\A#{Regexp.escape(AR_MARKED_PREFIX)}/

  class << self
    # Always returns [with_marker, without_marker] for an AR number,
    # regardless of which form was passed in -- callers query
    # `primary_phone IN ar_variants(...)` so both forms must be present no
    # matter which one is canonical for a given producer. Non-AR numbers (and
    # a bare "+54" with nothing to manipulate) are ambiguous outside this
    # scheme, so they pass through unchanged as a single-element array.
    def ar_variants(e164)
      digits = e164.to_s
      return [e164] unless ar_number?(digits)

      [with_marker(digits), without_marker(digits)]
    end

    private

    def ar_number?(digits)
      digits.start_with?(AR_PREFIX) && digits.length > AR_PREFIX.length
    end

    def marked?(digits)
      digits.start_with?(AR_MARKED_PREFIX)
    end

    def with_marker(digits)
      return digits if marked?(digits)

      digits.sub(AR_PREFIX_REGEXP, AR_MARKED_PREFIX)
    end

    def without_marker(digits)
      return digits unless marked?(digits)

      digits.sub(AR_MARKED_PREFIX_REGEXP, AR_PREFIX)
    end
  end
end
