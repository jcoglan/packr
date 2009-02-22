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
  File.open('my_script.min.js', 'wb') { |f| f.write(compressed) }

This method takes a number of options to control compression, for example:

  compressed = Packr.pack(code, :shrink_vars => true, :base62 => true)

The full list of available options is:

* <tt>:shrink_vars</tt> -- set to +true+ to compress local variable names
* <tt>:private</tt> -- set to +true+ to obfuscate 'private' identifiers, i.e.
  names beginning with a single underscore
* <tt>:base62</tt> -- encode the program using base 62
* <tt>:protect</tt> -- an array of variable names to protect from compression, e.g.

  compressed = Packr.pack(code, :shrink_vars => true,
                                :protect => %w[$super self])

To call from the command line (use <tt>packr --help</tt> to see available options):

  packr my_script.js > my_script.min.js
  
== Notes

This program is not a JavaScript parser, and rewrites your files using regular
expressions. Be sure to include semicolons and braces everywhere they are required
so that your program will work correctly when packed down to a single line.

By far the most efficient way to serve JavaScript over the web is to use PackR
with the --shrink-vars flag, combined with gzip compression. If you don't have access
to your server config to set up mod_deflate, you can generate gzip files using
(on Unix-like systems):

  packr -s my-file.js | gzip > my-file.js.gz
  
You can then get Apache to serve the files by putting this in your .htaccess file:

  AddEncoding gzip .gz
  RewriteCond %{HTTP:Accept-encoding} gzip
  RewriteCond %{HTTP_USER_AGENT} !Safari
  RewriteCond %{REQUEST_FILENAME}.gz -f
  RewriteRule ^(.*)$ $1.gz [QSA,L]

If you really cannot serve gzip files, use the --base62 option to further compress
your code. This mode is at its best when compressing large files with many repeated
tokens.

The --private option can be used to stop other programs calling private methods
in your code by renaming anything beginning with a single underscore. Beware that
you should not use this if the generated file contains 'private' methods that need
to be accessible by other files. Also know that all the files that access any
particular private method must be compressed together so they all get the same
rewritten name for the private method.

== Requirements

* Rubygems
* Oyster (installed automatically)

== Installation

  sudo gem install packr -y

== License

(The MIT License)

Copyright (c) 2004-2009 Dean Edwards, James Coglan

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
