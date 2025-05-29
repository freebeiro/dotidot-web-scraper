require 'rails_helper'

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

  describe '.call' do
    context 'basic extraction' do
      it 'extracts single element text' do
        field = ExtractedField.new(name: 'title', selector: 'h1.title', type: 'text')
        
        result = described_class.call(doc, [field])
        
        expect(result[:success]).to be true
        expect(result[:data]['title']).to eq('Page Title')
      end

      it 'extracts multiple fields' do
        fields = [
          ExtractedField.new(name: 'title', selector: 'h1.title', type: 'text'),
          ExtractedField.new(name: 'first_product', selector: '.product:first .name', type: 'text'),
          ExtractedField.new(name: 'first_price', selector: '.product:first .price', type: 'text')
        ]
        
        result = described_class.call(doc, fields)
        
        expect(result[:success]).to be true
        expect(result[:data]['title']).to eq('Page Title')
        expect(result[:data]['first_product']).to eq('Product Name')
        expect(result[:data]['first_price']).to eq('$99.99')
      end

      it 'extracts attributes' do
        field = ExtractedField.new(
          name: 'product_id', 
          selector: '.product:first', 
          type: 'attribute',
          attribute: 'data-id'
        )
        
        result = described_class.call(doc, fields: [field])
        
        expect(result[:success]).to be true
        expect(result[:data]['product_id']).to eq('123')
      end

      it 'extracts HTML content' do
        field = ExtractedField.new(
          name: 'description_html', 
          selector: '.description:first', 
          type: 'html'
        )
        
        result = described_class.call(doc, fields: [field])
        
        expect(result[:success]).to be true
        expect(result[:data]['description_html']).to include('<strong>bold text</strong>')
      end
    end

    context 'multiple elements' do
      it 'extracts all matching elements as array' do
        field = ExtractedField.new(
          name: 'all_prices', 
          selector: '.price', 
          type: 'text',
          multiple: true
        )
        
        result = described_class.call(doc, fields: [field])
        
        expect(result[:success]).to be true
        expect(result[:data]['all_prices']).to eq(['$99.99', '$149.99'])
      end

      it 'extracts list items' do
        field = ExtractedField.new(
          name: 'features', 
          selector: '.features li', 
          type: 'text',
          multiple: true
        )
        
        result = described_class.call(doc, fields: [field])
        
        expect(result[:success]).to be true
        expect(result[:data]['features']).to eq(['Feature 1', 'Feature 2', 'Feature 3'])
      end

      it 'returns empty array when no elements match' do
        field = ExtractedField.new(
          name: 'missing', 
          selector: '.nonexistent', 
          type: 'text',
          multiple: true
        )
        
        result = described_class.call(doc, fields: [field])
        
        expect(result[:success]).to be true
        expect(result[:data]['missing']).to eq([])
      end
    end

    context 'text normalization' do
      let(:whitespace_html) do
        <<~HTML
          <html>
            <body>
              <p class="spaced">  Multiple   spaces   here  </p>
              <p class="newlines">
                Line 1
                Line 2
                Line 3
              </p>
              <pre class="preformatted">  Preserved   spacing  </pre>
              <p class="nbsp">Non&nbsp;breaking&nbsp;spaces</p>
            </body>
          </html>
        HTML
      end
      
      let(:whitespace_doc) { Nokogiri::HTML(whitespace_html) }

      it 'normalizes whitespace in text extraction' do
        field = ExtractedField.new(name: 'spaced', selector: '.spaced', type: 'text')
        
        result = described_class.call(whitespace_doc, fields: [field])
        
        expect(result[:success]).to be true
        expect(result[:data]['spaced']).to eq('Multiple spaces here')
      end

      it 'handles newlines' do
        field = ExtractedField.new(name: 'lines', selector: '.newlines', type: 'text')
        
        result = described_class.call(whitespace_doc, fields: [field])
        
        expect(result[:success]).to be true
        expect(result[:data]['lines']).to eq('Line 1 Line 2 Line 3')
      end

      it 'preserves whitespace in preformatted text' do
        field = ExtractedField.new(name: 'pre', selector: '.preformatted', type: 'text')
        
        result = described_class.call(whitespace_doc, fields: [field])
        
        expect(result[:success]).to be true
        # Pre tags should preserve internal spacing but trim edges
        expect(result[:data]['pre']).to match(/Preserved\s+spacing/)
      end

      it 'handles non-breaking spaces' do
        field = ExtractedField.new(name: 'nbsp', selector: '.nbsp', type: 'text')
        
        result = described_class.call(whitespace_doc, fields: [field])
        
        expect(result[:success]).to be true
        expect(result[:data]['nbsp']).to eq('Non breaking spaces')
      end
    end

    context 'error handling' do
      it 'handles missing elements gracefully' do
        field = ExtractedField.new(name: 'missing', selector: '.nonexistent', type: 'text')
        
        result = described_class.call(doc, fields: [field])
        
        expect(result[:success]).to be true
        expect(result[:data]['missing']).to be_nil
      end

      it 'handles invalid selectors' do
        field = ExtractedField.new(name: 'invalid', selector: '!!!invalid', type: 'text')
        
        result = described_class.call(doc, fields: [field])
        
        expect(result[:success]).to be false
        expect(result[:error]).to include('CSS selector error')
      end

      it 'handles missing attributes' do
        field = ExtractedField.new(
          name: 'missing_attr', 
          selector: '.title', 
          type: 'attribute',
          attribute: 'nonexistent'
        )
        
        result = described_class.call(doc, fields: [field])
        
        expect(result[:success]).to be true
        expect(result[:data]['missing_attr']).to be_nil
      end

      it 'handles nil document' do
        result = described_class.call(nil, fields: [])
        
        expect(result[:success]).to be false
        expect(result[:error]).to include('Document is nil')
      end

      it 'handles empty fields array' do
        result = described_class.call(doc, fields: [])
        
        expect(result[:success]).to be true
        expect(result[:data]).to eq({})
      end

      it 'validates field types' do
        field = ExtractedField.new(
          name: 'invalid_type', 
          selector: '.title', 
          type: 'invalid'
        )
        
        result = described_class.call(doc, fields: [field])
        
        expect(result[:success]).to be false
        expect(result[:error]).to include('Unknown extraction type')
      end
    end

    context 'complex selectors' do
      it 'handles pseudo-selectors' do
        fields = [
          ExtractedField.new(name: 'first_li', selector: 'li:first-child', type: 'text'),
          ExtractedField.new(name: 'last_li', selector: 'li:last-child', type: 'text'),
          ExtractedField.new(name: 'second_li', selector: 'li:nth-child(2)', type: 'text')
        ]
        
        result = described_class.call(doc, fields: fields)
        
        expect(result[:success]).to be true
        expect(result[:data]['first_li']).to eq('Feature 1')
        expect(result[:data]['last_li']).to eq('Feature 3')
        expect(result[:data]['second_li']).to eq('Feature 2')
      end

      it 'handles descendant selectors' do
        field = ExtractedField.new(
          name: 'nested', 
          selector: '.product .description strong', 
          type: 'text'
        )
        
        result = described_class.call(doc, fields: [field])
        
        expect(result[:success]).to be true
        expect(result[:data]['nested']).to eq('bold text')
      end

      it 'handles attribute selectors' do
        field = ExtractedField.new(
          name: 'specific_product', 
          selector: '[data-id="456"] .name', 
          type: 'text'
        )
        
        result = described_class.call(doc, fields: [field])
        
        expect(result[:success]).to be true
        expect(result[:data]['specific_product']).to eq('Another Product')
      end

      it 'handles combinators' do
        html_with_siblings = <<~HTML
          <div>
            <h1>Title</h1>
            <p class="after-h1">Text after H1</p>
            <p>Another paragraph</p>
          </div>
        HTML
        doc_siblings = Nokogiri::HTML(html_with_siblings)
        
        field = ExtractedField.new(
          name: 'sibling', 
          selector: 'h1 + p', 
          type: 'text'
        )
        
        result = described_class.call(doc_siblings, fields: [field])
        
        expect(result[:success]).to be true
        expect(result[:data]['sibling']).to eq('Text after H1')
      end
    end

    context 'transformation options' do
      it 'applies text transformations' do
        field = ExtractedField.new(
          name: 'uppercase_title', 
          selector: 'h1.title', 
          type: 'text',
          transform: ->(text) { text.upcase }
        )
        
        result = described_class.call(doc, fields: [field])
        
        expect(result[:success]).to be true
        expect(result[:data]['uppercase_title']).to eq('PAGE TITLE')
      end

      it 'applies regex extraction' do
        field = ExtractedField.new(
          name: 'price_number', 
          selector: '.price', 
          type: 'text',
          pattern: /\$([\d.]+)/
        )
        
        result = described_class.call(doc, fields: [field])
        
        expect(result[:success]).to be true
        expect(result[:data]['price_number']).to eq('99.99')
      end

      it 'handles transformation errors' do
        field = ExtractedField.new(
          name: 'error_transform', 
          selector: '.title', 
          type: 'text',
          transform: ->(text) { raise 'Transform error' }
        )
        
        result = described_class.call(doc, fields: [field])
        
        expect(result[:success]).to be false
        expect(result[:error]).to include('Transform error')
      end
    end

    context 'performance' do
      let(:large_html) do
        items = (1..1000).map { |i| "<li class='item'>Item #{i}</li>" }.join
        "<html><body><ul>#{items}</ul></body></html>"
      end
      let(:large_doc) { Nokogiri::HTML(large_html) }

      it 'efficiently extracts from large documents' do
        field = ExtractedField.new(
          name: 'items', 
          selector: '.item', 
          type: 'text',
          multiple: true
        )
        
        start_time = Time.current
        result = described_class.call(large_doc, fields: [field])
        elapsed = Time.current - start_time
        
        expect(result[:success]).to be true
        expect(result[:data]['items'].length).to eq(1000)
        expect(elapsed).to be < 1.0 # Should process 1000 items in under 1 second
      end

      it 'caches selector results' do
        fields = [
          ExtractedField.new(name: 'title1', selector: '.title', type: 'text'),
          ExtractedField.new(name: 'title2', selector: '.title', type: 'html'),
          ExtractedField.new(name: 'title3', selector: '.title', type: 'attribute', attribute: 'class')
        ]
        
        # Should only query the selector once despite three fields using it
        expect(doc).to receive(:css).with('.title').once.and_call_original
        
        described_class.call(doc, fields: fields)
      end
    end

    context 'edge cases' do
      it 'handles empty text nodes' do
        empty_html = '<p class="empty"></p><p class="whitespace">   </p>'
        empty_doc = Nokogiri::HTML(empty_html)
        
        fields = [
          ExtractedField.new(name: 'empty', selector: '.empty', type: 'text'),
          ExtractedField.new(name: 'whitespace', selector: '.whitespace', type: 'text')
        ]
        
        result = described_class.call(empty_doc, fields: fields)
        
        expect(result[:success]).to be true
        expect(result[:data]['empty']).to eq('')
        expect(result[:data]['whitespace']).to eq('')
      end

      it 'handles special characters in selectors' do
        special_html = '<div id="test:id" class="test.class">Content</div>'
        special_doc = Nokogiri::HTML(special_html)
        
        field = ExtractedField.new(
          name: 'special', 
          selector: '#test\\:id', 
          type: 'text'
        )
        
        result = described_class.call(special_doc, fields: [field])
        
        expect(result[:success]).to be true
        expect(result[:data]['special']).to eq('Content')
      end

      it 'handles very long text content' do
        long_text = 'x' * 10000
        long_html = "<p class='long'>#{long_text}</p>"
        long_doc = Nokogiri::HTML(long_html)
        
        field = ExtractedField.new(name: 'long', selector: '.long', type: 'text')
        
        result = described_class.call(long_doc, fields: [field])
        
        expect(result[:success]).to be true
        expect(result[:data]['long'].length).to eq(10000)
      end

      it 'handles circular references in transform' do
        field = ExtractedField.new(
          name: 'circular', 
          selector: '.title', 
          type: 'text',
          transform: ->(text, context) { context[:data]['circular'] || text }
        )
        
        result = described_class.call(doc, fields: [field])
        
        expect(result[:success]).to be true
        expect(result[:data]['circular']).to eq('Page Title')
      end
    end
  end
end