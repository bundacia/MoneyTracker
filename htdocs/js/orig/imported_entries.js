function get_imported_entries() {
    // Show wait bar
    $('#main_content_wait_icon').show()

    // send request
    $.post("/cgi-bin/mt.cgi", {m: 'get_imported_entries'}, function(xml) {

        // Handle auth errors
        if(!check_for_errors(xml)) { 
            $('#main_content_wait_icon').hide()
            return
        }

        imported_entries_count = $("MoneyTracker_ImportedEntry", xml).length

        $("#import_entries").html('\n');

        imported_entries_list = new List(
            'imported_entries', 
            'Imported Entries'
        )

        $("#import_entries").append(imported_entries_list.getHTML())

        // format and output result
        imported_entries_html = '\n<form id="import_entries" onsubmit="javascript: return false">\n'
                + '<table>\n'
                + '<thead><tr><th scope="col">Date</th><th>Payee</th><th>Amount</th><th>Description</th><th>Fund</th>'
                + '<th><a href="javascript:void(0)" onclick="toggle_checkboxes(\'import\')">Import</a></th>'
                + '<th><a href="javascript:void(0)" onclick="toggle_checkboxes(\'save\')  ">Save  </a></th>'
                ;

        $("MoneyTracker_ImportedEntry", xml).each(function() {
            imported_entries_html += 
                 '<tr id="imported_entry_'+$(this).attr("ID")
                +     '" imported_entry_id="'+$(this).attr("ID")+'">'
                +'<td><input type="text" name="date" size="10" '
                +     'value="'+format_mysql_date($(this).attr("date")) + '">'
                +'</input></td>'
                +'<td><input type="text" name="entity" size="20" '
                +     'value="'+$(this).attr( "entity"      ) + '">'
                +'</input></td>'
                +'<td><input type="text" name="amount" size="8" '
                +     'value="'+$(this).attr( "amount"      ) + '">'
                +'</input></td>'
                +'<td><input type="text" name="description" size="10" '
                +     'value="'+$(this).attr( "description" ) + '">'
                +'</input></td>'
                +'<td><select name="fund_id" width="95" style="width: 95px"><option>loading...</option></select></td>'
                +'<td><input type="checkbox" name="import" value="0"></input></td>'
                +'<td><input type="checkbox" name="save"   value="0"></input></td>'
                +'</tr>';
        });

        imported_entries_html += '<tr><td colspan="7" style="{text-align: right}">'
                              +  '<input type="submit" onclick="submit_imported_entries()" value="Submit"/>'
                              +  '</td></tr>' 
                              +  '\n</table>\n</form>';

        imported_entries_list.setBody( imported_entries_html );

        // Hide the submit button if there are no entries
        if ( $("MoneyTracker_ImportedEntry", xml).length == 0 )
            $('#import_entries input[type=submit]').hide()

        // Set the Comment
        imported_entries_list.setComment(imported_entries_count);

        $('#import_entries input[name=date]').datepicker({
            changeMonth: false,    // no dropdown for changing month, year
            changeYear: false,     // no dropdown for changing month, year
            showOn: 'focus',       // popup on focus (no icon)
            closeAtTop: false,     // close/clear links at bottom
            showOtherMonths: true, // show days from other months at beginning and end
            dateFormat: 'yy/mm/dd'
        });


        // Reveal the imported entries budget
        imported_entries_list.open() 

        $("#import_entries").addClass("loaded")

        if ( ! $('#fund_manager').hasClass('loaded') ) {
            get_budget(function() {
                fund_options_html = $('#fund_manager').find('tr[fund_id]').map(function() { 
                                        return '<option value ="'+$(this).attr('fund_id')+'">'+$(this).find('td:first').text()+'</option>' 
                                    } ).get().join('\n')

                $('#import_entries select').html(fund_options_html)
            } )
        }

        $('#main_content_wait_icon').hide()

    });// end ajax callback()
}

function toggle_checkboxes(name) {
    checkit = $('input[name='+name+'][checked=1]').length < $('input[name='+name+']').length; 
    $('input[name='+name+']').each(function() { $(this).attr('checked', checkit) })
}

function submit_imported_entries() {

    // Disable the form inputs that are not going to be saved
    $('#import_entries tr[imported_entry_id]:has(input[name=save][checked=0], input[name=import][checked=1])').find('input, select').attr('disabled', true)

    rows2import = $('#import_entries tr[imported_entry_id]:has(input[name=import][checked=1])')
    rows2save   = $('#import_entries tr[imported_entry_id]:has(input[name=save][checked=1])')
    rows2ignore = $('#import_entries tr[imported_entry_id]:has(input[name=save][checked=0]):has(input[name=import][checked=0])')

    rows2import.each(import_row)
    rows2ignore.each(ignore_row)
}
function import_row() {

    entry_to_import=$(this).attr('imported_entry_id');

    $.get( "/cgi-bin/mt.cgi", 
        {
            m:           'import_entry',

            fund_id:     $(this).find('[@selected]').val(),
            date:        $(this).find('input[name=date]'       ).val(),
            entity:      $(this).find('input[name=entity]'     ).val(),
            amount:      $(this).find('input[name=amount]'     ).val(),
            description: $(this).find('input[name=description]').val(),

            imported_entry_id: $(this).attr('imported_entry_id')
        }, 
        function(xml) {
            // Handle auth errors
            if(!check_for_errors(xml)){ 
                return
            }

            $('tr[imported_entry_id='+$('MoneyTracker_ImportedEntry',xml).attr('ID')+']:has(input[name=save][checked=0])').remove()
            $('tr[imported_entry_id='+$('MoneyTracker_ImportedEntry',xml).attr('ID')+']:has(input[name=save][checked=1])').find('select,input').attr('disabled',false).find('input[name=import]').attr('checked',0);
        }
    )
}
function ignore_row() {

    $.get( "/cgi-bin/mt.cgi", 
        {
            m:      'edit_object',
            'class':  'MoneyTracker::ImportedEntry',
            ID:     $(this).attr('imported_entry_id'),
            status: 'ignored'
        }, 
        function(xml) {
            // Handle auth errors
            if(!check_for_errors(xml)){ 
                return
            }
            $('tr[imported_entry_id='+$('MoneyTracker_ImportedEntry',xml).attr('ID')+']').remove()
        }
    )
}
