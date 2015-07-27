/*global cordova, module, window*/
module.exports = {
 acr35WriteDataIntoTag: function(data, successCallback, errorCallback) {
  var self = this;
  cordova.exec(function(p) {
    if (p !== 'IGNORE') {
     successCallback.apply(self, arguments);
    }
    if (p === 'TIMEDOUT') {
     errorCallback.apply(self, arguments);
    }
    return true;
   },
   errorCallback,
   "ACR35Controller",
   "writeDataIntoTag", [data]
  );
 },
 acr35ReadDataFromTag: function(successCallback, errorCallback) {
  var self = this;
  cordova.exec(function(p) {
    if (p !== 'IGNORE') {
     successCallback.apply(self, arguments);
    }
    if (p === 'TIMEDOUT') {
     errorCallback.apply(self, arguments);
    }
    return true;
   },
   errorCallback,
   "ACR35Controller",
   "readDataFromTag", []
  );
 },
 acr35ReadIdFromTag: function(successCallback, errorCallback) {
  var self = this;
  cordova.exec(function(p) {
    if (p !== 'IGNORE') {
     successCallback.apply(self, arguments);
    }
    if (p === 'TIMEDOUT') {
     errorCallback.apply(self, arguments);
    }
    return true;
   },
   errorCallback,
   "ACR35Controller",
   "readIdFromTag", []
  );
 }
};
