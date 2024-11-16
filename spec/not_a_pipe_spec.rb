require 'not_a_pipe'
require 'saharspec/its/with'

RSpec.describe NotAPipe do
  describe '.rewrite' do
    subject { described_class.rewrite(code) }

    matcher :be_equivalent do |expected|
      match do |actual|
        Unparser.parse(actual) == Unparser.parse(expected)
      end
    end

    it_with(code: 'a >> b') { is_expected.to be_equivalent '_ = a; _ = b(_)' }

    it_with(code: 'a >> b >> _.upcase') {
      is_expected.to be_equivalent <<~RUBY
        _ = a
        _ = b(_)
        _ = _.upcase
      RUBY
    }

    it_with(code: 'a >> b >> _.upcase >> [_, _]') {
      is_expected.to be_equivalent <<~RUBY
        _ = a
        _ = b(_)
        _ = _.upcase
        _ = [_, _]
      RUBY
    }

    it_with(code: 'uri >> URI.open >> _.read >> JSON.parse(symbolize_names: true) >> _.first') {
      is_expected.to be_equivalent <<~RUBY
        _ = uri
        _ = URI.open(_)
        _ = _.read
        _ = JSON.parse(_, symbolize_names: true)
        _ = _.first
      RUBY
    }

    it_with(code: 'uri = fetch_uri; uri >> URI.open >> _.read') {
      is_expected.to be_equivalent <<~RUBY
        uri = fetch_uri
        (
          _ = uri
          _ = URI.open(_)
          _ = _.read
        )
      RUBY
    }

    it_with(code: 'a = b >> c') { is_expected.to be_equivalent 'a = (_ = b; _ = c(_))' }

    it_with(code: 'def foo; a >> b; end') { is_expected.to be_equivalent 'def foo; _ = a; _ = b(_); end' }
  end

  describe '#not_a_pipe' do
    let(:klass) {
      Class.new do
        extend NotAPipe

        not_a_pipe def root(a)
          a >> Math.sqrt >> "sqrt(%i) = %i" % [a, _]
        end
      end
    }

    it { expect(klass.new.root(4)).to eq "sqrt(4) = 2" }
  end
end
