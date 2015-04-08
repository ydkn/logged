require 'spec_helper'
require 'logged'

RSpec.describe Logged::Formatter::KeyValue do
  subject { described_class.new }

  it 'serializes data' do
    expect(subject.call(foo: 'bar', bar: 3.123)).to eq("foo='bar' bar=3.12")
  end

  it 'ignores nil values' do
    expect(subject.call(foo: 'bar', bar: nil)).to eq("foo='bar'")
  end
end
