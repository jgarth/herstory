require 'rails_helper'

RSpec.describe LogsChanges do

  before :all do
    Arrival.logs_changes includes: [users: {}, shipments: {superordinate: :record}]
    Shipment.logs_changes includes: {arrivals: {superordinate: :other_record}}
    User.logs_changes includes: [:arrival]
    ArrivalLoad.logs_changes
    Thread.current[:current_user] = User.create({name: 'Joanne Doe'})
  end

  context "when included in a class" do

    it "assigns an after_save callback" do
      # One callback is defined by default so
      # we expect there to be two callbacks
      expect(Arrival._save_callbacks.count).to eq(2)
      expect(User._save_callbacks.count).to eq(4)
      expect(ArrivalLoad._save_callbacks.count).to eq(5)
    end

    it "doesn't log a creation event when invalid" do
      expect do
        @arrival = Arrival.create(number_of_trucks: 0)
      end.to_not change(Event, :count)
    end

    it "logs a creation event" do
      @arrival = Arrival.create
      expect(@arrival.events.first.type).to eq('created')
    end

  end

  context "when invalid save is triggered" do
    let(:arrival) { Arrival.without_logging { Arrival.create } }

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
    let(:shipment) { Shipment.new }
    let(:arrival) { Arrival.without_logging { Arrival.create } }

    it "logs attribute changes" do
      @params = {number_of_trucks: 21}

      expect do
        arrival.update(@params)
      end.to change(arrival.events.reload, :count).by(1)
    end
  end

  context "when a new record is added to has_many-through collection" do
    let(:arrival) { Arrival.without_logging { Arrival.create } }
    let(:shipment) { Shipment.without_logging { Shipment.create } }

    before :each do
      expect do
        arrival.shipments << shipment
      end.to change(shipment.events.reload, :count).by(1)
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

  context "when a belongs_to association is set" do
    let(:arrival) { Arrival.without_logging { Arrival.create } }
    let(:user) { User.without_logging { User.create(name: 'John Wayne') } }

    it "logs events for addition" do
      expect do
        user.update(arrival: arrival)
      end.to change(Event, :count).by(2)

      expect(user.events.reload.first.type).to eq('arrival_attached')
      expect(arrival.events.reload.first.type).to eq('user_attached')
    end

    it "logs events for deletion" do
      user.update(arrival: arrival)

      expect do
        user.update(arrival: nil)
      end.to change(Event, :count).by(2)

      expect(user.events.reload.first.type).to eq('arrival_detached')
      expect(arrival.events.reload.first.type).to eq('user_detached')
    end

    it "logs events for change" do
      user.update(arrival: arrival)

      expect do
        new_arrival = Arrival.without_logging { Arrival.create }
        user.update(arrival: new_arrival)
      end.to change(Event, :count).by(4)
    end
  end

  context "when a new record is added to has_many collection" do
    let(:arrival) { Arrival.without_logging { Arrival.create } }
    let(:user) { User.without_logging { User.create(name: 'John Wayne') } }

    before :each do
      expect do
        arrival.users << user

      end.to change(Event, :count).by(2)
    end

    it "logs an event on owner" do
      last_event = arrival.events.reload.first
      expect(last_event.type).to eq('user_attached')
    end

    it "logs an event on record" do
      last_event = user.events.reload.first
      expect(last_event.type).to eq('arrival_attached')
    end
  end

  context "when a record is removed from has_many through: collection" do
    let(:arrival) { Arrival.without_logging { Arrival.create } }
    let(:shipment) { Shipment.without_logging { Shipment.create } }

    before :each do
      Arrival.without_logging do
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

  context "when a new record is added via has_and_belongs_to_many association" do
    it "logs an event on owner"
  end
end
