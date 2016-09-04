class Grammar

  attr_reader :rules, :terminals

  def initialize
    @terminals =  [
      :NUMERICAL,
      :VARIABLE
    ]

    @rules = {

    }

    def rules(rule)
      @rules[rule]
    end

    def is_terminal(rule)
      @terminals.index(rule) != nil
    end
  end
end
