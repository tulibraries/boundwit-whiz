class MarcRecordsController < ApplicationController
  def show
    @marc_record = MarcRecord.find(params[:id])

    render layout: false
  end
end
