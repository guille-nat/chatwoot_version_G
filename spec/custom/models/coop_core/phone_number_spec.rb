# frozen_string_literal: true

require 'rails_helper'

# R11: the WhatsApp Business API routinely drops the Argentine mobile `9`
# marker (+54 9 AAA NNNNNNN), so matching on a single stored form silently
# fails for a large share of real producers. #ar_variants always returns
# both forms for an AR number so callers can match regardless of which form
# is stored/received.
RSpec.describe CoopCore::PhoneNumber do
  describe '.ar_variants' do
    context 'when the number already carries the Argentine mobile marker' do
      it 'returns the marker form' do
        expect(described_class.ar_variants('+5491122334455')).to include('+5491122334455')
      end

      it 'returns the no-marker form' do
        expect(described_class.ar_variants('+5491122334455')).to include('+541122334455')
      end

      it 'returns exactly two variants' do
        expect(described_class.ar_variants('+5491122334455').size).to eq(2)
      end
    end

    context 'when the number omits the Argentine mobile marker' do
      it 'returns the marker form' do
        expect(described_class.ar_variants('+541122334455')).to include('+5491122334455')
      end

      it 'returns the no-marker form' do
        expect(described_class.ar_variants('+541122334455')).to include('+541122334455')
      end
    end

    context 'when the number is not Argentine' do
      it 'returns only the original number' do
        expect(described_class.ar_variants('+12025550179')).to eq(['+12025550179'])
      end
    end

    context 'when the number is blank' do
      it 'returns the input unchanged' do
        expect(described_class.ar_variants(nil)).to eq([nil])
      end
    end

    context 'when the number is just the Argentine country code' do
      it 'returns the input unchanged' do
        expect(described_class.ar_variants('+54')).to eq(['+54'])
      end
    end
  end
end
