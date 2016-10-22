require "./types.cr"

module Events

  # The base for all events
  abstract class Event < Exception
    include CharlyTypes
    property payload : BaseType
    property catchable : Bool

    def initialize(@payload)
      @message = "Exception: #{self.class.name}"
      @catchable = false
    end
  end

  class Return < Event
  end

  class Break < Event
  end

  class Throw < Event
    def initialize(@payload)
      super
      @catchable = true
    end
  end

  class Exit < Event
  end
end
