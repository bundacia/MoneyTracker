function Lists() {};
_LISTS = new Lists();

function getList(id) {
    return _LISTS[id]
}

function List(id, name, comment, load) {
    this.id      = id
    this.name    = name
    this.comment = comment
    this.load    = load == undefined ? function(){} : load

    this.header_id = "#list_header_" +this.id
    this.body_id   = "#list_body_"   +this.id

    // Add to the global list of lists
    _LISTS[id] = this;

    this.getHTML = function() {

        list = '\n' 
            + '<div  id="list_header_' +this.id+'" class="list_header" onclick="_LISTS[\''+this.id+'\'].clicked()" '
            + 'onMouseOver="_LISTS[\''+this.id+'\'].mOver()" '
            + 'onMouseOut ="_LISTS[\''+this.id+'\'].mOut() " '
            + '>\n'
            + '<span id="list_name_'   +this.id+'" class="list_name"   >' + this.name    + '</span>'
            + '<span id="list_comment_'+this.id+'" class="list_comment">' + this.comment + '</span>\n'
            + '</div>\n'
            + '<div class="list_body" style="display:none" id="list_body_' + this.id + '"></div>\n'
        return list
    }

    this.clicked = function() {

        //TODO this first case needs to be changed. things break if you click a fund while it's loading.
        if ($(this.body_id).css('display') == 'none' && $(this.body_id).html() == '')
            this.load(this.id, true);
        else if ($( this.body_id ).css('display') == 'none')
            this.open()
        else
            this.close()

    }

    this.open = function() {
        $( this.header_id ).addClass('open');
        $( this.body_id   ).show();
    }

    this.close = function() {
        $( this.body_id   ).hide();
        $( this.header_id ).removeClass('open');
    }

    this.mOver = function(){ 
        if(!$(this.header_id).is('.open')) 
            $(this.header_id).removeClass('list_header').addClass('list_header_hover')
    }

    this.mOut = function() { 
        if(!$(this.header_id).is('.open')) 
            $(this.header_id).removeClass('list_header_hover').addClass('list_header')
    }

    this.getComment = function() {
        return $( '#list_comment_'+this.id )
    }

    this.setComment = function(newVal) {
        this.comment = newVal
        $( '#list_comment_'+this.id ).html(this.comment)
    }

    this.setBody = function(newVal) {
        $( '#list_body_'+this.id ).html(newVal);
    }

    this.getBody = function() {
        return $( '#list_body_'+this.id );
    }

}


