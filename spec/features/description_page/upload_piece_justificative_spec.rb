require 'spec_helper'

feature 'user is on description page' do
  let(:dossier) { create(:dossier, :with_entreprise, :with_procedure) }
  before do
    visit dossier_description_path dossier
  end
  it { expect(page).to have_css('#description_page') }

  context 'he fill description fields' do
    before do
      find_by_id('nom_projet').set 'mon nom'
      find_by_id('description').set 'ma description'
      find_by_id('montant_projet').set 10_000
      find_by_id('montant_aide_demande').set 100
      find_by_id('date_previsionnelle').set '10/10/2010'
    end
    context 'before submit' do
      it 'dossier cerfa is empty' do
        expect(dossier.cerfa).to be_empty
      end
      it 'pieces_justificatives are empty' do
        dossier.pieces_justificatives.each do |piece_justificative|
          expect(piece_justificative).to be_empty
        end
      end
    end
    context 'he adds cerfa' do
      before do
        attach_file('cerfa_pdf', File.path('spec/support/files/dossierPDF.pdf'))
        click_on("Terminer la procédure")
        dossier.reload
      end
      it 'fills dossier cerfa' do
        expect(dossier.cerfa).not_to be_empty
      end
    end
    context 'when he adds a piece_justificative and submit form' do
      before do
        file_input_id = 'piece_justificative_' + dossier.pieces_justificatives.first.type.to_s
        attach_file(file_input_id, File.path('spec/support/files/dossierPDF.pdf'))
        click_on('Terminer la procédure')
        dossier.reload
      end
      scenario 'fills the given piece_justificative' do
        expect(dossier.pieces_justificatives.first).not_to be_empty
      end
    end
  end
end