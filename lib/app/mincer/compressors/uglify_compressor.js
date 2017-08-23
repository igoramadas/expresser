/**
 *  class UglifyCompressor
 *
 *  Engine for CSS minification. You will need `uglify-js` Node module installed:
 *
 *      npm install uglify-js
 *
 *
 *  ##### SUBCLASS OF
 *
 *  [[Template]]
 **/

'use strict';

// 3rd-party
var _ = require('lodash');
var path = require('path');
var UglifyES; // initialized later

// internal
var Template = require('../template');
var prop = require('../common').prop;

////////////////////////////////////////////////////////////////////////////////

// Class constructor
var UglifyCompressor = module.exports = function UglifyCompressor() {
    Template.apply(this, arguments);
    UglifyES = UglifyES || Template.libs['uglify-es'] || require('uglify-es');
};

require('util').inherits(UglifyCompressor, Template);

// Internal (private) options storage
var options = {};

/**
 *  UglifyCompressor.configure(opts) -> Void
 *  - opts (Object):
 *
 *  Allows to set UglifyES options.
 *  See UglifyES minify options for details.
 *
 *  Default: `{}`.
 *
 *
 *  ##### Example
 *
 *      UglifyCompressor.configure({mangle: false});
 **/
UglifyCompressor.configure = function(opts) {
    options = _.clone(opts);
};

// Compress data
UglifyCompressor.prototype.evaluate = function(context /*, locals*/ ) {
    var opts = options,
        result, origSourceMap, sourceMap;

    // SOURCE MAPS FOR JS TEMPORARILY REMOVED TILL WE UPDATE THE CODE TO WORK WITH UGLIFY-ES!
    // TODO! Re-enable source maps support working with Uglify ES.
    if (true || !context.environment.isEnabled('source_maps')) {
        var miniObj = UglifyES.minify(this.data, opts);
        if (miniObj.error) {
            throw miniObj.error;
        } else {
            this.data = miniObj.code;
        }
        return;
    }

    // Built-in 'UglifyES.minify' miss sources from input sourcemap
    // (it expect src only from minified files)
    // We create custom source_map object, and push src files manually
    origSourceMap = context.createSourceMapObject(this);

    /*eslint-disable new-cap*/
    sourceMap = UglifyES.SourceMap({
        file: path.basename(context.pathname),
        orig: origSourceMap
    });

    origSourceMap.sources.forEach(function(src, idx) {
        sourceMap.get().setSourceContent(src, origSourceMap.sourcesContent[idx]);
    });

    _.assign(opts, {
        output: {
            source_map: sourceMap
        }
    });
    result = UglifyES.minify(this.data, opts);

    this.map = result.map;
    this.data = result.code;
};

// Expose default MimeType of an engine
prop(UglifyCompressor, 'defaultMimeType', 'application/javascript');
