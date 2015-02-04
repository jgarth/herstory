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

A logger class that gets called from the extension with a minimal interface. You can (and probably will) replace this component to your heart's content. Herstory enables you to _take note_ of all changes to an AR model and its associations, but it's up to you how you log them.

Herstory ships with a default logger class, which is unceremoniously called `ChangeLogger`. It saves an `Event` model to persist change information to the DB. You could do anything though, as long as it can deal with Herstory's interface methods.

See [Implementing a custom logger](#implementing-a-custom-logger) for details.

## Caveats

So much beta warning here. Although it's used in production software. But it might blow up and spew poisonous lizards LOOKING AND ACTING like docile puppies EVERYWHERE until it is TOO LATE.

## Fine Print

_Herstory_ does what it does by injecting `before_save` and `before_destroy` callbacks on the model you're watching and all models that you're watching through associations. It monitors the `belongs_to` part of any association.

## Implementing a custom logger

Great idea! Go right ahead. Make a class, any class, and have it conform to the following interface (it's all named arguments):

`log_creation(record:, user: nil)`

`log_destruction(record: user: nil)`

`log_attribute_changes(record:, user: nil)`

```ruby
log_association_changes (
  change:, # Can be :addition or :deletion
  record:, # The record that has the association that's being logged
  superordinate:, # See below
  other_record:,  # The record that was added or deleted
  user: nil # The user who done did it
  )
```

About `superordinate:` - This information can be used to make sense of the relationship / hierarchy between two objects, which can't necessarily be inferred from the association definition. It serves to express _what_ is assigned to _what_. The included logger uses it to do some linguistic adjustments, e.g. sort out whether to save an Event á la `person_attached_to_contact` or `contact_attached_to_person`.

Possible values are:
  - `:record` - This end of the association is the superordinate, e.g. `Organization (record) has_and_belongs_to_many persons (other_record)`
  - `:other_record` - The other end of the association is the superordinate, e.g. `Person (record) has_and_belongs_to_many organizations (other_record)`
  - `:none` - They're both subordinate
  - `:both` (**Default**) - They're both equally superordinate, e.g. `House has_and_belongs_to_many neighboring_houses`

The `log_association_changes` method will only be called _once_, even if you define `logs_changes` on both ends of the association.

When you're done, register it with _Herstory_ like so:

`Herstory.logger = YourLoggerClass`

Done and done.

## Contributing

Yeah, sure! All I care about (except basic manners) are SPECS for any bugs you report or changes you want to introduce. The actual fix/implementation is a distant second to good SPECS!
