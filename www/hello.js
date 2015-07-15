/*global cordova, module*/

module.exports = {
    greet: function (name, successCallback, errorCallback) {
        cordova.exec(successCallback, errorCallback, "Hello", "greet", [name]);
    },
    piggyBack: function (successCallback, errorCallback) {
        cordova.exec(null, null, "Hello", "piggyBack", []);
    }
};
