require 'spec_helper'

describe TypeDeChamps do
  describe 'database columns' do
    it { is_expected.to have_db_column(:libelle) }
    it { is_expected.to have_db_column(:type) }
    it { is_expected.to have_db_column(:order_place) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:procedure) }
  end

  describe 'validation' do
    context 'libelle' do
      it { is_expected.not_to allow_value(nil).for(:libelle) }
      it { is_expected.not_to allow_value('').for(:libelle) }
      it { is_expected.to allow_value('Montant projet').for(:libelle) }
    end

    context 'type' do
      it { is_expected.not_to allow_value(nil).for(:type) }
      it { is_expected.not_to allow_value('').for(:type) }

      it { is_expected.to allow_value('text').for(:type) }
      it { is_expected.to allow_value('textarea').for(:type) }
      it { is_expected.to allow_value('datetime').for(:type) }
      it { is_expected.to allow_value('number').for(:type) }
    end

    context 'order_place' do
      it { is_expected.not_to allow_value(nil).for(:order_place) }
      it { is_expected.not_to allow_value('').for(:order_place) }
      it { is_expected.to allow_value(1).for(:order_place) }
    end
  end
end
