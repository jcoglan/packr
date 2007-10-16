// === Glazing ===
// Prototype-based windows for JavaScript
// Copyright (c) 2007 James Coglan
// 
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.


// The Glazing namespace -- this is the only global variable created
var Glazing = {
  Animation: {
    increment: 0.13,
    timeStep: 0.02,
    method: function(t) { return 1 - Math.pow(Math.exp(-t), 3); }
  },
  Keys: {
    CTRL: false
  },
  activeWindow: function() {
    return this.WindowManager.activeWindow;
  }
};


// The main Window class
Glazing.Window = function(options) {
  this.initialize(options);
};

// Padding applied between viewport edge and maximized windows
Glazing.Window.padding = 6;

Glazing.Window.defaultOptions = $H({
  id:                 0,
  className:          '',
  width:              400,
  height:             300,
  resizable:          true,
  minWidth:           120,
  minHeight:          0,
  draggable:          true,
  content:            '',
  titlebar:           true,
  title:              'Window',
  closable:           true,
  closeAnimation:     'implode',
  minimizable:        true,
  maximizable:        true,
  animated:           true,
  statusbar:          true,
  status:             '',
  modal:              false,
  url:                null
});

Glazing.Window.prototype = {

  // Returns true iff the required DOM elements are loaded
  readyToInitialize: function() {
    return !!Glazing.DragOverlay.screen;
  },
  
  // Initial window setup
  initialize: function(options) {
    if (!this.readyToInitialize()) {
      setTimeout(this.initialize.bind(this, options), 1000);
      return false;
    }
    if (this.window) { return false; }
    
    this.settings = $H({}).merge(Glazing.Window.defaultOptions).merge(options);
    
    // Get default window positions
    if (typeof(this.settings.top) == 'undefined' || typeof(this.settings.left) == 'undefined') {
      var newPos = Glazing.WindowManager.getNewWindowPosition();
      if (typeof(this.settings.top) == 'undefined') { this.settings.top = newPos.y; }
      if (typeof(this.settings.left) == 'undefined') { this.settings.left = newPos.x; }
    }
    
    // Set some properties
    this.isMinimized = false;
    this.isMinimizing = false;
    this.isMaximized = false;
    this.isMaximizing = false;
    this.isRestoring = false;
    
    // Create the window in the document
    while ($('glazing_' + this.settings.id)) { this.settings.id++; }
    var classNames = $w(this.settings.className);
    classNames.push('glazing');
    classNames.push('window');
    // URL mode over-rides plain HTML content
    var content;
    if (this.settings.url) {
      content = '<iframe class="content" src="' + this.settings.url + '"></iframe>';
      if (this.settings.status === null) { this.settings.status = this.settings.url; }
    } else {
      content = '<div class="content">' + this.settings.content + '</div>';
      if (this.settings.status === null) { this.settings.status = ''; }
    }
    // Cross-browser display is not going to be fun using floated/positioned divs. I tried
    // it, it doesn't work. You have to do things like the One True Layout to get the left and
    // right edges alongside the content, and IE6 chokes on the top edge if you do this.
    var insert = new Insertion.Bottom(document.body, '\
      <table id="glazing_' + this.settings.id + '" class="' + classNames.join(' ') + '">\
        <tr>\
          <td class="top left"></td>\
          <td class="top"></td>\
          <td class="top right"></td>\
        </tr>\
        <tr class="middle">\
          <td class="left"></td>\
          <td class="center">\
            <div class="titlebar">\
              <div class="title"></div>\
              <div class="minimize"></div>\
              <div class="maximize"></div>\
              <div class="close"></div>\
            </div>\
            <div class="contentHolder"></div>\
            <div class="statusbar"></div>\
          </td>\
          <td class="right"></td>\
        </tr>\
        <tr>\
          <td class="bottom left"></td>\
          <td class="bottom"></td>\
          <td class="bottom right"></td>\
        </tr>\
      </table>'
    );
    
    // Assign various parts of the window DOM element to this object
    this.window = $('glazing_' + this.settings.id);
    this.topEdge            = this.find('.top')[1];
    this.rightEdge          = this.find('.middle .right')[0];
    this.leftEdge           = this.find('.middle .left')[0];
    this.bottomEdge         = this.find('.bottom')[1];
    this.topLeftCorner      = this.find('.top.left')[0];
    this.topRightCorner     = this.find('.top.right')[0];
    this.bottomLeftCorner   = this.find('.bottom.left')[0];
    this.bottomRightCorner  = this.find('.bottom.right')[0];
    this.middle             = this.find('.middle')[0];
    this.titlebar           = this.find('.titlebar')[0];
    this.title              = this.find('.title')[0];
    this.closeButton        = this.find('.close')[0];
    this.minimizeButton     = this.find('.minimize')[0];
    this.maximizeButton     = this.find('.maximize')[0];
    this.contentHolder      = this.find('.contentHolder')[0];
    this.content            = this.find('.content')[0];
    this.statusbar          = this.find('.statusbar')[0];
    
    // Initial window setup
    this.setPosition(this.settings.left, this.settings.top);
    this.setDimensions(this.settings.width, this.settings.height);
    this.setResizable(this.settings.resizable);
    this.setTitle(this.settings.title);
    if (!this.settings.titlebar) { this.titlebar.hide(); }
    this.setStatus(this.settings.status);
    if (!this.settings.statusbar) { this.statusbar.hide(); }
    this.setContent({url: this.settings.url, html: this.settings.content});
    
    // Set up hover handling
    $w('titlebar closeButton minimizeButton maximizeButton').each(function(area) {
      this[area].observe('mouseover', this[area].addClassName.bind(this[area], 'hover'));
      this[area].observe('mouseout',  this[area].removeClassName.bind(this[area], 'hover'));
    }.bind(this) );
    
    // Note: mouseup events are handled at the document level
    // by the Window Manager. Code appears later on.
    
    // Steal focus on click
    this.contentHolder.observe('mousedown', this.makeActive.bind(this) );
    this.statusbar.observe('mousedown', this.makeActive.bind(this) );
    
    // Set up titlebar dragging handler
    this.titlebar.observe('mousedown', function(e) {
      Event.stop(e);
      this.makeActive();
      if (!this.canBeDragged()) { return false; }
      Glazing.WindowManager.recordMouseDownPosition(e);
      this.beginDragging();
    }.bind(this) );
    
    // Set up resizing event listeners. Thanks to Justin Palmer for the tip:
    // http://alternateidea.com/blog/articles/2007/5/14/shortcuts-for-the-new-prototype-dom-builder
    // This saves us having to write eight sets of drag event handlers!
    $w('topEdge topLeftCorner topRightCorner\
        bottomEdge bottomLeftCorner bottomRightCorner\
        leftEdge rightEdge').each(function(area) {
      this[area].observe('mousedown', function(e) {
        Event.stop(e);
        this.makeActive();
        if (!this.canBeResized()) { return false; }
        Glazing.WindowManager.recordMouseDownPosition(e);
        this.beginResizing(area);
      }.bind(this) );
    }.bind(this) );
    
    // Titlebar button event handlers
    $w('max min').each(function(mode) {
      var Mode = mode.replace(/^(.)/, function(chr) { return chr.toUpperCase(); });
      this[mode + 'imizeButton'].observe('click', function(e) {
        Event.stop(e);
        this.makeActive();
        if (this['canBe' + Mode + 'imized']()) {
          this[mode + 'imize']();
        } else if (this['is' + Mode + 'imized'] && this.canBeRestored()) {
          this.restore();
        }
      }.bind(this) );
    }.bind(this) );
    this.closeButton.observe('click', function(e) {
      Event.stop(e);
      if (this.canBeClosed()) { this.close(); }
    }.bind(this) );
    
    // Stop event bubbling that causes drag/resize overlay
    // to hide these elements and stops them completing a click.
    // Also means they can't be used to drag windows
    $w('maximize minimize close').each(function(mode) {
      this[mode + 'Button'].observe('mousedown', Event.stop);
    }.bind(this) );
    
    // Window Manager stuff
    Glazing.WindowManager.windows.append(this);
    this.makeActive();
    
    // Modal windows
    if (this.settings.modal) { Glazing.Overlay.setOwner(this); }
    
    return true;
  },
  
  // Shorthand function for getting elements by selector within the window
  find: function(selector) {
    return this.window.getElementsBySelector(selector);
  },
  
  // Sets the position of the window relative to the document
  setPosition: function(left, top, persist) {
    if (typeof(persist) == 'undefined') { persist = true; }
    if (persist) {
      this.settings.left = left;
      this.settings.top = top;
    }
    this.window.setStyle({
      left:   left + 'px',
      top:    top + 'px'
    });
  },
  
  // Centers the window within the browser window.
  // Displays slightly above the center of the viewport.
  center: function() {
    var winSize = Glazing.Utils.windowSize();
    var scrollOffset = Glazing.Utils.scrollOffset();
    var width = this.window.getWidth();
    var height = this.window.getHeight();
    this.setPosition(
      (winSize.x - width) / 2 + scrollOffset.x,
      0.7 * (winSize.y - height) / 2 + scrollOffset.y,
      true
    );
  },
  
  // Sets the dimensions of the window
  setDimensions: function(width, height, persist) {
    if (typeof(persist) == 'undefined') { persist = true; }
    if (persist) {
      this.settings.width = width;
      this.settings.height = height;
    }
    this.contentHolder.setStyle({
      height:   height + 'px',
      width:    width + 'px'
    });
  },
  
  // Sizes the window to just contain its contents. Bit flaky - you should really
  // avoid padding or margining the content element for this to work. Best suited
  // tight-looking dialog boxes anyway, where layout is tightly controlled.
  fitToContent: function() {
    if (this.settings.url !== null) { return; }
    this.content.setStyle({border: '1px solid #000;'});
    this.setDimensions(this.content.getWidth() - 2, this.content.getHeight() - 2, true);
    this.content.setStyle({border: ''});
  },
  
  // Get the total height of the window
  edgeSizes: function() {
    return {
      top: this.titlebar.getHeight() + this.topEdge.getHeight(),
      right: this.rightEdge.getWidth(),
      bottom: this.statusbar.getHeight() + this.bottomEdge.getHeight(),
      left: this.leftEdge.getWidth()
    };
  },
  
  // Sets the title of the window
  setTitle: function(title) {
    this.settings.title = title;
    this.title.update(title.truncate(32));
  },
  
  // Sets the status of the window
  setStatus: function(status) {
    this.settings.status = status;
    this.statusbar.update(status);
  },
  
  // Sets the content of the window. Can be HTML or
  // a URL to be loaded in an iframe.
  setContent: function(options) {
    var content, url;
    if (options.url) {
      url = options.url.strip().replace(/^(?:http:\/\/)?(.*)$/g, 'http://$1');
      this.settings.url = url;
      this.settings.content = null;
      this.statusbar.update(this.settings.status || url);
      content = '<iframe class="content" src="' + url + '"></iframe>';
    } else {
      this.settings.url = null;
      this.settings.content = options.html;
      content = '<div class="content">' + options.html + '</div>';
    }
    this.contentHolder.update(content);
    this.content = this.find('.content')[0];
  },
  
  // Make the window the active window
  makeActive: function() {
    Glazing.WindowManager.setActiveWindow(this);
  },
  
  // Returns true iff the window can be resized
  canBeDragged: function() {
    return !Glazing.TaskSwitcher.active &&
        this.settings.draggable && !this.isRestoring &&
        !this.isMaximized && !this.isMaximizing;
  },
  
  // Registers the window as being dragged with the window manager
  beginDragging: function() {
    Glazing.WindowManager.dragging = true;
    Glazing.DragOverlay.show({front: true});
  },
  
  // Ends the dragging process
  stopDragging: function() {
    Glazing.WindowManager.dragging = false;
    this.settings.left     = parseInt(this.window.getStyle('left'));
    this.settings.top      = parseInt(this.window.getStyle('top'));
    Glazing.DragOverlay.hide();
  },
  
  // Sets the ability of the window to be resized
  setResizable: function(state) {
    var bool = !!state;
    this.settings.resizable = bool;
    if (bool) {
      this.window.removeClassName('noresize');
    } else {
      this.window.addClassName('noresize');
    }
  },
  
  // Returns true iff the window can be resized
  canBeResized: function() {
    return !Glazing.TaskSwitcher.active &&
        this.settings.resizable && !this.isRestoring &&
        !this.isMinimized && !this.isMinimizing &&
        !this.isMaximized && !this.isMaximizing;
  },
  
  // Registers this window as being resized with the window manager
  beginResizing: function(mode) {
    Glazing.WindowManager.resizing = true;
    Glazing.WindowManager.resizingMode = mode;
    Glazing.DragOverlay.show({front: true});
  },
  
  // Ends the resize process
  stopResizing: function() {
    Glazing.WindowManager.resizing = false;
    Glazing.WindowManager.resizingMode = null;
    this.settings.width    = parseInt(this.contentHolder.getWidth());
    this.settings.height   = parseInt(this.contentHolder.getHeight());
    this.settings.left     = parseInt(this.window.getStyle('left'));
    this.settings.top      = parseInt(this.window.getStyle('top'));
    Glazing.DragOverlay.hide();
  },
  
  // Returns true iff it's okay to minimize the window
  canBeMinimized: function() {
    return !Glazing.TaskSwitcher.active &&
        this.settings.minimizable && !this.isMinimized &&
        !this.isMinimizing && !this.isRestoring && !this.isMaximizing;
  },
  
  // Returns true iff the window can be maximized
  canBeMaximized: function() {
    return !Glazing.TaskSwitcher.active &&
        this.settings.maximizable && !this.isMaximized &&
        !this.isMaximizing && !this.isRestoring &&
        !this.isMinimizing;
  },
  
  // Returns true iff the window can be restored
  canBeRestored: function() {
    return !Glazing.TaskSwitcher.active && (
      (this.isMinimized && !this.isMinimizing) ||
      (this.isMaximized && !this.isMaximizing)
    ) && !this.isRestoring;
  },
  
  // Minimizes the window
  minimize: function() {
    this.isMaximized = false;
    this.window.addClassName('noresize');
    this.contentHolder.setStyle({overflow: 'hidden'});
    if (!this.settings.animated) {
      this.setDimensions(this.settings.width, 0, false);
      this.setPosition(this.settings.left, this.settings.top, false);
      this.statusbar.setStyle({height: 0});
      this.isMinimized = true;
      return;
    }
    this.isMinimizing = true;
    this.animate({
      dimensions: {
        from: [this.contentHolder.getWidth(), this.contentHolder.getHeight()],
        to: [this.settings.width, 0], persist: false
      },
      position: {
        from: [parseInt(this.window.getStyle('left')), parseInt(this.window.getStyle('top'))],
        to: [this.settings.left, this.settings.top], persist: false
      },
      onComplete: function() {
        this.isMinimizing = false;
        this.isMinimized = true;
        this.statusbar.setStyle({height: 0});
      }
    });
  },
  
  // Maximizes the window
  maximize: function() {
    this.window.addClassName('noresize');
    if (this.isMinimized) {
      this.statusbar.setStyle({height: ''});
      this.contentHolder.setStyle({overflow: ''});
    }
    this.isMinimized = false;
    var winSize = Glazing.Utils.windowSize();
    var offset = Glazing.Utils.scrollOffset();
    var edges = this.edgeSizes();
    var width = winSize.x - 2 * Glazing.Window.padding - edges.left - edges.right - 18,
        height = winSize.y - 2 * Glazing.Window.padding - edges.top - edges.bottom - 18,
        top = offset.y + Glazing.Window.padding,
        left = offset.x + Glazing.Window.padding;
    if (!this.settings.animated) {
      this.setDimensions(width, height, false);
      this.setPosition(left, top, false);
      this.isMaximized = true;
      return;
    }
    this.isMaximizing = true;
    this.animate({
      dimensions: {
        from: [this.contentHolder.getWidth(), this.contentHolder.getHeight()],
        to: [width, height], persist: false
      },
      position: {
        from: [parseInt(this.window.getStyle('left')), parseInt(this.window.getStyle('top'))],
        to: [left, top], persist: false
      },
      onComplete: function() {
        this.isMaximizing = false;
        this.isMaximized = true;
      }
    });
  },
  
  // Restores the window
  restore: function() {
    this.isMinimized = false;
    this.isMaximized = false;
    this.setResizable(this.settings.resizable);
    this.statusbar.setStyle({height: ''});
    if (!this.settings.animated) {
      this.setDimensions(this.settings.width, this.settings.height);
      this.setPosition(this.settings.left, this.settings.top);
      return;
    }
    this.isRestoring = true;
    this.animate({
      dimensions: {
        from: [this.contentHolder.getWidth(), this.contentHolder.getHeight()],
        to: [this.settings.width, this.settings.height], persist: false
      },
      position: {
        from: [parseInt(this.window.getStyle('left')), parseInt(this.window.getStyle('top'))],
        to: [this.settings.left, this.settings.top], persist: false
      },
      onComplete: function() {
        this.isRestoring = false;
        this.contentHolder.setStyle({overflow: ''});
      }
    });
  },
  
  // Returns true iff the window can be closed
  canBeClosed: function() {
    return this.settings.closable;
  },
  
  // Closes the window
  close: function() {
    Glazing.WindowManager.removeWindow(this);
    this.contentHolder.setStyle({overflow: 'hidden'});
    if (!this.settings.animated) {
      this.window.remove();
      return;
    }
    if (this.settings.closeAnimation == 'fade') {
      this.animate({
        opacity: {from: 1, to: 0},
        onComplete: this.window.remove.bind(this.window)
      });
      return;
    }
    var width, height, left, top;
    switch (this.settings.closeAnimation) {
      case 'implode':
        width = 0; height = 0;
        left = parseInt(this.window.getStyle('left')) + 0.5 * this.contentHolder.getWidth();
        top = parseInt(this.window.getStyle('top')) + 0.5 * this.contentHolder.getHeight();
        break;
      case 'explode':
        width = 2 * this.contentHolder.getWidth();
        height = 2 * this.contentHolder.getHeight();
        left = parseInt(this.window.getStyle('left')) - 0.25 * width;
        top = parseInt(this.window.getStyle('top')) - 0.25 * height;
        break;
    }
    this.animate({
      dimensions: {
        from: [this.contentHolder.getWidth(), this.contentHolder.getHeight()],
        to: [width, height], persist: false
      },
      position: {
        from: [parseInt(this.window.getStyle('left')), parseInt(this.window.getStyle('top'))],
        to: [left, top], persist: false
      },
      opacity: {from: 1, to: 0},
      onComplete: this.window.remove.bind(this.window)
    });
  },
  
  // General animation method. Example usage:
  //    win.animate({
  //        dimensions: {from: [0,0], to: [400,300], persist: false},
  //        onComplete: function() { alert('Finished!'); }
  //    });
  // Supported properties: dimensions, position, opacity
  animate: function(options) {
    var t = 0, loop, k, prop;
    loop = new PeriodicalExecuter(function(pe) {
      k = Glazing.Animation.method(t);
      if (k > 0.999) {
        pe.stop();
        $w('dimensions position').each(function(property) {
          var prop, Property = property.replace(/^(.)/, function(chr) { return chr.toUpperCase(); });
          if (prop = options[property]) {
            this['set' + Property](prop.to[0], prop.to[1], !!prop.persist);
          }
        }.bind(this) );
        if (prop = options.opacity) {
          this.window.setStyle({opacity: prop.to});
        }
        if (options.onComplete) { options.onComplete.bind(this)(); }
      } else {
        $w('dimensions position').each(function(property) {
          var prop, Property = property.replace(/^(.)/, function(chr) { return chr.toUpperCase(); });
          if (prop = options[property]) {
            this['set' + Property](
              prop.from[0] + k * (prop.to[0] - prop.from[0]),
              prop.from[1] + k * (prop.to[1] - prop.from[1]),
              !!prop.persist
            );
          }
        }.bind(this) );
        if (prop = options.opacity) {
          this.window.setStyle({opacity: prop.from + k * (prop.to - prop.from)});
        }
      }
      t += Glazing.Animation.increment;
    }.bind(this), Glazing.Animation.timeStep);
  },
  
  // Returns true iff the window is accessible through the
  // browser GUI, that is if it is not behind the Overlay
  isAccessible: function() {
    var screenZ = parseInt(Glazing.Overlay.screen.getStyle('zIndex')) || 0;
    return !Glazing.Overlay.active ||
        parseInt(this.window.getStyle('zIndex')) >= screenZ;
  }
};


// Alerts and Confirms
$w('Alert Confirm').each(function(type) {
  Glazing[type] = function(content, options) {
    this.initializeModal(content, options);
  };
  
  Object.extend(Glazing[type].prototype, Glazing.Window.prototype);
  Object.extend(Glazing[type].prototype, {
  
    initializeModal: function(content, options) {
      if (!this.readyToInitialize()) {
        setTimeout(this.initializeModal.bind(this, content, options), 1000);
        return false;
      }
      if (this.window) { return false; }
      
      options = options || {};
      options = $H({
        className:        'modal ' + type.toLowerCase(),
        draggable:        false,
        resizable:        false,
        width:            340,
        minimizable:      false,
        maximizable:      false,
        closable:         false,
        closeAnimation:   'explode',
        titlebar:         false,
        statusbar:        false,
        modal:            true,
        onOK:             options.onClose || function() {},
        onCancel:         function() {},
        ok:               'OK',
        cancel:           'Cancel'
      }).merge(options);
      
      options.onOK     = options['on' + options.ok]     || options.onOK;
      options.onCancel = options['on' + options.cancel] || options.onCancel;
      
      var cancel = (type == 'Confirm') ? '<button class="cancel">' + options.cancel + '</button>' : '';
      content = '\
        <div class="modalContent">' + content + '</div>\
        <div class="modalButtons">\
          <button class="ok">' + options.ok + '</button>\
          ' + cancel + '\
        </div>';
      
      options.content = content;
      this.initialize(options);
      this.addEvents();
      
      this.setDimensions(this.content.getWidth(), this.content.getHeight());
      this.contentHolder.setStyle({overflow: 'hidden'});
      this.center();
    },
    
    addEvents: function() {
      this.ok = this.find('.ok')[0];
      this.ok.observe('click', function(e) {
        Event.stop(e);
        this.settings.onOK();
        this.close();
      }.bind(this) );
      this.ok.focus();
      
      if (type == 'Confirm') {
        this.cancel = this.find('.cancel')[0];
        this.cancel.observe('click', function(e) {
          Event.stop(e);
          this.settings.onCancel();
          this.close();
        }.bind(this) );
      }
      
      this.find('button').each(function(button) {
        button.observe('mouseover', button.addClassName.bind(button, 'hover'));
        button.observe('mouseout',  button.removeClassName.bind(button, 'hover'));
      });
    }
  });
});


// Global document event handlers - deals with dragging, resizing and keypress events
Event.observe(window, 'load', function() {

  // Pick up mouse movements for resizing and dragging
  Event.observe(document, 'mousemove', function(e) {
    var mX = Event.pointerX(e), mY = Event.pointerY(e);
    var win = Glazing.WindowManager.activeWindow, resizingMode = Glazing.WindowManager.resizingMode;
    var mousePos, diffX, diffY;
    var minHeight, minWidth;
    var w, h, horiz, vert;
    if (mousePos = Glazing.WindowManager.mouseDownPosition) {
      diffX = mX - mousePos.x;
      diffY = mY - mousePos.y;
    }
    switch (true) {
    
      // Deal with window dragging
      case Glazing.WindowManager.dragging:
        win.setPosition(win.settings.left + diffX, win.settings.top + diffY, false);
        break;
      
      // Deal with window resizing for all different drag edges
      case Glazing.WindowManager.resizing:
        minWidth = win.settings.minWidth;
        minHeight = win.settings.minHeight;
        
        // Determine how to work out the minimum width/height
        switch (true) {
          case !!resizingMode.match(/top/i):
            h = win.settings.height - diffY;
            vert = (h >= minHeight) ? [win.settings.top + diffY, h] :
                [win.settings.top + win.settings.height - minHeight, minHeight];
            break;
          case !!resizingMode.match(/bottom/i):
            h = win.settings.height + diffY;
            if (h < minHeight) { h = minHeight; }
            break;
        }
        switch (true) {
          case !!resizingMode.match(/left/i):
            w = win.settings.width - diffX;
            horiz = (w >= minWidth) ? [win.settings.left + diffX, w] :
                [win.settings.left + win.settings.width - minWidth, minWidth];
            break;
          case !!resizingMode.match(/right/i):
            w = win.settings.width + diffX;
            if (w < minWidth) { w = win.settings.minWidth; }
            break;
        }
        
        // Set size and position
        switch (Glazing.WindowManager.resizingMode) {
          case 'topEdge':
            win.setPosition(win.settings.left, vert[0], false);
            win.setDimensions(win.settings.width, vert[1], false);
            break;
          case 'topLeftCorner':
            win.setPosition(horiz[0], vert[0], false);
            win.setDimensions(horiz[1], vert[1], false);
            break;
          case 'topRightCorner':
            win.setPosition(win.settings.left, vert[0], false);
            win.setDimensions(w, vert[1], false);
            break;
          case 'bottomEdge':
            win.setDimensions(win.settings.width, h, false);
            break;
          case 'bottomLeftCorner':
            win.setPosition(horiz[0], win.settings.top, false);
            win.setDimensions(horiz[1], h, false);
            break;
          case 'bottomRightCorner':
            win.setDimensions(w, h, false);
            break;
          case 'leftEdge':
            win.setPosition(horiz[0], win.settings.top, false);
            win.setDimensions(horiz[1], win.settings.height, false);
            break;
          case 'rightEdge':
            win.setDimensions(w, win.settings.height, false);
            break;
        }
        break;
    }
  });
  
  // Document onmouseup observer - deals with events ending when
  // the mouse may not be over the original mousedown element
  Event.observe(document, 'mouseup', function(e) {
    switch (true) {
      case Glazing.WindowManager.dragging:
        Glazing.WindowManager.activeWindow.stopDragging();
        break;
      case Glazing.WindowManager.resizing:
        Glazing.WindowManager.activeWindow.stopResizing();
        break;
    }
  });
  
  // Document key press handling
  Object.extend(Event, {
    KEY_CTRL:     17,
    KEY_G:        71
  });
  Event.observe(document, 'keydown', function(e) {
    if (Glazing.Keys.CTRL) {
      switch (e.keyCode) {
        case Event.KEY_DOWN:
          Event.stop(e);
          Glazing.TaskSwitcher.prev();
          break;
        case Event.KEY_UP:
          Event.stop(e);
          Glazing.TaskSwitcher.next();
          break;
      }
    }
    if (e.keyCode == Event.KEY_CTRL) { Glazing.Keys.CTRL = true; }
  });
  Event.observe(document, 'keyup', function(e) {
    if (e.keyCode == Event.KEY_CTRL) {
      Glazing.Keys.CTRL = false;
      if (Glazing.TaskSwitcher.active) {
        Glazing.TaskSwitcher.exit();
      }
    }
  });
});


// The Overlay - used to render the document untouchable for modal windows
Glazing.OverlayClass = function() {};
Glazing.OverlayClass.prototype = {
  color: '#000000',
  opacity: 0.4,
  active: false,
  owner: null,
  
  // Returns true iff the Screen is owned by the given window
  belongsTo: function(win) {
    return this.owner == win;
  },
  
  // Sets the Overlay's owner property and shows/positions it as appropriate
  setOwner: function(win) {
    this.owner = win;
    this.show({behind: win});
  },
  
  // Sets the screen's size based on the document/window size
  // The screen should fill the whole document
  setSize: function() {
    var docSize = Glazing.Utils.documentSize();
    var winSize = Glazing.Utils.windowSize();
    var width = docSize.x;
    var height = (docSize.y > winSize.y) ? docSize.y : winSize.y;
    this.screen.setStyle({
      width: width + 'px',
      height: height + 'px'
    });
  },
  
  // Positions the screen on top of all open windows. Windows begin
  // at a high z-index so it's unlikely to end up behind any of the
  // document content.
  bringToFront: function() {
    this.setSize();
    var activeWin = Glazing.WindowManager.activeWindow;
    this.screen.setStyle({
      zIndex: activeWin ? parseInt(activeWin.window.getStyle('zIndex')) + 1 :
          Glazing.WindowManager.baseZindex
    });
  },
  
  // Positions the screen to lie behind the specified object
  positionBehind: function(obj) {
    this.setSize();
    var element = (obj == 'owner') ? this.owner.window : obj.window || obj;
    var z = element.getStyle('zIndex') || 0;
    this.screen.setStyle({zIndex: z});
  },
  
  // Shows the screen if it is not visible
  show: function(options) {
    this.setSize();
    options = options || {};
    if (options.front) { this.bringToFront(); }
    if (options.behind) { this.positionBehind(options.behind); }
    if (typeof(options.opacity) == 'undefined') { options.opacity = this.opacity; }
    if (!this.active) {
      this.active = true;
      // The 0.001 stops IE flashing the screen at full opacity
      this.screen.setStyle({opacity: 0.001, display: 'block', backgroundColor: this.color});
      var t = 0, loop, k;
      loop = new PeriodicalExecuter(function(pe) {
        k = Glazing.Animation.method(t);
        if (k > 0.999) {
          pe.stop();
          this.screen.setStyle({opacity: options.opacity || 0.001});
        } else {
          this.screen.setStyle({opacity: k * options.opacity || 0.001});
        }
        t += Glazing.Animation.increment;
      }.bind(this), Glazing.Animation.timeStep);
    }
  },

  // Hides the screen
  hide: function() {
    this.active = false;
    this.owner = null;
    this.screen.setStyle({display: 'none'});
  }
};

// This overlay is the visible one that's used for modal windows
Glazing.Overlay = new Glazing.OverlayClass();

// This one is invisible and is overlayed during dragging and
// resizing to get web-page viewer windows to work. It keeps
// the mouse over our document so we can keep capturing
// mousemove events that would be lost over the iframed doc.
Glazing.DragOverlay = new Glazing.OverlayClass();
Glazing.DragOverlay.opacity = 0;

// Onload Overlay setup
Event.observe(window, 'load', function() {
  ['', 'Drag'].each(function(mode) {
    var id = 0;
    while ($('glazingOverlay' + id)) { id++; }
    var screen = new Insertion.Top(document.body, '<div id="glazingOverlay' + id + '"></div>');
    // It's at the top, so setting its z-index equal to any other
    // element will display it behind the element
    
    Glazing[mode + 'Overlay'].screen = $('glazingOverlay' + id);
    Glazing[mode + 'Overlay'].screen.setStyle({
      display: 'none',
      position: 'absolute',
      left: '0',
      top: '0'
    });
    
    // On window resize, set the Overlay size
    Event.observe(window, 'resize', function(e) {
      if (Glazing[mode + 'Overlay'].active) { Glazing[mode + 'Overlay'].setSize(); }
    });
  });
});


// Linked list data structure - used for holding the window stack
Glazing.LinkedList = function() {};
Glazing.LinkedList.prototype = {
  length: 0,
  first: null,
  last: null,
  
  each: function(fn) {
    var node = this.first, n = this.length;
    for (var i = 0; i < n; i++) {
      fn(node, i);
      node = node.next;
    }
  },
  
  at: function(i) {
    if (!(i >= 0 && i < this.length)) { return null; }
    var node = this.first;
    while (i--) { node = node.next; }
    return node;
  },
  
  randomNode: function() {
    var n = Math.floor(Math.random() * this.length);
    return this.at(n);
  },
  
  indexOf: function(theNode) {
    var node = this.first, n = this.length;
    for (var i = 0; i < n; i++) {
      if (node == theNode) { return i; }
      node = node.next;
    }
    return null;
  },
  
  toArray: function() {
    var arr = [], node = this.first, n = this.length;
    while (n--) {
      arr.push(node.data || node);
      node = node.next;
    }
    return arr;
  }
};

Glazing.LinkedList.Circular = function() {};
Object.extend(Glazing.LinkedList.Circular.prototype, Glazing.LinkedList.prototype);
Object.extend(Glazing.LinkedList.Circular.prototype, {

  append: function(node) {
    if (this.first === null) {
      node.prev = node;
      node.next = node;
      this.first = node;
      this.last = node;
    } else {
      node.prev = this.last;
      node.next = this.first;
      this.first.prev = node;
      this.last.next = node;
      this.last = node;
    }
    this.length++;
  },

  prepend: function(node) {
    if (this.first === null) {
      this.append(node);
      return;
    } else {
      node.prev = this.last;
      node.next = this.first;
      this.first.prev = node;
      this.last.next = node;
      this.first = node;
    }
    this.length++;
  },

  insertAfter: function(node, newNode) {
    newNode.prev = node;
    newNode.next = node.next;
    node.next.prev = newNode;
    node.next = newNode;
    if (newNode.prev == this.last) { this.last = newNode; }
    this.length++;
  },

  insertBefore: function(node, newNode) {
    newNode.prev = node.prev;
    newNode.next = node;
    node.prev.next = newNode;
    node.prev = newNode;
    if (newNode.next == this.first) { this.first = newNode; }
    this.length++;
  },

  remove: function(node) {
    if (this.length > 1) {
      node.prev.next = node.next;
      node.next.prev = node.prev;
      if (node == this.first) { this.first = node.next; }
      if (node == this.last) { this.last = node.prev; }
    } else {
      this.first = null;
      this.last = null;
    }
    node.prev = null;
    node.next = null;
    this.length--;
  }
});


// The Window Manager keeps track of global information
// relating to window management. It keeps a list of all windows,
// knows which is active, and records mouse events.
Glazing.WindowManager = {
  windows: new Glazing.LinkedList.Circular(),
  activeWindow: null,
  mouseDownPosition: null,
  dragging: false,
  resizing: false,
  resizingMode: null,
  baseX: 50, baseY: 50,
  stepX: 30, stepY: 30,
  step: 0, maxSteps: 6,
  baseZindex: 1000,
  
  recordMouseDownPosition: function(e) {
    Glazing.WindowManager.mouseDownPosition = {x: Event.pointerX(e), y: Event.pointerY(e)};
  },
  
  getNewWindowPosition: function() {
    var position = {x: this.baseX + this.step * this.stepX, y: this.baseY + this.step * this.stepY};
    this.step++;
    if (this.step >= this.maxSteps) { this.step = 0; }
    return position;
  },
  
  setActiveWindow: function(win) {
    if (win != this.activeWindow) {
      this.windows.remove(win);
      this.windows.append(win);
      this.windows.each(function(node, i) {
        node.window.setStyle({zIndex: this.baseZindex + i});
      }.bind(this) );
      this.activeWindow = win;
      if (win.settings.modal) {
        Glazing.Overlay.setOwner(win);
      } else if (Glazing.Overlay.owner) {
        Glazing.Overlay.show({behind: 'owner'});
      }
    }
    this.hideSelects();
  },
  
  removeWindow: function(win) {
    // If the removed window owns the Overlay, drop the Overlay
    // down the window stack until we find another modal window
    if (Glazing.Overlay.active && Glazing.Overlay.belongsTo(win)) {
      var returned = false, node = win, n = 0, k = this.windows.indexOf(win);
      while (!returned && n < k) {
        node = node.prev;
        if (node.settings.modal) {
          Glazing.Overlay.setOwner(node);
          returned = true;
        }
        n++;
      }
      if (!returned) { Glazing.Overlay.hide(); }
    }
    this.windows.remove(win);
    if (win == this.activeWindow && this.windows.length > 0) {
      this.setActiveWindow(this.windows.last);
    }
    this.hideSelects();
  },
  
  minimizeAll: function() {
    this.windows.each(function(win) {
      if (win.canBeMinimized()) { win.minimize(); }
    });
  },
  
  hideSelects: function() {
    if (!navigator.userAgent.match(/MSIE 6/)) { return; }
    var selects = $$('select');
    if (selects.length === 0) { return; }
    var minimumZ = null;
    Glazing.WindowManager.windows.each(function(win) {
      var z = win.window.getStyle('zIndex') || 0;
      if (minimumZ === null) { minimumZ = z; }
      if (z < minimumZ) { minimumZ = z; }
    });
    selects.each(function(select) {
      select.setStyle({visibility: (select.getStyle('zIndex') <= minimumZ) && (minimumZ !== null) ? 'hidden' : 'visible'});
    });
  }
};


// The Task Switcher provides ALT-TAB-like functionality
Glazing.TaskSwitcher = {
  active: false,
  currentWindow: null,
  fadeOpacity: 0.15,
  
  exit: function() {
    var winMan = Glazing.WindowManager;
    this.active = false;
    if (this.currentWindow) {
      this.currentWindow.makeActive();
      if (this.currentWindow.isMinimized) { this.currentWindow.restore(); }
    }
    this.currentWindow = null;
    winMan.windows.each(function(win) {
      win.window.setStyle({opacity: 1});
    });
  }
};

$w('next prev').each(function(mode) {
  Glazing.TaskSwitcher[mode] = function() {
    var winMan = Glazing.WindowManager;
    var access = false, n = 0, k = winMan.windows.length - 1;
    if (!this.active) {
      this.active = true;
      this.currentWindow = winMan.activeWindow;
      while (!access && n < k) {
        this.currentWindow = this.currentWindow[mode];
        access = this.currentWindow.isAccessible();
        n++;
      }
      if (access) {
        winMan.windows.each(function(win) {
          if (win != this.currentWindow) { win.window.setStyle({opacity: this.fadeOpacity || 0.001}); }
        }.bind(this) );
      } else {
        this.currentWindow = null;
        this.exit();
      }
    } else {
      this.currentWindow.window.setStyle({opacity: this.fadeOpacity || 0.001});
      while (!access && n < k) {
        this.currentWindow = this.currentWindow[mode];
        access = this.currentWindow.isAccessible();
        n++;
      }
      this.currentWindow.window.setStyle({opacity: 1});
    }
  };
});


// Utilities library
Glazing.Utils = {

  // Get the viewport size - by PPK, http://www.quirksmode.org/viewport/compatibility.html
  windowSize: function() {
    var x, y;
    if (self.innerHeight) /* all except Explorer */ {
      x = self.innerWidth;
      y = self.innerHeight;
    }
    else if (document.documentElement && document.documentElement.clientHeight) /* Explorer 6 Strict Mode */ {
      x = document.documentElement.clientWidth;
      y = document.documentElement.clientHeight;
    }
    else if (document.body) /* other Explorers */ {
      x = document.body.clientWidth;
      y = document.body.clientHeight;
    }
    return {x: x, y: y};
  },
  
  // Get the document size - by PPK, http://www.quirksmode.org/viewport/compatibility.html
  documentSize: function() {
    var x, y;
    var test1 = document.body.scrollHeight;
    var test2 = document.body.offsetHeight;
    if (test1 > test2) /* all but Explorer Mac */ {
      x = document.body.scrollWidth;
      y = document.body.scrollHeight;
    }
    else /* Explorer Mac; would also work in Explorer 6 Strict, Mozilla and Safari */ {
      x = document.body.offsetWidth;
      y = document.body.offsetHeight;
    }
    return {x: x, y: y};
  },
  
  // Get the scroll offset - by PPK, http://www.quirksmode.org/viewport/compatibility.html
  scrollOffset: function() {
    var x, y;
    if (self.pageYOffset) /* all except Explorer */ {
      x = self.pageXOffset;
      y = self.pageYOffset;
    }
    else if (document.documentElement && document.documentElement.scrollTop) /* Explorer 6 Strict */ {
      x = document.documentElement.scrollLeft;
      y = document.documentElement.scrollTop;
    }
    else if (document.body) /* all other Explorers */ {
      x = document.body.scrollLeft;
      y = document.body.scrollTop;
    }
    return {x: x, y: y};
  }
};


// Function that adds window methods to the global scope
Glazing.enableGlobals = function(options) {
  options = $H(options || {});
  var methods = $w('Window Alert Confirm Overlay WindowManager TaskSwitcher');
  if (options.only) {
    methods = methods.findAll(function(method) {
      return options.only.include(method);
    });
  }
  if (options.except) {
    methods = methods.reject(function(method) {
      return options.except.include(method);
    });
  }
  methods.each(function(method) {
    window[method] = Glazing[method];
  });
};
