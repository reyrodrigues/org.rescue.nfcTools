/*global cordova, module*/

module.exports = {
 readCallback: null,
 readFailCallback: null,
 writeDataIntoTag: function(data, successCallback, errorCallback) {
  var self = this;
  cordova.exec(function(p) {
    if(p!== 'IGNORE') {
      successCallback.apply(self, arguments)
    }

    return true;
   },
   errorCallback,
   "RQAPDUController",
   "writeDataIntoTag", [data]
  );
 },
 readDataFromTag: function(successCallback, errorCallback) {
  var self = this;
  cordova.exec(function(p) {
    if(p!== 'IGNORE') {
      successCallback.apply(self, arguments)
    }
         return true;

   },
   errorCallback,
   "RQAPDUController",
   "readDataFromTag", []
  );
 },
 readIdFromTag: function(successCallback, errorCallback) {
  var self = this;
  cordova.exec(function(p) {
    if(p!== 'IGNORE') {
      successCallback.apply(self, arguments)
    }
         return true;

   },
   errorCallback,
   "RQAPDUController",
   "readIdFromTag", []
  );
 },
 executeCallback: function(result) {
  var self = this;
  cordova.fireDocumentEvent('nfc:data-received', {
   data: result
  });
 },
 timedOutCallback: function(result) {
  cordova.fireDocumentEvent('nfc:timeout', {});
 }
};
