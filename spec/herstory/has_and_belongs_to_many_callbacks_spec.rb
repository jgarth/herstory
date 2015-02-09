require 'rails_helper'

RSpec.describe Herstory::HasAndBelongsToManyCallbacks do

  before(:all) do
    Shipment.logs_changes includes: {arrivals: {superordinate: :other_record}, packs: {}}
    Pack.logs_changes includes: [:shipments]

    Thread.current[:current_user] = User.create({name: 'Joanne Doe'})
  end

  context "when a new record is added to HABTM collection" do
    let(:shipment) { Herstory.without_logging { Shipment.create } }
    let(:pack) { Herstory.without_logging { Pack.create } }

    before(:each) do
      expect do
        shipment.packs << pack
      end.to change(Event, :count).by(2)
    end

    it 'logs an event on owner' do
      last_event = shipment.events.order('created_at DESC').reload.first
      expect(last_event.type).to eq('pack_attached')
    end

    it 'logs an event on record' do
      last_event = pack.events.order('created_at DESC').reload.first
      expect(last_event.type).to eq('shipment_attached')
    end
  end

  context "when a record is removed from a HABTM collection" do
    let(:shipment) { Herstory.without_logging { Shipment.create } }
    let(:pack) { Herstory.without_logging { Pack.create } }

    before(:each) do
      Herstory.without_logging { shipment.packs << pack }
      expect do
        shipment.packs.delete pack
      end.to change(Event, :count).by(2)
    end

    it 'logs an event on owner' do
      last_event = shipment.events.order('created_at DESC').reload.first
      expect(last_event.type).to eq('pack_detached')
    end

    it 'logs an event on record' do
      last_event = pack.events.order('created_at DESC').reload.first
      expect(last_event.type).to eq('shipment_detached')
    end

  end
end
