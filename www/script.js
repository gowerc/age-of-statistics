const CIVS = [
    'Aztecs', 'Berbers', 'Bohemians', 'Britons', 'Bulgarians', 'Burgundians', 'Burmese',
    'Byzantines', 'Celts', 'Chinese', 'Cumans', 'Ethiopians', 'Franks', 'Goths', 'Huns', 'Incas',
    'Indians', 'Italians', 'Japanese', 'Khmer', 'Koreans', 'Lithuanians', 'Magyars', 'Malay',
    'Malians', 'Mayans', 'Mongols', 'Persians', 'Poles', 'Portuguese', 'Saracens', 'Sicilians',
    'Slavs', 'Spanish', 'Tatars', 'Teutons', 'Turks', 'Vietnamese', 'Vikings'
]


update_element = function(event, ui){
    var label = ui.item.label;
    var targetid = event.target.id;
    $("." + targetid).each((i, e) => {
        var e2 = $(e);
        var new_url = e2.data("url").formatUnicorn(label);
        e2.attr("src",new_url);
    })
}

init_autocomplete = function (id) {
    $("#" + id).autocomplete({
        source: CIVS,
        autoFocus: false,
        minLength: 0,
        select: update_element
    });
      
    $("#" + id ).click(function() {
        $( "#" + id ).autocomplete( "search", "" );
    });
}





// Generate table of contents
$(document).ready(function () {
    var toc = "";
    var level = 1;

    document.getElementById("contents").innerHTML =
        document.getElementById("contents").innerHTML.replace(
            /<h([\d])>([^<]+)<\/h([\d])>/gi,
            function (str, openLevel, titleText, closeLevel) {
                if (openLevel != closeLevel) {
                    return str;
                }

                if (openLevel > level) {
                    toc += (new Array(openLevel - level + 1)).join("<ul>");
                } else if (openLevel < level) {
                    toc += (new Array(level - openLevel + 1)).join("</ul>");
                }

                level = parseInt(openLevel);

                var anchor = titleText.replace(/ /g, "_");
                toc += "<li><a href=\"#" + anchor + "\">" + titleText
                    + "</a></li>";

                return "<h" + openLevel + "><a name=\"" + anchor + "\">"
                    + titleText + "</a></h" + closeLevel + ">";
            }
        );

    if (level) {
        toc += (new Array(level + 1)).join("</ul>");
    }

    document.getElementById("toc").innerHTML += toc;
    
    init_autocomplete("civselect");
});


String.prototype.formatUnicorn = String.prototype.formatUnicorn ||
function () {
    "use strict";
    var str = this.toString();
    if (arguments.length) {
        var t = typeof arguments[0];
        var key;
        var args = ("string" === t || "number" === t) ?
            Array.prototype.slice.call(arguments)
            : arguments[0];

        for (key in args) {
            str = str.replace(new RegExp("\\{" + key + "\\}", "gi"), args[key]);
        }
    }

    return str;
};