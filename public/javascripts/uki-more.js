uki.more = {};

uki.more.utils = {
    range: function (from, to) {
        var result = new Array(to - from), idx = 0;
        for (; from <= to; from++, idx++) {
            result[idx] = from;
        };
        return result;
    }
};

uki.extend(uki, uki.more.utils);

uki.more.view = {};

uki.viewNamespaces.push('uki.more.view.');

// really basic tree list implementation
uki.more.view.treeList = {};

uki.view.declare('uki.more.view.TreeList', uki.view.List, function(Base) {
    this._setup = function() {
        Base._setup.call(this);
        this._render = new uki.more.view.treeList.Render();
    };
    
    this.listData = Base.data;

    this.data = uki.newProp('_treeData', function(v) {
        this._treeData = v;
        this._data = this._treeNodeToListData(v);
        var children = this.listData(), opened = false;
        for (var i=children.length - 1; i >= 0 ; i--) {
            if (this._data[i].__opened) {
                opened = true;
                this._openSubElement(i);
            }
        };
        this.listData(this._data);
        if (opened) this.trigger('open');
    });

    this._treeNodeToListData = function(node, indent) {
        indent = indent || 0;
        return uki.map(node, function(row) {
            row.__indent = indent;
            return row;
        });
    };

    this.toggle = function(index) {
        this._data[index].__opened ? this.close(index) : this.open(index);
    };
    
    function offsetFrom (array, from, offset) {
        for (var i = from; i < array.length; i++) {
            array[i] += offset;
        };
    }
    
    function recursiveLength (item) {
        var children = uki.attr(item, 'children'),
        length = children.length;

        for (var i=0; i < children.length; i++) {
            if (children[i].__opened) length += recursiveLength(children[i]);
        };
        return length;
    }    
    
    this._openSubElement = function(index) {
        var item = this._data[index],
            children = uki.attr(item, 'children');

        if (!children || !children.length) return 0;
        var length = children.length;
        
        item.__opened = true;
        this._data.splice.apply(this._data, [index+1, 0].concat( this._treeNodeToListData(children, item.__indent + 1) ));
        
        for (var i=children.length - 1; i >= 0 ; i--) {
            if (this._data[index+1+i].__opened) {
                length += this._openSubElement(index+1+i);
            }
        };
        return length;
    };

    this.open = function(index) {
        if (this._data[index].__opened) return this;
        
        var length = this._openSubElement(index),
            positionInSelection = uki.binarySearch(index, this._selectedIndexes),
            clickIndex = this._lastClickIndex,
            indexes = this._selectedIndexes;
            
        this.clearSelection(true);
        offsetFrom(
            indexes, 
            positionInSelection + (indexes[positionInSelection] == index ? 1 : 0), 
            length
        );
            
        this.listData(this._data);
        this.selectedIndexes(indexes);
        this._lastClickIndex = clickIndex > index ? clickIndex + length : clickIndex;
        this.trigger('open');
        return this;
    };
    
    this.close = function(index) {
        var item = this._data[index],
            indexes = this._selectedIndexes,
            children = uki.attr(item, 'children');
        if (!children || !children.length || !item.__opened) return;
            
        var length = recursiveLength(item);
        
        item.__opened = false;
        this._data.splice(index+1, length);
        
        var positionInSelection = uki.binarySearch(index, indexes),
            removeFrom = positionInSelection + (indexes[positionInSelection] == index ? 1 : 0),
            toRemove = 0,
            clickIndex = this._lastClickIndex;
        while (indexes[removeFrom + toRemove] && indexes[removeFrom + toRemove] <= index + length) toRemove++;
        
        this.clearSelection(true);
        offsetFrom(indexes, removeFrom, -length);
        if (toRemove > 0) {
            indexes.splice(positionInSelection, toRemove);
        }

        this.listData(this._data);
        this.selectedIndexes(indexes);
        this._lastClickIndex = clickIndex > index ? clickIndex - length : clickIndex;
        this.trigger('close');
    };
    
    this._mousedown = function(e) {
        if (e.target.className.indexOf('toggle-tree') > -1) {
            var o = uki.dom.offset(this._dom),
                y = e.pageY - o.y,
                p = y / this._rowHeight << 0;
            this.toggle(p);
        } else {
            Base._mousedown.call(this, e);
        }
    };

    this._keypress = function(e) {
        Base._keypress.call(this, e);
        e = e.domEvent;
        if (e.which == 39 || e.keyCode == 39) { // RIGHT
            this.open(this._lastClickIndex);
        } else if (e.which == 37 || e.keyCode == 37) { // LEFT
            this.close(this._lastClickIndex);
        }
    };

});
// tree list render
uki.more.view.treeList.Render = uki.newClass(uki.view.list.Render, new function() {
    this._parentTemplate = new uki.theme.Template(
        '<div class="${classPrefix}-row ${classPrefix}-${opened}" style="margin-left:${indent}px">' + 
            '<div class="${classPrefix}-toggle"><i class="toggle-tree"></i></div>${text}' +
        '</div>'
    );

    this._leafTemplate = new uki.theme.Template(
        '<div class="${classPrefix}-row" style="margin-left:${indent}px">${text}</div>'
    );
    
    this.initStyles = function() {
        this.classPrefix = 'treeList-' + uki.guid++;
        var style = new uki.theme.Template(
            '.${classPrefix}-row { color: #333; position:relative; padding-top:3px; } ' +
            '.${classPrefix}-toggle { overflow: hidden; position:absolute; left:-15px; top:5px; width: 10px; height:9px; } ' +
            '.${classPrefix}-toggle i { display: block; position:absolute; left: 0; top: 0; width:20px; height:18px; background: url(${imageSrc});} ' +
            '.${classPrefix}-selected { background: #3875D7; } ' +
            '.${classPrefix}-selected .${classPrefix}-row { color: #FFF; } ' +
            '.${classPrefix}-selected i { left: -10px; } ' +
            '.${classPrefix}-selected-blured { background: #CCCCCC; } ' +
            '.${classPrefix}-opened i { top: -9px; }'
        ).render({ 
            classPrefix: this.classPrefix, 
            imageSrc: 'i/arrows.png'  // should call uki.image here
        });
        uki.dom.createStylesheet(style);
    };

    this.render = function(row, rect, i) {
        this.classPrefix || this.initStyles();
        var text = row.data,
            children = uki.attr(row, 'children');
        if (children && children.length) {
            return this._parentTemplate.render({ 
                text: text, 
                indent: row.__indent*18 + 22,
                classPrefix: this.classPrefix,
                opened: row.__opened ? 'opened' : ''
            });
        } else {
            return this._leafTemplate.render({ 
                text: text, 
                indent: row.__indent*18 + 22,
                classPrefix: this.classPrefix
            });
        }
    };
    
    this.setSelected = function(container, data, state, focus) {
        container.className = !state ? '' : focus ? this.classPrefix + '-selected' : this.classPrefix + '-selected-blured';
    };
});

uki.view.declare('uki.more.view.ToggleButton', uki.view.Button, function(Base) {
    
    this._setup = function() {
        Base._setup.call(this);
        this._focusable = false;
    };
    
    this.value = this.checked = uki.newProp('_checked', function(state) {
        this._checked = !!state;
        this._updateBg();
    });
    
    this._updateBg = function() {
        var name = this._disabled ? 'disabled' : this._down || this._checked ? 'down' : this._over ? 'hover' : 'normal';
        this._backgroundByName(name);
    };
    
    this._mouseup = function(e) {
        if (!this._down) return;
        this._down = false;
        if (!this._disabled) this.checked(!this.checked())
    };
    
});


uki.view.declare('uki.more.view.RadioButton', uki.more.view.ToggleButton, function(base) {
    var manager = uki.view.Radio;
    
    this.group = uki.newProp('_group', function(g) {
        manager.unregisterGroup(this);
        this._group = g;
        manager.registerGroup(this);
        if (this.checked()) manager.clearGroup(this);
    });
    
    this.value = this.checked = uki.newProp('_checked', function(state) {
        this._checked = !!state;
        if (state) manager.clearGroup(this);
        this._updateBg();
    });
    
    this._mouseup = function() {
        if (!this._down) return;
        this._down = false;
        if (!this._checked && !this._disabled) {
            this.checked(!this._checked);
            this.trigger('change', {checked: this._checked, source: this});
        }
    }
});
uki.more.view.splitTable = {};

uki.view.declare('uki.more.view.SplitTable', uki.view.Container, function(Base) {
    var Rect = uki.geometry.Rect,
        Size = uki.geometry.Size;
        
    var propertiesToDelegate = 'rowHeight data packSize visibleRectExt render selectedIndex focusable textSelectable multiselect'.split(' ');
    
    
    this._defaultHandlePosition = 200;
    this._headerHeight = 17;
    
    this._style = function(name, value) {
        this._leftHeader.style(name, value);
        this._rightHeader.style(name, value);
        return Base._style.call(this, name, value);
    };
    
    this.columns = uki.newProp('_columns', function(c) {
        this._columns = uki.build(c);
        this._totalWidth = 0;
        this._leftHeader.columns([this._columns[0]]);
        
        this._columns[0].bind('beforeResize', uki.proxy(this._syncHandlePosition, this, this._columns[0]));
        
        for (var i = 1; i < this._columns.length; i++) {
            this._columns[i].position(i - 1);
            this._columns[i].bind('beforeResize', uki.proxy(this._rightColumnResized, this, this._columns[i]));
        };
        this._updateTotalWidth();
        this._rightHeader.columns(Array.prototype.slice.call(this._columns, 1));
        this._splitPane.leftMin(this._columns[0].minWidth() - 1)
        // this._splitPane.handlePosition(this._columns[0].width());
        this._syncHandlePosition(this._splitPane);
    });
    
    uki.each(propertiesToDelegate, function(i, name) { 
        this[name] = function(v) {
            if (v === undefined) return this._leftList[name]();
            this._leftList[name](v);
            this._rightList[name](v);
            return this;
        };
    }, this);
    
    this.hasFocus = function() {
        return this._leftList.hasFocus() || this._rightList.hasFocus();
    };
    
    this.rightColumns = function() {
        return this._rightHeader.columns();
    };
    
    this._rightColumnResized = function(column) {
        this._updateTotalWidth();
        this._horizontalScroll.layout();
    };
    
    this.rowHeight = function(value) {
        if (value === undefined) return this._leftList.rowHeight();
        this._leftList.rowHeight(value);
        this._rightList.rowHeight(value);
        return this;
    };
    
    this.data = function(d) {
        if (d === undefined) return uki.map(this._leftList.data(), function(value, i) {
            return [value].concat(this._rightList.data()[i]);
        }, this);
        
        this._leftList.data(uki.map(d, function(value) {
            return [value[0]];
        }));
        
        this._rightList.data(uki.map(d, function(value) {
            return value.slice(1);
        }));
        
        this._splitPane.minSize(new Size(0, this._leftList.minSize().height));
        this._verticalScroll.layout();
    };
    
    this._createDom = function() {
        Base._createDom.call(this);
        var scrollWidth = uki.view.ScrollPane.initScrollWidth(),
            bodyHeight = this.rect().height - this._headerHeight - scrollWidth,
            contents = uki(
            [
                { 
                    view: 'table.Header', 
                    rect: new Rect(this._defaultHandlePosition, this._headerHeight), 
                    anchors: 'left top' 
                },
                { 
                    view: 'Box',
                    className: 'table-header-container',
                    style: { overflow: 'hidden' },
                    rect: new Rect(this._defaultHandlePosition, 0, this.rect().width - this._defaultHandlePosition - 1, this._headerHeight), 
                    anchors: 'left top right',
                    childViews: { 
                        view: 'table.Header', 
                        rect: new Rect(this.rect().width - this._defaultHandlePosition - 1, this._headerHeight), 
                        anchors: 'top left right', 
                        className: 'table-header' 
                    }
                },
                {
                    view: 'ScrollPane',
                    rect: new Rect(0, this._headerHeight, this.rect().width, bodyHeight),
                    anchors: 'left top right bottom',
                    className: 'table-v-scroll',
                    scrollV: true,
                    childViews: [
                        { 
                            view: 'HSplitPane', 
                            rect: new Rect(this.rect().width, bodyHeight), 
                            anchors: 'left top right bottom',
                            className: 'table-horizontal-split-pane',
                            handlePosition: this._defaultHandlePosition,
                            handleWidth: 1,
                            leftChildViews: [
                                { 
                                    view: 'List', 
                                    rect: new Rect(this._defaultHandlePosition, bodyHeight), 
                                    anchors: 'left top right bottom',
                                    className: 'table-list-left' 
                                }
                            ],
                            rightChildViews: [
                                { 
                                    view: 'Box', 
                                    rect: '0 0 100 100', 
                                    anchors: 'left top right bottom',
                                    style: { overflow: 'hidden' },
                                    rect: new Rect(this.rect().width - this._defaultHandlePosition - 1, bodyHeight), 
                                    childViews: { 
                                        view: 'ScrollPane', 
                                        rect: new Rect(this.rect().width - this._defaultHandlePosition - 1, bodyHeight + scrollWidth), 
                                        scrollableV: false,
                                        scrollableH: true,
                                        anchors: 'left top right bottom',
                                        className: 'table-h-scroll',
                                        childViews: [
                                            { 
                                                view: 'List', 
                                                rect: new Rect(this.rect().width - this._defaultHandlePosition - 1, bodyHeight + scrollWidth), 
                                                anchors: 'left top right bottom' 
                                            }
                                        ]
                                    }
                                    
                                }
                            ]
                        }
                    ]
                },
                { 
                    view: 'ScrollPane', 
                    rect: new Rect(this._defaultHandlePosition + 1, bodyHeight + this._headerHeight, this.rect().width - this._defaultHandlePosition - 1, scrollWidth), 
                    anchors: 'left bottom right',
                    scrollableH: true,
                    scrollableV: false,
                    scrollH: true,
                    className: 'table-h-scroll-bar',
                    childViews: { view: 'Box', rect: '1 1', anchors: 'left top' }
                 }
            ]).appendTo(this);
            
        this._verticalScroll = uki('ScrollPane[className=table-v-scroll]', this)[0];
        this._horizontalScroll = uki('ScrollPane[className=table-h-scroll]', this)[0];
        this._horizontalScrollBar = uki('ScrollPane[className=table-h-scroll-bar]', this)[0];
        this._leftList = uki('List:eq(0)', this)[0];
        this._rightList = uki('List:eq(1)', this)[0];
        this._splitPane = uki('HSplitPane', this)[0];
        this._leftHeader = uki('table.Header:eq(0)', this)[0];
        this._rightHeader = uki('table.Header:eq(1)', this)[0];
        this._rightHeaderContainer = uki('[className=table-header-container]', this)[0];
        this._dummyScrollContents = uki('Box', this._horizontalScrollBar);
        
        this._leftList._scrollableParent = this._verticalScroll;
        this._rightList._scrollableParent = this._verticalScroll;
        this._verticalScroll.bind('scroll', uki.proxy(this._leftList._scrollableParentScroll, this._leftList));
        this._verticalScroll.bind('scroll', uki.proxy(this._rightList._scrollableParentScroll, this._rightList));
        
        this._leftList.render(new uki.more.view.splitTable.Render(this._leftHeader));
        this._rightList.render(new uki.more.view.splitTable.Render(this._rightHeader));
        this._bindEvents();
    };
    
    this._bindEvents = function() {
        this._splitPane.bind('handleMove', uki.proxy(this._syncHandlePosition, this, this._splitPane));
        this._horizontalScroll.bind('scroll', uki.proxy(this._syncHScroll, this, this._horizontalScroll));
        this._horizontalScrollBar.bind('scroll', uki.proxy(this._syncHScroll, this, this._horizontalScrollBar));
        this._leftList.bind('selection', uki.proxy(this._syncSelection, this, this._leftList));
        this._rightList.bind('selection', uki.proxy(this._syncSelection, this, this._rightList));
    };
    
    var updatingHandlePosition = false;
    this._syncHandlePosition = function(source) {
        if (updatingHandlePosition) return;
        updatingHandlePosition = true;
        var w, rect;
        if (source == this._splitPane) {
            w = this._splitPane.handlePosition() + 1;
            this.columns()[0].width(w);
        } else {
            var w = this.columns()[0].width();
            this._splitPane.handlePosition(w - 1).layout();
        }
        
        this._leftHeader.rect(new Rect(w, this._headerHeight)).layout();
        
        rect = this._rightHeaderContainer.rect().clone();
        rect.x = w;
        rect.width = this._rect.width - w - uki.view.ScrollPane.initScrollWidth();
        this._rightHeaderContainer.rect(rect).layout();
        rect = this._horizontalScrollBar.rect().clone();
        rect.x = w;
        rect.width = this._rect.width - w - uki.view.ScrollPane.initScrollWidth();
        this._horizontalScrollBar.rect(rect).layout();
        updatingHandlePosition = false;
    };
    
    var updatingHScroll = false;
    this._syncHScroll = function(source) {
        if (updatingHScroll) return;
        updatingHScroll = true;
        var scroll, target = source == this._horizontalScroll ? this._horizontalScrollBar : this._horizontalScroll;
        scroll = source.scrollLeft();
        target.scrollLeft(scroll);
        this._rightHeader.dom().style.marginLeft = -scroll + 'px'; 
        updatingHScroll = false;
    };
    
    var updatingSelection = false;
    this._syncSelection = function(source) {
        if (updatingSelection) return;
        updatingSelection = true;
        var target = source == this._leftList ? this._rightList : this._leftList;
        target.selectedIndexes(source.selectedIndexes());
        updatingSelection = false;
    };
    
    this._updateTotalWidth = function() {
        this._totalWidth = 0;
        for (var i=1; i < this._columns.length; i++) {
            this._totalWidth += this._columns[i].width();
        };
        this._rightHeader.minSize(new Size(this._totalWidth, 0));
        this._rightList.minSize(new Size(this._totalWidth, this._rightList.minSize().height));
        this._dummyScrollContents.rect(new Rect(this._totalWidth, 1)).parent().layout();
        this._rightHeader.minSize(new Size(this._totalWidth, 0));
        this._horizontalScroll.layout();
    };
    
});
uki.more.view.splitTable.Render = uki.newClass(uki.view.table.Render, new function() {
    
    this.setSelected = function(container, data, state, focus) {
        focus = true;
        container.style.backgroundColor = state && focus ? '#3875D7' : state ? '#CCC' : '';
        container.style.color = state && focus ? '#FFF' : '#000';
    }

});


uki.view.declare('uki.more.view.Form', uki.view.Container, function(Base) {
    
    this._setup = function() {
        Base._setup.call(this);
        uki.extend(this, {
            _method: 'GET',
            _action: ''
        });
    };
    
    this.action = uki.newProp('_action', function(action) {
      this._dom.action = this._action = action;
    });
    this.method = uki.newProp('_method', function(method) {
      this._dom.method = this._method = method;
    });
    
    this.submit = function() { this._dom.submit(); }
    this.reset = function() { this._dom.reset(); }
    
    this._createDom = function() {
        this._dom = uki.createElement('form', Base.defaultCss);
        this._initClassName();
        this._dom.action = this._action;
        this._dom.method = this._method;
    };
   
});


uki.view.declare('uki.more.view.Select', uki.view.Checkbox, function(Base) {
    this._backgroundPrefix = 'select-';
    this._popupBackground = 'theme(select-popup)';
    this._listBackground = 'theme(select-list)';
    this._popupOffset = 0;
    
    this._setup = function() {
        Base._setup.call(this);
        this._inset = new uki.geometry.Inset(0, 20, 0, 4);
        this._selectFirst = true;
        this._focusable = true;
        this._options = [];
        this._maxPopupHeight = 200;
        this._lastScroll = 0;
    };
    
    this.Render = uki.newClass(uki.view.list.Render, function(Base) {
        this.render = function(data, rect, i) {
            return '<span style="line-height: 22px; text-align: left; white-space: nowrap; margin: 0 4px; cursor: default">' + data + '</span>';
        }
        
        this.setSelected = function(container, data, state, focus) {
            container.style.backgroundColor = state ? '#3875D7' : '';
            container.style.color = state ? '#FFF' : '#000';
        }
    });
    
    this.selectFirst = uki.newProp('_selectFirst');
    
    this.opened = function() {
        return this._popup.visible() && this._popup.parent();
    };
    
    this.popupAnchors = function(v) {
        if (v === undefined) return this._popup.anchors();
        this._popup.anchors(v);
        return this;
    };
    
    this._createDom = function() {
        Base._createDom.call(this);
        this.style({ fontWeight: 'normal', textAlign: 'left' });
        
        this._label.style.overflow = 'hidden';
        this._popup = uki(
            { view: 'Popup', anchors: 'left top', rect: '100 100',  style: {zIndex: 1000}, offset: this._popupOffset,
                background: this._popupBackground, relativeTo: this, visible: false, 
                childViews: [
                    { view: 'ScrollPane', rect: '100 100', anchors: 'left top right bottom', childViews: [
                        { view: 'List', rect: '100 100', anchors: 'left top right bottom', rowHeight: 22, 
                            textSelectable: false, focusable: true, background: this._listBackground,
                            render: new this.Render(), style: { fontSize: '12px' } }
                    ] }
                ] }
        )[0];
        
        this._popup.hide();
        
        this._list = uki('List', this._popup)[0];
        this._scroll = uki('ScrollPane', this._popup)[0];
        
        this._popup.bind('toggle', uki.proxy(function(e) {
            this._down = this._popup.visible();
            if (this._popup.visible()) {
                this._updateWidth();
                this._scroll.scrollTop(this._lastScroll);
            }
            this._checked = this._popup.visible();
            this._updateBg();
        }, this));
        
        this.bind(this._list.keyPressEvent(), function(e) {
            if (this.preventTransfer) {
                this.preventTransfer = false;
                return;
            }
            if (this._popup.visible()) {
                this._list.trigger(e.type, e);
            }
        });
        
        this.bind('blur', function() { 
            setTimeout(uki.proxy(function() {
                if (!this._hasFocus && this.opened()) {
                    this._lastScroll = this._scroll.scrollTop();
                    this._popup.hide();
                }
            }, this), 50)
        });
        
        // refocus on list click
        this._list.bind('focus', uki.proxy(function() {
            this._hasFocus = false;
            this.focus();
            // setTimeout(uki.proxy(this.focus, this), 5);
        }, this));
        
        this._list.bind('click', uki.proxy(this.selectCurrent, this));
    };
    
    this.contentsSize = function(autosize) {
        var html = this.html(), size;
        this.html(this._longestText);
        size = Base.contentsSize.call(this, autosize);
        this.html(html);
        return size;
    };

    this._keydown = function(e) {
        if ((e.which == 32 || e.which == 13) && this._popup.visible()) {
            this.selectCurrent(e);
        } else if ((e.which == 40 || e.which == 38) && !this._popup.visible()) {
            this._popup.toggle();
            e.preventDefault();
            this.preventTransfer = true;
        } else {
            Base._keydown.call(this, e);
        }
    };
    
    this.selectCurrent = function(e) {
        if (this.selectedIndex() == -1) {
            this.text(this._selectFirst && this._options[0] ? this._options[0].text : '');
        } else {
            this.text(this._options[this.selectedIndex()].text);
        }
        this._lastScroll = this._scroll.scrollTop();
        this._popup.hide();
        if (e) this.trigger('change', { source: this });
    };
    
    this.value = function(v) {
        if (v === undefined) {
            return this._options[this.selectedIndex()] ? this._options[this.selectedIndex()].value : undefined;
        } else {
            var index = -1,
                option,
                l = this._options.length,
                i;
            for (i=0; i < l; i++) {
                option = this._options[i];
                if (option.value == v) {
                    index = i;
                    break;
                }
            };
            this.selectedIndex(index);
            this.selectCurrent();
        }
    };
    
    this.maxPopupHeight = uki.newProp('_maxPopupHeight');
    
    this._updateWidth = function() {
        if (this._widthCached || !this._options.length) return;
        var source = this._list.dom().firstChild.firstChild.firstChild, /// omg!
            html = source.innerHTML;
            
        source.innerHTML = this._longestText;
        this._widthCached = source.offsetWidth + 8;
        source.innerHTML = html;
        this._popup.rect(new uki.geometry.Rect(
            this._popup.rect().x,
            this._popup.rect().y,
            Math.max(this._widthCached, this.rect().width),
            Math.min(this._maxPopupHeight, this._options.length * 22)
        )).layout();
    };
    
    this.options = uki.newProp('_options', function(o) {
        this._options = o;
        this._list
            .data(uki.map(o, 'text'))
            .selectedIndex(0);
        
        if (this._selectFirst && (o.length > 0)) this.text(o[0].text);
        this._longestText = '';
        uki.each(o, function(i, row) {
            if (row.text.length > this._longestText.length) this._longestText = row.text;
        }, this);
        this._widthCached = false;
        this._lastScroll = 0;
    });
    
    uki.delegateProp(this, 'selectedIndex', '_list');
    
    this._updateBg = function() {
        return Base._updateBg.call(this);
    };
    
    this._mousedown = function(e) {
        Base._mousedown.call(this, e);
        if (this.disabled()) return;
        this._popup.toggle();
        this.trigger('toggle', { opened: this.opened() });
        // if (this._popup.visible()) this._list.focus();
    };
    
    this._mouseup = function(e) {
        if (!this._down) return;
        this._down = false;
    };
    
});

uki.Collection.addAttrs(['options']);


(function() {
    function selectHandle (image, css) {
        return new uki.background.CssBox((css || '') + 'background: url(' + uki.theme.imageSrc(image) + '); background-position: 100% 50%; background-repeat: no-repeat;');
    }
    
    var theme = uki.extend({}, uki.theme.Base, {
        backgrounds: {
            // 'select-list': function() {
            //     
            // },
            // 'select-popup': function() {
            //     
            // },
            'select-normal': function() {
                return new uki.background.Multi(
                    selectHandle('select-handle-normal'),
                    uki.theme.background('button-normal')
                );
            },
            'select-hover': function() {
                return new uki.background.Multi(
                    selectHandle('select-handle-normal'),
                    uki.theme.background('button-hover')
                );
            },
            'select-checked-normal': function() {
                return new uki.background.Multi(
                    selectHandle('select-handle-normal'),
                    uki.theme.background('button-down')
                );
            },
            'select-disabled': function() {
                return new uki.background.Multi(
                    selectHandle('select-handle-normal', 'opacity:0.4;'),
                    uki.theme.background('button-disabled')
                );
            },
            
            'select-popup': function() {
                return uki.theme.background('popup-normal');
            }
        },
        
        imageSrcs: {
            'select-handle-normal': function() {
                return ["select-down-m.png", "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABcAAABkCAYAAABtnKvPAAAAeUlEQVRo3u3SMQ2AMBAFUCQgAQlIQUKTthq6IhEpOIAOTIWFABPvkr/c8IZ/15VStu6rgcPhcDgcDofD4XA4HA6HnybnvNRsF1ke4yGEoUJrA691379SS4xxavDx1c5TSvMBh08Oegv253A4HA6Hw+FwOBwOh8P/ie9z0RuWFOYPhAAAAABJRU5ErkJggg==", "select-down-m.gif"];
            }
        }
    });
    theme.backgrounds['select-checked-hover'] = theme.backgrounds['select-checked-normal'];
    
    uki.theme.register(theme);
})();

