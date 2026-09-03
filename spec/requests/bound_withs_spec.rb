require "rails_helper"

RSpec.describe "BoundWiths", type: :request do
  describe "GET /" do
    it "renders the form" do
      get root_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /bound_withs" do
    let(:mms_ids) do
      <<~IDS
        991039535820903811
        991039535820803811
      IDS
    end

    let(:parsed_mms_ids) do
      [
        "991039535820903811",
        "991039535820803811"
      ]
    end

    let(:bibs) do
      [
        instance_double(
          Alma::Bib,
          id: "991039535820903811",
          title: "Parent title"
        ),
        instance_double(
          Alma::Bib,
          id: "991039535820803811",
          title: "Child title"
        )
      ]
    end

    let(:holding) do
      instance_double(
        Alma::BibHolding,
        id: "2"
      )
    end

    it "calls the updater and redirects to success" do
      preparation = double(
        "preparation",
        holding_selection_required?: false,
        mms_ids: parsed_mms_ids,
        bibs:,
        holding:
      )

      preparation_service = instance_double(
        BoundWith::Preparation,
        call: preparation
      )

      expect(BoundWith::Preparation)
        .to receive(:new)
        .with(mms_ids: parsed_mms_ids)
        .and_return(preparation_service)

      updater = instance_double(
        BoundWith::Updater,
        call: bibs
      )

      expect(BoundWith::Updater)
        .to receive(:new)
        .with(
          bibs:,
          holding:
        )
        .and_return(updater)

      post bound_withs_path,
        params: {
          bound_with: {
            mms_ids:
          }
        }

      expect(response).to redirect_to(
        bound_with_success_path(
          mms_ids: parsed_mms_ids
        )
      )
    end

    context "when a holding must be selected" do
      let(:holdings) do
        [
          {
            "holding_id" => "1",
            "library" => {
              "value" => "MAIN",
              "desc" => "Main Library"
            },
            "location" => {
              "value" => "STACKS",
              "desc" => "Stacks"
            }
          },
          {
            "holding_id" => "2",
            "library" => {
              "value" => "MAIN",
              "desc" => "Main Library"
            },
            "location" => {
              "value" => "REF",
              "desc" => "Reference"
            }
          }
        ]
      end

      it "renders the holding selection page" do
        preparation = double(
          "preparation",
          holding_selection_required?: true,
          mms_ids: parsed_mms_ids,
          holdings:
        )

        preparation_service = instance_double(
          BoundWith::Preparation,
          call: preparation
        )

        expect(BoundWith::Preparation)
          .to receive(:new)
          .with(mms_ids: parsed_mms_ids)
          .and_return(preparation_service)

        expect(BoundWith::Updater)
          .not_to receive(:new)

        post bound_withs_path,
          params: {
            bound_with: {
              mms_ids:
            }
          }

        expect(response)
          .to have_http_status(:unprocessable_content)
      end
    end

    it "rejects a non-MMS ID" do
      expect(BoundWith::Preparation)
        .not_to receive(:new)

      expect(BoundWith::Updater)
        .not_to receive(:new)

      post bound_withs_path,
        params: {
          bound_with: {
            mms_ids: <<~IDS
              991039535820903811
              not-an-mms-id
            IDS
          }
        }

      expect(response)
        .to have_http_status(:unprocessable_content)

      expect(response.body)
        .to include("Invalid MMS ID")
    end

    it "rejects an incorrectly formatted MMS ID" do
      expect(BoundWith::Preparation)
        .not_to receive(:new)

      expect(BoundWith::Updater)
        .not_to receive(:new)

      post bound_withs_path,
        params: {
          bound_with: {
            mms_ids: <<~IDS
              991039535820903811
              99103953582090381
            IDS
          }
        }

      expect(response)
        .to have_http_status(:unprocessable_content)

      expect(response.body)
        .to include("Invalid MMS ID")
    end

    it "requires at least 2 MMS IDs" do
      expect(BoundWith::Preparation)
        .not_to receive(:new)

      expect(BoundWith::Updater)
        .not_to receive(:new)

      post bound_withs_path,
        params: {
          bound_with: {
            mms_ids: "991039535820903811"
          }
        }

      expect(response)
        .to have_http_status(:unprocessable_content)

      expect(response.body)
        .to include("Enter at least two MMS IDs")
    end

    it "renders an error when preparation fails" do
      preparation_service = instance_double(
        BoundWith::Preparation
      )

      expect(BoundWith::Preparation)
        .to receive(:new)
        .with(mms_ids: parsed_mms_ids)
        .and_return(preparation_service)

      expect(preparation_service)
        .to receive(:call)
        .and_raise(
          ArgumentError,
          "Something went wrong"
        )

      expect(BoundWith::Updater)
        .not_to receive(:new)

      post bound_withs_path,
        params: {
          bound_with: {
            mms_ids:
          }
        }

      expect(response)
        .to have_http_status(:unprocessable_content)

      expect(response.body)
        .to include("Something went wrong")
    end

    it "renders an error when the updater fails" do
      preparation = double(
        "preparation",
        holding_selection_required?: false,
        mms_ids: parsed_mms_ids,
        bibs:,
        holding:
      )

      preparation_service = instance_double(
        BoundWith::Preparation,
        call: preparation
      )

      allow(BoundWith::Preparation)
        .to receive(:new)
        .with(mms_ids: parsed_mms_ids)
        .and_return(preparation_service)

      updater = instance_double(
        BoundWith::Updater
      )

      expect(BoundWith::Updater)
        .to receive(:new)
        .with(
          bibs:,
          holding:
        )
        .and_return(updater)

      expect(updater)
        .to receive(:call)
        .and_raise(
          ArgumentError,
          "Something went wrong"
        )

      post bound_withs_path,
        params: {
          bound_with: {
            mms_ids:
          }
        }

      expect(response)
        .to have_http_status(:unprocessable_content)

      expect(response.body)
        .to include("Something went wrong")
    end
  end

  describe "POST /bound_withs/create_with_selected_holding" do
    let(:mms_ids) do
      [
        "991039535820903811",
        "991039535820803811"
      ]
    end

    let(:bibs) do
      [
        instance_double(
          Alma::Bib,
          id: "991039535820903811",
          title: "Parent title"
        ),
        instance_double(
          Alma::Bib,
          id: "991039535820803811",
          title: "Child title"
        )
      ]
    end

    let(:marc_records) do
      [
        instance_double(
          MarcRecord,
          to_bib: bibs[0]
        ),
        instance_double(
          MarcRecord,
          to_bib: bibs[1]
        )
      ]
    end

    let(:relation) do
      instance_double(
        ActiveRecord::Relation
      )
    end

    let(:holding) do
      instance_double(
        Alma::BibHolding,
        id: "2"
      )
    end

    before do
      allow(MarcRecord)
        .to receive(:where)
        .with(record_id: mms_ids)
        .and_return(relation)

      allow(relation)
        .to receive(:in_order_of)
        .with(:record_id, mms_ids)
        .and_return(marc_records)

      allow(Alma::BibHolding)
        .to receive(:find)
        .with(
          mms_id: "991039535820903811",
          holding_id: "2"
        )
        .and_return(holding)
    end

    it "updates using the selected holding and redirects to success" do
      updater = instance_double(
        BoundWith::Updater,
        call: bibs
      )

      expect(BoundWith::Updater)
        .to receive(:new)
        .with(
          bibs:,
          holding:
        )
        .and_return(updater)

      post create_with_selected_holding_path,
        params: {
          bound_with: {
            mms_ids:,
            holding_id: "2"
          }
        }

      expect(response).to redirect_to(
        bound_with_success_path(
          mms_ids:
        )
      )
    end

    it "loads the selected holding from the parent bib" do
      expect(Alma::BibHolding)
        .to receive(:find)
        .with(
          mms_id: "991039535820903811",
          holding_id: "2"
        )
        .and_return(holding)

      updater = instance_double(
        BoundWith::Updater,
        call: bibs
      )

      allow(BoundWith::Updater)
        .to receive(:new)
        .with(
          bibs:,
          holding:
        )
        .and_return(updater)

      post create_with_selected_holding_path,
        params: {
          bound_with: {
            mms_ids:,
            holding_id: "2"
          }
        }

      expect(response).to have_http_status(:found)
    end

    it "renders an error when the updater fails" do
      updater = instance_double(
        BoundWith::Updater
      )

      allow(BoundWith::Updater)
        .to receive(:new)
        .with(
          bibs:,
          holding:
        )
        .and_return(updater)

      expect(updater)
        .to receive(:call)
        .and_raise(
          ArgumentError,
          "Something went wrong"
        )

      post create_with_selected_holding_path,
        params: {
          bound_with: {
            mms_ids:,
            holding_id: "2"
          }
        }

      expect(response)
        .to have_http_status(:unprocessable_content)

      expect(response.body)
        .to include("Something went wrong")
    end
  end
end
