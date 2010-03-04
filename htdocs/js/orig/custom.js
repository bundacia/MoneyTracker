//------------------------------------//
// CONSTANTS                          //
//------------------------------------//
MT_ERR_NOT_LOGGED_IN = 1;
MT_ERR_LOGIN_FAILED  = 2;
MT_MONTH_ABBRV = new Array(undefined,'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec');
MT_MONTH_NAMES = new Array(undefined,'January','February','March','April','May','June','July','August','September','October','November','December');

WAIT_ICON_URL    = '/media/icons/wait/white_arrows.gif';
WAIT_ICON_IMG    = '<img class="wait_icon" border="none" src="'+WAIT_ICON_URL+'"></img>';
REFRESH_ICON_URL = '/media/icons/PNG/Blue/18/refresh.png';

function mt_state_info(args) { this.looks_logged_in = false }
var mt = new mt_state_info;

//------------------------------------//
// ON DOCUMENT READY                  //
//------------------------------------//
$(document).ready(function() {

    // Guess weather we're logged in based on the cookie
    mt.looks_logged_in = document.cookie.indexOf('mts=') >= 0;

    // Add onSubmit handler to login form
    $('#login_form form').submit(submit_login_form)

    // ---------------------------------------------------
    // Get Year and Month
    args = getArgs();
    d = new Date();
    if ( args.y )
        mt.year = parseInt( args.y )
    else
        mt.year  = d.getFullYear()
    if ( args.m )
        mt.month = parseInt( args.m )
    else 
        mt.month = d.getMonth() + 1

    // Get day of month
    mt.day = d.getDate()
    // ---------------------------------------------------

    // Initiate the xhr to load the funds page
    change_page(0,1)

    // ---------------------------------------------------
    // Setup the Selected Menu so it scrolls with the page
    top_of_main_menu    = parseInt($('#main_menu').css("top").substring(0, $('#main_menu').css("top").indexOf("px")))
    bottom_of_main_menu = top_of_main_menu + 130 // add the hight of the main_menu. $('#main_menu').height() didn't work =(
    fix_selected_menu_height = function () {
        $('.selected_menu').each(function() {
            elHeight = $(this).height();
            elTop    = sTop() + (wHeight() / 2) - (elHeight);
            elTop    = Math.max(bottom_of_main_menu, elTop);
            //offset = bottom_of_main_menu + main_menu_padding + $(document).scrollTop();
            $(this).css({top: elTop+"px", marginTop: '0'});
        })
    }
    fix_selected_menu_height()
    $(window).scroll(fix_selected_menu_height);
    // ---------------------------------------------------

    // ---------------------------------------------------
    // Setup the Change month links
    $('#change_month_option a:eq(0)').attr('href','javascript:void(0)').click(function(){
        if(mt.month != 1) {
            mt.month = mt.month - 1
        }
        else {
            mt.month = 12
            mt.year  = mt.year-1
        }
        $( '#funds' ).html('')
        get_funds()
    })
    $('#change_month_option a:eq(1)').attr('href','javascript:void(0)').click(function(){
        if(mt.month != 12) {
            mt.month = mt.month + 1
        }
        else {
            mt.month = 1
            mt.year  = mt.year+1
        }
        $( '#funds' ).html('')
        get_funds()
    })
    // ---------------------------------------------------
});

//------------------------------------//
// FUNCTIONS                          //
//------------------------------------//

function change_page(new_page, reload) {

   $('.selected_menu').hide()

   switch (new_page) {
       case 0:
          if(reload || ! $( '#funds' ).hasClass("loaded")) {
              $( '#funds' ).html('')
              get_funds()
          }
          $( '.logged_out'        ).hide()
          $( '.import_page'       ).hide()
          $( '.fund_manager_page' ).hide()
          $( '.funds_page'        ).show()
       break;
       case 1:
          if(reload || ! $( '#fund_manager' ).hasClass("loaded")) {
              $( '#fund_manager' ).html('')
              get_budget()
          }
          $( '.logged_out'        ).hide()
          $( '.funds_page'        ).hide()
          $( '.import_page'       ).hide()
          $( '.fund_manager_page' ).show()
       break
       case 2:
          if(reload || ! $( '#import_entries' ).hasClass("loaded")) {
              $( '#import_entries' ).html('')
              get_imported_entries()
          }
          $( '.logged_out'        ).hide()
          $( '.funds_page'        ).hide()
          $( '.fund_manager_page' ).hide()
          $( '.import_page'       ).show()
       break
       default:
           throw_error(new error("Looks like you hit a bug. Unknown page number: "+new_page))
   }
}

function submit_login_form() {

    $('#login_wait_icon').show();
    $('#login_form input[type=submit]').hide();
    $('#login_form input').attr('disabled', true);

    $.get( "/cgi-bin/mt.cgi", 
        {
            m:         'login',
            user_name: $('#login_form input:eq(0)').val(),
            password:  $('#login_form input:eq(1)').val()
        }, 
        function(xml) {

            $('#login_wait_icon').hide();
            $('#login_form input[type=submit]').show();
            $('#login_form input').attr('disabled', false);

            // Handle auth errors
            if(!check_for_errors(xml)){ return; }

            mt.looks_logged_in = true
            $('.logged_out').hide()
            change_page(0,1);
        }
    );
    return false;
}


//-------------------------------------------//
// Main Menu Options                         //
//-------------------------------------------//

function logout() {
    $.post("/cgi-bin/mt.cgi", {m: 'logout'}, function(xml) {

        // Handle errors
        if(!check_for_errors(xml)){ return; }

        mt.looks_logged_in = false
        $( '.logged_in'  ).hide();
        $( '.selected'   ).removeClass('.selected');
        $( '.logged_out' ).show();
    })
}

//-------------------------------------------//
// END _ Main Menu Options                   //
//-------------------------------------------//

function check_for_errors(xml) {

    if( $('MoneyTracker_Error', xml).length == 0 ) {
        // Make sure that .logged_in stuff is 
        // visible if we got no errors
        $( '.display_on_login' ).show();

        return true;
    }

    // Failed login
    if( $('MoneyTracker_Error code', xml).text() == MT_ERR_NOT_LOGGED_IN && mt.looks_logged_in ) {
        mt.looks_logged_in = false
        alert('Sorry, your session has expired. Please log in again.')
        $( '.logged_in'     ).hide();
        $( '.selected'      ).removeClass('.selected');
        $( '.logged_out'    ).show();
    }
    else if( $('MoneyTracker_Error code', xml).text() == MT_ERR_NOT_LOGGED_IN && ! mt.looks_logged_in ) {
        $( '.logged_in'     ).hide();
        $( '.selected'      ).removeClass('.selected');
        $( '.logged_out'    ).show();
    }
    // Default
    else {
        throw_error( new server_error(xml) )
    }

    return false;
}

//-----------------------------------------//
// Utility Functions                       //
//-----------------------------------------//

function format_js_date (jsdate) {
    var year  = jsdate.getFullYear()
    var month = jsdate.getMonth() + 1 // add one to month since jan is 0 in js
    var day   = jsdate.getDate();

    // Pad fields with zeros
    if (month < 10 ){ month = '0'+month }
    if (day   < 10 ){ day   = '0'+day   }

    return year+'/'+month+'/'+day;
}

function format_mysql_date(mysqldate) {

    var year  = mysqldate.slice( 0 ,4  )
    var month = mysqldate.slice( 5 ,7  )
    var day   = mysqldate.slice( 8 ,10 )

    return year+'/'+month+'/'+day;
}

function throw_error(error) {
    alert(error.msg);
}

function error(msg,err,code) {
    this.msg   = msg;
    this.error = err;
    this.code  = code;
}

function server_error(xml) {
    this.msg   = $('MoneyTracker_Error msg'   ,xml).text()
    this.error = $('MoneyTracker_Error error' ,xml).text()
    this.code  = $('MoneyTracker_Error code'  ,xml).text()
}

function fmtDollars(num) {
    var result = roundNumber(num, 2) + ''
    decimal_part = result.substr(result.indexOf('.'))
    if (decimal_part.length == 2)
        return result + '0'
    if (decimal_part.length < 2)
        return result + '.00'

    return result
}

function roundNumber(num, dec) {
    var result = Math.round(num*Math.pow(10,dec))/Math.pow(10,dec);
    return result;
}

function sTop() {
    return window.pageYOffset
    || document.documentElement && document.documentElement.scrollTop
    || document.body.scrollTop;
}

function wHeight() {
    return window.innerHeight
    || document.documentElement && document.documentElement.clientHeight
    || document.body.clientHeight;
}

function getArgs() {
    var args = new Object();
    var query = location.search.substring(1);
    var pairs = query.split("&");
    for(var i = 0; i < pairs.length; i++) {
        var pos = pairs[i].indexOf('=');
        if (pos == -1) continue;
        var argname = pairs[i].substring(0,pos);
        var value   = pairs[i].substring(pos+1);
        args[argname] = unescape(value);
    }
    return args;
}

function grayOut(vis, options) {
    // Pass true to gray out screen, false to ungray
    // options are optional.  This is a JSON object with the following (optional) properties
    // opacity:0-100         // Lower number = less grayout higher = more of a blackout 
    // zindex: #             // HTML elements with a higher zindex appear on top of the gray out
    // bgcolor: (#xxxxxx)    // Standard RGB Hex color code
    // grayOut(true, {'zindex':'50', 'bgcolor':'#0000FF', 'opacity':'70'});
    // Because options is JSON opacity/zindex/bgcolor are all optional and can appear
    // in any order.  Pass only the properties you need to set.
    var options = options         || {}; 
    var zindex  = options.zindex  || 50;
    var opacity = options.opacity || 70;
    var opaque  = (opacity / 100);
    var bgcolor = options.bgcolor || '#000000';
    var dark=document.getElementById('darkenScreenObject');
    if (!dark) {
        // The dark layer doesn't exist, it's never been created.  So we'll
        // create it here and apply some basic styles.
        // If you are getting errors in IE see: http://support.microsoft.com/default.aspx/kb/927917
        var tbody = document.getElementsByTagName("body")[0];
        var tnode = document.createElement('div');           // Create the layer.
            tnode.style.position='absolute';                 // Position absolutely
            tnode.style.top='0px';                           // In the top
            tnode.style.left='0px';                          // Left corner of the page
            tnode.style.overflow='hidden';                   // Try to avoid making scroll bars            
            tnode.style.display='none';                      // Start out Hidden
            tnode.id='darkenScreenObject';                   // Name it so we can find it later
        tbody.appendChild(tnode);                            // Add it to the web page
        dark=document.getElementById('darkenScreenObject');  // Get the object.
    }
    if (vis) {
        // Calculate the page width and height 
        if( document.body && ( document.body.scrollWidth || document.body.scrollHeight ) ) {
            var pageWidth  = document.body.scrollWidth+'px';
            var pageHeight = document.body.scrollHeight+'px';
        } else if( document.body.offsetWidth ) {
            var pageWidth  = document.body.offsetWidth+'px';
            var pageHeight = document.body.offsetHeight+'px';
        } else {
            var pageWidth='100%';
            var pageHeight='100%';
        }   
        //set the shader to cover the entire page and make it visible.
        dark.style.opacity         = opaque                       ;                      
        dark.style.MozOpacity      = opaque                       ;                   
        dark.style.filter          = 'alpha(opacity='+opacity+')' ; 
        dark.style.zIndex          = zindex                       ;        
        dark.style.backgroundColor = bgcolor                      ;  
        dark.style.width           = pageWidth                    ;
        dark.style.height          = pageHeight                   ;
        dark.style.display         ='block'                       ;                          
    } else {
        dark.style.display='none';
    }
}
