# CUIT (Clave Única de Identificación Tributaria) structural + mod-11
# check-digit validation (design §3/Domain 3). A PORO, not an
# ActiveModel::EachValidator, so it stays trivially unit-testable and
# reusable outside a model context (e.g. import/export in a later slice).
class CoopCore::Producer::Cuit
  # Known AR CUIT type prefixes: 20/23/24/26/27 persona física,
  # 25 extranjero, 30/33/34 persona jurídica.
  PREFIXES = %w[20 23 24 25 26 27 30 33 34].freeze
  WEIGHTS = [5, 4, 3, 2, 7, 6, 5, 4, 3, 2].freeze

  class << self
    def normalize(raw)
      raw.to_s.gsub(/\D/, '')
    end

    def valid?(raw)
      digits = normalize(raw)
      return false if digits.length != 11
      return false unless PREFIXES.include?(digits[0, 2])

      digits[10].to_i == check_digit(digits[0, 10])
    end

    def format(raw)
      digits = normalize(raw)
      return raw if digits.length != 11

      "#{digits[0, 2]}-#{digits[2, 8]}-#{digits[10]}"
    end

    private

    # weights 5,4,3,2,7,6,5,4,3,2 over the first 10 digits; remainder = sum
    # mod 11; check digit = 11 - remainder, wrapping 11 -> 0; remainder 1 has
    # no valid check digit (returns -1, which no real digit ever equals).
    def check_digit(first_ten_digits)
      sum = first_ten_digits.chars.each_with_index.sum { |digit, index| digit.to_i * WEIGHTS[index] }
      remainder = sum % 11

      case remainder
      when 0 then 0
      when 1 then -1
      else 11 - remainder
      end
    end
  end
end
