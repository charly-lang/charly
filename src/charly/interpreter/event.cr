require "./types.cr"

module Events

  # The base for all events
  abstract class Event < Exception
    include CharlyTypes
    property payload : BaseType
    property catchable : Bool

    def initialize(@payload = TNull.new)
      @message = ""
      @catchable = false
    end
  end

  class Return < Event
  end

  class Break < Event
  end

  class Exit < Event
  end
end
