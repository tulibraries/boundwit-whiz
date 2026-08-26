class BoundWithsController < ApplicationController
  def new
  end

  def create
    bibs = BoundWith::Updater.new(mms_ids:).call
    ids = bibs.map(&:id)

    redirect_to bound_with_success_path(
      mms_ids: ids
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
    ids = params
      .require(:bound_with)
      .fetch(:mms_ids)
      .split(/\s+/)
      .map(&:strip)
      .reject(&:blank?)
      .uniq

    raise ArgumentError, "Enter at least two MMS IDs." if ids.size < 2

    invalid_ids = ids.reject { |id| id.match?(/\A9910\d{10}3811\z/) }

    if invalid_ids.any?
      raise ArgumentError,
        "Invalid MMS ID: #{invalid_ids.join(', ')}"
    end

    ids
  end
end
