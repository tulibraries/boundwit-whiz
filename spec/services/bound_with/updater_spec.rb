require "rails_helper"

RSpec.describe BoundWith::Updater do
  subject(:updater) do
    described_class.new(
      bibs:,
      holding:
    )
  end

  let(:parent_bib) do
    instance_double(
      Alma::Bib,
      record: parent_record
    )
  end

  let(:child_bib) do
    instance_double(
      Alma::Bib,
      record: child_record
    )
  end

  let(:bibs) do
    [
      parent_bib,
      child_bib
    ]
  end

  let(:holding) do
    instance_double(
      Alma::BibHolding,
      record: holding_record
    )
  end

  let(:parent_record) do
    instance_double(MARC::Record)
  end

  let(:child_record) do
    instance_double(MARC::Record)
  end

  let(:holding_record) do
    instance_double(MARC::Record)
  end

  let(:marc_editor) do
    instance_double(BoundWith::MarcEditor)
  end

  before do
    allow(BoundWith::MarcEditor)
      .to receive(:new)
      .and_return(marc_editor)

    allow(marc_editor).to receive(:add_501_field)
    allow(marc_editor).to receive(:add_773_field)
    allow(marc_editor).to receive(:add_774_field)
    allow(marc_editor).to receive(:add_014_field)

    allow(parent_bib).to receive(:update!)
    allow(child_bib).to receive(:update!)
    allow(holding).to receive(:update!)

    allow(parent_bib).to receive(:cache!)
    allow(child_bib).to receive(:cache!)
    allow(holding).to receive(:cache!)
  end

  describe "#call" do
    it "adds the 501 field to the parent record" do
      expect(marc_editor)
        .to receive(:add_501_field)
        .with(
          rec: parent_record,
          recs: [
            parent_record,
            child_record
          ]
        )

      updater.call
    end

    it "adds the child linking fields" do
      expect(marc_editor)
        .to receive(:add_773_field)
        .with(
          parent: parent_record,
          child: child_record
        )

      expect(marc_editor)
        .to receive(:add_774_field)
        .with(
          parent: parent_record,
          child: child_record
        )

      updater.call
    end

    it "adds the 501 field to each child record" do
      expect(marc_editor)
        .to receive(:add_501_field)
        .with(
          rec: child_record,
          recs: [
            parent_record,
            child_record
          ]
        )

      updater.call
    end

    it "adds the 014 field to the holding for each child" do
      expect(marc_editor)
        .to receive(:add_014_field)
        .with(
          parent: holding_record,
          child: child_record
        )

      updater.call
    end

    it "updates all bibs" do
      expect(parent_bib).to receive(:update!)
      expect(child_bib).to receive(:update!)

      updater.call
    end

    it "updates the parent holding" do
      expect(holding).to receive(:update!)

      updater.call
    end

    it "caches all bibs after updating them" do
      expect(parent_bib).to receive(:cache!)
      expect(child_bib).to receive(:cache!)

      updater.call
    end

    it "caches the parent holding" do
      expect(holding).to receive(:cache!)

      updater.call
    end

    it "returns the bibs" do
      expect(updater.call).to eq(bibs)
    end

    context "when a bib update fails" do
      before do
        allow(parent_bib)
          .to receive(:update!)
          .and_raise(StandardError, "Alma update failed")
      end

      it "does not cache the records" do
        expect(parent_bib).not_to receive(:cache!)
        expect(child_bib).not_to receive(:cache!)
        expect(holding).not_to receive(:cache!)

        expect {
          updater.call
        }.to raise_error(
          StandardError,
          "Alma update failed"
        )
      end
    end

    context "when the holding update fails" do
      before do
        allow(holding)
          .to receive(:update!)
          .and_raise(StandardError, "Holding update failed")
      end

      it "does not cache the records" do
        expect(parent_bib).not_to receive(:cache!)
        expect(child_bib).not_to receive(:cache!)
        expect(holding).not_to receive(:cache!)

        expect {
          updater.call
        }.to raise_error(
          StandardError,
          "Holding update failed"
        )
      end
    end
  end
end
