var Lail; if(!Lail) Lail={};
Lail.PaginatedList = function(list, options) {
  // todo: paste John Resig's code
  
  options = options || {};
  var self = this;
  
  this.set = [];
  this.set_length = 0;
  this.current_page = 1;
  this.page_size = options.page_size || 20;
  this.always_show = (typeof options.always_show == 'undefined') ? true : options.always_show;
  this.page_count = 1;
  this.observer = new Observer();
  this.pagination_container = null;
  this.during_init = false;
  
  
  
  this.count = function() {
    return self.set_length;
  }
  
  
  
  this.init = function(list, initialPage, options) {
    if((options || {}).page_size) {
      self.page_size = options.page_size;
    }
    self.during_init = true;
    self.set = list;
    self.set_length = self.set.length;
    self.page_count = parseInt(Math.ceil(self.set_length / self.page_size));
    if(self.page_count < 1) {
      self.page_count = 1;
    }
    self.current_page = 0;
    self.gotoPage(initialPage || 1);
    self.during_init = false;
  }
  
  this.gotoPage = function(page_number) {
    page_number = +page_number; // needs to be an integer
    if(page_number < 1) page_number = 1;
    if(page_number > self.page_count) page_number = self.page_count;
    if(page_number != self.current_page) __setCurrentPage(page_number);
  }
  
  function __setCurrentPage(page_number) {
    self.current_page = page_number;
    self.current_set = self.set.slice(self.firstItemIndex(), self.lastItemIndex());
    renderPagination();
    notifyOfPageChange();
  }
  
  this.firstItemIndex = function() {
    return (self.current_page - 1) * self.page_size || 0;
  }
  
  this.lastItemIndex = function() {
    var end = self.current_page * self.page_size;
    return (end > self.set_length) ? self.set_length : end;
  }
  
  this.getCurrentPage = function() {
    return self.current_page;
  }
  
  this.getCurrentSet = function() {
    return self.current_set;
  }
  
  this.getEntireSet = function() {
    return self.set;
  }
  
  function renderPagination() {
    if(self.pagination_container) {
      self.pagination_container.html(self.renderPagination());
    }
  }
  
  function notifyOfPageChange() {
    self.observer.fire('changed', {onInit: self.during_init});
  }
  
  
  
  this.onPageChange = function(callback) {
    self.observer.observe('changed', callback);
  }
  
  
  
  this.gotoNextPage = function() {
    if(self.isLastPage()) { 
      return false;
    } else {
      self.gotoPage(self.current_page + 1);
      return true;
    }
  }
  
  this.getNextPageNumber = function() {
    return self.isLastPage() ? self.current_page : (self.current_page + 1);
  }
  
  this.isLastPage = function() {
    return (self.current_page == self.page_count);
  }
  
  
  
  this.gotoPreviousPage = function() {
    if(self.isFirstPage()) { 
      return false;
    } else {
      self.gotoPage(self.current_page - 1);
      return true;
    }
  }
  
  this.getPreviousPageNumber = function() {
    return self.isFirstPage() ? self.current_page : (self.current_page - 1);
  }
  
  this.isFirstPage = function() {
    return (self.current_page == 1);
  }
  
  
  
  // !nb: uses jQuery!!!
  this.renderPaginationIn = function(selector) {
    self.pagination_container = jQuery(selector);
    self.pagination_container.delegate('a', 'click', function(e) {
      e.preventDefault();
      e.stopImmediatePropagation();
      var a = jQuery(this);
      if(a.hasClass('prev_page')) {
        self.gotoPreviousPage();
      } else if(a.hasClass('next_page')) {
        self.gotoNextPage();
      } else if(a.hasClass('goto_page')) {
        self.gotoPage(parseInt(a.attr('id').substring(5)));
      }
      return false;
    });
  }
  
  // !todo: use Handlebars
  this.renderPagination = function() {
    var html = '',
        current = self.current_page,
        count = self.page_count,
        min = 1,
        max = count;
    
    if(this.always_show || count > 1) {
      if(self.isFirstPage()) {
        html += '<span class="prev_page disabled">&#171; Previous</span> ';
      } else {
        html += '<a class="prev_page" href="#" rel="previous">&#171; Previous</a> ';
      }
      
      // list no more than 7 page numbers
      if(self.page_count > 7) {
        min = current - 3;
        max = current + 3;
        var shift = (min < 1) ? (1 - min) : ((max > count) ? (count - max) : 0);
        min += shift;
        max += shift;
      }
      for(var i=min; i<=max; i++) {
        if(i == self.current_page) {
          html += ' <span class="currentPage">' + i + '</span> ';
        } else {
          html += ' <a class="goto_page" href="#" id="page_' + i + '">' + i + '</a> ';
        }
      }
      
      if(self.isLastPage()) {
        html += ' <span class="next_page disabled">Next &#187;</span>';
      } else {
        html += ' <a class="next_page" href="#" rel="next">Next &#187;</a>';
      }
    }
    
    return html;
  }
  
  // !todo: use handlebars
  this.renderExtendedPagination = function() {
    var html = 'Listing <strong>';
    if(self.page_count > 1) { 
      html += (self.firstItemIndex()+1) + '&ndash;' + self.lastItemIndex() + '</strong> of <strong>';
    }
    return html + self.count() + '</strong>';
  }
  
  
  
  this.init(list || []);
}