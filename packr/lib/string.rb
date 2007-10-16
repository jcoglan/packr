require 'strscan'

class String
  def indexes(regexp)
    scanner, ary = StringScanner.new(self), []
    ary << scanner.pointer while scanner.scan_until(regexp)
    ary
  end
  
  def rescape
    gsub(/([\/()[\]{}|*+-.,^$?\\])/, "\\\\1")
  end
end
