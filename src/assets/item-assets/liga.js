/* A polyfill for browsers that don't support ligatures. */
/* The script tag referring to this file must be placed before the ending body tag. */

/* To provide support for elements dynamically added, this script adds
   method 'icomoonLiga' to the window object. You can pass element references to this method.
*/
(function () {
    'use strict';
    function supportsProperty(p) {
        var prefixes = ['Webkit', 'Moz', 'O', 'ms'],
            i,
            div = document.createElement('div'),
            ret = p in div.style;
        if (!ret) {
            p = p.charAt(0).toUpperCase() + p.substr(1);
            for (i = 0; i < prefixes.length; i += 1) {
                ret = prefixes[i] + p in div.style;
                if (ret) {
                    break;
                }
            }
        }
        return ret;
    }
    var icons;
    if (!supportsProperty('fontFeatureSettings')) {
        icons = {
            'pencil': '&#xe905;',
            'write': '&#xe905;',
            'eyedropper': '&#xe90a;',
            'color': '&#xe90a;',
            'image': '&#xe90d;',
            'picture': '&#xe90d;',
            'camera': '&#xe90f;',
            'photo': '&#xe90f;',
            'headphones': '&#xe910;',
            'headset': '&#xe910;',
            'book': '&#xe91f;',
            'read': '&#xe91f;',
            'folder-open': '&#xe930;',
            'directory2': '&#xe930;',
            'phone': '&#xe942;',
            'telephone': '&#xe942;',
            'map': '&#xe94b;',
            'guide': '&#xe94b;',
            'binoculars': '&#xe985;',
            'lookup': '&#xe985;',
            'enlarge': '&#xe989;',
            'expand': '&#xe989;',
            'key': '&#xe98d;',
            'password': '&#xe98d;',
            'wrench': '&#xe991;',
            'tool': '&#xe991;',
            'hammer': '&#xe996;',
            'tool2': '&#xe996;',
            'aid-kit': '&#xe998;',
            'health': '&#xe998;',
            'trophy': '&#xe99e;',
            'cup': '&#xe99e;',
            'gift': '&#xe99f;',
            'present': '&#xe99f;',
            'leaf': '&#xe9a4;',
            'nature': '&#xe9a4;',
            'lab': '&#xe9aa;',
            'beta': '&#xe9aa;',
            'flag': '&#xe9cc;',
            'report': '&#xe9cc;',
            'star-full': '&#xe9d9;',
            'rate3': '&#xe9d9;',
            'heart': '&#xe9da;',
            'like': '&#xe9da;',
            'smile2': '&#xe9e2;',
            'emoticon4': '&#xe9e2;',
            'sad2': '&#xe9e6;',
            'emoticon8': '&#xe9e6;',
            'cross': '&#xea0f;',
            'cancel': '&#xea0f;',
          '0': 0
        };
        delete icons['0'];
        window.icomoonLiga = function (els) {
            var classes,
                el,
                i,
                innerHTML,
                key;
            els = els || document.getElementsByTagName('*');
            if (!els.length) {
                els = [els];
            }
            for (i = 0; ; i += 1) {
                el = els[i];
                if (!el) {
                    break;
                }
                classes = el.className;
                if (/icon-/.test(classes)) {
                    innerHTML = el.innerHTML;
                    if (innerHTML && innerHTML.length > 1) {
                        for (key in icons) {
                            if (icons.hasOwnProperty(key)) {
                                innerHTML = innerHTML.replace(new RegExp(key, 'g'), icons[key]);
                            }
                        }
                        el.innerHTML = innerHTML;
                    }
                }
            }
        };
        window.icomoonLiga();
    }
}());
