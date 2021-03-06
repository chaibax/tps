require 'spec_helper'

describe Procedure do
  describe 'mail templates' do
    subject { create(:procedure) }

    it { expect(subject.initiated_mail_template).to be_a(Mails::InitiatedMail) }
    it { expect(subject.received_mail_template).to be_a(Mails::ReceivedMail) }
    it { expect(subject.closed_mail_template).to be_a(Mails::ClosedMail) }
    it { expect(subject.refused_mail_template).to be_a(Mails::RefusedMail) }
    it { expect(subject.without_continuation_mail_template).to be_a(Mails::WithoutContinuationMail) }
  end

  describe 'initiated_mail' do
    let(:procedure) { create(:procedure) }

    subject { procedure }

    context 'when initiated_mail is not customize' do
      it { expect(subject.initiated_mail_template.body).to eq(Mails::InitiatedMail.default_for_procedure(procedure).body) }
    end

    context 'when initiated_mail is customize' do
      before :each do
        subject.initiated_mail = Mails::InitiatedMail.new(body: 'sisi')
        subject.save
        subject.reload
      end
      it { expect(subject.initiated_mail_template.body).to eq('sisi') }
    end

    context 'when initiated_mail is customize ... again' do
      before :each do
        subject.initiated_mail = Mails::InitiatedMail.new(body: 'toto')
        subject.save
        subject.reload
      end
      it { expect(subject.initiated_mail_template.body).to eq('toto') }

      it { expect(Mails::InitiatedMail.count).to eq(1) }
    end
  end

  describe 'closed mail template body' do
    let(:procedure) { create(:procedure) }

    subject { procedure.closed_mail_template.body }

    context 'for procedures without an attestation' do
      it { is_expected.not_to include('lien attestation') }
    end

    context 'for procedures with an attestation' do
      before { create(:attestation_template, procedure: procedure, activated: activated) }

      context 'when the attestation is inactive' do
        let(:activated) { false }

        it { is_expected.not_to include('lien attestation') }
      end

      context 'when the attestation is inactive' do
        let(:activated) { true }

        it { is_expected.to include('lien attestation') }
      end
    end
  end

  describe '#closed_mail_template_attestation_inconsistency_state' do
    let(:procedure_without_attestation) { create(:procedure, closed_mail: closed_mail) }
    let(:procedure_with_active_attestation) do
      procedure = create(:procedure, closed_mail: closed_mail)
      create(:attestation_template, procedure: procedure, activated: true)
      procedure
    end
    let(:procedure_with_inactive_attestation) do
      procedure = create(:procedure, closed_mail: closed_mail)
      create(:attestation_template, procedure: procedure, activated: false)
      procedure
    end

    subject { procedure.closed_mail_template_attestation_inconsistency_state }

    context 'with a custom mail template' do
      context 'that contains a lien attestation tag' do
        let(:closed_mail) { create(:closed_mail, body: '--lien attestation--') }

        context 'when the procedure doesn’t have an attestation' do
          let(:procedure) { procedure_without_attestation }

          it { is_expected.to eq(:extraneous_tag) }
        end

        context 'when the procedure has an active attestation' do
          let(:procedure) { procedure_with_active_attestation }

          it { is_expected.to be(nil) }
        end

        context 'when the procedure has an inactive attestation' do
          let(:procedure) { procedure_with_inactive_attestation }

          it { is_expected.to eq(:extraneous_tag) }
        end
      end

      context 'that doesn’t contain a lien attestation tag' do
        let(:closed_mail) { create(:closed_mail) }

        context 'when the procedure doesn’t have an attestation' do
          let(:procedure) { procedure_without_attestation }

          it { is_expected.to be(nil) }
        end

        context 'when the procedure has an active attestation' do
          let(:procedure) { procedure_with_active_attestation }

          it { is_expected.to eq(:missing_tag) }
        end

        context 'when the procedure has an inactive attestation' do
          let(:procedure) { procedure_with_inactive_attestation }

          it { is_expected.to be(nil) }
        end
      end
    end

    context 'with the default mail template' do
      let(:closed_mail) { nil }

      context 'when the procedure doesn’t have an attestation' do
        let(:procedure) { procedure_without_attestation }

        it { is_expected.to be(nil) }
      end

      context 'when the procedure has an active attestation' do
        let(:procedure) { procedure_with_active_attestation }

        it { is_expected.to be(nil) }
      end

      context 'when the procedure has an inactive attestation' do
        let(:procedure) { procedure_with_inactive_attestation }

        it { is_expected.to be(nil) }
      end
    end
  end

  describe 'validation' do
    context 'libelle' do
      it { is_expected.not_to allow_value(nil).for(:libelle) }
      it { is_expected.not_to allow_value('').for(:libelle) }
      it { is_expected.to allow_value('Demande de subvention').for(:libelle) }
    end

    context 'description' do
      it { is_expected.not_to allow_value(nil).for(:description) }
      it { is_expected.not_to allow_value('').for(:description) }
      it { is_expected.to allow_value('Description Demande de subvention').for(:description) }
    end

    context 'lien_demarche' do
      it { is_expected.to allow_value(nil).for(:lien_demarche) }
      it { is_expected.to allow_value('').for(:lien_demarche) }
      it { is_expected.to allow_value('http://localhost').for(:lien_demarche) }
    end

    context 'organisation' do
      it { is_expected.to allow_value('URRSAF').for(:organisation) }
    end

    context 'juridique' do
      it { is_expected.not_to allow_value(nil).for(:cadre_juridique) }
      it { is_expected.to allow_value('text').for(:cadre_juridique) }

      context 'with deliberation' do
        let(:procedure) { build(:procedure, cadre_juridique: nil) }

        it { expect(procedure.valid?).to eq(false) }

        context 'when the deliberation is uploaded ' do
          before do
            allow(procedure).to receive(:deliberation)
              .and_return(double('attached?': true))
          end

          it { expect(procedure.valid?).to eq(true) }
        end
      end
    end

    context 'when juridique_required is false' do
      let(:procedure) { build(:procedure, juridique_required: false, cadre_juridique: nil) }

      it { expect(procedure.valid?).to eq(true) }
    end

    shared_examples 'duree de conservation' do
      context 'duree_conservation_required it true, the field gets validated' do
        before { subject.durees_conservation_required = true }

        it { is_expected.not_to allow_value(nil).for(field_name) }
        it { is_expected.not_to allow_value('').for(field_name) }
        it { is_expected.not_to allow_value('trois').for(field_name) }
        it { is_expected.to allow_value(3).for(field_name) }
      end

      context 'duree_conservation_required is false, the field doesn’t get validated' do
        before { subject.durees_conservation_required = false }

        it { is_expected.to allow_value(nil).for(field_name) }
        it { is_expected.to allow_value('').for(field_name) }
        it { is_expected.not_to allow_value('trois').for(field_name) }
        it { is_expected.to allow_value(3).for(field_name) }
      end
    end

    describe 'duree de conservation dans ds' do
      let(:field_name) { :duree_conservation_dossiers_dans_ds }

      it_behaves_like 'duree de conservation'
    end

    describe 'duree de conservation hors ds' do
      let(:field_name) { :duree_conservation_dossiers_hors_ds }

      it_behaves_like 'duree de conservation'
    end
  end

  describe '#duree_de_conservation_required' do
    it 'automatically jumps to true once both durees de conservation have been set' do
      p = build(
        :procedure,
        durees_conservation_required: false,
        duree_conservation_dossiers_dans_ds: nil,
        duree_conservation_dossiers_hors_ds: nil
      )
      p.save
      expect(p.durees_conservation_required).to be_falsey

      p.duree_conservation_dossiers_hors_ds = 3
      p.save
      expect(p.durees_conservation_required).to be_falsey

      p.duree_conservation_dossiers_dans_ds = 6
      p.save
      expect(p.durees_conservation_required).to be_truthy

      p.duree_conservation_dossiers_dans_ds = nil
      p.save
      expect(p.durees_conservation_required).to be_truthy
    end
  end

  describe '#types_de_champ_ordered' do
    let(:procedure) { create(:procedure) }
    let!(:type_de_champ_0) { create(:type_de_champ, procedure: procedure, order_place: 1) }
    let!(:type_de_champ_1) { create(:type_de_champ, procedure: procedure, order_place: 0) }
    subject { procedure.types_de_champ_ordered }
    it { expect(subject.first).to eq(type_de_champ_1) }
    it { expect(subject.last).to eq(type_de_champ_0) }
  end

  describe '#switch_types_de_champ' do
    let(:procedure) { create(:procedure) }
    let(:index) { 0 }
    subject { procedure.switch_types_de_champ index }

    context 'when procedure have no types_de_champ' do
      it { expect(subject).to eq(false) }
    end
    context 'when procedure have 2 types de champ' do
      let!(:type_de_champ_0) { create(:type_de_champ, procedure: procedure, order_place: 0) }
      let!(:type_de_champ_1) { create(:type_de_champ, procedure: procedure, order_place: 1) }
      context 'when index is not the last element' do
        it { expect(subject).to eq(true) }
        it 'switch order place' do
          procedure.switch_types_de_champ index
          type_de_champ_0.reload
          type_de_champ_1.reload
          expect(type_de_champ_0.order_place).to eq(1)
          expect(type_de_champ_1.order_place).to eq(0)
        end
      end
      context 'when index is the last element' do
        let(:index) { 1 }
        it { expect(subject).to eq(false) }
      end
    end
  end

  describe 'locked?' do
    let(:procedure) { create(:procedure, aasm_state: aasm_state) }

    subject { procedure.locked? }

    context 'when procedure is in brouillon status' do
      let(:aasm_state) { :brouillon }
      it { is_expected.to be_falsey }
    end

    context 'when procedure is in publiee status' do
      let(:aasm_state) { :publiee }
      it { is_expected.to be_truthy }
    end
  end

  describe 'active' do
    let(:procedure) { create(:procedure) }
    subject { Procedure.active(procedure.id) }

    context 'when procedure is in draft status and not archived' do
      it { expect { subject }.to raise_error(ActiveRecord::RecordNotFound) }
    end

    context 'when procedure is published and not archived' do
      let(:procedure) { create(:procedure, :published) }
      it { is_expected.to be_truthy }
    end

    context 'when procedure is published and archived' do
      let(:procedure) { create(:procedure, :archived) }
      it { expect { subject }.to raise_error(ActiveRecord::RecordNotFound) }
    end
  end

  describe 'clone' do
    let!(:service) { create(:service) }
    let(:procedure) { create(:procedure, received_mail: received_mail, service: service) }
    let!(:type_de_champ_0) { create(:type_de_champ, procedure: procedure, order_place: 0) }
    let!(:type_de_champ_1) { create(:type_de_champ, procedure: procedure, order_place: 1) }
    let!(:type_de_champ_2) { create(:type_de_champ_drop_down_list, procedure: procedure, order_place: 2) }
    let!(:type_de_champ_private_0) { create(:type_de_champ, :private, procedure: procedure, order_place: 0) }
    let!(:type_de_champ_private_1) { create(:type_de_champ, :private, procedure: procedure, order_place: 1) }
    let!(:type_de_champ_private_2) { create(:type_de_champ_drop_down_list, :private, procedure: procedure, order_place: 2) }
    let!(:piece_justificative_0) { create(:type_de_piece_justificative, procedure: procedure, order_place: 0) }
    let!(:piece_justificative_1) { create(:type_de_piece_justificative, procedure: procedure, order_place: 1) }
    let(:received_mail){ create(:received_mail) }
    let(:from_library) { false }

    before do
      @logo = File.open('spec/fixtures/white.png')
      @signature = File.open('spec/fixtures/black.png')
      @attestation_template = create(:attestation_template, procedure: procedure, logo: @logo, signature: @signature)
      @procedure = procedure.clone(procedure.administrateur, from_library)
      @procedure.save
    end

    after do
      @logo.close
      @signature.close
    end

    subject { @procedure }

    it { expect(subject.parent_procedure).to eq(procedure) }

    it 'should duplicate specific objects with different id' do
      expect(subject.id).not_to eq(procedure.id)
      expect(subject.module_api_carto).to have_same_attributes_as(procedure.module_api_carto)

      expect(subject.types_de_piece_justificative.size).to eq procedure.types_de_piece_justificative.size
      expect(subject.types_de_champ.size).to eq procedure.types_de_champ.size
      expect(subject.types_de_champ_private.size).to eq procedure.types_de_champ_private.size
      expect(subject.types_de_champ.map(&:drop_down_list).compact.size).to eq procedure.types_de_champ.map(&:drop_down_list).compact.size
      expect(subject.types_de_champ_private.map(&:drop_down_list).compact.size).to eq procedure.types_de_champ_private.map(&:drop_down_list).compact.size

      subject.types_de_champ.zip(procedure.types_de_champ).each do |stc, ptc|
        expect(stc).to have_same_attributes_as(ptc)
      end

      subject.types_de_champ_private.zip(procedure.types_de_champ_private).each do |stc, ptc|
        expect(stc).to have_same_attributes_as(ptc)
      end

      subject.types_de_piece_justificative.zip(procedure.types_de_piece_justificative).each do |stc, ptc|
        expect(stc).to have_same_attributes_as(ptc)
      end

      expect(subject.attestation_template.title).to eq(procedure.attestation_template.title)

      expect(subject.cloned_from_library).to be(false)

      cloned_procedure = subject
      cloned_procedure.parent_procedure_id = nil
      expect(cloned_procedure).to have_same_attributes_as(procedure)
    end

    context 'when the procedure is clone from the library' do
      let(:from_library) { true }

      it { expect(subject.cloned_from_library).to be(true) }
    end

    it 'should keep service_id' do
      expect(subject.service).to eq(service)
    end

    it 'should duplicate existing mail_templates' do
      expect(subject.received_mail.attributes.except("id", "procedure_id", "created_at", "updated_at")).to eq procedure.received_mail.attributes.except("id", "procedure_id", "created_at", "updated_at")
      expect(subject.received_mail.id).not_to eq procedure.received_mail.id
      expect(subject.received_mail.id).not_to be nil
      expect(subject.received_mail.procedure_id).not_to eq procedure.received_mail.procedure_id
      expect(subject.received_mail.procedure_id).not_to be nil
    end

    it 'should not duplicate default mail_template' do
      expect(subject.initiated_mail_template.attributes).to eq Mails::InitiatedMail.default_for_procedure(subject).attributes
    end

    it 'should not duplicate specific related objects' do
      expect(subject.dossiers).to eq([])
      expect(subject.gestionnaires).to eq([])
      expect(subject.assign_to).to eq([])
    end

    describe 'procedure status is reset' do
      let(:procedure) { create(:procedure, :archived, received_mail: received_mail, service: service) }

      it 'Not published nor archived' do
        expect(subject.archived_at).to be_nil
        expect(subject.published_at).to be_nil
        expect(subject.test_started_at).to be_nil
        expect(subject.aasm_state).to eq "brouillon"
        expect(subject.path).to be_nil
      end
    end
  end

  describe '#publish!' do
    let(:procedure) { create(:procedure) }
    let(:now) { Time.now.beginning_of_minute }

    before do
      Timecop.freeze(now)
      procedure.publish!("example-path")
    end
    after { Timecop.return }

    it { expect(procedure.archived_at).to eq(nil) }
    it { expect(procedure.published_at).to eq(now) }
    it { expect(ProcedurePath.find_by(path: "example-path")).to be }
    it { expect(ProcedurePath.find_by(path: "example-path").procedure).to eq(procedure) }
    it { expect(ProcedurePath.find_by(path: "example-path").administrateur).to eq(procedure.administrateur) }
  end

  describe "#brouillon?" do
    let(:procedure_brouillon) { Procedure.new() }
    let(:procedure_publiee) { Procedure.new(aasm_state: :publiee, published_at: Time.now) }
    let(:procedure_archivee) { Procedure.new(aasm_state: :archivee, published_at: Time.now, archived_at: Time.now) }

    it { expect(procedure_brouillon.brouillon?).to be_truthy }
    it { expect(procedure_publiee.brouillon?).to be_falsey }
    it { expect(procedure_archivee.brouillon?).to be_falsey }
  end

  describe "#publiee?" do
    let(:procedure_brouillon) { Procedure.new() }
    let(:procedure_publiee) { Procedure.new(aasm_state: :publiee, published_at: Time.now) }
    let(:procedure_archivee) { Procedure.new(aasm_state: :archivee, published_at: Time.now, archived_at: Time.now) }

    it { expect(procedure_brouillon.publiee?).to be_falsey }
    it { expect(procedure_publiee.publiee?).to be_truthy }
    it { expect(procedure_archivee.publiee?).to be_falsey }
  end

  describe "#archivee?" do
    let(:procedure_brouillon) { Procedure.new() }
    let(:procedure_publiee) { Procedure.new(aasm_state: :publiee, published_at: Time.now) }
    let(:procedure_archivee) { Procedure.new(aasm_state: :archivee, published_at: Time.now, archived_at: Time.now) }

    it { expect(procedure_brouillon.archivee?).to be_falsey }
    it { expect(procedure_publiee.archivee?).to be_falsey }
    it { expect(procedure_archivee.archivee?).to be_truthy }
  end

  describe "#publiee_ou_archivee?" do
    let(:procedure_brouillon) { Procedure.new() }
    let(:procedure_publiee) { Procedure.new(aasm_state: :publiee, published_at: Time.now) }
    let(:procedure_archivee) { Procedure.new(aasm_state: :archivee, published_at: Time.now, archived_at: Time.now) }

    it { expect(procedure_brouillon.publiee_ou_archivee?).to be_falsey }
    it { expect(procedure_publiee.publiee_ou_archivee?).to be_truthy }
    it { expect(procedure_archivee.publiee_ou_archivee?).to be_truthy }
  end

  describe 'archive' do
    let(:procedure) { create(:procedure, :published) }
    let(:procedure_path) { ProcedurePath.find(procedure.procedure_path.id) }
    let(:now) { Time.now.beginning_of_minute }
    before do
      Timecop.freeze(now)
      procedure.archive!
      procedure.reload
    end
    after { Timecop.return }

    it { expect(procedure.archivee?).to be_truthy }
    it { expect(procedure.archived_at).to eq(now) }
  end

  describe 'total_dossier' do
    let(:procedure) { create :procedure }

    before do
      create :dossier, procedure: procedure, state: Dossier.states.fetch(:en_construction)
      create :dossier, procedure: procedure, state: Dossier.states.fetch(:brouillon)
      create :dossier, procedure: procedure, state: Dossier.states.fetch(:en_construction)
    end

    subject { procedure.total_dossier }

    it { is_expected.to eq 2 }
  end

  describe '#generate_export' do
    let(:procedure) { create :procedure }
    subject { procedure.generate_export }

    shared_examples "export is empty" do
      it { expect(subject[:data]).to eq([[]]) }
      it { expect(subject[:headers]).to eq([]) }
    end

    context 'when there are no dossiers' do
      it_behaves_like "export is empty"
    end

    context 'when there are some dossiers' do
      let!(:dossier){ create(:dossier, procedure: procedure, state: Dossier.states.fetch(:en_construction)) }
      let!(:dossier2){ create(:dossier, procedure: procedure, state: Dossier.states.fetch(:accepte)) }

      it { expect(subject[:data].size).to eq(2) }
      it { expect(subject[:headers]).to eq(dossier.export_headers) }

      context 'with ordered champs' do
        let(:tc_2) { create(:type_de_champ, order_place: 2) }
        let(:tc_1) { create(:type_de_champ, order_place: 1) }
        let(:tcp_2) { create(:type_de_champ, :private, order_place: 2) }
        let(:tcp_1) { create(:type_de_champ, :private, order_place: 1) }

        before do
          procedure.types_de_champ << tc_2 << tc_1
          procedure.types_de_champ_private << tcp_2 << tcp_1

          dossier.build_default_champs
          dossier.champs.find_by(type_de_champ: tc_1).update(value: "value 1")
          dossier.champs.find_by(type_de_champ: tc_2).update(value: "value 2")
          dossier.champs_private.find_by(type_de_champ: tcp_1).update(value: "private value 1")
          dossier.champs_private.find_by(type_de_champ: tcp_2).update(value: "private value 2")

          dossier2.build_default_champs
          dossier2.champs.find_by(type_de_champ: tc_1).update(value: "value 1")
          dossier2.champs.find_by(type_de_champ: tc_2).update(value: "value 2")
          dossier2.champs_private.find_by(type_de_champ: tcp_1).update(value: "private value 1")
          dossier2.champs_private.find_by(type_de_champ: tcp_2).update(value: "private value 2")
        end

        it { expect(subject[:headers].index(tc_1.libelle.parameterize.underscore.to_sym)).to be < subject[:headers].index(tc_2.libelle.parameterize.underscore.to_sym) }
        it { expect(subject[:headers].index(tcp_1.libelle.parameterize.underscore.to_sym)).to be < subject[:headers].index(tcp_2.libelle.parameterize.underscore.to_sym) }

        it { expect(subject[:data][0].index("value 1")).to be < subject[:data].first.index("value 2") }
        it { expect(subject[:data][0].index("private value 1")).to be < subject[:data].first.index("private value 2") }

        it { expect(subject[:data][1].index("value 1")).to be < subject[:data].first.index("value 2") }
        it { expect(subject[:data][1].index("private value 1")).to be < subject[:data].first.index("private value 2") }
      end
    end

    context 'when there is a brouillon dossier' do
      let!(:dossier_not_exportable){ create(:dossier, procedure: procedure, state: Dossier.states.fetch(:brouillon)) }

      it_behaves_like "export is empty"
    end
  end

  describe '#default_path' do
    let(:procedure){ create(:procedure, libelle: 'A long libelle with àccênts, blabla coucou hello un deux trois voila') }

    subject { procedure.default_path }

    it { is_expected.to eq('a-long-libelle-with-accents-blabla-coucou-hello-un') }
  end

  describe ".default_scope" do
    let!(:procedure) { create(:procedure, hidden_at: hidden_at) }

    context "when hidden_at is nil" do
      let(:hidden_at) { nil }

      it { expect(Procedure.count).to eq(1) }
      it { expect(Procedure.all).to include(procedure) }
    end

    context "when hidden_at is not nil" do
      let(:hidden_at) { 2.days.ago }

      it { expect(Procedure.count).to eq(0) }
      it { expect { Procedure.find(procedure.id) }.to raise_error(ActiveRecord::RecordNotFound) }
    end
  end

  describe "#hide!" do
    let(:procedure) { create(:procedure) }
    let!(:dossier) { create(:dossier, procedure: procedure) }
    let!(:dossier2) { create(:dossier, procedure: procedure) }
    let(:gestionnaire) { create(:gestionnaire) }

    it { expect(Dossier.count).to eq(2) }
    it { expect(Dossier.all).to include(dossier, dossier2) }

    context "when hidding procedure" do
      before do
        gestionnaire.followed_dossiers << dossier
        procedure.hide!
        gestionnaire.reload
      end

      it { expect(procedure.dossiers.count).to eq(0) }
      it { expect(Dossier.count).to eq(0) }
      it { expect(gestionnaire.followed_dossiers).not_to include(dossier) }
    end
  end

  describe "#fields" do
    subject { create(:procedure, :with_type_de_champ, :with_type_de_champ_private, :types_de_champ_count => 4, :types_de_champ_private_count => 4) }
    let(:tdc_1) { subject.types_de_champ[0] }
    let(:tdc_2) { subject.types_de_champ[1] }
    let(:tdc_private_1) { subject.types_de_champ_private[0] }
    let(:tdc_private_2) { subject.types_de_champ_private[1] }
    let(:expected) {
      [
        { "label" => 'Créé le', "table" => 'self', "column" => 'created_at' },
        { "label" => 'Mis à jour le', "table" => 'self', "column" => 'updated_at' },
        { "label" => 'Demandeur', "table" => 'user', "column" => 'email' },
        { "label" => 'Civilité (FC)', "table" => 'france_connect_information', "column" => 'gender' },
        { "label" => 'Prénom (FC)', "table" => 'france_connect_information', "column" => 'given_name' },
        { "label" => 'Nom (FC)', "table" => 'france_connect_information', "column" => 'family_name' },
        { "label" => 'SIREN', "table" => 'etablissement', "column" => 'entreprise_siren' },
        { "label" => 'Forme juridique', "table" => 'etablissement', "column" => 'entreprise_forme_juridique' },
        { "label" => 'Nom commercial', "table" => 'etablissement', "column" => 'entreprise_nom_commercial' },
        { "label" => 'Raison sociale', "table" => 'etablissement', "column" => 'entreprise_raison_sociale' },
        { "label" => 'SIRET siège social', "table" => 'etablissement', "column" => 'entreprise_siret_siege_social' },
        { "label" => 'Date de création', "table" => 'etablissement', "column" => 'entreprise_date_creation' },
        { "label" => 'SIRET', "table" => 'etablissement', "column" => 'siret' },
        { "label" => 'Libellé NAF', "table" => 'etablissement', "column" => 'libelle_naf' },
        { "label" => 'Code postal', "table" => 'etablissement', "column" => 'code_postal' },
        { "label" => tdc_1.libelle, "table" => 'type_de_champ', "column" => tdc_1.id.to_s },
        { "label" => tdc_2.libelle, "table" => 'type_de_champ', "column" => tdc_2.id.to_s },
        { "label" => tdc_private_1.libelle, "table" => 'type_de_champ_private', "column" => tdc_private_1.id.to_s },
        { "label" => tdc_private_2.libelle, "table" => 'type_de_champ_private', "column" => tdc_private_2.id.to_s }
      ]
    }

    before do
      subject.types_de_champ[2].update_attribute(:type_champ,TypeDeChamp.type_champs.fetch(:header_section))
      subject.types_de_champ[3].update_attribute(:type_champ,TypeDeChamp.type_champs.fetch(:explication))
      subject.types_de_champ_private[2].update_attribute(:type_champ,TypeDeChamp.type_champs.fetch(:header_section))
      subject.types_de_champ_private[3].update_attribute(:type_champ,TypeDeChamp.type_champs.fetch(:explication))
    end

    it { expect(subject.fields).to eq(expected) }
  end

  describe "#fields_for_select" do
    subject { create(:procedure) }

    before do
      allow(subject).to receive(:fields).and_return([
        {
          "label" => "label1",
          "table" => "table1",
          "column" => "column1"
        },
        {
          "label" => "label2",
          "table" => "table2",
          "column" => "column2"
        }
      ])
    end

    it { expect(subject.fields_for_select).to eq([["label1", "table1/column1"], ["label2", "table2/column2"]]) }
  end

  describe ".default_sort" do
    it { expect(Procedure.default_sort).to eq("{\"table\":\"self\",\"column\":\"id\",\"order\":\"desc\"}") }
  end

  describe "#export_filename" do
    before { Timecop.freeze(Time.new(2018, 1, 2, 23, 11, 14)) }

    subject { procedure.export_filename }

    context "with a path" do
      let(:procedure) { create(:procedure, :published) }

      it { is_expected.to eq("dossiers_#{procedure.procedure_path.path}_2018-01-02_23-11") }
    end

    context "without a path" do
      let(:procedure) { create(:procedure) }

      it { is_expected.to eq("dossiers_procedure-#{procedure.id}_2018-01-02_23-11") }
    end
  end

  describe '#new_dossier' do
    let(:procedure) do
      procedure = create(:procedure)

      create(:type_de_champ_text, procedure: procedure, order_place: 1)
      create(:type_de_champ_number, procedure: procedure, order_place: 2)
      create(:type_de_champ_textarea, :private, procedure: procedure)

      procedure
    end

    let(:dossier) { procedure.new_dossier }

    it { expect(dossier.procedure).to eq(procedure) }

    it { expect(dossier.champs.size).to eq(2) }
    it { expect(dossier.champs[0].type).to eq("Champs::TextChamp") }

    it { expect(dossier.champs_private.size).to eq(1) }
    it { expect(dossier.champs_private[0].type).to eq("Champs::TextareaChamp") }

    it { expect(Champ.count).to eq(0) }
  end

  describe "#organisation_name" do
    subject { procedure.organisation_name }
    context 'when the procedure has a service (and no organization)' do
      let(:procedure) { create(:procedure, :with_service, organisation: nil) }
      it { is_expected.to eq procedure.service.nom }
    end

    context 'when the procedure has an organization (and no service)' do
      let(:procedure) { create(:procedure, organisation: 'DDT des Vosges', service: nil) }
      it { is_expected.to eq procedure.organisation }
    end
  end

  describe '#juridique_required' do
    it 'automatically jumps to true once cadre_juridique or deliberation have been set' do
      p = create(
        :procedure,
        juridique_required: false,
        cadre_juridique: nil,
      )

      expect(p.juridique_required).to be_falsey

      p.update(cadre_juridique: 'cadre')
      expect(p.juridique_required).to be_truthy

      p.update(cadre_juridique: nil)
      expect(p.juridique_required).to be_truthy

      p.update_columns(cadre_juridique: nil, juridique_required: false)
      p.reload
      expect(p.juridique_required).to be_falsey

      allow(p).to receive(:deliberation).and_return(double('attached?': true))
      p.save
      expect(p.juridique_required).to be_truthy
    end
  end
end
