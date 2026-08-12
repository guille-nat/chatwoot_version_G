# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CoopCore::StaffRole, type: :model do
  let(:account) { create(:account) }

  describe 'validations' do
    it 'is invalid without a key' do
      role = build(:coop_core_staff_role, account: account, key: nil)

      expect(role).not_to be_valid
    end

    it 'is invalid without a name' do
      role = build(:coop_core_staff_role, account: account, name: nil)

      expect(role).not_to be_valid
    end

    it 'is invalid with a duplicate key within the same account' do
      create(:coop_core_staff_role, account: account, key: 'operador')
      duplicate = build(:coop_core_staff_role, account: account, key: 'operador')

      expect(duplicate).not_to be_valid
    end

    it 'is valid with the same key under a different account' do
      other_account = create(:account)
      create(:coop_core_staff_role, account: account, key: 'operador')
      other_role = build(:coop_core_staff_role, account: other_account, key: 'operador')

      expect(other_role).to be_valid
    end

    it 'is valid with a known permission' do
      role = build(:coop_core_staff_role, account: account, permissions: ['producers_read'])

      expect(role).to be_valid
    end

    it 'is invalid with an unknown permission' do
      role = build(:coop_core_staff_role, account: account, permissions: %w[producers_read time_travel])

      expect(role).not_to be_valid
    end
  end

  describe 'defaults' do
    it 'defaults system to false' do
      role = described_class.new

      expect(role.system).to be false
    end

    it 'defaults permissions to an empty array' do
      role = described_class.new

      expect(role.permissions).to eq([])
    end
  end

  describe '#destroy' do
    context 'when the role is a system role' do
      it 'does not destroy the role' do
        role = create(:coop_core_staff_role, account: account, system: true)

        role.destroy

        expect(described_class.exists?(role.id)).to be true
      end

      it 'adds an error' do
        role = create(:coop_core_staff_role, account: account, system: true)

        role.destroy

        expect(role.errors[:base]).to be_present
      end
    end

    context 'when the role is not a system role' do
      it 'destroys the role' do
        role = create(:coop_core_staff_role, account: account, system: false)

        role.destroy

        expect(described_class.exists?(role.id)).to be false
      end
    end

    context 'when a system role is destroyed as part of Account#destroy!' do
      it 'does not block the account destroy' do
        create(:coop_core_staff_role, account: account, system: true)

        expect { account.destroy! }.not_to raise_error
      end

      it 'destroys the system role along with the account' do
        role = create(:coop_core_staff_role, account: account, system: true)

        account.destroy!

        expect(described_class.exists?(role.id)).to be false
      end
    end
  end

  describe 'auditing' do
    it 'is audited' do
      expect(described_class.auditing_enabled).to be true
    end
  end

  describe '.ensure_seeded!' do
    it 'creates one role per seeded key' do
      expect { described_class.ensure_seeded!(account) }.to change(described_class, :count).by(6)
    end

    it 'creates the seeded roles as system roles' do
      described_class.ensure_seeded!(account)

      expect(described_class.where(account: account).pluck(:system)).to all(be true)
    end

    it 'grants gerente every read permission plus manage permissions' do
      described_class.ensure_seeded!(account)

      gerente = described_class.find_by(account: account, key: 'gerente')

      expect(gerente.permissions).to include('producers_read', 'producers_manage', 'branches_manage',
                                             'staff_manage', 'modules_manage', 'audit_read', 'export_data')
    end

    it 'grants operador only read permissions' do
      described_class.ensure_seeded!(account)

      operador = described_class.find_by(account: account, key: 'operador')

      expect(operador.permissions).to match_array(
        %w[producers_read fields_read plots_read crops_read branches_read staff_read modules_read]
      )
    end

    it 'does not reset permissions edited after seeding' do
      described_class.ensure_seeded!(account)
      operador = described_class.find_by(account: account, key: 'operador')
      operador.update!(permissions: ['producers_read'])

      described_class.ensure_seeded!(account)

      expect(operador.reload.permissions).to eq(['producers_read'])
    end

    it 'is idempotent' do
      described_class.ensure_seeded!(account)

      expect { described_class.ensure_seeded!(account) }.not_to change(described_class, :count)
    end

    context 'when a concurrent request wins the race on the unique index' do
      before do
        # Simulates two concurrent first-index requests both passing the
        # find_or_create_by! SELECT before either INSERTs: the first call
        # raises RecordNotUnique (as Postgres would once a concurrent
        # transaction's INSERT commits first), the real implementation
        # underneath is left untouched for every other seed key.
        call_count = 0
        allow(described_class).to receive(:find_or_create_by!).and_wrap_original do |method, *args, &block|
          call_count += 1
          raise ActiveRecord::RecordNotUnique, 'duplicate key value violates unique constraint' if call_count == 1

          method.call(*args, &block)
        end
      end

      it 'does not raise' do
        expect { described_class.ensure_seeded!(account) }.not_to raise_error
      end

      it 'still creates one role per seeded key' do
        expect { described_class.ensure_seeded!(account) }.to change(described_class, :count).by(6)
      end
    end
  end
end
