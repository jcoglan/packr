class String
  def rescape
    gsub(/([\/()\[\]{}|*+-.,^$?\\])/) { |m| "\\#{$1}" }
  end
end

