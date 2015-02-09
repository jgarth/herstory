require 'rails_helper'

RSpec.describe Herstory::BelongsToCallbacks do
  before(:all) do
    Arrival.logs_changes includes: {users: {}, shipments: {superordinate: :record}}
    User.logs_changes includes: [:arrival]
    Note.logs_changes includes: [:parent] unless Note.logs_changes_for?(:parent)

    Thread.current[:current_user] = User.create({name: 'Joanne Doe'})
  end

  context "when a belongs_to association is set" do
    let(:arrival) { Herstory.without_logging { Arrival.create } }
    let(:user) { Herstory.without_logging { User.create(name: 'John Wayne') } }

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
        new_arrival = Herstory.without_logging { Arrival.create }
        user.update(arrival: new_arrival)
      end.to change(Event, :count).by(4)
    end
  end

  context "when a new record is added to has_many collection" do
    let(:arrival) { Herstory.without_logging { Arrival.create } }
    let(:user) { Herstory.without_logging { User.create(name: 'John Wayne') } }

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

  context "when a polymorphic record is added to has_many collection" do
    let(:arrival) { Herstory.without_logging { Arrival.create } }
    let(:user) { Herstory.without_logging { User.create(name: 'John Wayne') } }
    let(:note) { Note.new(user: user, text: 'John Wayne') }

    before :each do
      expect do
        arrival.notes << note
      end.to change(Event, :count).by(3)
    end

    it "logs an event on child" do
      last_event = note.events.reload.last
      expect(last_event.type).to eq('arrival_attached')
    end

    it "logs an event on parent" do
      last_event = arrival.events.reload.first
      expect(last_event.type).to eq('note_attached')
    end
  end

end
