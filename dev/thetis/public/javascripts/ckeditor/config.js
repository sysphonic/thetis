/*
Copyright (c) 2003-2012, CKSource - Frederico Knabben. All rights reserved.
For licensing, see LICENSE.html or http://ckeditor.com/license
*/

CKEDITOR.editorConfig = function( config )
{
	// Define changes to default configuration here. For example:
	// config.language = 'fr';
	// config.uiColor = '#AADC6E';

  config.contentsCss = '../../javascripts/ckeditor/thetis_contents.css';
  config.resize_enabled = false;

  //config.removePlugins =  'elementspath,enterkey,entities,forms,pastefromword,htmldataprocessor,specialchar' ;
  config.removePlugins =  'elementspath,enterkey,entities,forms,pastefromword,htmldataprocessor,wsc';
  //config.toolbar = 'Basic';
  CKEDITOR.config.toolbar = [
   ['Maximize', 'ShowBlocks','-','Preview'],
   ['Source','-','Templates'],
   ['Cut','Copy','Paste','PasteText','PasteFromWord','-','SpellChecker','Scayt'],
   ['Undo','Redo','-','Find','Replace','-','SelectAll','RemoveFormat'],
   '/',
   ['Bold','Italic','Underline','Strike','-','Subscript','Superscript'],
   ['NumberedList','BulletedList','-','Outdent','Indent','Blockquote'],
   ['JustifyLeft','JustifyCenter','JustifyRight','JustifyBlock'],
   ['Link','Unlink','Anchor'],
   ['Image','Flash','Table','HorizontalRule','Smiley','SpecialChar','PageBreak'],
   '/',
   ['Styles','Format','Font','FontSize'],
   ['TextColor','BGColor']
  ];
};
