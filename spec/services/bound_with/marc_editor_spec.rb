require "rails_helper"

RSpec.describe BoundWith::MarcEditor do
  subject(:editor) { described_class.new }

  let(:parent) do
    MARC::Record.new.tap do |record|
      record.append(MARC::ControlField.new("001", "parent-id"))
      record.append(
        MARC::DataField.new(
          "245", "1", "0",
          [ "a", "Parent title" ]
        )
      )
    end
  end

  let(:child) do
    MARC::Record.new.tap do |record|
      record.append(MARC::ControlField.new("001", "child-id"))
      record.append(
        MARC::DataField.new(
          "245", "1", "0",
          [ "a", "Child title" ]
        )
      )
    end
  end

  describe "#add_774_field" do
    it "adds a 774 for the child to the parent" do
      editor.add_774_field(parent:, child:)

      field = parent["774"]

      expect(field["t"]).to eq("Child title")
      expect(field["w"]).to eq("child-id")
      expect(field.indicator1).to eq("1")
      expect(field.indicator2).to eq(" ")
    end
  end

  describe "#add_773_field" do
    it "adds a 773 pointing from the child to the parent" do
      editor.add_773_field(parent:, child:)

      field = child["773"]

      expect(field["t"]).to eq("Parent title")
      expect(field["w"]).to eq("parent-id")
    end
  end

  describe "#add_501_field" do
    let(:other_child) do
      MARC::Record.new.tap do |record|
        record.append(MARC::ControlField.new("001", "child-2"))
        record.append(
          MARC::DataField.new(
            "245", "1", "0",
            [ "a", "Second child" ]
          )
        )
      end
    end

    it "lists all of the other titles" do
      editor.add_501_field(
        rec: parent,
        recs: [ parent, child, other_child ]
      )

      field = parent["501"]

      expect(field["a"])
        .to eq("Bound with: Child title -- Second child.")

      expect(field["5"]).to eq("PPT")
      expect(field.indicator1).to eq(" ")
      expect(field.indicator2).to eq(" ")
    end

    it "does not add a duplicate 501 field" do
      editor.add_501_field(
        rec: parent,
        recs: [ parent, child ]
      )

      editor.add_501_field(
        rec: parent,
        recs: [ parent, child ]
      )

      expect(parent.fields("501").length).to eq(1)

      field = parent["501"]

      expect(field["a"]).to eq("Bound with: Child title.")
      expect(field["5"]).to eq("PPT")
    end
  end

  describe "#purge_old_fields" do
    it "removes 773 and 774 fields from a bib record" do
      parent.append(MARC::DataField.new("773", " ", " "))
      parent.append(MARC::DataField.new("774", " ", " "))

      editor.purge_old_fields(rec: parent)

      expect(parent["773"]).to be_nil
      expect(parent["774"]).to be_nil
    end

    it "does not purge 501 fields" do
      parent.append(
        MARC::DataField.new(
          "501", " ", " ",
          [ "a", "Bound with: Something." ],
          [ "5", "PPT" ]
        )
      )

      editor.purge_old_fields(rec: parent)

      expect(parent.fields("501").length).to eq(1)
      expect(parent["501"]["a"]).to eq("Bound with: Something.")
    end

    describe "#title" do
      let(:record) do
        MARC::Record.new.tap do |record|
          record.append(MARC::ControlField.new("001", "parent-id"))

          record.append(
            MARC::DataField.new(
              "245", "1", "0",
              [ "a", "Parent title /" ]
            )
          )
        end
      end

      it "removes trailing MARC punctuation" do
        expect(editor.title(record)).to eq("Parent title")
      end
    end
  end
end
