class DossierTableExportSerializer < ActiveModel::Serializer
  attributes :id,
    :created_at,
    :updated_at,
    :archived,
    :email,
    :state,
    :initiated_at,
    :received_at,
    :processed_at,
    :motivation

  attribute :emails_instructeurs

  attributes :individual_gender,
    :individual_prenom,
    :individual_nom,
    :individual_birthdate

  def email
    object.user&.email
  end

  def state
    case object.state
    when Dossier.states.fetch(:en_construction)
      'initiated'
    when Dossier.states.fetch(:en_instruction)
      'received'
    when Dossier.states.fetch(:accepte)
      'closed'
    when Dossier.states.fetch(:refuse)
      'refused'
    when Dossier.states.fetch(:sans_suite)
      'without_continuation'
    else
      object.state
    end
  end

  def initiated_at
    object.en_construction_at
  end

  def received_at
    object.en_instruction_at
  end

  def individual_prenom
    object.individual&.prenom
  end

  def individual_nom
    object.individual&.nom
  end

  def individual_birthdate
    object.individual&.birthdate
  end

  def individual_gender
    object.individual&.gender
  end

  def emails_instructeurs
    object.followers_gestionnaires.pluck(:email).join(' ')
  end
end
