# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CoopCore::Plot, type: :model do
  let(:account) { create(:account) }
  let(:producer) { create(:coop_core_producer, account: account) }
  let(:field) { create(:coop_core_field, account: account, producer: producer) }

  describe 'validations' do
    it 'is invalid without a name' do
      plot = build(:coop_core_plot, account: account, field: field, name: nil)

      expect(plot).not_to be_valid
    end

    it 'is invalid without a field' do
      plot = build(:coop_core_plot, account: account, field: nil)

      expect(plot).not_to be_valid
    end

    it 'is valid with only a name and a field' do
      plot = build(:coop_core_plot, account: account, field: field)

      expect(plot).to be_valid
    end

    context 'with a duplicate name (case-insensitive) under the same field' do
      it 'is invalid' do
        create(:coop_core_plot, account: account, field: field, name: 'Lote 1')
        duplicate = build(:coop_core_plot, account: account, field: field, name: 'lote 1')

        expect(duplicate).not_to be_valid
      end
    end

    context 'with the same name under a different field' do
      it 'is valid' do
        create(:coop_core_plot, account: account, field: field, name: 'Lote 1')
        other_field = create(:coop_core_field, account: account, producer: producer)
        other_plot = build(:coop_core_plot, account: account, field: other_field, name: 'Lote 1')

        expect(other_plot).to be_valid
      end
    end

    context 'with a negative hectares' do
      it 'is invalid' do
        plot = build(:coop_core_plot, account: account, field: field, hectares: -1)

        expect(plot).not_to be_valid
      end
    end

    context 'when the account does not match the field account' do
      it 'is invalid' do
        other_account = create(:account)
        plot = build(:coop_core_plot, account: other_account, field: field)

        expect(plot).not_to be_valid
      end
    end
  end

  describe 'geometry' do
    it 'stores a GeoJSON polygon' do
      geojson = { 'type' => 'Polygon', 'coordinates' => [[[-60.0, -33.0], [-60.1, -33.0], [-60.1, -33.1], [-60.0, -33.0]]] }
      plot = create(:coop_core_plot, account: account, field: field, geometry: geojson)

      expect(plot.reload.geometry).to eq(geojson)
    end
  end

  describe 'associations' do
    it 'destroys its crops when destroyed' do
      plot = create(:coop_core_plot, account: account, field: field)
      crop = create(:coop_core_crop, account: account, plot: plot)

      plot.destroy!

      expect(CoopCore::Crop.exists?(crop.id)).to be false
    end
  end

  describe 'auditing' do
    it 'is audited' do
      expect(described_class.auditing_enabled).to be true
    end
  end
end
