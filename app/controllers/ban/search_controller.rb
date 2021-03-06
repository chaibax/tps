class Ban::SearchController < ApplicationController
  def get
    request = params[:request]

    json = Carto::Bano::AddressRetriever.new(request).list.map do |value|
      { label: value }
    end.to_json

    render json: json
  end

  def get_address_point
    point = Carto::Geocodeur.convert_adresse_to_point(params[:request])

    if point.present?
      lon = point.x.to_s
      lat = point.y.to_s
    end

    render json: { lon: lon, lat: lat, zoom: '14', dossier_id: params[:dossier_id] }
  end
end
