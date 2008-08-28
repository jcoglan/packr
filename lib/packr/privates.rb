class Packr
  class Privates < Encoder
    
    IGNORE = {
      :CONDITIONAL => Packr::IGNORE,
      "(OPERATOR)(REGXEP)" => Packr::IGNORE
    }
    
    PATTERN = /\b_[\da-zA-Z$][\w$]*\b/
    
    def initialize
      super(PATTERN, lambda { |index|
        "_" + Packr.encode62(index)
      }, IGNORE)
    end
    
  end
end

