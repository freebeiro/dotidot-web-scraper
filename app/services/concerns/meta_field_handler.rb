# frozen_string_literal: true

# Handles meta field parsing and partitioning logic
module MetaFieldHandler
  extend ActiveSupport::Concern

  private

  def partition_fields(fields)
    css_fields = []
    meta_fields = []

    fields.each do |field|
      if field_is_meta_tag?(field)
        meta_fields << build_meta_field(field)
      else
        css_fields << field
      end
    end

    [css_fields, meta_fields]
  end

  def field_is_meta_tag?(field)
    # A field is a meta tag if it explicitly specifies type: "meta"
    # or if the name starts with "meta:" prefix
    return true if field[:type] == "meta" || field["type"] == "meta"

    # Check the name field for meta: prefix
    name = field[:name] || field["name"] || ""
    name.to_s.start_with?("meta:")
  end

  def build_meta_field(field)
    name = field[:name] || field["name"] || ""
    meta_field = {}

    if name.to_s.start_with?("meta:")
      meta_field[:name] = name.sub(/^meta:/, "")
      meta_field[:original_name] = name
    else
      meta_field[:name] = name
    end

    # Copy type if present
    type = field[:type] || field["type"]
    meta_field[:type] = type if type

    meta_field
  end
end
