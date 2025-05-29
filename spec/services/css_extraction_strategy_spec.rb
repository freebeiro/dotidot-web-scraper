# frozen_string_literal: true

require "rails_helper"

RSpec.describe CssExtractionStrategy do
  let(:html) do
    <<~HTML
      <html>
        <body>
          <h1 class="title">Page Title</h1>
          <div class="product" data-id="123">
            <h2 class="name">Product Name</h2>
            <p class="price">$99.99</p>
            <p class="description">This is a product description with <strong>bold text</strong>.</p>
          </div>
          <div class="product" data-id="456">
            <h2 class="name">Another Product</h2>
            <p class="price">$149.99</p>
            <p class="description">Another description here.</p>
          </div>
          <ul class="features">
            <li>Feature 1</li>
            <li>Feature 2</li>
            <li>Feature 3</li>
          </ul>
        </body>
      </html>
    HTML
  end

  let(:doc) { Nokogiri::HTML(html) }

  describe ".call" do
    context "basic extraction" do
      it "extracts single element text" do
        field = { name: "title", selector: "h1.title", type: "text" }

        result = described_class.call(doc, [field])

        expect(result[:success]).to be true
        expect(result[:data]["title"]).to eq("Page Title")
      end

      it "extracts multiple fields" do
        fields = [
          { name: "title", selector: "h1.title", type: "text" },
          { name: "first_product", selector: ".product .name", type: "text" },
          { name: "first_price", selector: ".product .price", type: "text" }
        ]

        result = described_class.call(doc, fields)

        expect(result[:success]).to be true
        expect(result[:data]["title"]).to eq("Page Title")
        expect(result[:data]["first_product"]).to eq("Product Name")
        expect(result[:data]["first_price"]).to eq("$99.99")
      end

      it "extracts attributes" do
        fields = [
          {
            name: "product_id",
            selector: ".product",
            type: "attribute",
            attribute: "data-id",
            multiple: false
          }
        ]

        result = described_class.call(doc, fields)

        expect(result[:success]).to be true
        expect(result[:data]["product_id"]).to eq("123")
      end

      it "extracts HTML content" do
        field = {
          name: "description_html",
          selector: ".description",
          type: "html"
        }

        result = described_class.call(doc, [field])

        expect(result[:success]).to be true
        expect(result[:data]["description_html"]).to include("<strong>bold text</strong>")
      end
    end

    context "multiple elements" do
      it "extracts all matching elements as array" do
        field = {
          name: "all_prices",
          selector: ".price",
          type: "text",
          multiple: true
        }

        result = described_class.call(doc, [field])

        expect(result[:success]).to be true
        expect(result[:data]["all_prices"]).to eq(["$99.99", "$149.99"])
      end

      it "extracts list items" do
        field = {
          name: "features",
          selector: ".features li",
          type: "text",
          multiple: true
        }

        result = described_class.call(doc, [field])

        expect(result[:success]).to be true
        expect(result[:data]["features"]).to eq(["Feature 1", "Feature 2", "Feature 3"])
      end

      it "returns empty array when no elements match" do
        field = {
          name: "nonexistent",
          selector: ".nonexistent",
          type: "text",
          multiple: true
        }

        result = described_class.call(doc, [field])

        expect(result[:success]).to be true
        expect(result[:data]["nonexistent"]).to be_nil
      end
    end

    context "text normalization" do
      let(:whitespace_html) do
        <<~HTML
          <div class="spaced">Multiple   spaces    here</div>
          <div class="newlines">Line 1
          Line 2

          Line 3</div>
          <pre class="preformatted">  Preserved    spacing  </pre>
          <div class="nbsp">Non&nbsp;breaking&nbsp;spaces</div>
        HTML
      end

      let(:whitespace_doc) { Nokogiri::HTML(whitespace_html) }

      it "normalizes whitespace in text extraction" do
        field = { name: "spaced", selector: ".spaced", type: "text" }

        result = described_class.call(whitespace_doc, [field])

        expect(result[:success]).to be true
        expect(result[:data]["spaced"]).to eq("Multiple spaces here")
      end

      it "handles newlines" do
        field = { name: "lines", selector: ".newlines", type: "text" }

        result = described_class.call(whitespace_doc, [field])

        expect(result[:success]).to be true
        expect(result[:data]["lines"]).to eq("Line 1 Line 2 Line 3")
      end

      it "preserves whitespace in preformatted text" do
        field = { name: "pre", selector: ".preformatted", type: "text" }

        result = described_class.call(whitespace_doc, [field])

        expect(result[:success]).to be true
        # Pre tags should preserve internal spacing but trim edges
        expect(result[:data]["pre"]).to match(/Preserved\s+spacing/)
      end

      it "handles non-breaking spaces" do
        field = { name: "nbsp", selector: ".nbsp", type: "text" }

        result = described_class.call(whitespace_doc, [field])

        expect(result[:success]).to be true
        expect(result[:data]["nbsp"]).to eq("Non breaking spaces")
      end
    end

    context "error handling" do
      it "handles missing elements gracefully" do
        field = { name: "missing", selector: ".nonexistent", type: "text" }

        result = described_class.call(doc, [field])

        expect(result[:success]).to be true
        expect(result[:data]["missing"]).to be_nil
      end

      it "handles missing attributes" do
        field = {
          name: "missing_attr",
          selector: ".title",
          type: "attribute",
          attribute: "nonexistent"
        }

        result = described_class.call(doc, [field])

        expect(result[:success]).to be true
        expect(result[:data]["missing_attr"]).to be_nil
      end

      it "handles nil document" do
        result = described_class.call(nil, [])

        expect(result[:success]).to be false
        expect(result[:error]).to include("Document is nil")
      end

      it "handles empty fields array" do
        result = described_class.call(doc, [])

        expect(result[:success]).to be true
        expect(result[:data]).to eq({})
      end

      it "validates field types" do
        field = {
          name: "unknown_type",
          selector: ".title",
          type: "unknown"
        }

        result = described_class.call(doc, [field])

        expect(result[:success]).to be true
        # Unknown types default to text extraction
        expect(result[:data]["unknown_type"]).to eq("Page Title")
      end
    end

    context "complex selectors" do
      it "handles descendant selectors" do
        field = { name: "nested", selector: ".product .name", type: "text" }

        result = described_class.call(doc, [field])

        expect(result[:success]).to be true
        expect(result[:data]["nested"]).to eq("Product Name")
      end

      it "handles attribute selectors" do
        field = { name: "specific_product", selector: "[data-id='456'] .name", type: "text" }

        result = described_class.call(doc, [field])

        expect(result[:success]).to be true
        expect(result[:data]["specific_product"]).to eq("Another Product")
      end

      it "handles combinators" do
        field = { name: "adjacent", selector: ".product + .product .name", type: "text" }

        result = described_class.call(doc, [field])

        expect(result[:success]).to be true
        expect(result[:data]["adjacent"]).to eq("Another Product")
      end
    end

    context "edge cases" do
      it "handles empty text nodes" do
        empty_html = "<div class='empty'></div>"
        empty_doc = Nokogiri::HTML(empty_html)
        field = { name: "empty", selector: ".empty", type: "text" }

        result = described_class.call(empty_doc, [field])

        expect(result[:success]).to be true
        expect(result[:data]["empty"]).to eq("")
      end

      it "handles special characters in selectors" do
        special_html = "<div class='test-class_name'>Special Content</div>"
        special_doc = Nokogiri::HTML(special_html)
        field = { name: "special", selector: ".test-class_name", type: "text" }

        result = described_class.call(special_doc, [field])

        expect(result[:success]).to be true
        expect(result[:data]["special"]).to eq("Special Content")
      end

      it "handles very long text content" do
        long_text = "a" * 10_000
        long_html = "<div class='long'>#{long_text}</div>"
        long_doc = Nokogiri::HTML(long_html)
        field = { name: "long", selector: ".long", type: "text" }

        result = described_class.call(long_doc, [field])

        expect(result[:success]).to be true
        expect(result[:data]["long"]).to eq(long_text)
      end
    end
  end
end
