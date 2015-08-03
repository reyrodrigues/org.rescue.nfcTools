/*global cordova, module, window*/
module.exports = {
    acr35WriteDataIntoTag: function (data, successCallback, errorCallback) {
        var self = this;
        cordova.exec(function (p) {
                if (p === 'TIMEDOUT') {
                    errorCallback.apply(self, arguments);
                } else if (p === 'NOTFOUND') {
                    errorCallback.apply(self, arguments);
                } else if (p !== 'IGNORE') {
                    successCallback.apply(self, arguments);
                }
                return true;
            },
            errorCallback,
            "ACR35Controller",
            "writeDataIntoTag", [data]
        );
    },
    acr35FormatNdef: function (successCallback, errorCallback) {
        var self = this;
        cordova.exec(function (p) {
                if (p === 'TIMEDOUT') {
                    errorCallback.apply(self, arguments);
                } else if (p === 'NOTFOUND') {
                    errorCallback.apply(self, arguments);
                } else if (p !== 'IGNORE') {
                    successCallback.apply(self, arguments);
                }
                return true;
            },
            errorCallback,
            "ACR35Controller",
            "formatNdef", []
        );
    },
    acr35ReadDataFromTag: function (successCallback, errorCallback) {
        var self = this;
        cordova.exec(function (p) {
                if (p === 'TIMEDOUT') {
                    errorCallback.apply(self, arguments);
                } else if (p === 'NOTFOUND') {
                    errorCallback.apply(self, arguments);
                } else if (p !== 'IGNORE') {
                    successCallback.apply(self, arguments);
                }
                return true;
            },
            errorCallback,
            "ACR35Controller",
            "readDataFromTag", []
        );
    },
    acr35ReadIdFromTag: function (successCallback, errorCallback) {
        var self = this;
        cordova.exec(function (p) {
                if (p === 'TIMEDOUT') {
                    errorCallback.apply(self, arguments);
                } else if (p === 'NOTFOUND') {
                    errorCallback.apply(self, arguments);
                } else if (p !== 'IGNORE') {
                    successCallback.apply(self, arguments);
                }
                return true;
            },
            errorCallback,
            "ACR35Controller",
            "readIdFromTag", []
        );
    },
    acr35GetDeviceStatus: function (successCallback, errorCallback) {
        var self = this;
        cordova.exec(function (p) {
                if (p === 'TIMEDOUT') {
                    errorCallback.apply(self, arguments);
                } else if (p === 'NOTFOUND') {
                    errorCallback.apply(self, arguments);
                } else if (p !== 'IGNORE') {
                    successCallback.apply(self, arguments);
                }
                return true;
            },
            errorCallback,
            "ACR35Controller",
            "getDeviceStatus", []
        );
    },
    acr35GetDeviceId: function (successCallback, errorCallback) {
        var self = this;
        cordova.exec(function (p) {
                if (p === 'TIMEDOUT') {
                    errorCallback.apply(self, arguments);
                } else if (p === 'NOTFOUND') {
                    errorCallback.apply(self, arguments);
                } else if (p !== 'IGNORE') {
                    successCallback.apply(self, arguments);
                }
                return true;
            },
            errorCallback,
            "ACR35Controller",
            "getDeviceId", []
        );
    },
    isoDepReadIdFromTag: function (successCallback, errorCallback) {
        var self = this;
        cordova.exec(function (p) {
                if (p === 'TIMEDOUT') {
                    errorCallback.apply(self, arguments);
                } else if (p === 'NOTFOUND') {
                    errorCallback.apply(self, arguments);
                } else if (p !== 'IGNORE') {
                    successCallback.apply(self, arguments);
                }
                return true;
            },
            errorCallback,
            "IsoDepController",
            "readIdFromTag", []
        );
    }
};
