'use strict';
/*jshint esversion: 6 */
/*jshint node: true */

const path = require('path');
const ExtractTextPlugin = require('extract-text-webpack-plugin');

const baseConfig = require('./webpack.config.base.js');

const BASE_DIR = __dirname;

const extractCss = new ExtractTextPlugin('admin-[name].bundle.css');

module.exports = baseConfig(extractCss)({
	entry: {
		'app': path.join(
			BASE_DIR, 'front-end-sources', 'admin', 'scripts', 'main.ls'
		),
		'vendor': [
			'jquery',
			'jquery-ui/sortable',
			'backbone',
			'backbone.marionette',
			'backbone.wreqr',
			'ckeditor/adapters/jquery',
			'jade/jade'
		]
	},
	resolve: {
		alias: {
			base: path.resolve(BASE_DIR, 'front-end-sources', 'admin'),
			app: path.resolve(BASE_DIR, 'front-end-sources', 'admin', 'scripts'),
			tpl: path.resolve(BASE_DIR, 'front-end-sources', 'admin', 'templates')
		},
		extensions: ['', '.js', '.ls']
	},
	output: {
		path: path.join(BASE_DIR, 'static'),
		filename: 'admin-[name].bundle.js'
	},
	plugins: [
		extractCss
	]
});
