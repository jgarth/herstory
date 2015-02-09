require 'rails_helper'

RSpec.describe Herstory do

  before :all do
    Note.logs_changes includes: [:parent]
    Thread.current[:current_user] = User.create({name: 'Joanne Doe'})
  end

  it "parses array options" do
    clean_options = Herstory.clean_options(includes: [:arrivals, :shipments])
    expect(clean_options).to eq({arrivals: {}, shipments: {}})
  end

  it "parses hash options" do
    clean_options = Herstory.clean_options(includes: {arrivals: {}, shipments: {superordinate: :none}})
    expect(clean_options).to eq({arrivals: {}, shipments: {superordinate: :none}})
  end

  it "parses no options" do
    clean_options = Herstory.clean_options()
    expect(clean_options).to eq({})
  end

  context "when included in a class" do

    it "provides a logs_changes_for? method" do
      expect(Note).to respond_to(:logs_changes_for?)
    end

    it "does not assign the callback twice" do
      count = Note._save_callbacks.count

      expect do
        Note.logs_changes includes: [:parent]
        count = Note._save_callbacks.count
      end.to change{ count }.by(0)

    end

  end


end
