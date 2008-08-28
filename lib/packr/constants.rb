class Packr
  
  IGNORE  = RegexpGroup::IGNORE
  KEYS    = "~"
  REMOVE  = ""
  SPACE   = " "
  
  CONTINUE = /\\\r?\n/
  ENCODED  = /~\^(\d+)\^~/
  PRIVATES = /\b_[\da-zA-Z$][\w$]*\b/
  SHRUNK   = /@\d+\b/
  WORDS    = /\b[\da-zA-Z]\b|\w{2,}/
  
  ENCODE10 = "String"
  ENCODE36 = "function(c){return c.toString(36)}"
  ENCODE62 = "function(c){return(c<62?'':e(parseInt(c/62)))+((c=c%62)>35?String.fromCharCode(c+29):c.toString(36))}"
  
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
  
  UNPACK = lambda do |p,a,c,k,e,r|
    "eval(function(p,a,c,k,e,r){e=#{e};if('0'.replace(0,e)==0){while(c--)r[e(c)]=k[c];" +
        "k=[function(e){return r[e]||e}];e=function(){return'#{r}'};c=1};while(c--)if(k[c])p=p." +
        "replace(new RegExp('\\\\b'+e(c)+'\\\\b','g'),k[c]);return p}('#{p}',#{a},#{c},'#{k}'.split('|'),0,{}))"
  end
  
end

