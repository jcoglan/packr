= PackR

* http://github.com/jcoglan/packr
* http://dean.edwards.name/packer/
* http://base2.googlecode.com

== Description

PackR is a Ruby version of Dean Edwards' JavaScript compressor.

== Features

* Whitespace and comment removal
* Compression of local variable names
* Compression and obfuscation of 'private' (_underscored) identifiers
* Base-62 encoding

== Synopsis

To call from within a Ruby program:

  require 'rubygems'
  require 'packr'
  
  code = File.read('my_script.js')
  compressed = Packr.pack(code)

To call from the command line:

  packr my_script.js > my_script.min.js

== Requirements

* Rubygems
* Oyster (installed automatically)

== Installation

  sudo gem install packr -y

== License

(The MIT License)

Copyright (c) 2004-2008 Dean Edwards, James Coglan

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
