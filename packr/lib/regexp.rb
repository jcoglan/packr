class Regexp
  def source
    self.inspect.gsub(/^\/(.*?)\/[^\/]*$/, '\1')
  end
end
