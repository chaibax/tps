(function() {
  var showNotFound = function() {
    $('.dossier-link .text-info').hide();
    $('.dossier-link .text-warning').show();
  };

  var showData = function(data) {
    $('.dossier-link .procedureLibelle').text(data.procedureLibelle);
    $('.dossier-link .text-info').show();
    $('.dossier-link .text-warning').hide();
  };

  var hideEverything = function() {
    $('.dossier-link .text-info').hide();
    $('.dossier-link .text-warning').hide();
  };

  var fetchProcedureLibelle = function(e) {
    var dossierId = $(e.target).val();
    if(dossierId) {
      $.get('/users/dossiers/' + dossierId + '/procedure_libelle')
        .done(showData)
        .fail(showNotFound);
    } else {
      hideEverything();
    }
  };

  var timeOut = null;
  var debounceFetchProcedureLibelle = function(e) {
    if(timeOut){ clearTimeout(timeOut); }
    timeOut = setTimeout(function() { fetchProcedureLibelle(e); }, 300);
  };

  $(document).on('input', '[data-type=dossier-link]', debounceFetchProcedureLibelle);
})();
