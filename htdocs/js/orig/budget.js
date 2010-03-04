function get_budget(callback) {
    // Show wait bar
    $('#main_content_wait_icon').show()

    // send request
    $.post("/cgi-bin/mt.cgi", {m: 'load_budget'}, function(xml) {

        // Handle auth errors
        if(!check_for_errors(xml)){ 
            $('#main_content_wait_icon').hide()
            if (callback)
                callback(false); 
            return; 
        }

        // format and output result
        if( $("MoneyTracker_Budget", xml).length > 0 ) {

            id = $("MoneyTracker_Budget", xml).attr("ID");

            budget = new List(
                'b'+id, 
                $("MoneyTracker_Budget", xml).attr("name")
            )

            $("#fund_manager").html('\n').append(budget.getHTML())

            // format and output result
            funds = '\n<form id="create_fund_'+id+'">\n'
                    + '<input type="hidden" name="budget_id" value="'+id+'"></input>'
                    + '<table>\n'
                    + '<thead><tr><th scope="col">Name</th><th>Allowance</th><th>Rollover</th></thead>'
                    ;

            fund_value_total = 0;
            $("MoneyTracker_Fund", xml).each(function() {
                funds += '<tr id="fund_details_'+$(this).attr("ID")+'" fund_id="'+$(this).attr("ID")+'"onClick="fund_clicked(this)">'
                        +'</td><td>'+ $(this).attr( "name"     ) 
                        +'</td><td>'+ $(this).attr( "value"    ) 
                        +'</td><td>'+ ( $(this).attr( "rollover" ) == 1 ? 'X' : '' )
                        +'</td></tr>';
                fund_value_total += parseFloat( $(this).attr("value") );
            });

            funds +='<tr>'
                    + '<td><input type="text"     name="name"     onKeyDown="javascript:return create_fund_key_event(event,'+id+')"></input></td>'
                    + '<td><input type="text"     name="value"    onKeyDown="javascript:return create_fund_key_event(event,'+id+')"></input></td>'
                    + '<td><input type="checkbox" name="rollover" onKeyDown="javascript:return create_fund_key_event(event,'+id+')"></input></td>'
                    + '</tr>'
                    + '\n</table>'
                    + '\n</form>';
            budget.setBody( funds );

            // Set the balance, with helpfull colors
            budget.setComment(fund_value_total);

            // Reveal this budget
            budget.open() 

            if (callback)
                callback(true)

            $("#fund_manager").addClass("loaded");

        }

        $('#main_content_wait_icon').hide()

    });// end ajax callback()
}

function fund_clicked(fund) {

    if( $(fund).is('.deleting') || $(fund).is('.editing') ) 
        return

    $(fund).toggleClass('selected')

    update_selected_funds_menu();
}

function edit_fund_key_event(evt, fund_id){
    var charCode = (evt.which) ? evt.which : evt.keyCode
    if(charCode == "13"){ // carriage return
        edit_fund(fund_id);
        return false;
    }
    return true;
} 

function create_fund_key_event(evt, budget_id){
    var charCode = (evt.which) ? evt.which : evt.keyCode
    if(charCode == "13"){ // carriage return
        create_fund(budget_id);
        return false;
    }
    return true;
} 

function create_fund(budget_id) {

    // Ignore re-submissions
    if ( $('#create_fund_'+budget_id+' input[name="name"]').attr('disabled') ) {
        return
    }

    $('#create_fund_'+budget_id+' input').attr('disabled', true)
    _LISTS['b'+budget_id].setComment('<img class="wait_icon" border="none" src="'+WAIT_ICON_URL+'"></img>')

    $.get( "/cgi-bin/mt.cgi", 
        {
            m:        'create_object',
            'class':    'MoneyTracker::Fund',
            name:     $('#create_fund_'+budget_id+' input[name="name"]'     ).val(),
            value:    $('#create_fund_'+budget_id+' input[name="value"]'    ).val(),
            rollover: $('#create_fund_'+budget_id+' input[name="rollover"]' ).attr('checked')
        }, 
        function(xml) {

            // Handle auth errors
            if(!check_for_errors(xml)){ 
                $('#create_fund_'+budget_id+' input').attr('disabled', false)
                return; 
            }

            // TODO just insert the new fund, we don't 
            // have to reload the whole budget. Also, we need to 
            // add the fund to the entries page
            get_budget();
        }
    );
}

function show_fund_edit_forms() {

    $( "tr.selected" ).unbind('click').removeClass('selected').addClass('editing').each(function() {
        fund_id       = $(this).attr('fund_id');
        fund_name     = $('#fund_details_'+fund_id+' td:eq(0)').html()
        fund_value    = $('#fund_details_'+fund_id+' td:eq(1)').html()
        fund_rollover = $('#fund_details_'+fund_id+' td:eq(2)').attr('checked') ? 'true' : 'false'
        $(this).html(
              '<td><input type="text"     id="fund_details_'+ fund_id +'_name"     value="'+ fund_name     +'"></input></td>'
            + '<td><input type="text"     id="fund_details_'+ fund_id +'_value"    value="'+ fund_value    +'"></input></td>'
            + '<td><input type="checkbox" id="fund_details_'+ fund_id +'_rollover" checked="'+ fund_rollover +'"></input></td>'
        )
        $(this).find('input').attr('onKeyDown', 'javascript:return edit_fund_key_event(event,'+fund_id+')')

    })

    update_selected_funds_menu();
}

function edit_fund(id) {

    // Ignore re-submissions
    if ( $('#fund_details_'+id).parents('form').find('input[id^="fund_details_'+id+'_name"]').attr('disabled') ) {
        return
    }

    $('#fund_details_'+id).parents('form').find('input[id^="fund_details_'+id+'_"]').attr('disabled',true)

    $.get( "/cgi-bin/mt.cgi", 
        {
            m:         'edit_object',
            'class':     'MoneyTracker::Fund',
            ID:        id,
            budget_id: $('#fund_details_'+id).parents('form').find('input[name="budget_id"]').val(),
            name:      $('#fund_details_'+id+'_name'     ).val(),
            value:     $('#fund_details_'+id+'_value'    ).val(),
            rollover:  $('#fund_details_'+id+'_rollover' ).attr('checked') ? '1' : '0'
        }, 
        function(xml) {

            // Handle auth errors
            if(!check_for_errors(xml)){ 
                $('#entry_'+id).parents('form').find('input[id^="fund_details_'+id+'_"]').attr('disabled',false)
                return
            }

            if( $('MoneyTracker_Fund', xml).length == 1 ) {
                fund_id       = $('MoneyTracker_Fund', xml).attr( 'ID'       );
                fund_name     = $('MoneyTracker_Fund', xml).attr( 'name'     );
                fund_value    = $('MoneyTracker_Fund', xml).attr( 'value'    );
                fund_rollover = $('MoneyTracker_Fund', xml).attr( 'rollover' );

                $('#fund_details_'+fund_id).html(
                      '<td>'+  fund_name                      +'</td>'
                    + '<td>'+  fund_value                     +'</td>'
                    + '<td>'+ (fund_rollover == 1 ? 'X' : '' )+'</td>'
                );

                $('#fund_details_'+fund_id).removeClass('editing').removeClass('selected')

                update_selected_funds_menu();
            }
            else {
                $('#entry_'+id).parents('form').find('input[id^="fund_details_'+id+'_"]').attr('disabled',false)
                throw_error( new error('I didn\'t understand the response from the server. This could be a bug.') )
            }
        }
    );
}

function delete_funds() {

    $( "#fund_manager").find("tr.selected").unbind('click').removeClass('selected').addClass('deleting').each(function() {

        $.get( "/cgi-bin/mt.cgi", 
            {
                m      : 'delete_object'        ,
                'class': 'MoneyTracker::Fund'   ,
                ID     : $(this).attr("fund_id")
            }, 
            function(xml) {

                // Handle auth errors
                if(!check_for_errors(xml)){ 
                    $( "#fund_manager").find("tr.selected").removeClass('deleting').addClass('selected'); 
                    return; 
                }

                fund_id_deleted = $('MoneyTracker_Fund',xml).attr("ID");
                $('#fund_details_'+fund_id_deleted).remove();

                update_selected_funds_menu()
            }
        )
    });
}

function deselect_funds() {
    $("#fund_manager").find(".selected").removeClass("selected")
    update_selected_funds_menu();
}

function update_selected_funds_menu() {
    menu = $( '#selected_funds_menu' );

    selected = $( '#fund_manager' ).find( '.selected' ).length
    editing  = $( '#fund_manager' ).find( '.editing'  ).length
    deleting = $( '#fund_manager' ).find( '.deleting' ).length
    total    = selected + editing + deleting

    // Update count and sum
    sum   = 0;
    count = 0;
    $('#fund_manager' ).find( '.selected').each(function(){sum += parseFloat($(this).find('td:eq(1)').text()); count++;});
    $( '#selected_funds_sum'  ).text(roundNumber(sum,2));
    $( '#selected_funds_count').text(count);

    if(selected == 0)
        menu.hide()
    else
        menu.show()

}

