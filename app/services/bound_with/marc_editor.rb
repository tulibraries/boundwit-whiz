module BoundWith
  class MarcEditor
    def add_014_field(parent:, child:)
      new_field = MARC::DataField.new(
        "014", "1", " ",
        [ "a", id(child) ]
      )

      append_field(new_field:, rec: parent)
    end

    def add_773_field(parent:, child:)
      new_field = MARC::DataField.new(
        "773", "1", " ",
        [ "t", title(parent) ],
        [ "w", id(parent) ]
      )

      append_field(new_field:, rec: child)
    end

    def add_774_field(parent:, child:)
      new_field = MARC::DataField.new(
        "774", "1", " ",
        [ "t", title(child) ],
        [ "w", id(child) ]
      )

      append_field(new_field:, rec: parent)
    end

    def add_501_field(rec:, recs:)
      new_field = MARC::DataField.new(
        "501", " ", " ",
        [ "a", bound_with_titles(rec, recs) ],
        [ "5", "PPT" ]
      )

      append_field(new_field:, rec:)
    end

    def title(rec)
      rec["245"]["a"].sub(/[\s\/:;,.]+\z/, "")
    end

    def id(rec)
      rec["001"].value
    end

    def bound_with_titles(except_rec, recs)
      except_id = id(except_rec)

      titles = recs
        .reject { |rec| id(rec) == except_id }
        .map { |rec| title(rec) }
        .join(" -- ")

      "Bound with: #{titles}."
    end

    private

    def append_field(new_field:, rec:)
      tag = new_field.tag
      if rec.fields(tag).any? { |f| f == new_field }
        rec
      else
        rec.append(new_field)
      end
    end
  end
end
