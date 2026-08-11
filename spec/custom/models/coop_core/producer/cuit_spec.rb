# frozen_string_literal: true

require 'rails_helper'

# Pure domain logic (mod-11 CUIT validation, design §3/Domain 3) -- unit-tested
# directly against the PORO rather than only through CoopCore::Producer's
# validation, per rspec-best-practices ("pure domain logic -> model or PORO
# service spec"). CoopCore::Producer's own spec covers how the model wires
# this in (uniqueness scope, normalization on save).
RSpec.describe CoopCore::Producer::Cuit do
  describe '.valid?' do
    context 'with a valid mod-11 CUIT (spec Domain 3 example: 20-12345678-6, sum=148, remainder=5, check digit=6)' do
      it 'returns true' do
        expect(described_class.valid?('20-12345678-6')).to be true
      end
    end

    context 'with an 11-digit CUIT whose check digit does not match the mod-11 result' do
      it 'returns false' do
        expect(described_class.valid?('20-12345678-0')).to be false
      end
    end

    context 'with a correct check digit but an unknown type prefix' do
      it 'returns false' do
        # base digits 9912345678 -> sum 219, remainder 219 % 11 = 10,
        # check digit = 11 - 10 = 1. The check digit is correct, isolating
        # the prefix failure from the check-digit failure.
        expect(described_class.valid?('99-12345678-1')).to be false
      end
    end

    context 'with base digits whose weighted sum has remainder 1 (no valid check digit exists)' do
      it 'returns false for every possible trailing digit' do
        # base digits 2001000000 -> weighted sum 12, remainder 12 % 11 = 1,
        # which maps to no valid check digit (Domain 3: remainder 1 has no
        # solution). Every trailing digit must therefore be rejected.
        aggregate_failures do
          expect(described_class.valid?('20-01000000-0')).to be false
          expect(described_class.valid?('20-01000000-1')).to be false
        end
      end
    end

    context 'with fewer than 11 digits' do
      it 'returns false' do
        expect(described_class.valid?('20-1234567-6')).to be false
      end
    end

    context 'with a blank value' do
      it 'returns false' do
        expect(described_class.valid?('')).to be false
      end
    end
  end

  describe '.normalize' do
    it 'strips separators down to 11 digits' do
      expect(described_class.normalize('20-12345678-6')).to eq('20123456786')
    end
  end

  describe '.format' do
    context 'with a normalized 11-digit CUIT' do
      it 'renders the XX-XXXXXXXX-X display form' do
        expect(described_class.format('20123456786')).to eq('20-12345678-6')
      end
    end

    context 'with an incomplete value' do
      it 'returns the original value unchanged' do
        expect(described_class.format('123')).to eq('123')
      end
    end
  end
end
