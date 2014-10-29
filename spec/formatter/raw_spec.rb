require 'spec_helper'
require 'logged'

RSpec.describe Logged::Formatter::Raw do
  subject { described_class.new }

  it 'serializes data' do
    expect(subject.call(foo: 'bar')).to eq(foo: 'bar')
  end
end
