import $ from 'jquery';

$('body').on('click', () => {
  $('.button.dropdown').removeClass('open');
});

$(document).on('click', '.dropdown-button', event => {
  event.stopPropagation();
  const parent = $(event.target).parent();
  if (parent.hasClass('dropdown')) {
    parent.toggleClass('open');
  }
});
