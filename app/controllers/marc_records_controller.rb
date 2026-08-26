class MarcRecordsController < ApplicationController
  def show
    @marc_record = MarcRecord.find(params[:id])

    render layout: false
  end

  def refresh
    @marc_record = MarcRecord.find(params[:id])
    @marc_record.refresh_from_alma!

    redirect_to @marc_record,
      notice: "Record refreshed from Alma."
  end
end
