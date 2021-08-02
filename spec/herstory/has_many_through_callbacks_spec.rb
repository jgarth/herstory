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

    it "does not prevent event creation when enclosing association creation in 'without_logging'" do

      # It seems that even the original author of Herstory assumed
      # that associating objects in a 'without_logging' block would
      # prevent events from being created. Looks like this is not
      # true.

      expect do
        Herstory.without_logging do
          arrival.shipments << shipment
        end
      end.to change { shipment.events.reload.count }.by(1)
               .and change { arrival.events.reload.count }.by(1)
    end
  end

  context "when a record is removed from has_many through: collection" do

    # The test setup now writes a shipment and and an arrival (that
    # are never explicitly used in any test) to the database.  This
    # allows the following tests to make sure that the methods
    # gathering the different IDs required in the log entries are do
    # not confuse shipment IDs with arrival IDs.

    let(:shipment_id) { 1000003 }
    let(:unused_arrival_id) { 1000003 }
    let(:arrival_id) { 99991 }
    let(:unused_shipment_id) { 99991 }

    let!(:unused_arrival) { Herstory.without_logging { Arrival.create(id: unused_arrival_id) } }
    let(:arrival) { Herstory.without_logging { Arrival.create(id: arrival_id) } }
    let!(:unused_shipment) { Herstory.without_logging { Shipment.create(id: unused_shipment_id) } }
    let(:shipment) { Herstory.without_logging { Shipment.create(id: shipment_id) } }

    before :each do
      arrival.shipments << shipment
    end

    it 'logs two events when deleting an association' do
      expect do
        arrival.shipments.delete shipment
      end.to change(Event, :count).by(2)
    end

    it 'logs two two deletion events when deleting an association' do
      expect do
        arrival.shipments.delete shipment
      end.to change(Event.where(type: ['shipment_detached', 'detached_from_arrival']), :count).by(2)
    end

    it "logs an event on owner" do
      arrival.shipments.delete shipment
      deletion_event = arrival.events.reload.where(type: 'shipment_detached').first

      expect(deletion_event.parent_type).to eq('Arrival')
      expect(deletion_event.parent_id).to eq(arrival_id)
      expect(deletion_event.previously_associated_object_type).to eq('Shipment')
      expect(deletion_event.previously_associated_object_id).to eq(shipment_id)
    end

    it "logs an event on record" do
        arrival.shipments.delete shipment
      deletion_event = shipment.events.reload.where(type: 'detached_from_arrival').first

      expect(deletion_event.parent_type).to eq('Shipment')
      expect(deletion_event.parent_id).to eq(shipment_id)
      expect(deletion_event.previously_associated_object_type).to eq('Arrival')
      expect(deletion_event.previously_associated_object_id).to eq(arrival_id)
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
