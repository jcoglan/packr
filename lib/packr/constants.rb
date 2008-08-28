class Packr
  
  IGNORE  = RegexpGroup::IGNORE
  KEYS    = "~"
  REMOVE  = ""
  SPACE   = " "
  
  CONTINUE = /\\\r?\n/
  ENCODED  = /~\^(\d+)\^~/
  PRIVATES = /\b_[\da-zA-Z$][\w$]*\b/
  SHRUNK   = /@\d+\b/
  
  def self.encode62(c)
    (c < 62 ? '' : encode62((c / 62.0).to_i)) +
        ((c = c % 62) > 35 ? (c+29).chr : c.to_s(36))
  end
  
  def self.encode52(c)
    # Base52 encoding (a-Z)
    encode = lambda do |d|
      (d < 52 ? '' : encode.call((d / 52.0).to_i)) +
          ((d = d % 52) > 25 ? (d + 39).chr : (d + 97).chr)
    end
    encoded = encode.call(c.to_i)
    encoded = encoded[1..-1] + '0' if encoded =~ /^(do|if|in)$/
    encoded
  end
  
end

