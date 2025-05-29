require 'rails_helper'

RSpec.describe HtmlParserService do
  describe '.call' do
    context 'with valid HTML' do
      let(:html) { '<html><body><h1>Hello World</h1><p>Test content</p></body></html>' }

      it 'returns parsed document' do
        result = described_class.call(html)
        
        expect(result[:success]).to be true
        expect(result[:doc]).to be_a(Nokogiri::HTML::Document)
        expect(result[:doc].at('h1').text).to eq('Hello World')
        expect(result[:doc].at('p').text).to eq('Test content')
      end

      it 'preserves document structure' do
        complex_html = <<~HTML
          <html>
            <head><title>Test Page</title></head>
            <body>
              <div class="container">
                <h1>Title</h1>
                <ul>
                  <li>Item 1</li>
                  <li>Item 2</li>
                </ul>
              </div>
            </body>
          </html>
        HTML

        result = described_class.call(complex_html)
        
        expect(result[:success]).to be true
        expect(result[:doc].at('title').text).to eq('Test Page')
        expect(result[:doc].css('li').map(&:text)).to eq(['Item 1', 'Item 2'])
      end

      it 'handles nested elements' do
        nested_html = <<~HTML
          <div>
            <p>Level 1
              <span>Level 2
                <strong>Level 3</strong>
              </span>
            </p>
          </div>
        HTML

        result = described_class.call(nested_html)
        
        expect(result[:success]).to be true
        expect(result[:doc].at('strong').text).to eq('Level 3')
      end
    end

    context 'with malformed HTML' do
      it 'handles unclosed tags' do
        html = '<div><p>Unclosed paragraph<div>Another div</div>'
        
        result = described_class.call(html)
        
        expect(result[:success]).to be true
        expect(result[:doc].css('div').count).to eq(2)
      end

      it 'handles missing closing tags' do
        html = '<html><body><p>Paragraph 1<p>Paragraph 2</body></html>'
        
        result = described_class.call(html)
        
        expect(result[:success]).to be true
        expect(result[:doc].css('p').count).to eq(2)
      end

      it 'handles incorrectly nested tags' do
        html = '<p><div>Invalid nesting</div></p>'
        
        result = described_class.call(html)
        
        expect(result[:success]).to be true
        expect(result[:doc].at('div')).not_to be_nil
      end

      it 'recovers from broken attributes' do
        html = '<div class="test" invalid=no-quotes data-id="123">Content</div>'
        
        result = described_class.call(html)
        
        expect(result[:success]).to be true
        expect(result[:doc].at('div')['class']).to eq('test')
        expect(result[:doc].at('div')['data-id']).to eq('123')
      end
    end

    context 'encoding handling' do
      it 'handles UTF-8 content' do
        html = '<html><body><p>Hello 世界 🌍</p></body></html>'
        
        result = described_class.call(html)
        
        expect(result[:success]).to be true
        expect(result[:doc].at('p').text).to eq('Hello 世界 🌍')
      end

      it 'handles ISO-8859-1 content' do
        html = "<html><body><p>Café résumé</p></body></html>".encode('ISO-8859-1')
        
        result = described_class.call(html)
        
        expect(result[:success]).to be true
        expect(result[:doc].at('p').text).to include('Café')
      end

      it 'handles Windows-1252 content' do
        html = '<html><body><p>Smart quotes: "test"</p></body></html>'
        
        result = described_class.call(html)
        
        expect(result[:success]).to be true
        expect(result[:doc].at('p').text).to include('quotes')
      end

      it 'detects encoding from meta tag' do
        html = <<~HTML
          <html>
            <head>
              <meta charset="UTF-8">
            </head>
            <body><p>Unicode: ♠♣♥♦</p></body>
          </html>
        HTML

        result = described_class.call(html)
        
        expect(result[:success]).to be true
        expect(result[:doc].at('p').text).to include('♠♣♥♦')
      end

      it 'handles BOM markers' do
        html_with_bom = "\xEF\xBB\xBF<html><body><p>BOM test</p></body></html>"
        
        result = described_class.call(html_with_bom)
        
        expect(result[:success]).to be true
        expect(result[:doc].at('p').text).to eq('BOM test')
      end
    end

    context 'size limits' do
      it 'accepts normal-sized documents' do
        html = '<html><body>' + '<p>Paragraph</p>' * 1000 + '</body></html>'
        
        result = described_class.call(html)
        
        expect(result[:success]).to be true
        expect(result[:doc].css('p').count).to eq(1000)
      end

      it 'rejects oversized documents' do
        # Create 11MB HTML (over 10MB limit)
        large_html = '<html><body><p>' + 'x' * 11_000_000 + '</p></body></html>'
        
        result = described_class.call(large_html)
        
        expect(result[:success]).to be false
        expect(result[:error]).to include('HTML content too large')
      end

      it 'handles documents at size boundary' do
        # Just under 10MB
        boundary_html = '<html><body><p>' + 'x' * 9_999_000 + '</p></body></html>'
        
        result = described_class.call(boundary_html)
        
        expect(result[:success]).to be true
      end
    end

    context 'special HTML elements' do
      it 'preserves script tags' do
        html = <<~HTML
          <html>
            <body>
              <script>console.log('test');</script>
              <p>Content</p>
            </body>
          </html>
        HTML

        result = described_class.call(html)
        
        expect(result[:success]).to be true
        expect(result[:doc].at('script').text).to include('console.log')
      end

      it 'preserves style tags' do
        html = <<~HTML
          <html>
            <head>
              <style>body { color: red; }</style>
            </head>
            <body><p>Styled content</p></body>
          </html>
        HTML

        result = described_class.call(html)
        
        expect(result[:success]).to be true
        expect(result[:doc].at('style').text).to include('color: red')
      end

      it 'handles comments' do
        html = <<~HTML
          <html>
            <body>
              <!-- This is a comment -->
              <p>Content</p>
              <!-- Another comment -->
            </body>
          </html>
        HTML

        result = described_class.call(html)
        
        expect(result[:success]).to be true
        expect(result[:doc].xpath('//comment()').count).to eq(2)
      end

      it 'handles CDATA sections' do
        html = <<~HTML
          <html>
            <body>
              <script>
                <![CDATA[
                  function test() { return 1 < 2; }
                ]]>
              </script>
            </body>
          </html>
        HTML

        result = described_class.call(html)
        
        expect(result[:success]).to be true
        expect(result[:doc].at('script')).not_to be_nil
      end

      it 'handles HTML entities' do
        html = '<html><body><p>&lt;tag&gt; &amp; &quot;quotes&quot; &apos;apostrophe&apos;</p></body></html>'
        
        result = described_class.call(html)
        
        expect(result[:success]).to be true
        expect(result[:doc].at('p').text).to eq('<tag> & "quotes" \'apostrophe\'')
      end
    end

    context 'error handling' do
      it 'handles nil input' do
        result = described_class.call(nil)
        
        expect(result[:success]).to be false
        expect(result[:error]).to include('HTML content cannot be nil')
      end

      it 'handles empty string' do
        result = described_class.call('')
        
        expect(result[:success]).to be false
        expect(result[:error]).to include('HTML content cannot be empty')
      end

      it 'handles binary data' do
        binary_data = "\x00\x01\x02\x03\x04"
        
        result = described_class.call(binary_data)
        
        expect(result[:success]).to be false
        expect(result[:error]).to include('Invalid HTML')
      end

      it 'handles invalid encoding' do
        invalid_utf8 = "\xFF\xFE"
        
        result = described_class.call(invalid_utf8)
        
        # Should still try to parse
        expect(result[:success]).to be true
      end
    end

    context 'HTML5 features' do
      it 'handles HTML5 semantic elements' do
        html = <<~HTML
          <html>
            <body>
              <header>Header</header>
              <nav>Navigation</nav>
              <main>
                <article>Article</article>
                <section>Section</section>
              </main>
              <footer>Footer</footer>
            </body>
          </html>
        HTML

        result = described_class.call(html)
        
        expect(result[:success]).to be true
        expect(result[:doc].at('header').text).to eq('Header')
        expect(result[:doc].at('article').text).to eq('Article')
      end

      it 'handles data attributes' do
        html = '<div data-id="123" data-name="test" data-complex-name="value">Content</div>'
        
        result = described_class.call(html)
        
        expect(result[:success]).to be true
        expect(result[:doc].at('div')['data-id']).to eq('123')
        expect(result[:doc].at('div')['data-name']).to eq('test')
        expect(result[:doc].at('div')['data-complex-name']).to eq('value')
      end

      it 'handles custom elements' do
        html = '<my-component attr="value"><inner-element>Content</inner-element></my-component>'
        
        result = described_class.call(html)
        
        expect(result[:success]).to be true
        expect(result[:doc].at('my-component')).not_to be_nil
        expect(result[:doc].at('inner-element').text).to eq('Content')
      end
    end

    context 'performance' do
      it 'parses quickly for typical documents' do
        html = '<html><body>' + '<div><p>Content</p></div>' * 100 + '</body></html>'
        
        start_time = Time.current
        result = described_class.call(html)
        elapsed = Time.current - start_time
        
        expect(result[:success]).to be true
        expect(elapsed).to be < 0.1 # Should parse in under 100ms
      end

      it 'handles deeply nested structures' do
        # Create 50 levels of nesting
        opening_tags = '<div>' * 50
        closing_tags = '</div>' * 50
        html = "#{opening_tags}<p>Deep content</p>#{closing_tags}"
        
        result = described_class.call(html)
        
        expect(result[:success]).to be true
        expect(result[:doc].at('p').text).to eq('Deep content')
      end
    end

    context 'whitespace handling' do
      it 'preserves significant whitespace' do
        html = '<pre>  Line 1\n    Line 2\n      Line 3</pre>'
        
        result = described_class.call(html)
        
        expect(result[:success]).to be true
        expect(result[:doc].at('pre').text).to include('    Line 2')
      end

      it 'normalizes whitespace in regular elements' do
        html = '<p>  Multiple   spaces   and\n\nnewlines  </p>'
        
        result = described_class.call(html)
        
        expect(result[:success]).to be true
        # Nokogiri preserves whitespace, normalization happens in extraction
        expect(result[:doc].at('p').text).to include('Multiple   spaces')
      end

      it 'handles non-breaking spaces' do
        html = '<p>Non&nbsp;breaking&nbsp;spaces</p>'
        
        result = described_class.call(html)
        
        expect(result[:success]).to be true
        expect(result[:doc].at('p').text).to include('Non breaking spaces')
      end
    end

    context 'edge cases' do
      it 'handles very long attribute values' do
        long_value = 'x' * 10000
        html = %Q{<div data-long="#{long_value}">Content</div>}
        
        result = described_class.call(html)
        
        expect(result[:success]).to be true
        expect(result[:doc].at('div')['data-long'].length).to eq(10000)
      end

      it 'handles many attributes' do
        attrs = (1..100).map { |i| %Q{data-attr#{i}="value#{i}"} }.join(' ')
        html = "<div #{attrs}>Content</div>"
        
        result = described_class.call(html)
        
        expect(result[:success]).to be true
        expect(result[:doc].at('div')['data-attr50']).to eq('value50')
      end

      it 'handles unusual tag names' do
        html = '<x-1><y_2><z-element>Content</z-element></y_2></x-1>'
        
        result = described_class.call(html)
        
        expect(result[:success]).to be true
        expect(result[:doc].at('z-element').text).to eq('Content')
      end

      it 'handles mixed content' do
        html = '<p>Text <strong>bold</strong> more text <em>italic</em> end</p>'
        
        result = described_class.call(html)
        
        expect(result[:success]).to be true
        expect(result[:doc].at('p').text).to eq('Text bold more text italic end')
        expect(result[:doc].at('strong').text).to eq('bold')
        expect(result[:doc].at('em').text).to eq('italic')
      end
    end
  end
end