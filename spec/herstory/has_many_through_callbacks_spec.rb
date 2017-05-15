require 'rails_helper'

RSpec.describe Herstory::HasManyThroughCallbacks do
  before(:all) do
    Arrival.logs_changes includes: {users: {}, shipments: {superordinate: :record}}
    Shipment.logs_changes includes: {arrivals: {superordinate: :other_record}, packs: {}}

    Thread.current[:current_user] = User.create({name: 'Joanne Doe'})
  end

  context "when a new record is added to has_many-through collection" do
    let(:arrival) { Herstory.without_logging { Arrival.create } }
    let(:shipment) { Herstory.without_logging { Shipment.create } }

    before :each do
      arrival.shipments << shipment
      expect do
        arrival.shipments << shipment
      end.to change{shipment.events.reload.count}.by(1)
    end

    it "logs an event on owner" do
      last_event = arrival.events.reload.first
      expect(last_event.type).to eq('shipment_attached')
    end

    it "logs an event on record" do
      last_event = shipment.events.reload.first
      expect(last_event.type).to eq('attached_to_arrival')
    end

    it "respects record position" do
      new_shipment = Shipment.create
      new_shipment.arrivals << arrival

      last_event = arrival.events.reload.first
      expect(last_event.type).to eq('shipment_attached')

      last_event = new_shipment.events.reload.first
      expect(last_event.type).to eq('attached_to_arrival')
    end
  end

  context "when a record is removed from has_many through: collection" do
    let(:arrival) { Herstory.without_logging { Arrival.create } }
    let(:shipment) { Herstory.without_logging { Shipment.create } }

    before :each do
      Herstory.without_logging do
        arrival.shipments << shipment
      end

      expect do
        arrival.shipments.delete shipment
      end.to change(Event, :count).by(2)
    end

    it "logs an event on owner" do
      last_event = arrival.events.reload.first
      expect(last_event.type).to eq('shipment_detached')
    end

    it "logs an event on record" do
      last_event = shipment.events.reload.first
      expect(last_event.type).to eq('detached_from_arrival')
    end
  end

  context "when a join model saves independently of association" do
    let(:arrival) { Herstory.without_logging { Arrival.create } }
    let(:shipment) { Herstory.without_logging { Shipment.create } }

    before(:each) do
      shipment.arrivals << arrival
    end

    it "saves no events" do
      arrival_load = shipment.arrival_loads.first

      expect do
        arrival_load.update(shipment_id: nil)
      end.to_not change(Event, :count)
    end
  end
end
