require 'rails_helper'

RSpec.describe AutoReceiveDossiersForProcedureJob, type: :job do
  describe "perform" do
    let(:date) { Time.utc(2017, 9, 1, 10, 5, 0) }

    before { Timecop.freeze(date) }
    after { Timecop.return }

    subject { AutoReceiveDossiersForProcedureJob.new.perform(procedure_id, state) }

    context "with some dossiers" do
      let(:nouveau_dossier1) { create(:dossier, :en_construction) }
      let(:nouveau_dossier2) { create(:dossier, :en_construction, procedure: nouveau_dossier1.procedure) }
      let(:dossier_recu) { create(:dossier, :en_instruction, procedure: nouveau_dossier2.procedure) }
      let(:dossier_brouillon) { create(:dossier, procedure: dossier_recu.procedure) }
      let(:procedure_id) { dossier_brouillon.procedure_id }

      context "en_construction" do
        let(:state) { Dossier.states.fetch(:en_instruction) }

        it do
          subject
          expect(nouveau_dossier1.reload.en_instruction?).to be true
          expect(nouveau_dossier1.reload.en_instruction_at).to eq(date)

          expect(nouveau_dossier2.reload.en_instruction?).to be true
          expect(nouveau_dossier2.reload.en_instruction_at).to eq(date)

          expect(dossier_recu.reload.en_instruction?).to be true
          expect(dossier_recu.reload.en_instruction_at).to eq(date)

          expect(dossier_brouillon.reload.brouillon?).to be true
          expect(dossier_brouillon.reload.en_instruction_at).to eq(nil)
        end
      end

      context "accepte" do
        let(:state) { Dossier.states.fetch(:accepte) }

        it do
          subject
          expect(nouveau_dossier1.reload.accepte?).to be true
          expect(nouveau_dossier1.reload.en_instruction_at).to eq(date)
          expect(nouveau_dossier1.reload.processed_at).to eq(date)

          expect(nouveau_dossier2.reload.accepte?).to be true
          expect(nouveau_dossier2.reload.en_instruction_at).to eq(date)
          expect(nouveau_dossier2.reload.processed_at).to eq(date)

          expect(dossier_recu.reload.en_instruction?).to be true
          expect(dossier_recu.reload.en_instruction_at).to eq(date)
          expect(dossier_recu.reload.processed_at).to eq(nil)

          expect(dossier_brouillon.reload.brouillon?).to be true
          expect(dossier_brouillon.reload.en_instruction_at).to eq(nil)
          expect(dossier_brouillon.reload.processed_at).to eq(nil)
        end
      end
    end
  end
end
