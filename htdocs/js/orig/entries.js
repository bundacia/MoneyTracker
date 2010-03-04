/***************************************************
 * Class    : FundList
 * Inherits : List
 *
 * Description:
 *    A FundList represents the GUI representation
 *    of a fund as a list of entries. It provides 
 *    methods for creating and manipulating this 
 *    GUI element.
 ***************************************************/
function FundList(id, name, balance, allowance, load) {

    this.inheritFrom = List
    this.inheritFrom(
        'f'+id, 
        name, 
        balance+'&nbsp;/&nbsp;<span class="fund_allowance">'+allowance+'</span>',
        load
    )
    this.allowance = allowance
    this.balance   = balance
    this.fund_id   = id

    /*-----------------------------------------------------*
    * Method : appendTo
    * Params : element - a css descriptor of a DOM element
    * Desc.  : Append the HTML for this FundList to a
    *          DOM element.
    *------------------------------------------------------*/
    this.appendTo = function(element) {

        html = this.getHTML();

        $(element).append(html);

        $('#list_body_'+this.id).html(
              '<div id="fund_list_details_' +this.fund_id+'" class="list_details" >Allowance: ' + this.allowance + '</div>\n'
            + '<form id="create_entry_'+this.fund_id+'">\n'
            + '<input type="hidden" name="fund_id" value="'+this.fund_id+'"></input>'
            + '<table>\n'
            + '<thead><tr><th scope="col">Date</th><th>Payee</th><th>Amount</th><th>Description</th></thead>\n'
            + '<tbody>'
            + '<tr>'
            + '<td><input type="text" name="date"        size="10" onKeyDown="javascript:return create_entry_key_event(event,'+this.fund_id+')"></input></td>'
            + '<td><input type="text" name="entity"      size="20" onKeyDown="javascript:return create_entry_key_event(event,'+this.fund_id+')"></input></td>'
            + '<td><input type="text" name="amount"      size="10" onKeyDown="javascript:return create_entry_key_event(event,'+this.fund_id+')"></input></td>'
            + '<td><input type="text" name="description" size="25" onKeyDown="javascript:return create_entry_key_event(event,'+this.fund_id+')"></input></td>'
            + '</tr>'
            + '</tbody>\n'
            + '</table>\n'
            + '</form>\n'
        );
    
        this.setBalance(this.balance)

        // Add the date picker
        $('#create_entry_'+id+' input[name=date]').datepicker({ 
            changeMonth: false,    // no dropdown for changing month, year
            changeYear: false,     // no dropdown for changing month, year
            showOn: 'focus',       // popup on focus (no icon)
            closeAtTop: false,     // close/clear links at bottom
            showOtherMonths: true, // show days from other months at beginning and end 
            dateFormat: 'yy/mm/dd',
            defaultDate: new Date(mt.year, mt.month-1, mt.day) // Show todays date or a date in the right month
        });

        // Setup autocomplete hook
        $('#create_entry_'+id+' input[name=entity]')
            .autocomplete( '/cgi-bin/mt.cgi', {
                cacheLength: 3,
                extraParams: {m: 'ac_entity', fund: id},
                autoFill: 1
            })
        ;

        return this
    }

    /*-----------------------------------------------------*
    * Method : setRows
    * Params : newVal
    * Desc.  : set the contents of the FundList
    *------------------------------------------------------*/
    this.setRows = function(newVal) {
        $( '#list_body_'+this.id+' tbody > tr:last' ).before(newVal);
        return this
    }

    /*-----------------------------------------------------*
    * Method : getRows
    * Desc.  : get the tbody jquery object for the FundList
    *------------------------------------------------------*/
    this.getRows = function() {
        return $( '#list_body_'+this.id+' tbody' );
    }

    /*-----------------------------------------------------*
    * Method : setBalance
    * Params : newVal
    * Desc.  : set balance for this FundList
    *------------------------------------------------------*/
    this.setBalance = function(newVal) {
        this.balance = parseFloat( newVal )
        this.setComment(
            fmtDollars(this.balance)
            +'&nbsp;/&nbsp;'
            +'<span class="fund_allowance">'+this.allowance+'</span>'
        )

        // We have to round before doing the comparisons because of float errors
        rounded = roundNumber(this.balance,2)
        if      (rounded <  0) {
            this.getComment()
                .removeClass('zero_balance'    )
                .addClass   ('negative_balance') 
        }
        else if (rounded == 0) {
            this.getComment()
                .removeClass('negative_balance')
                .addClass   ('zero_balance'    ) 
        }
        else { 
            this.getComment()
                .removeClass('negative_balance')
                .removeClass('zero_balance'    ) 
        }
        return this
    }

    /*-----------------------------------------------------*
    * Method : getBalance
    * Desc.  : get floating point balance for this FundList
    *------------------------------------------------------*/
    this.getBalance = function() {
        return parseFloat( this.balance )
    }

    /*-----------------------------------------------------*
    * Method : updateBalance
    * Desc.  : recalculate balance from the entries
    *------------------------------------------------------*/
    this.updateBalance = function() {

        // initialise with this months allowance
        balance = parseFloat( this.allowance )

        // add up the amounts in the 3rd col
        this.getBody()
            .find('tr[entry_id] td:nth-child(3)')
            .each(function(){
                amount   = $(this).text()
                balance += parseFloat(amount)
            })

        this.setBalance(balance);

        return this
    }

}

/***************************************************
 * Method : getFundList
 * Params : id - the fund_id of the fund you want
 * Desc.  : Returns the FundList for the given fund
 ***************************************************/
function getFundList(id) {
    return getList('f'+id)
}

/***************************************************
 * Method : get_funds
 * Desc.  : Initiate XHR to load all funds. Uses 
 *          the month and year that were set globally
 ***************************************************/
function get_funds() {
    // Show wait bar
    $('#main_content_wait_icon').show()

    // send request
    $.post("/cgi-bin/mt.cgi", 
        {
            m     : 'get_entries', 
            month : mt.month     , 
            year  : mt.year
        }, 
        function(xml) {
            // Handle auth errors
            if(!check_for_errors(xml)) { 
                $('#main_content_wait_icon').hide()
                return
            }
            // Handle result
            process_funds_xml(xml)
            // Hide wait bar
            $('#main_content_wait_icon').hide()
        }
    );
}

/***************************************************
 * Method : process_funds_xml
 * Params : xml - xml representing funds and entries
 *          as returned by the "get_entries" runmode
 * Desc.  : use XML to create FundLists
 ***************************************************/
function process_funds_xml(xml) {

    // format and output result
    if( $("MoneyTracker_Fund", xml).length > 0 ) {

        $("#funds").html('\n')

        d = new Date()
        if( mt.year == d.getFullYear() )
            $("#month_display").html(MT_MONTH_NAMES[mt.month]);
        else
            $("#month_display").html(MT_MONTH_ABBRV[mt.month]+' '+mt.year);

        $("MoneyTracker_Fund", xml).each(function() {
            id = $(this).attr("ID");

            fund = new FundList(
                id, 
                $(this).attr( "name"    ), 
                $(this).attr( "balance" ),
                $(this).attr( "value"   ),
                reload_fund
            )

            fund.appendTo("#funds")

            process_fund_xml( $("MoneyTracker_Fund[ID="+id+"]", xml) )
        });

        $("#funds").addClass("loaded");

    } //end if
}

/******************************************************
 * Method : reload_fund
 * Params : id     - fund_id of fund to load
 *          reveal - if true, show FundList after load
 * Desc.  : Initiate XHR to reload an existing FundList 
 ******************************************************/
function reload_fund(id, reveal) { 

    // send request
    $.get("/cgi-bin/mt.cgi", 
        {
            m:       'get_entries', 
            month:   mt.month, 
            year:    mt.year, 
            fund_id: id
        }, 
        function(xml){ 
            // Handle auth errors
            if(!check_for_errors(xml)){ return; }
            process_fund_xml(xml); 

            // Reveal this fund if asked 
            if (reveal) {
                getFundList(id).show(); 
            }
         }
     );
}

/********************************************************
 * Method : process_fund_xml
 * Params : xml - fund xml
 * Desc.  : update the rows of a Fundlist given fund xml
 ********************************************************/
function process_fund_xml(xml) {

    // We could be passed the raw xml or an object, so get the ID the right way.
    id = xml.attr ? xml.attr('ID') : $('MoneyTracker_Fund', xml).attr('ID') ;

    fund_list = getFundList(id)

    // format and output result
    entries = ''
    $("MoneyTracker_Entry", xml).each(function() {
        entries += '<tr id="entry_'+$(this).attr("ID")+'" '
                +      'entry_id="'+$(this).attr("ID")+'" '
                +      'onClick="entry_clicked(this)">'
                +  '<td>'+ format_mysql_date($(this).attr("date"))
                +  '</td><td>'+ $(this).attr( "entity"      ) 
                +  '</td><td>'+ $(this).attr( "amount"      ) 
                +  '</td><td>'+ $(this).attr( "description" )
                +  '</td></tr>';
    });

    fund_list.setRows( entries )

}

/********************************************************
 * Method : entry_clicked
 * Params : entry - an entry row (tr DOM element)
 * Desc.  : handle en entry being clicked
 ********************************************************/
function entry_clicked(entry) {

    if( $(entry).is('.deleting') || $(entry).is('.editing') ) 
        return

    $(entry).toggleClass('selected')

    update_selected_menu();
}

/********************************************************
 * Method : edit_entry_key_event
 * Params : evt      - a key event
 *          entry_id - id the the entry 
 * Desc.  : called when a key is pressed in an entry
 *          edit form. Submits the form in that key
 *          is carriage return.
 ********************************************************/
function edit_entry_key_event(evt, entry_id){
    var charCode = (evt.which) ? evt.which : evt.keyCode
    if(charCode == "13"){ // carriage return
        edit_entry(entry_id);
        return false;
    }
    return true;
} 

/********************************************************
 * Method : create_entry_key_event
 * Params : evt      - a key event
 *          fund_id - id the the fund 
 * Desc.  : called when a key is pressed in an entry
 *          create form. Submits the form in that key
 *          is a carriage return.
 ********************************************************/
function create_entry_key_event(evt, fund_id){
    var charCode = (evt.which) ? evt.which : evt.keyCode
    if(charCode == "13"){ // carriage return
        create_entry(fund_id);
        return false; // hide this enter press
    }
    return true;
} 

/********************************************************
 * Method : create_entry
 * Params : fund_id - id the the fund 
 * Desc.  : Submit the create entry form for a fund.
 ********************************************************/
function create_entry(fund_id) {

    // Ignore re-submissions
    if ( $('#create_entry_'+fund_id+' input[name="date"]').attr('disabled') ) {
        return
    }

    if( ! validate_entry('#create_entry_'+fund_id) ) {
        return;
    }

    $('#create_entry_'+fund_id+' input').attr('disabled', true)
    getFundList(fund_id).setComment(WAIT_ICON_IMG)

    $.get( "/cgi-bin/mt.cgi", 
        {
            m:           'create_object',
            'class':       'MoneyTracker::Entry',
            fund_id:     $('#create_entry_'+fund_id+' input[name="fund_id"]'    ).val(),
            date:        $('#create_entry_'+fund_id+' input[name="date"]'       ).val(),
            entity:      $('#create_entry_'+fund_id+' input[name="entity"]'     ).val(),
            amount:      $('#create_entry_'+fund_id+' input[name="amount"]'     ).val(),
            description: $('#create_entry_'+fund_id+' input[name="description"]').val()
        }, 
        function(xml) {

            // Handle auth errors
            if(!check_for_errors(xml)){ 
                $('#create_entry_'+fund_id+' input').attr('disabled', false)
                return; 
            }

            insert_new_entry(xml);
            $('#create_entry_'+fund_id+' input')
                .attr('disabled', false)
                .not('[type=hidden]')
                .val('')
        }
    );
}

/********************************************************
 * Method : validate_entry
 * Params : form_id - the dom id of the entry form 
 * Desc.  : validate an edit/create entry form.
 * Returns: true if the form validated OK.
 ********************************************************/
function validate_entry(form_id) {
    
    if( $(form_id+' input[name="date"]').val() == '' ) {
        alert('Please specify a date.')
        return false;
    }
    return true;
}

/********************************************************
 * Method : insert_new_entry
 * Params : entry_or_xml - xml for an entry, 
 *          either raw or as a jquery object.
 * Desc.  : Insert a new entry row in a FundList
 ********************************************************/
function insert_new_entry(entry_or_xml) {

    // Get the entry object (build from xml if needed)
    entry = entry_or_xml.attr ?  entry_or_xml : $('MoneyTracker_Entry', entry_or_xml) ;    

    // Get the formatted entry date (yyy/mm/dd)
    entry_date = format_mysql_date(entry.attr("date"))

    // Build the html for this new entry
    entry_html = '<tr id="entry_'+ entry.attr("ID") +'" entry_id="'+ entry.attr("ID") +'"onClick="entry_clicked(this)">'
               + '<td>'+ entry_date
               + '</td><td>'+ entry.attr( "entity"      ) 
               + '</td><td>'+ entry.attr( "amount"      ) 
               + '</td><td>'+ entry.attr( "description" )
               + '</td></tr>';

    // Get the fund list we need to add it to
    fund_list = getFundList(entry.attr('fund_id'))

    // Itterate through the fund list entries, looking 
    // for the right place to put this entry.
    entries = fund_list.getBody().find('tr[entry_id]')
    inserted = false 

    for (i=0; i < entries.length; i++) { 

        this_entry = entries.eq(i) 
        this_date  = this_entry.find('td:first').text()

        if (! inserted && this_date > entry_date ) { 
            this_entry.before(entry_html)
            inserted = true   //remember that we inserted it        
        } 
    } 

    // If we didn't find a good entry to place this 
    // one before then it belongs at the end.
    if (! inserted) {
        fund_list.getBody().find('tr:last').before(entry_html)
    }

    // Update the fund balance
    fund_list.setBalance( fund_list.getBalance() + parseFloat(entry.attr("amount")) )
    
}

/********************************************************
 * Method : show_edit_forms
 * Desc.  : Convert selected entries to editable forms.
 ********************************************************/
function show_edit_forms() {

    $( "tr.selected" ).unbind('click').removeClass('selected').addClass('editing').each(function() {
        entry_id     = $(this).attr('entry_id');
        entry_date   = $('#entry_'+entry_id+' td:eq(0)').html();
        entry_entity = $('#entry_'+entry_id+' td:eq(1)').html();
        entry_amount = $('#entry_'+entry_id+' td:eq(2)').html();
        entry_desc   = $('#entry_'+entry_id+' td:eq(3)').html();
        $(this).html(
              '<td><input type="text" id="entry_'+ entry_id +'_date"        size="10" value="'+ entry_date   +'"></input></td>'
            + '<td><input type="text" id="entry_'+ entry_id +'_entity"      size="20" value="'+ entry_entity +'"></input></td>'
            + '<td><input type="text" id="entry_'+ entry_id +'_amount"      size="10" value="'+ entry_amount +'"></input></td>'
            + '<td><input type="text" id="entry_'+ entry_id +'_description" size="25" value="'+ entry_desc   +'"></input></td>'
        )
        $(this).find('input').attr('onKeyDown', 'javascript:return edit_entry_key_event(event,'+entry_id+')')

        // Add the date picker
        $('#entry_'+entry_id+'_date').datepicker({ 
            changeMonth: false,    // no dropdown for changing month, year
            changeYear: false,     // no dropdown for changing month, year
            showOn: 'focus',       // popup on focus (no icon)
            closeAtTop: false,     // close/clear links at bottom
            showOtherMonths: true, // show days from other months at beginning and end 
            dateFormat: 'yy/mm/dd'
        });
    })

    update_selected_menu();
}

/********************************************************
 * Method : edit_entry
 * Params : id - the entry_id
 * Desc.  : Initiate XHR to submit edit form for entry
 ********************************************************/
function edit_entry(id) {

    // Ignore edits once the form has been disabled
    if ( $('#entry_'+id).parents('form').find('input[id^="entry_'+id+'_date"]').attr('disabled') ) {
        return
    }

    $('#entry_'+id).parents('form').find('input[id^="entry_'+id+'_"]').attr('disabled',true)

    $.get( "/cgi-bin/mt.cgi", 
        {
            m:           'edit_object',
            'class':       'MoneyTracker::Entry',
            ID:          id,
            fund_id:     $('#entry_'+id).parents('form').find('input[name="fund_id"]').val(),
            date:        $('#entry_'+id+'_date'       ).val(),
            entity:      $('#entry_'+id+'_entity'     ).val(),
            amount:      $('#entry_'+id+'_amount'     ).val(),
            description: $('#entry_'+id+'_description').val()
        }, 
        function(xml) {

            // Handle auth errors
            if(!check_for_errors(xml)){ 
                $('#entry_'+id).parents('form').find('input[id^="entry_'+id+'_"]').attr('disabled',false)
                return; 
            }

            if( $('MoneyTracker_Entry', xml).length == 1 ) {
                entry_id     = $('MoneyTracker_Entry', xml).attr( 'ID'          );
                fund_id      = $('MoneyTracker_Entry', xml).attr( 'fund_id'     );
                entry_date   = $('MoneyTracker_Entry', xml).attr( 'date'        );
                entry_entity = $('MoneyTracker_Entry', xml).attr( 'entity'      );
                entry_amount = $('MoneyTracker_Entry', xml).attr( 'amount'      );
                entry_desc   = $('MoneyTracker_Entry', xml).attr( 'description');

                $('#entry_'+entry_id).html(
                      '<td>'+ format_mysql_date( entry_date   ) +'</td>'
                    + '<td>'+                    entry_entity   +'</td>'
                    + '<td>'+                    entry_amount   +'</td>'
                    + '<td>'+                    entry_desc     +'</td>'
                );

                getFundList(fund_id).updateBalance() 

                $('#entry_'+entry_id).removeClass('editing').removeClass('selected')
                update_selected_menu();
            }
            else {
                $('#entry_'+id).parents('form').find('input[id^="entry_'+id+'_"]').attr('disabled',false)
                throw_error( new error('I didn\'t understand the response from the server. This could be a bug.') )
            }
        }
    );
}

/********************************************************
 * Method : delete_entry
 * Desc.  : Initiate XHR to delete selected entries
 ********************************************************/
function delete_entries() {

    $( "tr.selected" )
        .unbind('click')
        .removeClass('selected')
        .addClass('deleting')
        .each(function() {

            $.get( "/cgi-bin/mt.cgi", 
                {
                    m     : 'delete_object'         ,
                    'class' : 'MoneyTracker::Entry' ,
                    ID    : $(this).attr("entry_id")
                }, 
                function(xml) {

                    // Handle auth errors
                    if(!check_for_errors(xml)){ 
                        $( "tr.selected" )
                            .removeClass('deleting')
                            .addClass('selected'); 
                        return; 
                    }

                    entry    = $('MoneyTracker_Entry',xml)
                    entry_id = entry.attr( "ID"      )
                    fund_id  = entry.attr( "fund_id" )
                    amount   = entry.attr( "amount"  )

                    // Update the fund balance
                    getFundList(fund_id).setBalance( 
                        fund_list.getBalance() - parseFloat(amount) 
                    )
        
                    // Remove the entry from the display
                    $('#entry_'+entry_id).remove();

                    update_selected_menu()
                }
            )
        })
}

/********************************************************
 * Method : deselect_entries
 * Desc.  : um... deselect the um... entries.
 ********************************************************/
function deselect_entries() {
    $(".selected").removeClass("selected")
    update_selected_menu();
}

/********************************************************
 * Method : update_selected_menu
 * Desc.  : Update the selected menu to reflect the 
 *          current selection. This should be called
 *          whenever the selection changes.
 ********************************************************/
function update_selected_menu() {

    menu = $( '#selected_menu' );

    selected = $( '.selected' ).length
    editing  = $( '.editing'  ).length
    deleting = $( '.deleting' ).length
    total    = selected + editing + deleting

    // Update count and sum
    sum   = 0;
    count = 0;
    $('.selected').each(function(){
        sum += parseFloat($(this).find('td:eq(2)').text()); 
        count++;
    });
    $( '#selected_sum'  ).text(fmtDollars(sum));
    $( '#selected_count').text(count);

    if(selected == 0)
        menu.hide()
    else
        menu.show()

}

