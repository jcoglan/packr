class Packr
  class Shrinker
    
    ENCODED_DATA = /~\^(\d+)\^~/
    PREFIX = '@'
    SHRUNK = /\@\d+\b/
    
    def decode_data(script)
      # put strings and regular expressions back
      script.gsub(ENCODED_DATA) { |match| @strings[$1.to_i] }
    end
    
    def encode_data(script)
      # encode strings and regular expressions
      @strings = [] # encoded strings and regular expressions
      DATA.exec(script, lambda { |match, *args|
        operator, regexp = args[0].to_s, args[1].to_s
        replacement = "~^#{@strings.length}^~"
        unless regexp.empty?
          replacement = operator + replacement
          match = regexp
        end
        @strings << match
        replacement
      })
    end
    
    def shrink(script, protected_names = [])
      script = encode_data(script)
      protected_names ||= []
      protected_names = protected_names.map { |s| s.to_s }
      
      # identify blocks, particularly identify function blocks (which define scope)
      __block         = /((catch|do|if|while|with|function)\b[^~{};]*(\(\s*[^{};]*\s*\))\s*)?(\{[^{}]*\})/
      __brackets      = /\{[^{}]*\}|\[[^\[\]]*\]|\([^\(\)]*\)|~[^~]+~/
      __encoded_block = /~#?(\d+)~/
      __identifier    = /[a-zA-Z_$][\w\$]*/
      __scoped        = /~#(\d+)~/
      __var           = /\bvar\b/
      __vars          = /\bvar\s+[\w$]+[^;#]*|\bfunction\s+[\w$]+/
      __var_tidy      = /\b(var|function)\b|\sin\s+[^;]+/
      __var_equal     = /\s*=[^,;]*/
      
      blocks = [] # store program blocks (anything between braces {})
      total = 0
      # decoder for program blocks
      decode_blocks = lambda do |script, encoded|
        script = script.gsub(encoded) { |match| blocks[$1.to_i] } while script =~ encoded
        script
      end
      
      # encoder for program blocks
      encode_blocks = lambda do |match|
        prefix, block_type, args, block = $1 || "", $2, $3, $4
        if block_type == 'function'
          # decode the function block (THIS IS THE IMPORTANT BIT)
          # We are retrieving all sub-blocks and will re-parse them in light
          # of newly shrunk variables
          block = args + decode_blocks.call(block, __scoped)
          prefix = prefix.gsub(__brackets, "")
          
          # create the list of variable and argument names
          args = args[1...-1]
          
          if args != '_no_shrink_'
            vars = block.scan(__vars).join(";").gsub(__var, ";var")
            vars = vars.gsub(__brackets, "") while vars =~ __brackets
            vars = vars.gsub(__var_tidy, "").gsub(__var_equal, "")
          end
          block = decode_blocks.call(block, __encoded_block)
          
          # process each identifier
          if args != '_no_shrink_'
            count, short_id = 0, nil
            ids = [args, vars].join(",").scan(__identifier)
            processed = {}
            ids.each do |id|
              if !processed['#' + id] and !protected_names.include?(id)
                processed['#' + id] = true
                id = id.rescape
                # encode variable names
                count += 1 while block =~ Regexp.new("#{PREFIX}#{count}\\b")
                reg = Regexp.new("([^\\w$.])#{id}([^\\w$:])")
                block = block.gsub(reg, "\\1#{PREFIX}#{count}\\2") while block =~ reg
                reg = Regexp.new("([^{,\\w$.])#{id}:")
                block = block.gsub(reg, "\\1#{PREFIX}#{count}:")
                count += 1
              end
            end
            total = [total, count].max
          end
          replacement = "#{prefix}~#{blocks.length}~"
          blocks << block
        else
          replacement = "~##{blocks.length}~"
          blocks << (prefix + block)
        end
        replacement
      end
      
      # encode blocks, as we encode we replace variable and argument names
      script = script.gsub(__block, &encode_blocks) while script =~ __block
      
      # put the blocks back
      script = decode_blocks.call(script, __encoded_block)
      
      short_id, count = nil, 0
      shrunk = Encoder.new(SHRUNK, lambda { |object|
        # find the next free short name
        begin
          short_id = Packr.encode52(count)
          count += 1
        end while script =~ Regexp.new("[^\\w$.]#{short_id}[^\\w$:]")
        short_id
      })
      script = shrunk.encode(script)
      
      decode_data(script)
    end
    
  end
end

