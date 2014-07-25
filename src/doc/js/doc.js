if (typeof window._mu === 'undefined') {
    window._mu = {};
}

_mu.doc = {
    init: function(page) {
        var $script = $('#code'),
            $code = $('code'),
            $doc = $(document),
            $pdoc = $(window.parent.document),

            escapeHTML = function(str) {
                return str.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
            };

        $code.html(escapeHTML($script.html()));

        setTimeout(function() {
            $pdoc.find('#ifm-' + page + '-demo').height($doc.height());
        }, 0);
    }
};