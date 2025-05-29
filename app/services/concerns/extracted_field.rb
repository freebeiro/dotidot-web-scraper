# frozen_string_literal: true

# Shared structure for extraction results across different strategies
# Provides a consistent interface for field extraction success/failure
module ExtractedField
  ExtractedField = Struct.new(:selector, :value, :error, keyword_init: true) do
    def success?
      error.nil?
    end

    def failed?
      !success?
    end
  end
end
