function setup_media_change(ele) {
  if ($(ele).val() == 'spacewalk') {
    $('[id$="medium_path"]').prop('disabled', true)
    $('#spacewalk_hostname').prop('disabled', false)
  } else {
    $('#spacewalk_hostname').prop('disabled', true)
    $('[id$="medium_path"]').prop('disabled', false)
  }
}

function setup_media_create_change(ele) {
  $('[id$="medium_id"]').val('')
}
