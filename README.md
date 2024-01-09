<!-- FIXME: Caveat about logs_changes on both models needs to be equal
      , one is loaded first, other is a noop, relevant in testing  -->

## What is this?

Herstory is made to _record changes to ActiveRecord models, including all of their associations._

## How does it work?

It's a two component system:

### Component One: ActiveRecord::Base concern

This component **registers** all the changes and passes it on to the next component. It's a class method `logs_changes`, which in turn defines some `after_save` callbacks to do its work. See [Fine Print](#details) for a more detailed explanation.

```ruby

class Person < ActiveRecord::Base
  includes Herstory
  has_many :addresses
  has_many :phone_numbers, through: :addresses
  has_and_belongs_to_many :meetups

  logs_changes includes: [:addresses, :phone_numbers,
   {meetups: {superordinate: :other_record}]
end

```

### Component Two: Logging Implementation

Herstory ships with a default logger class. It saves an `Event` model to persist change information to the DB.

### Configuration

Herstory accepts a hash of options that allow a rudimentary configuration of its behavior. As of today, the only valid option is `log_all_attributes_on_creation`. Adding

```ruby

  self._herstory_options = { log_all_attributes_on_creation: true }

```

to your model after the `include Herstory` instructs Herstory to log all the parameters that were present when the model was created.

### Caveats

So much beta warning here. Although it's used in production software. But it might blow up and spew poisonous lizards LOOKING AND ACTING like docile puppies EVERYWHERE until it is TOO LATE.

### Fine Print

_Herstory_ does what it does by injecting `before_save` and `before_destroy` callbacks on the model you're watching and all models that you're watching through associations. It monitors the `belongs_to` part of any association.

### But what about polymorphic associations?

Define logs_changes on your polymorphic model, done.
