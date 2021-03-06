describe DossierSerializer do
  describe '#attributes' do
    subject { DossierSerializer.new(dossier).serializable_hash }

    context 'when the dossier is en_construction' do
      let(:dossier) { create(:dossier, :en_construction) }

      it { is_expected.to include(initiated_at: dossier.en_construction_at) }
      it { is_expected.to include(state: 'initiated') }
    end

    context 'when the dossier is en instruction' do
      let(:dossier) { create(:dossier, :en_instruction) }

      it { is_expected.to include(received_at: dossier.en_instruction_at) }
      it { is_expected.to include(state: 'received') }
    end

    context 'when the dossier is accepte' do
      let(:dossier) { create(:dossier, state: Dossier.states.fetch(:accepte)) }

      it { is_expected.to include(state: 'closed') }
    end

    context 'when the dossier is refuse' do
      let(:dossier) { create(:dossier, state: Dossier.states.fetch(:refuse)) }

      it { is_expected.to include(state: 'refused') }
    end

    context 'when the dossier is sans_suite' do
      let(:dossier) { create(:dossier, state: Dossier.states.fetch(:sans_suite)) }

      it { is_expected.to include(state: 'without_continuation') }
    end
  end
end
