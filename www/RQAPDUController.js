/*global cordova, module*/

module.exports = {
 readCallback: null,
 readFailCallback: null,
 writeDataIntoTag: function(key, data, successCallback, errorCallback) {
   this.readCallback = successCallback;
   this.readFailCallback = errorCallback;
   cordova.exec(successCallback, errorCallback, "RQAPDUController", "writeDataIntoTag", [data]);
 },
 readDataFromTag: function(successCallback, errorCallback) {
   this.readCallback = successCallback;
   this.readFailCallback = errorCallback;
   cordova.exec(successCallback, errorCallback, "RQAPDUController", "readDataFromTag", []);
 },
 readIdFromTag: function(successCallback, errorCallback) {
   this.readCallback = successCallback;
   this.readFailCallback = errorCallback;
   cordova.exec(successCallback, errorCallback, "RQAPDUController", "readIdFromTag", []);
 },
 executeCallback: function(result) {
  var self = this;
  cordova.fireDocumentEvent('nfc:data-received', {data:result});
 },
 timedOutCallback: function(result) {
  cordova.fireDocumentEvent('nfc:timeout', {});
 }
};
