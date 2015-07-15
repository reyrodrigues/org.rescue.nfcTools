/*global cordova, module*/

module.exports = {
  init: function(config, successCallback, errorCallback) {
    cordova.exec(successCallback, errorCallback, "NFCCard", "init", [JSON.stringify(config)]);
  },
  writeData: function(successCallback, errorCallback) {
    cordova.exec(successCallback, errorCallback, "NFCCard", "writeData", []);
  },
  read: function(object) {
    alert('read');
    alert(object);
  }
};
