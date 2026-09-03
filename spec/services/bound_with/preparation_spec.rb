require "rails_helper"

RSpec.describe BoundWith::Preparation do
  subject(:preparation) do
    described_class.new(mms_ids:)
  end

  let(:mms_ids) do
    [
      "991039535820903811",
      "991039535820803811"
    ]
  end

  let(:parent_bib) do
    instance_double(
      Alma::Bib,
      id: "991039535820903811",
      holding_ids: [ "1" ]
    )
  end

  let(:child_bib) do
    instance_double(
      Alma::Bib,
      id: "991039535820803811"
    )
  end

  let(:holding) do
    instance_double(
      Alma::BibHolding
    )
  end

  describe "#call" do
    context "when the parent bib has one holding" do
      before do
        allow(parent_bib)
          .to receive(:holdings)
          .and_return([ { "holding_id" => "1" } ])

        allow(parent_bib).to receive(:cache!)
        allow(child_bib).to receive(:cache!)
        allow(holding).to receive(:cache!)

        allow(Alma::Bib)
          .to receive(:get_bibs)
          .with(mms_ids)
          .and_return([ parent_bib, child_bib ])

        allow(Alma::BibHolding)
          .to receive(:find)
          .with(
            mms_id: "991039535820903811",
            holding_id: "1"
          )
          .and_return(holding)
      end

      it "returns itself" do
        expect(preparation.call).to be(preparation)
      end

      it "stores the bibs" do
        preparation.call

        expect(preparation.bibs)
          .to eq([ parent_bib, child_bib ])
      end

      it "stores the holdings" do
        preparation.call

        expect(preparation.holdings)
          .to eq([ { "holding_id" => "1" } ])
      end

      it "does not require holding selection" do
        preparation.call

        expect(preparation)
          .not_to be_holding_selection_required
      end

      it "loads the parent's holding" do
        expect(Alma::BibHolding)
          .to receive(:find)
          .with(
            mms_id: "991039535820903811",
            holding_id: "1"
          )
          .and_return(holding)

        preparation.call
      end

      it "caches each bib" do
        expect(parent_bib).to receive(:cache!)
        expect(child_bib).to receive(:cache!)

        preparation.call
      end

      it "caches the holding" do
        expect(holding).to receive(:cache!)

        preparation.call
      end
    end

    context "when the parent bib has multiple holdings" do
      let(:holdings) do
        [
          { "holding_id" => "1" },
          { "holding_id" => "2" }
        ]
      end

      before do
        allow(parent_bib)
          .to receive(:holdings)
          .and_return(holdings)

        allow(parent_bib).to receive(:cache!)
        allow(child_bib).to receive(:cache!)

        allow(Alma::Bib)
          .to receive(:get_bibs)
          .with(mms_ids)
          .and_return([ parent_bib, child_bib ])
      end

      it "requires holding selection" do
        preparation.call

        expect(preparation)
          .to be_holding_selection_required
      end

      it "does not load a specific holding" do
        expect(Alma::BibHolding)
          .not_to receive(:find)

        preparation.call
      end

      it "still caches the bibs" do
        expect(parent_bib).to receive(:cache!)
        expect(child_bib).to receive(:cache!)

        preparation.call
      end
    end

    context "when the parent bib has no holdings" do
      before do
        allow(parent_bib)
          .to receive(:holdings)
          .and_return([])

        allow(Alma::Bib)
          .to receive(:get_bibs)
          .with(mms_ids)
          .and_return([ parent_bib, child_bib ])
      end

      it "raises BoundWith::NoHoldingsError" do
        expect {
          preparation.call
        }.to raise_error(BoundWith::NoHoldingsError)
      end
    end

    context "when Alma returns duplicate bibs" do
      before do
        duplicate_parent = instance_double(
          Alma::Bib,
          id: "991039535820903811"
        )

        allow(parent_bib)
          .to receive(:holdings)
          .and_return([ { "holding_id" => "1" } ])

        allow(parent_bib).to receive(:cache!)
        allow(child_bib).to receive(:cache!)
        allow(holding).to receive(:cache!)

        allow(Alma::Bib)
          .to receive(:get_bibs)
          .with(mms_ids)
          .and_return(
            [
              parent_bib,
              duplicate_parent,
              child_bib
            ]
          )

        allow(Alma::BibHolding)
          .to receive(:find)
          .and_return(holding)
      end

      it "deduplicates bibs by id" do
        preparation.call

        expect(preparation.bibs)
          .to eq([ parent_bib, child_bib ])
      end
    end
  end
end
