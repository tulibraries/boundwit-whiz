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

    it "calls the updater and renders success" do
      updater = instance_double(
        BoundWith::Updater,
        call: bibs
      )

      expect(BoundWith::Updater)
        .to receive(:new)
        .with(
          mms_ids: [
            "991039535820903811",
            "991039535820803811"
          ]
        )
          .and_return(updater)

        post bound_withs_path,
          params: {
            bound_with: {
              mms_ids:
            }
          }

        expect(response).to have_http_status(:found)

        follow_redirect!

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Boundwith success!")
    end

    it "rejects invalid MMS IDs" do
      expect(BoundWith::Updater).not_to receive(:new)

      post bound_withs_path,
        params: {
          bound_with: {
            mms_ids: <<~IDS
          991039535820903811
          not-an-mms-id
            IDS
          }
        }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Invalid MMS ID")
    end

    it "rejects invalid MMS IDs" do
      expect(BoundWith::Updater).not_to receive(:new)

      post bound_withs_path,
        params: {
          bound_with: {
            mms_ids: <<~IDS
          991039535820903811
          99103953582090381
            IDS
          }
        }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Invalid MMS ID")
    end

    it "requires at least 2 MMS IDs" do
      expect(BoundWith::Updater).not_to receive(:new)

      post bound_withs_path,
        params: {
          bound_with: {
            mms_ids: <<~IDS
          991039535820903811
            IDS
          }
        }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Enter at least two MMS IDs")
    end

    it "renders an error when the updater fails" do
      updater = instance_double(BoundWith::Updater)

      allow(BoundWith::Updater)
        .to receive(:new)
        .and_return(updater)

      allow(updater)
        .to receive(:call)
        .and_raise(ArgumentError, "Something went wrong")

      post bound_withs_path,
        params: {
          bound_with: {
            mms_ids:
          }
        }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Something went wrong")
    end
  end
end
