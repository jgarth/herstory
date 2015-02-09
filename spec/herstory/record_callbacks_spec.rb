require 'rails_helper'

RSpec.describe Herstory::RecordCallbacks do

  before :all do
    Arrival.logs_changes includes: {users: {}, shipments: {superordinate: :record}}
    Thread.current[:current_user] = User.create({name: 'Joanne Doe'})
  end

  context "when included in a class" do
    it "doesn't log a creation event when invalid" do
      expect do
        Arrival.create(number_of_trucks: 0)
      end.to_not change(Event, :count)
    end

    it "logs a creation event when valid" do
      arrival = Arrival.create
      expect(arrival.events.first.type).to eq('created')
    end
  end

  context "when invalid save is triggered" do
    let(:arrival) { Herstory.without_logging { Arrival.create } }

    it "doesn't log attribute changes" do
      @params = {number_of_trucks: 0}

      expect do
        arrival.update(@params)
      end.to_not change(arrival.events.reload, :count)
    end

    it "doesn't log additions to collections" do
      shipment = arrival.shipments.build({pieces: 0})

      expect do
        begin
          arrival.shipments << shipment
        rescue
        end
      end.to_not change(arrival.events.reload, :count)
    end
  end

  context "when save is triggered" do
    let(:arrival) { Herstory.without_logging { Arrival.create } }

    it "logs attribute changes" do
      @params = {number_of_trucks: 21}

      expect do
        arrival.update(@params)
      end.to change(arrival.events.reload, :count).by(1)
    end
  end

end
