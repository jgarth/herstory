module Herstory
  class HasAndBelongsToManyCallbacks
    def initialize(record:, reflection:, superordinate:)
      @record = record
      @reflection = reflection
      @superordinate = superordinate
    end

    def after_add
      return -> (method, owner, record) do
        owner.log_record_change(nil, record, @superordinate)
      end
    end

    def after_remove
      return -> (method, owner, record) do
        owner.log_record_change(record, nil, @superordinate)
      end
    end
  end
end
