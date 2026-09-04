class BoundWithsController < ApplicationController
  def new
  end

  def create
    preparation = BoundWith::Preparation.new(mms_ids:).call

    if preparation.holding_selection_required?
      @mms_ids = preparation.mms_ids
      @holdings = preparation.holdings

      render :select_holding, status: :unprocessable_entity
    else
      BoundWith::Updater.new(
        bibs: preparation.bibs,
        holding: preparation.holding
      ).call

      redirect_to bound_with_success_path(
        mms_ids: preparation.mms_ids
      )
    end
  rescue StandardError => e
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_entity
  end

  def create_with_selected_holding
    mms_ids = params.dig(:bound_with, :mms_ids)
    validate(mms_ids:)
    holding_id = params.dig(:bound_with, :holding_id)

    bibs = MarcRecord.where(record_id: mms_ids)
      .in_order_of(:record_id, mms_ids)
      .map(&:to_bib)

    parent_bib = bibs.first
    holding = Alma::BibHolding.find(mms_id: parent_bib.id, holding_id: holding_id)

    BoundWith::Updater.new(
      bibs: bibs,
      holding: holding
    ).call

    redirect_to bound_with_success_path(
      mms_ids: mms_ids
    )
  rescue StandardError => e
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_entity
  end

  def success
    mms_ids = Array(params[:mms_ids]).uniq

    bibs = MarcRecord.where(
      record_type: "bib",
      mms_id: mms_ids
    ).index_by(&:mms_id)

    holdings = MarcRecord.where(
      record_type: "holding",
      mms_id: mms_ids
    ).group_by(&:mms_id)

    @records = mms_ids.filter_map do |mms_id|
      bib = bibs[mms_id]
      next unless bib

      {
        bib:,
        holdings: holdings.fetch(mms_id, [])
      }
    end
  end

  private


  def mms_ids
    raw_value = params.
      require(:bound_with)
      .fetch(:mms_ids)

    flash[:mms_id_values] = raw_value

    ids = raw_value
      .split(/\s+/)
      .map(&:strip)
      .reject(&:blank?)
      .uniq

    validate(mms_ids: ids)
  end


  def validate(mms_ids:)
    raise ArgumentError, "Enter at least two MMS IDs." if mms_ids.size < 2

    invalid_ids = mms_ids.reject { |id| id.match?(/\A9910\d{10}3811\z/) }

    if invalid_ids.any?
      raise ArgumentError,
        "Invalid MMS ID: #{invalid_ids.join(', ')}"
    end

    mms_ids
  end
end
