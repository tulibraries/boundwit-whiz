module BoundWith
  class MarcEditor
    def purge_old_fields(rec:)
      type = rec.leader[6]
      is_holding_record = %w[x y].include?(type)

      if is_holding_record
        rec.fields.delete_if { |field| field.tag == "014" }
      else
        rec.fields.delete_if { |field| field.tag == "773" }
        rec.fields.delete_if { |field| field.tag == "774" }
      end

      rec
    end

    def add_014_field(parent:, child:)
      field = MARC::DataField.new(
        "014", "1", " ",
        [ "a", id(child) ]
      )

      parent.append(field)
    end

    def add_773_field(parent:, child:)
      field = MARC::DataField.new(
        "773", "1", " ",
        [ "t", title(parent) ],
        [ "w", id(parent) ]
      )

      child.append(field)
    end

    def add_774_field(parent:, child:)
      field = MARC::DataField.new(
        "774", "1", " ",
        [ "t", title(child) ],
        [ "w", id(child) ]
      )

      parent.append(field)
    end

    def add_501_field(rec:, recs:)
      content = bound_with_titles(rec, recs)

      duplicate = rec.fields("501").any? do |field|
        field["a"] == content &&
          field["5"] == "PPT"
      end

      return rec if duplicate

      field = MARC::DataField.new(
        "501", " ", " ",
        [ "a", content ],
        [ "5", "PPT" ]
      )

      rec.append(field)
      rec
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
  end
end
