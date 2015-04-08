require 'spec_helper'
require 'logged'

RSpec.describe Logged::Formatter::SingleKey do
  subject { described_class.new(:foo) }

  it 'serializes data' do
    expect(subject.call(foo: 'bar', bar: 'foo')).to eq('bar')
  end
end
